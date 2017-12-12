package Perl::Critic::Policy::Operators::ProhibitSmartmatch;

use 5.008005;
use strict;
use warnings;

use parent 'Perl::Critic::Policy';
use Readonly;
use Perl::Critic::Utils qw{ :severities };

our $VERSION = '0.2';

Readonly::Scalar my $DESC => q{Smartmatch operator used};
Readonly::Scalar my $EXPL => q{Avoid using smartmatch operator};

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
    return 'PPI::Token::Operator';
}

sub violates {
    my ( $self, $elem ) = @_;
    return if $elem ne '~~';
    return $self->violation( $DESC, $EXPL, $elem );
}

1;

__END__

=encoding utf-8

=head1 NAME

Perl::Critic::Policy::Operators::ProhibitSmartmatch
- avoid using explicit smartmatching via C<~~> operator

=head1 DESCRIPTION

Smartmatch operator is considered experimental, see L<perlop/"Smartmatch Operator">.

    if ($foo ~~ [ $bar ]) {
        say 'No!';
    }

=head1 AUTHOR

Jan Holcapek E<lt>holcapek@gmail.comE<gt>, who was heavily inspired by the work of
hisaichi5518 E<lt>hisada.kazuki@gmail.comE<gt>

=cut

