package Struct::Path::PerlStyle;

use 5.006;
use strict;
use warnings FATAL => 'all';
use parent qw(Exporter);
use Carp qw(croak);
use PPI;
use Scalar::Util qw(looks_like_number);

our @EXPORT_OK = qw(ps_parse ps_serialize);

=encoding utf8

=head1 NAME

Struct::Path::PerlStyle - Perl-style syntax frontend for L<Struct::Path|Struct::Path>.

=begin html

<a href="https://travis-ci.org/mr-mixas/Struct-Path-PerlStyle.pm"><img src="https://travis-ci.org/mr-mixas/Struct-Path-PerlStyle.pm.svg?branch=master" alt="Travis CI"></a>
<a href='https://coveralls.io/github/mr-mixas/Struct-Path-PerlStyle.pm?branch=master'><img src='https://coveralls.io/repos/github/mr-mixas/Struct-Path-PerlStyle.pm/badge.svg?branch=master' alt='Coverage Status'/></a>
<a href="https://badge.fury.io/pl/Struct-Path-PerlStyle"><img src="https://badge.fury.io/pl/Struct-Path-PerlStyle.svg" alt="CPAN version"></a>

=end html

=head1 VERSION

Version 0.71

=cut

our $VERSION = '0.71';

=head1 SYNOPSIS

    use Struct::Path::PerlStyle qw(ps_parse ps_serialize);

    $struct = ps_parse('{a}{b}[1]');    # string to Struct::Path path
    $string = ps_serialize($struct);    # Struct::Path path to string

=head1 EXPORT

Nothing is exported by default.

=head1 PATH SYNTAX

Examples:

    '{a}{b}'              # points to b's value
    '{a}{}'               # all values from a's subhash; same for arrays (using empty square brackets)
    '{a}{b,c}'            # b's and c's values
    '{a}{b c}'            # same, space also is a delimiter
    '{a}{"space inside"}' # key must be quoted unless it is a simple word (single quotes supported as well)
    '{a}{"multi\nline"}'  # same for special characters (if double quoted)
    '{a}{"π"}'            # keys containing non ASCII characters also must be quoted*
    '{a}{/regexp/}'       # regexp keys match
    '{a}{b}[0,1,2,5]'     # 0, 1, 2 and 5 array's items
    '{a}{b}[0..2,5]'      # same, but using ranges
    '{a}{b}[9..0]'        # descending ranges allowed (perl doesn't)
    '{a}{b}(back){c}'     # step back (to previous level)

    * at least until https://github.com/adamkennedy/PPI/issues/168

=head1 SUBROUTINES

=head2 ps_parse

Parse perl-style string to L<Struct::Path|Struct::Path> path

    $struct_path = ps_parse($string);

=cut

our $HOOKS = {
    'back' => sub { # step back $count times
        my $static = defined $_[0] ? $_[0] : 1;
        return sub {
            my $count = $static; # keep arg (reusable closure)
            while ($count) {
                croak "Can't step back (root of the structure)"
                    unless (@{$_[0]} and @{$_[1]});
                pop @{$_[0]};
                pop @{$_[1]};
                $count--;
            }
            return 1;
        };
    },
    '=~' => sub {
        croak "Only one arg accepted by '=~'" if (@_ != 1);
        my $arg = shift;
        return sub {
            return (defined ${$_[1]->[-1]} and ${$_[1]->[-1]} =~ $arg) ? 1 : 0;
        }
    },
    'defined' => sub {
        croak "no args accepted by 'defined'" if (@_);
        return sub { return defined (${$_[1]->[-1]}) ? 1 : 0 }
    },
    'eq' => sub {
        croak "Only one arg accepted by 'eq'" if (@_ != 1);
        my $arg = shift;
        return sub {
            return (defined ${$_[1]->[-1]} and ${$_[1]->[-1]} eq $arg) ? 1 : 0;
        };
    },
};

$HOOKS->{'<<'} = $HOOKS->{back}; # backward compatibility ('<<' is deprecated)

sub ps_parse($;$);
sub ps_parse($;$) {
    my ($path, $opts) = @_;
    croak "Undefined path passed" unless (defined $path);
    my $doc = PPI::Document->new(ref $path ? $path : \$path);
    croak "Failed to parse passed path '$path'" unless (defined $doc);
    my @out;

    for my $step ($doc->elements) {
        croak "Unsupported thing '$step' in the path, step #" . @out
            unless ($step->can('elements'));
        for my $item ($step->elements) {
            $item->prune('PPI::Token::Whitespace') if $item->can('prune');

            if ($item->isa('PPI::Structure') and $item->start->content eq '{' and $item->finish) {
                push @out, {};
                for my $t (map { $_->elements } $item->children) {
                    my $tmp;
                    if ($t->isa('PPI::Token::Word') or $t->isa('PPI::Token::Number')) {
                        $tmp->{keys} = $t->content;
                    } elsif ($t->isa('PPI::Token::Operator') and $t->content eq ',') {
                        next;
                    } elsif ($t->isa('PPI::Token::Quote::Single')) {
                        $tmp->{keys} = $t->literal;
                    } elsif ($t->isa('PPI::Token::Quote::Double')) {
                        $tmp->{keys} = $t->string;
                        $tmp->{keys} =~ s/\\"/"/g;
                    } elsif ($t->isa('PPI::Token::Regexp::Match')) {
                        $tmp->{regs} = substr(substr($t->content, 1), 0, -1); # get rid of slashes
                        $tmp->{regs} = qr($tmp->{regs});
                    } else {
                        croak "Unsupported thing '$t' for hash key, step #$#out";
                    }
                    map { push @{$out[-1]->{$_}}, delete $tmp->{$_} } keys %{$tmp};
                }
            } elsif ($item->isa('PPI::Structure') and $item->start->content eq '[' and $item->finish) {
                push @out, [];
                my $is_range;
                for my $t (map { $_->elements } $item->children) {
                    if ($t->isa('PPI::Token::Number')) {
                        croak "Incorrect array index '$t', step #$#out"
                            unless ($t->content == int($t->content));
                        if ($is_range) {
                            my $start = pop(@{$out[-1]});
                            croak "Range start undefided, step #$#out"
                                unless (defined $start);
                            push @{$out[-1]},
                                ($start < $t->content ? $start..$t->content : reverse $t->content..$start);
                            $is_range = undef;
                        } else {
                            push @{$out[-1]}, int($t->content);
                        }
                    } elsif ($t->isa('PPI::Token::Operator') and $t->content eq ',') {
                        $is_range = undef;
                    } elsif ($t->isa('PPI::Token::Operator') and $t->content eq '..') {
                        $is_range = $t;
                    } else {
                        croak "Unsupported thing '$t' for array index, step #$#out";
                    }
                }
                croak "Unfinished range secified, step #$#out" if ($is_range);
            } elsif ($item->isa('PPI::Structure') and $item->start->content eq '(' and $item->finish) {
                my ($hook, @args) = map { $_->elements } $item->children;
                my $neg;
                if ($hook->content eq 'not' or $hook->content eq '!') {
                    $neg = $hook->content;
                    $hook = shift @args;
                }
                croak "Unsupported thing '$hook' as hook, step #" . @out
                    unless ($hook->isa('PPI::Token::Operator') or $hook->isa('PPI::Token::Word'));
                croak "Unsupported hook '$hook', step #" . @out unless (exists $HOOKS->{$hook->content});
                @args = map {
                    if ($_->isa('PPI::Token::Quote::Single') or $_->isa('PPI::Token::Number')) {
                        $_->literal;
                    } elsif ($_->isa('PPI::Token::Quote::Double')) {
                        $_->string;
                    } else {
                        croak "Unsupported thing '$_' as hook argument, step #" . @out;
                    }
                } @args;
                $hook = $HOOKS->{$hook->content}->(@args); # closure with saved args
                push @out, ($neg ? sub { not $hook->(@_) } : $hook);
            } elsif ($item->isa('PPI::Token::Symbol') and $item->raw_type eq '$') {
                my $name = substr($item->content, 1); # cut off sigil
                croak "Unknown alias '$name'" unless (exists $opts->{aliases}->{$name});
                push @out, @{ps_parse($opts->{aliases}->{$name}, $opts)};
            } else {
                croak "Unsupported thing '$item' in the path, step #" . @out;
            }
        }
    }

    return \@out;
}

=head2 ps_serialize

Serialize L<Struct::Path|Struct::Path> path to perl-style string

    $string = ps_serialize($struct_path);

=cut

my %esc = (
    '"'  => '\"',
    "\a" => '\a',
    "\b" => '\b',
    "\t" => '\t',
    "\n" => '\n',
    "\f" => '\f',
    "\r" => '\r',
    "\e" => '\e',
);
my $esc = join('', keys %esc);

sub ps_serialize($) {
    my $path = shift;
    croak "Path must be an arrayref" unless (ref $path eq 'ARRAY');

    my $out = '';
    my $sc = 0; # step counter

    for my $step (@{$path}) {
        if (ref $step eq 'ARRAY') {
            my @ranges;
            for my $i (@{$step}) {
                croak "Incorrect array index '$i', step #$sc"
                    unless (looks_like_number($i) and int($i) == $i);
                if (@ranges and (
                    $ranges[-1][0] < $i and $ranges[-1][-1] == $i - 1 or   # ascending
                    $ranges[-1][0] > $i and $ranges[-1][-1] == $i + 1      # descending
                )) {
                    $ranges[-1][1] = $i; # update range
                } else {
                    push @ranges, [$i]; # new range
                }
            }
            $out .= "[" . join(",", map { $_->[0] == $_->[-1] ? $_->[0] : "$_->[0]..$_->[-1]" } @{ranges}) . "]";
        } elsif (ref $step eq 'HASH') {
            my @items;
            if (keys %{$step} == 1 and exists $step->{keys} and ref $step->{keys} eq 'ARRAY' or not keys %{$step}) {
                for my $k (@{$step->{keys}}) {
                    if (not defined $k) {
                        croak "Unsupported hash key type 'undef', step #$sc";
                    } elsif (ref $k) {
                        croak "Unsupported hash key type '" . (ref $k) . "', step #$sc";
                    } elsif (looks_like_number($k) or $k =~ /^[0-9a-zA-Z_]+$/) {
                        # \w doesn't fit -- PPI can't parse unquoted utf8 hash keys
                        # https://github.com/adamkennedy/PPI/issues/168#issuecomment-180506979
                        push @items, $k;
                    } else {
                        push @items, map { $_ =~ s/([\\$esc])/$esc{$1}/g; qq("$_"); } $k; # escape and quote
                    }
                }
            } else {
                croak "Unsupported hash definition, step #$sc";
            }
            $out .= "{" . join(",", @items) . "}";
        } else {
            croak "Unsupported thing in the path, step #$sc";
        }
        $sc++;
    }

    return $out;
}

=head1 AUTHOR

Michael Samoglyadov, C<< <mixas at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-struct-path-native at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Struct-Path-PerlStyle>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Struct::Path::PerlStyle

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Struct-Path-PerlStyle>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Struct-Path-PerlStyle>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Struct-Path-PerlStyle>

=item * Search CPAN

L<http://search.cpan.org/dist/Struct-Path-PerlStyle/>

=back

=head1 SEE ALSO

L<Struct::Path>, L<Struct::Diff>, L<perldsc>, L<perldata>

=head1 LICENSE AND COPYRIGHT

Copyright 2016,2017 Michael Samoglyadov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1; # End of Struct::Path::PerlStyle
