package Perl::Critic::Policy::OTRS::ProhibitLowPrecedenceOps;

# ABSTRACT: Do not use "not", "and" and other low precedence operators

use strict;
use warnings;

use Perl::Critic::Utils qw{ :severities :classification :ppi };
use base 'Perl::Critic::Policy';

use Readonly;

our $VERSION = '0.03';

Readonly::Scalar my $DESC => q{Use of low precedence operators is not allowed};
Readonly::Scalar my $EXPL => q{Replace low precedence operators with the high precedence substitutes};

my %lowprecedence = (
  not => '!',
  and => '&&',
  or  => '||',
);

sub supported_parameters { return; }
sub default_severity     { return $SEVERITY_HIGHEST; }
sub default_themes       { return qw( otrs otrs_lt_3_3 ) }
sub applies_to           { return 'PPI::Token::Operator'  }

sub violates {
    my ( $self, $elem ) = @_;

    return if !grep{ $elem eq $_ }keys %lowprecedence;
    return $self->violation( $DESC, $EXPL, $elem );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::OTRS::ProhibitLowPrecedenceOps - Do not use "not", "and" and other low precedence operators

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
