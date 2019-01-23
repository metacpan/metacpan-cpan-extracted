package Perl::Critic::Policy::OTRS::RequireCamelCase;

# ABSTRACT: Variable, subroutine, and package names have to be in CamelCase

use strict;
use warnings;

use Perl::Critic::Utils qw{ :severities :classification :ppi };
use base 'Perl::Critic::Policy';

use Readonly;

our $VERSION = '0.03';

Readonly::Scalar my $DESC => q{Variable, subroutine, and package names have to be in CamelCase};
Readonly::Scalar my $EXPL => q{};

sub supported_parameters { return; }
sub default_severity     { return $SEVERITY_HIGHEST; }
sub default_themes       { return qw( otrs otrs_lt_3_3 ) }

my %dispatcher = (
    'PPI::Statement::Sub'     => \&_is_camelcase,
    'PPI::Statement::Package' => \&_is_camelcase,
    'PPI::Token::Symbol'      => \&_variable_is_camelcase,
);

sub applies_to {
    sort keys %dispatcher,
}

sub violates {
    my ( $self, $elem ) = @_;

    my $ref = ref $elem;
    my $sub = $dispatcher{$ref};
    return if !$sub;

    my $success = $self->$sub( $elem );

    return if $success;
    return $self->violation( $DESC, $EXPL, $elem );
}

sub _is_camelcase {
    my ( $self, $elem ) = @_;

    my $words = $elem->find( 'PPI::Token::Word' );
    my $name  = $words->[1];

    if ( $elem->isa( 'PPI::Statement::Sub' ) and $name eq 'new' ) {
        return 1;
    }
    elsif ( $elem->isa( 'PPI::Statement::Package' ) and $name eq 'main' ) {
        return 1;
    }
    elsif ( $elem->isa( 'PPI::Statement::Package' ) and $name =~ m{ \A t:: }x ) {
        return 1;
    }
    elsif ( $elem->isa( 'PPI::Statement::Package' ) and $name =~ m{ Language :: [a-z]{2,3}_ }xms ) {
        return 1;
    }

    return 1 if !$name;

    my $is_camelcase = !( $name !~ m{ \A _* [A-Z][a-z]* }xms || $name =~ m{ [^_]_ }xms );

    return $is_camelcase;
}

sub _variable_is_camelcase {
    my ( $self, $elem ) = @_;

    my $name = "$elem";

    # Allow Perl builtins.
    return 1 if $name eq '$a';
    return 1 if $name eq '$b';

    # Ignore function calls
    return 1 if substr($name, 0, 1) eq '&';

    # Allow short variable names with lowercase characters like $s.
    return 1 if length $name == 2;

    my $is_camelcase = !( $name !~ m{ \A [\*\@\$\%]_*[A-Z][a-z]* }xms || $name =~ m{ [^_]_ }xms );

    #print STDERR "$name" if !$is_camelcase;

    return $is_camelcase;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::OTRS::RequireCamelCase - Variable, subroutine, and package names have to be in CamelCase

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
