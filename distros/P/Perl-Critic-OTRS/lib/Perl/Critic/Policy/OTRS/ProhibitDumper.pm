package Perl::Critic::Policy::OTRS::ProhibitDumper;

# ABSTRACT: Check module for use of "Dumper"

use strict;
use warnings;

use Perl::Critic::Utils qw{ :severities :classification :ppi };
use base 'Perl::Critic::Policy';

use Readonly;

our $VERSION = '0.03';

Readonly::Scalar my $DESC => q{Use of "Dumper" is not allowed.};
Readonly::Scalar my $EXPL => q{Use "Dump" method of MainObject instead};

sub supported_parameters { return; }
sub default_severity     { return $SEVERITY_HIGHEST; }
sub default_themes       { return qw( otrs otrs_lt_3_3 ) }
sub applies_to           { return 'PPI::Token::Word' }

sub violates {
    my ( $self, $elem ) = @_;

    return if $elem ne 'Dumper' && $elem ne 'Data::Dumper::Dumper';
    return if !is_function_call( $elem );
    return $self->violation( $DESC, $EXPL, $elem );
}

1;
