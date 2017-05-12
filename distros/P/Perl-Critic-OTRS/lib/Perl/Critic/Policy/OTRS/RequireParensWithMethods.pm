package Perl::Critic::Policy::OTRS::RequireParensWithMethods;

# ABSTRACT: Use parens when a method is called

use strict;
use warnings;

use Perl::Critic::Utils qw{ :severities :classification :ppi };
use base 'Perl::Critic::Policy';

use Readonly;

our $VERSION = '0.02';

Readonly::Scalar my $DESC => q{Method invocation should use "()"};
Readonly::Scalar my $EXPL => q{Use "->MethodName()" instead of "->MethodName".};

sub supported_parameters { return; }
sub default_severity     { return $SEVERITY_HIGHEST; }
sub default_themes       { return qw( otrs otrs_lt_3_3 ) }
sub applies_to           { return 'PPI::Token::Operator' }

sub violates {
    my ( $self, $elem ) = @_;

    return if $elem ne '->';

    my $method = $elem->snext_sibling;

    # $Variable->();
    return if ref $method eq 'PPI::Structure::List';

    # $Variable->method();
    return if ref $method eq 'PPI::Structure::Subscript';

    my $list   = $method->snext_sibling;
    return if ref $list eq 'PPI::Structure::List';

    return $self->violation( $DESC, $EXPL, $elem );
}

1;
