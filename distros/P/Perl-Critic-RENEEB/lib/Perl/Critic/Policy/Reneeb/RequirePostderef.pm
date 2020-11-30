package Perl::Critic::Policy::Reneeb::RequirePostderef;

# ABSTRACT: Require Postdereferencing which became stable in Perl 5.24

use 5.006001;
use strict;
use warnings;
use Readonly;
use List::Util qw(first);

use Perl::Critic::Utils qw{ :severities };

use base 'Perl::Critic::Policy';

our $VERSION = '2.04';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Use postderef (e.g. $ref->@*) instead of the "old" dereferencing (e.g. @{$ref})};
Readonly::Scalar my $EXPL => [  ];

#-----------------------------------------------------------------------------

sub default_severity     { return $SEVERITY_MEDIUM           }
sub default_themes       { return qw<reneeb> }
sub applies_to           {
    return qw<
        PPI::Token::Cast
    >;
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    # postderence syntax do also have a PPI::Token::Cast object,
    # but that looks different
    return if !first{ $elem->content ne $_ }qw($ @ * % &),'$#';

    my $sibling = $elem->snext_sibling;
    return if !$sibling;

    # grep in boolean or void context isn't checked
    return if !$sibling->isa('PPI::Structure::Block') && !$sibling->isa('PPI::Token::Symbol');

    return $self->violation( $DESC, $EXPL, $elem );
}

1;

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::Reneeb::RequirePostderef - Require Postdereferencing which became stable in Perl 5.24

=head1 VERSION

version 2.04

=head1 DESCRIPTION

Use postderef (e.g. $ref->@*) instead of the "old" dereferencing (e.g. @{$ref})

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

__END__

#-----------------------------------------------------------------------------


