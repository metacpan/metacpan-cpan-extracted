package Perl::Critic::Policy::OTRS::ProhibitRequire;

# ABSTRACT: Do not use "require"

use strict;
use warnings;

use Perl::Critic::Utils qw{ :severities :classification :ppi };
use base 'Perl::Critic::Policy';

use Readonly;

our $VERSION = '0.02';

Readonly::Scalar my $DESC => q{Use of "require" is not allowed};
Readonly::Scalar my $EXPL => q{Use Require() method of MainObject instead.};

sub supported_parameters { return; }
sub default_severity     { return $SEVERITY_HIGHEST; }
sub default_themes       { return qw( otrs otrs_lt_3_3 ) }
sub applies_to           { return 'PPI::Token::Word'  }

sub violates {
    my ( $self, $elem ) = @_;

    return if $elem ne 'require';
    return $self->violation( $DESC, $EXPL, $elem );
}

1;
