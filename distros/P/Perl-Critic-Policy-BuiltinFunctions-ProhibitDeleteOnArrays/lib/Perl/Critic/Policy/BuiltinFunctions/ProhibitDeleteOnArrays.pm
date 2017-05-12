package Perl::Critic::Policy::BuiltinFunctions::ProhibitDeleteOnArrays;
$Perl::Critic::Policy::BuiltinFunctions::ProhibitDeleteOnArrays::VERSION = '0.02';
use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities :classification :ppi };
use base 'Perl::Critic::Policy';


#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{"delete" on array};
Readonly::Scalar my $EXPL => q{Calling delete on array values is strongly discouraged};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                       }
sub default_severity     { return $SEVERITY_LOW            }
sub default_themes       { return qw(maintenance)          }
sub applies_to           { return 'PPI::Token::Word'       }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    return if $elem ne 'delete';
    return if !is_function_call($elem);

    my ($ppi_arg) = parse_arg_list($elem);
    return if !$ppi_arg;

    my $subscr = _get_delete_subscript($ppi_arg);
    return if !$subscr;

    if ($subscr->start->content eq q#[#) {
        return $self->violation( $DESC, $EXPL, $elem );
    }

    return;
}


sub _get_delete_subscript {
    my ($arg) = @_;

    my $subscr;
    for my $i (1 .. $#$arg) {
        my $token = $arg->[$i];

        if (
            $token->isa("PPI::Structure::Subscript")
            || (
                $i == 2 &&
                $token->isa("PPI::Structure::Constructor") &&
                $arg->[$i-2]->isa("PPI::Token::Cast")
            )
        ) {
            $subscr = $token;
            next;
        }

        last if !(
            $token->isa("PPI::Token::Cast") ||
            $token->isa("PPI::Token::Symbol") ||
            $token->isa("PPI::Structure::Block") ||
            ( $token->isa("PPI::Token::Operator") && $token->content eq '->' )
        );
    }

    return $subscr;

}


1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::BuiltinFunctions::ProhibitDeleteOnArrays - Do not use
C<delete> on arrays.

=head1 DESCRIPTION

Calling delete on array values is strongly discouraged. See
L<http://perldoc.perl.org/functions/delete.html>.

=head1 CONFIGURATION

This Policy is not configurable except for the standard options.

=head1 AUTHOR

Aleksey Korabelshchikov L<mailto:xliosha@gmail.com>

=cut

