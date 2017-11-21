package Perl::Critic::Policy::ControlStructures::ProhibitSwitchStatements;

use strict;
use warnings;

use parent 'Perl::Critic::Policy';
use Perl::Critic::Utils qw{ :severities };
use Readonly;

our $VERSION = '0.1';

Readonly::Scalar my $DESC => q{Switch statement keywords used};
Readonly::Scalar my $EXPL => q{Avoid using switch statement keywords};

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
    # PPI::Statement and PPI::Structure works for (given|when|default),
    # yet do not for CORE::(given|when|default)
    return 'PPI::Token';
}

sub violates {
    my ( $self, $elem, undef ) = @_;

    return if $elem !~ m{^(CORE::)?(given|when|default)$};
    return $self->violation( $DESC, $EXPL, $elem );
}

1;

__END__

=encoding utf-8

=head1 NAME

Perl::Critic::Policy::ControlStructures::ProhibitSwitchStatements
- avoid using switch statement keywords which might imply implicit smartmatching

=head1 DESCRIPTION

Switch statements are considered experimental, see L<perlsyn/"Switch Statements">.
This policy aims to avoid using switch statement keywords.

    given ($foo) {
        when (42) { say 'Heureka!'; }
        default { die 'Oh!'; }
    }

=head1 AUTHOR

Jan Holcapek E<lt>holcapek@gmail.comE<gt>

=cut
