package Positron::DataTemplate;
our $VERSION = 'v0.1.3'; # VERSION

=head1 NAME

Positron::DataTemplate - templating plain data to plain data

=head1 VERSION

version v0.1.3

=head1 SYNOPSIS

    my $engine   = Positron::DataTemplate->new();
    my $template = { contents => ['@list', '$title'] };
    my $data     = { list => [
        { title => 'first title', url => '/first-title.html' },
        { title => 'second title', url => '/second-title.html' },
    ] };
    my $result   = $engine->process($template, $data);
    # { contents => [ 'first title', 'second title' ] }

=head1 DESCRIPTION

C<Positron::DataTemplate> is a templating engine. Unlike most templating engines,
though, it does not work on text, but on raw data: the template is (typically)
a hash or array reference, and the result is one, too.

This module rose from a script that regularly produced HTML snippets on disk,
using regular, text-based templates. Each use case used the same data, but a different
template. For one use case, however, the output was needed in
JSON format, not HTML. One solution would have been to use the text-based
templating system to produce a valid JSON document (quite risky). The other solution,
which was taken at that time, was to transform the input data into the desired
output structure in code, and use a JSON serializer on that, bypassing the template
output.

The third solution would have been to provide a template that did not directly
produce the serialised JSON text, but described the data structure transformation
in an on-disc format. By working only with structured data, and never with text,
the serialized output must always be valid JSON.

This (minus the serialization) is the domain of C<Positron::DataTemplate>.

=head1 EXAMPLES

This code is still being worked on. This includes the documentation. In the meanwhile,
please use the following examples (and some trial & error) to gain a first look.
Alternatively, if you have access to the tests of this distribution, these also
give some examples.

=head2 Text replacement

  [ '$one', '{$two}', 'and {$three}' ] + { one => 1, two => 2, three => 3 }
  -> [ '1', '2', 'and 3' ]

=head2 Direct inclusion

  [ '&this', '&that' ] + { this => [1, 2], that => { 3 => 4 } }
  -> [ [1, 2], { 3 => 4} ]

=head2 Loops

  { titles => ['@list', '{$id}: {$title}'] }
  + { list => [ { id => 1, title => 'one' }, { id => 2, title => 'two' } ] }
  -> { titles => [ '1: one', '2: two' ] }

=head2 Conditions

  { checked => ['?active', 'yes', 'no] } + { active => 1 }
  -> { checked => 'yes' }

=head2 Interpolation (works with a lot of constructs)

  [1, '&list', 4] + { list => [2, 3] }
  -> [1, [2, 3], 4]
  [1, '&-list', 4] + { list => [2, 3] }
  -> [1, 2, 3, 4]
  [1, '<', '&list', 4] + { list => [2, 3] }
  -> [1, 2, 3, 4]

  { '< 1' => { a => 'b' }, '< 2' => { c => 'd', e => 'f' }
  -> { a => 'b', c => 'd', e => 'f' }
  { '< 1' => '&hash', two => 2 } + { hash => { one => 1 } }
  -> { one => 1, two => 2 }

=head2 Comments

  'this is {#not} a comment' -> 'this is a comment'
  [1, '#comment', 2, 3]      -> [1, 2, 3]
  [1, '/comment', 2, 3]      -> [1, 3]
  [1, '//comment', 2, 3]     -> [1]
  { 1 => 2, '#3' => 4 }      -> { 1 => 2, '' => 4 }
  { 1 => 2, '/3' => 4 }      -> { 1 => 2 }

=head2 File inclusion (requires L<JSON> and L<File::Slurp>)

  [1, '. "/tmp/data.json"', 3] + '{ key: "value"}'
  -> [1, { key => 'value' }, 3]

=head2 File wrapping (also requires L<JSON> and L<File::Slurp>)

  [1, ': "/tmp/wrap.json"', { animal => 'dog' }, 3]
  + '{ key: "value", contents: ":"}'
  -> [1, { key => 'value', contents => { animal => 'dog' }, 3]

=head2 Funtions on data

  [1, '^len', "abcde", 2] + { len => \&CORE::length }
  -> [1, 5, 2]

=head2 Assignment

  [1, '= title object.name', 'My {$title} and {$count}' ]
  + { object => { name => 'Name', count => 10 } }
  -> [1, 'My Name and']

=head2 Escaping other constructs

  [ '~?cond', 'Talking about {{~}$templates}', '~.htaccess' ]
  -> [ '?cond', 'Talking about {$templates}', '.htaccess' ]
=cut

use v5.10;
use strict;
use warnings;

use Carp qw( croak );
use Data::Dump qw(dump);
use Positron::Environment;
use Positron::Expression;

sub new {
    # Note: no Moose; we have no inheritance or attributes to speak of.
    my ($class) = @_;
    my $self = {
        include_paths => ['.'],
    };
    return bless($self, $class);
}

sub process {
    my ($self, $template, $env) = @_;
    # Returns (undef) in list context - is this correct?
    return undef unless defined $template;
    $env = Positron::Environment->new($env);
    my ($return, $interpolate) = $self->_process($template, $env);
    # $return may be an interpolating construct,
    # which depends on the context here.
    if (wantarray and $interpolate and ref($return) eq 'ARRAY') {
        return @$return;
    } else {
        return $return;
    }
}

sub _process {
    my ($self, $template, $env) = @_;
    if (not ref($template)) {
        return $self->_process_text($template, $env);
    } elsif (ref($template) eq 'ARRAY') {
        return $self->_process_array($template, $env);
    } elsif (ref($template) eq 'HASH') {
        return $self->_process_hash($template, $env);
    }
    return $template; # TODO: deep copy?
}

sub _process_text {
    my ($self, $template, $env) = @_;
    return ($template, 0) unless $template; # undef, '', 0, or '0'
    my $interpolate = 0;
    if ($template =~ m{ \A [&,] (-?) (.*) \z}xms) {
        if ($1) { $interpolate = 1; }
        my $expr = $2;
        if ($expr eq ':') {
            # Special case: internal wrap evaluation
            my ($return, $i) = $self->_process($env->get(':'), $env);
            $interpolate ||= $i;
            return ($return, $interpolate);
        } else {
            return (Positron::Expression::evaluate($expr, $env), $interpolate);
        }
    } elsif ($template =~ m{ \A \$ (.*) \z}xms) {
        my $value = Positron::Expression::evaluate($1, $env) // '';
        return ("$value", 0);
    } elsif ($template =~ m{ \A \x23 (\+?) }xms) {
        return ('', ($1 ? 0 : 1));
    } elsif ($template =~ m{ \A = \s* (\w+) \s+ (.*) }xms) {
        # Always interpolates, the new identifier means nothing
        Positron::Expression::evaluate($2, $env); # still perform it, means nothing
        return ('', 1);
    } elsif ($template =~ m{ \A ([.:]) (-?) \s* ([^\s-].*) }xms) {
        my $filename_expr = $3;
        if ($2) { $interpolate = 1; }
        my $new_env = $env;
        if ($1 eq ':') {
            # A wrap in text context, explicitly unset ':'.
            $new_env = Positron::Environment->new({ ':' => undef }, { parent => $env });
        }
        my $filename = Positron::Expression::evaluate($filename_expr, $new_env);
        require JSON;
        require File::Slurp;
        my $json = JSON->new();
        my $file = undef;
        foreach my $path (@{$self->{include_paths}}) {
            if (-f $path . $filename) {
                $file = $path . $filename; # TODO: platform-independent chaining
            }
        }
        if ($file) {
            my $result = $json->decode(scalar(File::Slurp::read_file($file)));
            my ($return, $i) = $self->_process($result, $new_env);
            $interpolate ||= $i;
            return ($return, $interpolate);
        } else {
            croak "Can't find template '$filename' in " . join(':', @{$self->{include_paths}});
        }
    } elsif ($template =~ m{ \A \: (-?) \s* \z }xms) {
        # wrap evaluation
        if ($1) { $interpolate = 1; }
        my ($return, $i) = $self->_process($env->get(':'), $env);
        $interpolate ||= $i;
        return ($return, $interpolate);
    } elsif ($template =~ m{ \A \^ (-?) \s* (.*) }xms) {
        # Special non-list case, e.g. hash value (not key)
        # cannot interpolate
        my $function = Positron::Expression::evaluate($2, $env);
        return (scalar($function->()), 0);
    } else {
        $template =~ s{
            \{ \$ ([^\}]*) \}
        }{
            my $replacement = Positron::Expression::evaluate($1, $env) // '';
            "$replacement";
        }xmseg;
        $template =~ s{
           (\s*) \{ \x23 (-?) ([^\}]*) \} (\s*)
        }{
            $2 ? '' : $1 . $4;
        }xmseg;
        # At the very end: get rid of escaping tildes (one layer)
        $template =~ s{ \A ~ }{}xms;
        $template =~ s{ \{ ~ \} }{}xmsg;
        return ($template, 0);
    }
}

sub _process_array {
    my ($self, $template, $env) = @_;
    my $interpolate = 0;
    return ([], 0) unless @$template;
    my @elements = @$template;
    if ($elements[0] =~ m{ \A \@ (-?) (.*) \z}xms) {
        # list iteration
        if ($1) { $interpolate = 1; }
        my $clause = $2;
        shift @elements;
        my $result = [];
        my $list = Positron::Expression::evaluate($clause, $env);
        if (not ref($list) eq 'ARRAY') {
            # If it's not a list, make it a one-element list.
            # Useful for forcing interpolation via '[@- ""]' or aliasing (to be introduced)
            $list = [$list];
        }
        foreach my $el (@$list) {
            my $new_env = Positron::Environment->new( $el, { parent => $env } );
            # evaluate rest of list as array,
            my ($return, undef) = $self->_process_array(\@elements, $new_env);
            # and flatten
            push @$result, @$return;
        }
        return ($result, $interpolate);
    } elsif ($elements[0] =~ m{ \A \? (-?) (.*) \z}xms) {
        # conditional
        if ($1) { $interpolate = 1; }
        my $clause = $2;
        shift @elements;
        my $has_else = (@elements > 1) ? 1 : 0;
        my $cond = Positron::Expression::evaluate($clause, $env); # can be anything!
        # for Positron, empty lists and hashes are false!
        $cond = Positron::Expression::true($cond);
        if (not $cond and not $has_else) {
            # no else clause, return empty on false
            # (please interpolate!)
            return ('', 1);
        }
        my $then = shift @elements;
        my $else = shift @elements;
        my $result = $cond ? $then : $else;
        my ($return, $i) = $self->_process($result, $env);
        $interpolate ||= $i;
        return ($return, $interpolate);
    } else {
        my $return = [];
        # potential structural comments
        my $skip_next = 0;
        my $capturing_function = 0;
        my $capturing_wrap = 0;
        my $capturing_wrap_interpolates = 0;
        my $interpolate_next = 0; # actual count
        my $is_first_element = 1;
        foreach my $element (@elements) {
            if ($element =~ m{ \A // (-?) }xms) {
                if ($is_first_element and $1) { $interpolate = 1; }
                last; # nothing more
            } elsif ($element =~ m{ \A / (-?) }xms) {
                if ($is_first_element and $1) { $interpolate = 1; }
                $skip_next = 1;
            } elsif ($skip_next) {
                $skip_next = 0;
            } elsif ($element =~ m{ \A \^ (-?) \s* ([^\s-].*) }xms) {
                if ($is_first_element and $1) { $interpolate = 1; }
                $capturing_function = Positron::Expression::evaluate($2, $env);
                # do not push!
            } elsif ($element =~ m{ \A \: (-?) \s* ([^\s-].*) }xms) {
                $capturing_wrap_interpolates = $1 ? 1 : 0;
                my $filename = Positron::Expression::evaluate($2, $env);
                if (!$filename) {
                    warn "# no filename in expression '$element'?";
                }
                require JSON;
                require File::Slurp;
                my $json = JSON->new();
                my $file = undef;
                foreach my $path (@{$self->{include_paths}}) {
                    if (-f $path . $filename) {
                        $file = $path . $filename; # TODO: platform-independent chaining
                    }
                }
                if ($file) {
                    my $contents = File::Slurp::read_file($file);
                    $capturing_wrap = $json->decode($contents);
                } else {
                    croak "Can't find template '$filename' in " . join(':', @{$self->{include_paths}});
                }
                # do not push!
            } elsif ($element =~ m{ \A = (-?) \s* (\w+) \s+ (.*) }xms) {
                if ($is_first_element and $1) { $interpolate = 1; }
                my $new_key = $2;
                my $new_value = Positron::Expression::evaluate($3, $env);
                # We change env here!
                $env = Positron::Environment->new({}, { parent => $env });
                $env->set($new_key, $new_value); # Handles '_' on either side
            } elsif ($capturing_function) {
                # we have a capturing function waiting for input
                my ($arg, $i) = $self->_process($element, $env);
                # interpolate: could be ['@- ""', arg1, arg2]
                if (ref($arg) eq 'ARRAY' and $i) {
                    push @$return, $capturing_function->(@$arg);
                } elsif (ref($arg) eq 'HASH' and $i) {
                    push @$return, $capturing_function->(%$arg);
                } else {
                    push @$return, $capturing_function->($arg);
                }
                # no more waiting function
                $capturing_function = 0;
            } elsif ($capturing_wrap) {
                # we have a capturing wrap file waiting for input
                # Note: neither the wrap nor the element have been evaluated yet!
                my $new_env = Positron::Environment->new({ ':' => $element }, { parent => $env });
                my ($result, $i) = $self->_process($capturing_wrap, $new_env);
                $i ||= $capturing_wrap_interpolates;
                # interpolate: could be ['@- ""', arg1, arg2]
                #              or [1, ':- file', 'contents', 2]
                if (ref($result) eq 'ARRAY' and $i) {
                    push @$return, @$result;
                } elsif (ref($result) eq 'HASH' and $i) {
                    push @$return, %$result;
                } else {
                    push @$return, $result;
                }
                # no more waiting wrap
                $capturing_wrap = 0;
            } elsif ($element =~ m{ \A < }xms) {
                $interpolate_next += 1; # actual count
            } else {
                my ($result, $interpolate_me) = $self->_process($element, $env);
                my @results = ($result);
                $interpolate_next += $interpolate_me;
                while ($interpolate_next > 0 and @results) {
                    if (ref($results[0]) eq 'ARRAY') {
                        my $array = shift @results;
                        unshift @results, @$array;
                    } elsif (($results[0] // '') eq '') {
                        # Note: the empty string, if it wants to interpolate, becomes the empty list
                        #       i.e. just drop it.
                        shift @results;
                    } else {
                        last; # conditions can't match any more
                    }
                    $interpolate_next--;
                }
                $interpolate_next = 0;
                push @$return, @results;
            }
            $is_first_element = 0; # not anymore
        }
        if ($capturing_function) {
            # Oh no, a function waiting for args?
            push @$return, $capturing_function->();
        }
        if ($capturing_wrap) {
            # Oh no, a wrap waiting for args?
            my $new_env = Positron::Environment->new({ ':' => undef }, { parent => $env });
            my ($result, $i) = $self->_process($capturing_wrap, $new_env);
            if (ref($result) eq 'ARRAY' and $i) {
                push @$return, @$result;
            } elsif (ref($result) eq 'HASH' and $i) {
                push @$return, %$result;
            } else {
                push @$return, $result;
            }
        }
        return ($return, $interpolate);
    }
}
sub _process_hash {
    my ($self, $template, $env) = @_;
    return ({}, 0) unless %$template;
    my %result = ();
    my $hash_construct = undef;
    my $switch_construct = undef;
    foreach my $key (keys %$template) {
        if ($key =~ m{ \A \% (.*) \z }xms) {
            $hash_construct = [$key, $1]; last;
        } elsif ($key =~ m{ \A \| (.*) \z }xms) {
            # basically auto-interpolates
            $switch_construct = [$key, $1]; last;
        }
    }
    if ($hash_construct) {
        my $e_content = Positron::Expression::evaluate($hash_construct->[1], $env);
        croak "Error: result of expression '".$hash_construct->[1]."' must be hash" unless ref($e_content) eq 'HASH';
        while (my ($key, $value) = each %$e_content) {
            my $new_env = Positron::Environment->new( { key => $key, value => $value }, { parent => $env } );
            my ($t_content, undef) = $self->_process( $template->{$hash_construct->[0]}, $new_env);
            croak "Error: content of % construct must be hash" unless ref($t_content) eq 'HASH';
            # copy into result (automatically interpolates)
            foreach my $k (keys %$t_content) {
                $result{$k} = $t_content->{$k};
            }
        }
    } elsif ($switch_construct) {
        my $e_content = Positron::Expression::evaluate($switch_construct->[1], $env); # The switch key
        # escape the '|' by adding another one!
        my $qe_content = ( defined $e_content and $e_content =~m{ \A \|}xms ) ? "|$e_content" : $e_content;
        if (defined $e_content and exists $template->{$switch_construct->[0]}->{$qe_content}) {
            # We have no interpolation of our own, just pass the below up.
            return $self->_process($template->{$switch_construct->[0]}->{$qe_content}, $env);
        } elsif (exists $template->{$switch_construct->[0]}->{'|'}) {
            return $self->_process($template->{$switch_construct->[0]}->{'|'}, $env);
        } else {
            return ('', 1);
        }
    } else {
        # simple copy
        # '<': find first, and interpolate
        # do by sorting keys alphabetically
        my @keys = sort {
            if($a =~ m{ \A < }xms) {
                if ($b =~ m{ \A < }xms) {
                    return $a cmp $b;
                } else {
                    return -1;
                }
            } else {
                if ($b =~ m{ \A < }xms) {
                    return 1;
                } else {
                    return $a cmp $b;
                }
            }
        } keys %$template;
        foreach my $key (@keys) {
            my $value = $template->{$key};
            if ($key =~ m{ \A < }xms) {
                # interpolate
                my ($values, $interpolate) = $self->_process($value, $env);
                %result = (%result, %$values);
                next;
            }
            if ($key =~ m{ \A / }xms) {
                # structural comment
                next;
            }
            if ($value =~ m{ \A / }xms) {
                # structural comment (forbidden on values)
                croak "Cannot comment out a value";
            }
            if ($key =~ m{ \A \^ \s* (.*)}xms) {
                # consuming function call (interpolates)
                my $func = Positron::Expression::evaluate($1, $env);
                my ($value_in, undef) = $self->_process($value, $env);
                my $hash_out = $func->($value_in);
                # interpolate
                foreach my $k (keys %$hash_out) {
                    $result{$k} = $hash_out->{$k};
                }
                next;
            }
            if ($key =~ m{ \A : (-?) \s* (.+) }xms) {
                # consuming wrap (interpolates in any case)
                my $capturing_wrap;
                my $filename = Positron::Expression::evaluate($2, $env);
                require JSON;
                require File::Slurp;
                my $json = JSON->new();
                my $file = undef;
                foreach my $path (@{$self->{include_paths}}) {
                    if (-f $path . $filename) {
                        $file = $path . $filename; # TODO: platform-independent chaining
                    }
                }
                if ($file) {
                    my $contents = File::Slurp::read_file($file);
                    $capturing_wrap = $json->decode($contents);
                } else {
                    croak "Can't find template '$filename' in " . join(':', @{$self->{include_paths}});
                }
                my $new_env = Positron::Environment->new({ ':' => $value }, { parent => $env });
                my ($hash_out, undef) = $self->_process($capturing_wrap, $new_env);
                # interpolate
                foreach my $k (keys %$hash_out) {
                    $result{$k} = $hash_out->{$k};
                }
                next;
            }
            if ($key =~ m{ \A = (-?) \s* (\w+) \s+ (.*) }xms) {
                # assignment (always interpolates)
                my $new_key = $2;
                my $new_value = Positron::Expression::evaluate($3, $env);
                # We change env here!
                my $new_env = Positron::Environment->new({}, { parent => $env });
                $new_env->set($new_key, $new_value); # Handles '_' on either side
                my ($hash_out, undef) = $self->_process($value, $new_env);
                # interpolate
                foreach my $k (keys %$hash_out) {
                    $result{$k} = $hash_out->{$k};
                }
                next;
            }
            if ($key =~ m{ \A \? \s* (.*)}xms) {
                # "conditional key", syntactic sugar that interpolates the hash
                # Short for { '< 1' => ['?cond', { ... }, {}], ... }
                my $cond = Positron::Expression::evaluate($1, $env);
                if ($cond) {
                    my ($hash_out, undef) = $self->_process($value, $env);
                    # interpolate
                    foreach my $k (keys %$hash_out) {
                        $result{$k} = $hash_out->{$k};
                    }
                } else {
                    # nothing!
                }
                next;
            }
            ($key, undef) = $self->_process($key, $env);
            ($value, undef) = $self->_process($value, $env);
            $result{$key} = $value;
        }
    }
    return (\%result, 0);
}

sub add_include_paths {
    my ($self, @paths) = @_;
    push @{$self->{'include_paths'}}, @paths;
}

1; # End of Positron::DataTemplate

__END__

=head1 AUTHOR

Ben Deutsch, C<< <ben at bendeutsch.de> >>

=head1 BUGS

None known so far, though keep in mind that this is alpha software.

Please report any bugs or feature requests to C<bug-positron at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Positron>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

This module is part of the Positron distribution.

You can find documentation for this distribution with the perldoc command.

    perldoc Positron

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Positron>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Positron>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Positron>

=item * Search CPAN

L<http://search.cpan.org/dist/Positron/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Ben Deutsch. All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
See L<http://dev.perl.org/licenses/> for more information.

=cut
