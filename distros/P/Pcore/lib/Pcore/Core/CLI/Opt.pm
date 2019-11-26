package Pcore::Core::CLI::Opt;

# NOTE http://docopt.org/

use Pcore -class;
use Pcore::Util::Scalar qw[is_ref is_plain_arrayref is_plain_hashref];

with qw[Pcore::Core::CLI::Type];

has name  => ( required => 1 );
has short => ( is       => 'lazy' );    # undef - disable short option
has desc  => ();

has type    => ( is => 'lazy' );        # option type desc for usage help
has isa     => ();                      # CodeRef | RegexpRef | ArrayRef | Enum [ keys $Pcore::Core::CLI::Type::TYPE->%* ]
has default => ();                      # Str | ArrayRef | HashRef, applied, when option is not exists, possible only for required options

# NOTE !!!WARNING!!! default_val is not work as it should with Getopt::Long, don't use it now
has default_val => ();                  # applied, when option value is not defined

has min => ( is => 'lazy' );            # PositiveOrZeroInt, 0 - option is not required
has max => ( is => 'lazy' );            # PositiveOrZeroInt, 0 - unlimited repeats

has negated => ( is => 'lazy' );        # trigger can be used with --no prefix
has hash    => ();                      # if true - option is a hash, --opt key=val

has getopt_name   => ( is => 'lazy', init_arg => undef );
has is_trigger    => ( is => 'lazy', init_arg => undef );
has is_repeatable => ( is => 'lazy', init_arg => undef );
has is_required   => ( is => 'lazy', init_arg => undef );
has getopt_spec   => ( is => 'lazy', init_arg => undef );
has help_spec     => ( is => 'lazy', init_arg => undef );

sub BUILD ( $self, $args ) {
    my $name = $self->{name};

    # TODO remove, when this bug will be fixed
    die qq[Option "$name", don't use default_val until bug with Getopt::Long will be fixed] if defined $self->{default_val};

    # max
    die qq[Option "$name", "max" must be >= "min" ] if $self->max && $self->max < $self->min;

    # default
    if ( defined $self->{default} ) {
        die qq[Option "$name", default value can be used only for required option (min > 0)] if $self->min == 0;

        if ( $self->is_trigger ) {
            if ( $self->is_repeatable ) {
                die qq[Option "$name", default value can be positive integer for incremental trigger] if $self->{default} !~ /\A\d+\z/sm;
            }
            else {
                die qq[Option "$name", default value can be 0 or 1 for boolean trigger] if $self->{default} !~ /\A[01]\z/sm;
            }
        }
        else {
            if ( $self->{hash} ) {
                die qq[Option "$name", default value must be a hash for hash option] if !is_plain_hashref $self->{default};
            }
            elsif ( $self->is_repeatable ) {
                die qq[Option "$name", default value must be a array for repeatable option] if !is_plain_arrayref $self->{default};
            }
            else {
                die qq[Option "$name", default value must be a string for plain option] if is_ref $self->{default};
            }
        }
    }

    # default_val
    if ( defined $self->{default_val} ) {
        die qq[Option "$name", "default_val" can not be used for trigger, hash or repeatable option] if $self->is_trigger || $self->{hash} || $self->is_repeatable;
    }

    if ( $self->is_trigger ) {
        die qq[Option "$name", trigger can't be a hash] if $self->{hash};

        if ( $self->negated ) {
            die qq[Option "$name", negated can't be used with short option] if defined $self->short;

            die qq[Option "$name", negated can't be used with incremental trigger] if $self->is_repeatable;

            die qq[Option "$name", negated is useless for the boolean trigger with default value = 0] if defined $self->{default} && $self->{default} == 0;
        }
        else {
            die qq[Option "$name", negated should be enabled for the boolean trigger with default value = 1] if !$self->is_repeatable && defined $self->{default} && $self->{default} == 1;
        }
    }
    else {
        die qq[Option "$name", negated can be used only with triggers] if $self->negated;
    }

    return;
}

sub _build_min ($self) {
    return defined $self->{default} ? 1 : 0;
}

sub _build_max ($self) {
    return $self->min ? $self->min : 1;
}

sub _build_negated ($self) {
    if ( $self->is_trigger && defined $self->{default} ) {
        return 0 if $self->{default} == 0;    # negated is useless if default value is already = 0

        return 1 if $self->{default} == 1 && !$self->is_repeatable;    # negated is mandatory for boolean trigger with default value = 1
    }

    return 0;
}

sub _build_getopt_name ($self) {
    return $self->{name} =~ s/_/-/smgr;
}

sub _build_is_trigger ($self) { return defined $self->{isa} ? 0 : 1 }

sub _build_is_repeatable ($self) {
    return $self->max != 1 ? 1 : 0;
}

sub _build_is_required ($self) {
    return $self->min && !defined $self->{default} ? 1 : 0;
}

sub _build_short ($self) {
    return $self->negated ? undef : substr $self->{name}, 0, 1;
}

sub _build_type ($self) {
    if ( !$self->is_trigger ) {
        my $ref = ref $self->{isa};

        if ( !$ref ) {
            return uc $self->{isa};
        }
        elsif ( $ref eq 'ARRAY' ) {
            return 'ENUM';
        }
        elsif ( $ref eq 'CODE' ) {
            return 'STR';
        }
        elsif ( $ref eq 'Regexp' ) {
            return 'STR';
        }
    }

    return $EMPTY;
}

sub _build_getopt_spec ($self) {
    my $spec = $self->getopt_name;

    $spec .= q[|] . $self->short if defined $self->short;

    if ( $self->is_trigger ) {
        $spec .= q[!] if $self->negated;

        $spec .= q[+] if $self->is_repeatable;
    }
    else {
        if ( defined $self->{default_val} ) {
            $spec .= q[:s];
        }
        else {
            $spec .= q[=s];

            if ( $self->{hash} ) {
                $spec .= q[%];
            }
            elsif ( $self->is_repeatable ) {
                $spec .= q[@];
            }
        }
    }

    return $spec;
}

sub _build_help_spec ($self) {
    my $spec = $self->short ? q[-] . $self->short . $SPACE : $SPACE x 3;

    $spec .= '--';

    $spec .= '[no[-]]' if $self->negated;

    $spec .= $self->getopt_name;

    if ( !$self->is_trigger ) {
        my $type = uc $self->type;

        if ( $self->{hash} ) {
            $spec .= " key=$type";
        }
        else {
            if ( defined $self->{default_val} ) {
                $spec .= "=[$type]";
            }
            else {
                $spec .= " $type";
            }
        }
    }

    my @attrs;

    push @attrs, '+' if $self->is_repeatable;

    push @attrs, '!' if $self->is_required;

    $spec .= $SPACE . join $EMPTY, map {"[$_]"} @attrs if @attrs;

    return $spec;
}

sub validate ( $self, $opt ) {
    my $name = $self->{name};

    # remap getopt name
    $opt->{$name} = delete $opt->{ $self->getopt_name } if exists $opt->{ $self->getopt_name };

    if ( !exists $opt->{$name} ) {
        if ( $self->min ) {    # option is required
            if ( defined $self->{default} ) {

                # apply default value
                $opt->{$name} = $self->{default};
            }
            else {
                return qq[option "$name" is required];
            }
        }
        else {

            # option is not exists and is not required
            return;
        }
    }
    elsif ( defined $self->{default_val} && $opt->{$name} eq $EMPTY ) {

        # apply default_val if opt is exists. but value is not specified
        $opt->{$name} = $self->{default_val};
    }

    # min / max check for the repeatable opt
    if ( $self->is_repeatable ) {
        my $count;

        if ( $self->is_trigger ) {
            $count = $opt->{$name};

            # do not check min / max for the repeatable trigger with default = 0
            goto VALIDATE if $count == 0;
        }
        elsif ( !ref $opt->{$name} ) {
            $count = 1;
        }
        elsif ( is_plain_arrayref $opt->{$name} ) {
            $count = scalar $opt->{$name}->@*;
        }
        elsif ( is_plain_hashref $opt->{$name} ) {
            $count = scalar keys $opt->{$name}->%*;
        }

        # check min args num
        return qq[option "$name" must be repeated at least @{[$self->min]} time(s)] if $count < $self->min;

        # check max args num
        return qq[option "$name" can be repeated not more, than @{[$self->max]} time(s)] if $self->max && $count > $self->max;
    }

  VALIDATE:

    # validate option value type
    if ( defined $self->{isa} && ( my $error_msg = $self->_validate_isa( $opt->{$name} ) ) ) {
        return qq[option "$name" $error_msg];
    }

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 34                   | Subroutines::ProhibitExcessComplexity - Subroutine "BUILD" with high complexity score (35)                     |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Core::CLI::Opt

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
