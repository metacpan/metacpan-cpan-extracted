package Pcore::Core::CLI::Arg;

use Pcore -class;
use Pcore::Util::Scalar qw[is_plain_arrayref];

with qw[Pcore::Core::CLI::Type];

has name => ( is => 'ro', isa => Str, required => 1 );

has isa => ( is => 'ro', isa => Maybe CodeRef | RegexpRef | ArrayRef | Enum [ keys $Pcore::Core::CLI::Type::TYPE->%* ] );
has default => ( is => 'ro', isa => Str | ArrayRef );

has min => ( is => 'lazy', isa => PositiveOrZeroInt );    # 0 - option is not required
has max => ( is => 'lazy', isa => PositiveOrZeroInt );    # 0 - unlimited repeats

has type          => ( is => 'lazy', isa => Str,  init_arg => undef );
has is_repeatable => ( is => 'lazy', isa => Bool, init_arg => undef );
has is_required   => ( is => 'lazy', isa => Bool, init_arg => undef );
has help_spec     => ( is => 'lazy', isa => Str,  init_arg => undef );

sub BUILD ( $self, $args ) {
    my $name = $self->name;

    # max
    die qq[Argument "$name", "max" must be >= "min" ] if $self->max && $self->max < $self->min;

    # default
    if ( defined $self->default ) {
        die qq[Argument "$name", default value can be used only for required argument (min > 0)] if $self->min == 0;

        if ( $self->is_repeatable ) {
            die qq[Argument "$name", default value must be a array for repeatable argument] if !is_plain_arrayref $self->default;
        }
        else {
            die qq[Argument "$name", default value must be a string for plain argument] if ref $self->default;
        }
    }

    return;
}

sub _build_min ($self) {
    return 1;
}

sub _build_max ($self) {
    return $self->min ? $self->min : 1;
}

sub _build_type ($self) {
    return uc $self->name =~ s/_/-/smgr;
}

sub _build_is_repeatable ($self) {
    return $self->max != 1 ? 1 : 0;
}

sub _build_is_required ($self) {
    return $self->min && !defined $self->default ? 1 : 0;
}

sub _build_help_spec ($self) {
    my $spec;

    if ( $self->is_required ) {
        $spec = uc $self->type;
    }
    else {
        $spec = '[' . uc $self->type . ']';
    }

    $spec .= '...' if $self->is_repeatable;

    return $spec;
}

sub parse ( $self, $from, $to ) {
    if ( !$from->@* ) {
        if ( $self->min ) {    # argument is required
            if ( defined $self->default ) {

                # apply default value
                $to->{ $self->name } = $self->default;
            }
            else {
                return qq[required argument "@{[$self->type]}" is missed];
            }
        }
        else {

            # argument not exists and is not required
            return;
        }
    }
    else {
        if ( !$self->max ) {    # slurpy
            push $to->{ $self->name }->@*, splice $from->@*, 0, scalar $from->@*, ();
        }
        elsif ( $self->max == 1 ) {    # not repeatable
            $to->{ $self->name } = shift $from->@*;
        }
        else {                         # repeatable
            push $to->{ $self->name }->@*, splice $from->@*, 0, $self->max, ();
        }
    }

    # min / max check for the repeatable arg
    if ( $self->is_repeatable ) {

        # check min args num
        return qq[argument "@{[$self->type]}" must be repeated at least @{[$self->min]} time(s)] if $to->{ $self->name }->@* < $self->min;

        # check max args num
        return qq[argument "@{[$self->type]}" can be repeated not more, than @{[$self->max]} time(s)] if $self->max && $to->{ $self->name }->@* > $self->max;
    }

    # validate arg value type
    if ( defined $self->isa && ( my $error_msg = $self->_validate_isa( $to->{ $self->name } ) ) ) {
        return qq[argument "@{[$self->type]}" $error_msg];
    }

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Core::CLI::Arg

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
