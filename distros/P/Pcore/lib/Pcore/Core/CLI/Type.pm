package Pcore::Core::CLI::Type;

use Pcore -role, -const;

const our $TYPE => {
    Str => sub ($val) {
        return Str->check($val);
    },
    Bool => sub ($val) {
        return Bool->check($val);
    },
    Int => sub ($val) {
        return Int->check($val);
    },
    PositiveInt => sub ($val) {
        return PositiveInt->check($val);
    },
    PositiveOrZeroInt => sub ($val) {
        return PositiveOrZeroInt->check($val);
    },
    Num => sub ($val) {
        return Num->check($val);
    },
    Path => sub ($val) {
        return -e $val;
    },
    Dir => sub ($val) {
        return -d $val;
    },
    File => sub ($val) {
        return -f $val;
    },
};

sub _validate_isa ( $self, @ ) {
    my $vals = ref $_[1] eq 'ARRAY' ? $_[1] : ref $_[1] eq 'HASH' ? [ \values $_[1]->%* ] : [ \$_[1] ];

    my $isa_ref = ref $self->isa;

    for my $val_ref ( $vals->@* ) {
        if ( !$isa_ref ) {
            return qq[value "$val_ref->$*" is not a ] . uc $self->isa if !$TYPE->{ $self->isa }->( $val_ref->$* );
        }
        elsif ( $isa_ref eq 'CODE' ) {
            if ( my $error_msg = $self->isa->($val_ref) ) {
                return $error_msg;
            }
        }
        elsif ( $isa_ref eq 'Regexp' ) {
            return qq[value "$val_ref->$*" should match regexp ] . $self->isa if $val_ref->$* !~ $self->isa;
        }
        elsif ( $isa_ref eq 'ARRAY' ) {
            my $possible_val = [];

            for ( $self->isa->@* ) {
                if ( index( $_, $val_ref->$*, 0 ) == 0 ) {
                    if ( length == length $val_ref->$* ) {

                        # select current value if matched completely
                        $possible_val = [$_];

                        last;
                    }

                    push $possible_val->@*, $_;
                }
            }

            if ( !$possible_val->@* ) {
                return qq[value "$val_ref->$*" should be one of the: ] . join q[, ], map {qq["$_"]} $self->isa->@*;
            }
            elsif ( $possible_val->@* > 1 ) {
                return qq[value "$val_ref->$*" is ambigous, did you mean: ] . join q[, ], map {qq["$_"]} $possible_val->@*;
            }
            else {
                $val_ref->$* = $possible_val->[0];    ## no critic qw[Variables::RequireLocalizedPunctuationVars]
            }
        }
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
## |    3 | 35                   | Subroutines::ProhibitUnusedPrivateSubroutines - Private subroutine/method '_validate_isa' declared but not     |
## |      |                      | used                                                                                                           |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Core::CLI::Type

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
