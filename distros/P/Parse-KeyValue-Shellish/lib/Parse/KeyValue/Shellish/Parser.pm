package Parse::KeyValue::Shellish::Parser;
use strict;
use warnings;
use Carp;

sub new {
    my ($class, $str) = @_;

    bless {
        index   => 0,
        escaped => 0,
        key     => '',
        str     => $str,
        strlen  => length $str,
        parsed  => {},
    }, $class;
}

sub parse {
    my ($self) = @_;

    my $value  = '';
    my $strlen = $self->{strlen};
    for ($self->{index} = 0; $self->{index} < $strlen; $self->{index}++) {
        my $ch = substr($self->{str}, $self->{index}, 1);

        if ($ch eq '=') {
            if ($self->{key}) { # for example `foo=bar=buz`
                $value .= $ch;
                next;
            }
            $self->{key} = $value;
            $value = '';
            next;
        }

        if ($ch =~ /\s/) {
            if ($self->{escaped}) {
                $value .= $ch;
                $self->{escaped} = 0;
                next;
            }

            if ($self->{key}) {
                $self->{parsed}->{$self->{key}} = $value;
            }
            $self->{key} = '';
            $value = '';
            next;
        }

        if ($ch eq "'" || $ch eq '"') {
            $value .= $self->_parse_in_quote($ch);
            next;
        }

        if ($ch eq '(' && !$self->{escaped}) {
            $self->_parse_in_paren;
            next;
        }

        if ($ch eq ')' && !$self->{escaped}) {
            croak qq{[ERROR] Unbalanced parenthesis "$self->{str}"};
        }

        if ($ch eq '\\') {
            if ($self->{escaped}) {
                $value .= $ch;
                $self->{escaped} = 0;
                next;
            }
            $self->{escaped} = 1;
            next;
        }

        $value .= $ch;
        $self->{escaped} = 0;
    }

    if ($self->{key} && $value) {
        $value .= '\\' if $self->{escaped};
        $self->{parsed}->{$self->{key}} = $value;
    }

    return $self->{parsed};
}

sub _parse_in_quote {
    my ($self, $quote) = @_;

    my $balanced = 0;
    my $value    = '';
    my $strlen   = $self->{strlen};

    for ($self->{index}++; $self->{index} < $strlen; $self->{index}++) {
        my $ch = substr $self->{str}, $self->{index}, 1;

        if ($ch eq $quote && !$self->{escaped}) {
            $balanced = 1;
            last;
        }

        if ($ch eq '\\') {
            if ($quote eq "'") {
                $value .= $ch;
                next;
            }
            $self->{escaped} = 1;
            next;
        }

        $value .= $ch;
        $self->{escaped} = 0;
    }

    croak qq{[ERROR] Unbalanced quotation: "$self->{str}"} unless $balanced;

    return $value;
}

sub _parse_in_paren {
    my ($self) = @_;

    my @array;
    my $balanced = 0;
    my $value    = '';
    my $strlen   = $self->{strlen};

    for ($self->{index}++; $self->{index} < $strlen; $self->{index}++) {
        my $ch = substr($self->{str}, $self->{index}, 1);

        if ($ch eq '(') {
            croak qq{[ERROR] Unbalanced parenthesis "$self->{str}"};
        }

        if ($ch eq ')') {
            $balanced = 1;
            last;
        }

        if ($ch =~ /\s/) {
            push @array, $value;
            $value = '';
            next;
        }

        if ($ch eq "'" || $ch eq '"') {
            $value .= $self->_parse_in_quote($ch);
            next;
        }

        $value .= $ch;
    }

    if ($self->{key} && $value) {
        $value .= '\\' if $self->{escaped};
        push @array, $value;
        $value = '';
    }

    croak qq{[ERROR] Unbalanced parenthesis "$self->{str}"} unless $balanced;

    $self->{parsed}->{$self->{key}} = \@array;
    $self->{key} = '';
}

1;

