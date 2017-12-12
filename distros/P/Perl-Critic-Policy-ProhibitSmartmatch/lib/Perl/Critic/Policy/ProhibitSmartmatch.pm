package Perl::Critic::Policy::ProhibitSmartmatch;

use strict;
use warnings;

use parent 'Perl::Critic::Policy';
use Readonly;
use Perl::Critic::Utils qw{ :severities };

use Perl::Critic::Policy::Operators::ProhibitSmartmatch;
use Perl::Critic::Policy::ControlStructures::ProhibitSwitchStatements;

our $VERSION = '0.4';

Readonly::Scalar my $DESC => q{Implicit or explicit smartmatch used};
Readonly::Scalar my $EXPL => q{Avoid using implicit and explicit smartmatch};

sub supported_parameters {
    return ();
}

sub default_severity {
    return $SEVERITY_MEDIUM;
}

sub default_themes {
    return qw( core );
}

sub applies_to {

    # P::C::P::ControlStructures::ProhibitSwitchStatements
    #   applies to PPI::Token::Operator
    # P::C::P::Operators::ProhibitSmartmatch
    #   applies to PPI::Token
    # so we stick to the more generic class
    return 'PPI::Token';
}

sub violates {
    my ( $self, $elem ) = @_;

    my $p_o_ps   = Perl::Critic::Policy::Operators::ProhibitSmartmatch->new;
    my $p_cs_pss = Perl::Critic::Policy::ControlStructures::ProhibitSwitchStatements->new;

    my @violation;

    @violation = $p_o_ps->violates($elem);
    return $self->violation( $DESC, $EXPL, $elem )
        if @violation;

    @violation = $p_cs_pss->violates($elem);
    return $self->violation( $DESC, $EXPL, $elem )
        if @violation;

    return;
}

1;

__END__

=encoding utf-8

=head1 NAME

Perl::Critic::Policy::ProhibitSmartmatch
- avoid using both explicit and implicit smartmatching

=head1 DESCRIPTION

This distribution provides two Perl::Critic policies
which help to avoid both explicit and implicit smartmatching.

=head1 AUTHOR

Jan Holcapek E<lt>holcapek@gmail.comE<gt>, who was heavily inspired by the work of
hisaichi5518 E<lt>hisada.kazuki@gmail.comE<gt>

=cut
