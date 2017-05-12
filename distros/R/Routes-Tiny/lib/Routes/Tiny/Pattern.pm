package Routes::Tiny::Pattern;

use strict;
use warnings;

require Scalar::Util;
use Routes::Tiny::Match;

my $TOKEN = '[^\/()]+';

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    if (my $arguments = delete $params{'+arguments'}) {
        $self->{arguments_push} = 1;
        $params{arguments} = $arguments;
    }

    $self->{name}           = $params{name};
    $self->{defaults}       = $params{defaults};
    $self->{arguments}      = $params{arguments};
    $self->{method}         = $params{method} || $params{default_method};
    $self->{pattern}        = $params{pattern};
    $self->{constraints}    = $params{constraints} || {};
    $self->{routes}         = $params{routes};
    $self->{subroutes}      = $params{subroutes};
    $self->{strict_trailing_slash} = $params{strict_trailing_slash};

    Scalar::Util::weaken($self->{routes}) if $self->{routes};
    $self->{strict_trailing_slash} = 1 unless defined $self->{strict_trailing_slash};

    if (my $methods = $self->{method}) {
        $methods = [$methods] unless ref $methods eq 'ARRAY';
        $methods = [map {uc} @$methods];
        $self->{method} = $methods;
    }

    $self->{captures} = [];

    $self->_prepare_pattern;

    return $self;
}

sub arguments { return shift->{arguments} }

sub name { return shift->{name} }

sub match {
    my $self = shift;
    my ($path, %args) = @_;

    return unless $self->_match_method($args{method});

    $path = '/' . $path unless substr($path, 0, 1) eq '/';

    if (!$self->{strict_trailing_slash} && $path ne '/' && $path !~ m{/$}) {
        $path .= '/';
    }

    my @captures = ($path =~ $self->{pattern});
    return unless @captures;

    my $captures = {%{$self->{defaults} || {}}};

    foreach my $capture (@{$self->{captures}}) {
        last unless @captures;

        my $value = shift @captures;

        if (defined($value) || !exists $captures->{$capture}) {
            $captures->{$capture} = $value;
        }
    }

    my $arguments;
    if ($self->{arguments_push}) {
        %$arguments = %{ $self->arguments };

        foreach my $key (keys %{ $args{arguments} || {} }) {
            my $value = $args{arguments}->{$key};

            if (exists $arguments->{$key}) {
                $arguments->{$key} = [$arguments->{$key}] unless ref $arguments->{$key} eq 'ARRAY';
                unshift @{ $arguments->{$key} }, ref $value eq 'ARRAY' ? @$value : $value;
            }
            else {
                $arguments->{$key} = $value;
            }
        }
    }
    else {
        $arguments = {
            %{ $args{arguments} || {} },
            %{ $self->arguments || {} }
        };
    }

    my $match = $self->_build_match(
        name      => $self->name,
        arguments => $arguments,
        captures  => $captures,
        parent    => $args{parent}
    );

    if ($self->{subroutes}) {
        my $parent = $match;
        my $tail = substr($path, length $&);
        $match = $self->{subroutes}
          ->match($tail, %args, parent => $parent, arguments => $arguments);
    }

    return $match;
}

sub build_path {
    my $self   = shift;
    my (%params) = @_;

    my @parts;

    my $optional_depth = 0;
    my $trailing_slash = 0;

    foreach my $group_part (@{$self->{parts}}) {
        my $path = '';

        foreach my $part (@$group_part) {
            my $type = $part->{type};
            my $name = $part->{name};

            if ($type eq 'capture') {
                if ($part->{level} && exists $params{$name}) {
                    $optional_depth = $part->{level};
                }

                if (!exists $params{$name}) {
                    next
                      if $part->{level} && $part->{level} > $optional_depth;

                    if (   exists $self->{defaults}
                        && exists $self->{defaults}->{$name})
                    {
                        $params{$name} = $self->{defaults}->{$name};
                    }
                    else {
                        Carp::croak("Required param '$part->{name}' was not "
                              . "passed when building a path");
                    }
                }

                my $param = $params{$name};

                if (defined(my $constraint = $part->{constraint})) {
                    Carp::croak("Param '$name' fails a constraint")
                      unless $param =~ m/^ $constraint $/xms;
                }

                $path .= $param;
            }
            elsif ($type eq 'glob') {
                if (!exists $params{$name}) {
                    if (   exists $self->{defaults}
                        && exists $self->{defaults}->{$name})
                    {
                        $params{$name} = $self->{defaults}->{$name};
                    }
                    elsif ($part->{optional}) {
                        next;
                    }
                    else {
                        Carp::croak(
                                "Required glob param '$part->{name}' was not "
                              . "passed when building a path");
                    }
                }

                $path .= $params{$name};
            }
            elsif ($type eq 'text') {
                $path .= $part->{text};
            }

            $trailing_slash = $part->{trailing_slash};
        }

        if ($path ne '') {
            push @parts, $path;
        }
    }

    my $head = q{/};

    my $parent_pattern = $self->{routes} && $self->{routes}->{parent_pattern};
    if ($parent_pattern) {
        $head = $parent_pattern->build_path(%params);
        $head .= q{/} unless substr($head, -1) eq q{/};
    }

    my $path = $head . join q{/} => @parts;

    if ($path ne '/' && $trailing_slash) {
        $path .= q{/};
    }

    return $path;
}

sub _match_method {
    my $self = shift;
    my ($value) = @_;

    my $methods = $self->{method};

    return 1 unless defined $methods;

    return unless defined $value;
    $value = uc $value;

    return !!scalar grep { $_ eq $value } @{$methods};
}

sub _prepare_pattern {
    my $self = shift;

    return $self->{pattern} if ref $self->{pattern} eq 'Regexp';

    my $pattern = $self->{pattern};
    if ($pattern !~ m{ \A ( / | \(/.+?\)\?/ ) }xms) {
        $pattern = q{/} . $pattern;
    }

    $self->{captures} = [];

    my $re        = q{};
    my $par_depth = 0;
    my @parts;

    my $part;

    pos $pattern = 0;
    while (pos $pattern < length $pattern) {
        if ($pattern =~ m{ \G \/ }gcxms) {
            if ($part) {
                push @parts, $part;
            }

            $part = [];
            $re .= q{/};
        }
        elsif ($pattern =~ m{ \G :($TOKEN) }gcxms) {
            my $name = $1;
            my $constraint;

            if (exists $self->{constraints}->{$name}) {
                $constraint = $self->{constraints}->{$name};
                if (ref $constraint eq 'ARRAY') {
                    $constraint = join('|', @$constraint);
                }
                $re .= "($constraint)";
            }
            else {
                $re .= '([^\/]+)';
            }

            push @$part,
              { type       => 'capture',
                name       => $name,
                constraint => $constraint ? qr/^ $constraint $/xms : undef,
                level      => $par_depth
              };

            push @{$self->{captures}}, $name;
        }
        elsif ($pattern =~ m{ \G \*($TOKEN) }gcxms) {
            my $name = $1;

            $re .= '(.*)';

            push @$part, {type => 'glob', name => $name};

            push @{$self->{captures}}, $name;
        }
        elsif ($pattern =~ m{ \G ($TOKEN) }gcxms) {
            my $text = $1;
            $re .= quotemeta $text;

            push @$part, {type => 'text', text => $text};
        }
        elsif ($pattern =~ m{ \G \( }gcxms) {
            $par_depth++;
            $re .= '(?: ';
            next;
        }
        elsif ($pattern =~ m{ \G \)\? }gcxms) {
            $part->[-1]->{optional} = 1;
            $par_depth--;
            $re .= ' )?';
            next;
        }
        elsif ($pattern =~ m{ \G \) }gcxms) {
            $par_depth--;
            $re .= ' )';
            next;
        }

        if ($part->[-1] && substr($pattern, pos($pattern), 1) eq '/') {
            $part->[-1]->{trailing_slash} = 1;
        }
    }

    if ($par_depth != 0) {
        Carp::croak("Parentheses are not balanced in pattern '$pattern'");
    }

    if (!$self->{strict_trailing_slash} && !$self->{subroutes}) {
        if ($re =~ m{/$}) {
            $re .= '?';
        }
        elsif ($re =~ m{\)\?$}) {
            $re =~ s{\)\?$}{/?)?}
        }
        else {
            $re .= '/?';
        }
    }

    if ($self->{subroutes}) {
        $re = qr/^ $re /xmsi;
    }
    else {
        $re = qr/^ $re $/xmsi;
    }

    if ($part && @$part) {
        push @parts, $part;
    }

    $self->{parts}   = [@parts];
    $self->{pattern} = $re;

    return $self;
}

sub _build_match { shift; return Routes::Tiny::Match->new(@_) }

1;
__END__

=head1 NAME

Routes::Tiny::Pattern - Routes pattern

=head1 SYNOPSIS

    my $pattern = Routes::Tiny::Pattern->new(
        pattern  => '/:foo/:bar',
        defaults => {bar => 'index'},
        name     => 'route'
    );

    my $match = $pattern->match('/hello/world');

    my $path = $pattern->build_path('route', foo => 'hello', bar => 'world');

=head1 DESCRIPTION

L<Routes::Tiny::Pattern> is an Object that incapsulates pattern matching and
path building.

=head1 ATTRIBUTES

=head2 C<defaults>

Pass default values for captures.

=head2 C<constraints>

Pass constraints.

=head2 C<name>

Pass route name.

=head2 C<arguments>

Pass arbitrary arguments.

=head1 METHODS

=head2 C<new>

    my $pattern = Routes::Tiny::Pattern->new;

Create new instance of L<Routes::Tiny::Pattern>.

=head2 C<match>

Match pattern agains a path.

=head2 C<build_path>

    $pattern->build_path('name', {foo => 'bar'});

Build path from a given name and params.

=cut
