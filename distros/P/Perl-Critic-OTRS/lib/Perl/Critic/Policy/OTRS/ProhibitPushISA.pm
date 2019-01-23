package Perl::Critic::Policy::OTRS::ProhibitPushISA;

# ABSTRACT: Do not use "push @ISA, ..."

use strict;
use warnings;

use Perl::Critic::Utils qw{ :severities :classification :ppi };
use base 'Perl::Critic::Policy';

use Readonly;

our $VERSION = '0.02';

Readonly::Scalar my $DESC => q{Use of "push @ISA, ..." is not allowed};
Readonly::Scalar my $EXPL => q{Use RequireBaseClass method of MainObject instead.};

sub supported_parameters { return; }
sub default_severity     { return $SEVERITY_HIGHEST; }
sub default_themes       { return qw( otrs ) }
sub applies_to           { return 'PPI::Token::Word'  }

sub violates {
    my ( $self, $elem ) = @_;

    return if $elem ne 'push' and $elem ne 'CORE::push';
    
    my $sibling = $elem->snext_sibling;
    return if !$sibling->isa( 'PPI::Token::Symbol' ) and !$sibling->isa( 'PPI::Structure::List' );

    if ( $sibling->isa( 'PPI::Token::Symbol' ) ) {
        return if $sibling ne '@ISA';
    }
    elsif ( $sibling->isa( 'PPI::Structure::List' ) ) {
        my $symbol = $sibling->find( 'PPI::Token::Symbol' );

        return if !$symbol;
        return if $symbol->[0] ne '@ISA';
    }

    return $self->violation( $DESC, $EXPL, $elem );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::OTRS::ProhibitPushISA - Do not use "push @ISA, ..."

=head1 VERSION

version 0.09

=head1 METHODS

=head2 supported_parameters

There are no supported parameters.

=head1 AUTHOR

Renee Baecker <info@perl-services.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
