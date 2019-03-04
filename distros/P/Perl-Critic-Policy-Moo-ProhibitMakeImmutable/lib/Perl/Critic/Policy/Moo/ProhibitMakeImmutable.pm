package Perl::Critic::Policy::Moo::ProhibitMakeImmutable;
use 5.008001;
use strict;
use warnings;
our $VERSION = '0.05';

use Readonly;
use Perl::Critic::Utils qw{ :severities :classification :ppi };

use base 'Perl::Critic::Policy';

Readonly::Scalar my $DESC => q{Moo class should not call ->make_immutable};
Readonly::Scalar my $EXPL => q{When migrating from Moose to Moo it is easy to leave in __PACKAGE__->meta->make_immutable; statements which will cause Moose to be loaded and a metaclass created};

sub supported_parameters { return() }
sub default_severity     { return $SEVERITY_MEDIUM }
sub default_themes       { return qw( performance ) }
sub applies_to           { return 'PPI::Token::Word'  }

sub violates {
    my ($self, $start_word, $doc) = @_;

    return unless $start_word->content() eq '__PACKAGE__';
    my $element = $start_word;

    $element = $element->snext_sibling();
    return unless $element
           and $element->isa('PPI::Token::Operator')
           and $element->content() eq '->';

    $element = $element->snext_sibling();
    return unless $element
           and $element->isa('PPI::Token::Word')
           and $element->content() eq 'meta';

    $element = $element->snext_sibling();
    return unless $element
           and $element->isa('PPI::Token::Operator')
           and $element->content() eq '->';

    $element = $element->snext_sibling();
    return unless $element
           and $element->isa('PPI::Token::Word')
           and $element->content() eq 'make_immutable';

    my $package = _find_package( $start_word );

    my $included = $doc->find_any(sub{
        $_[1]->isa('PPI::Statement::Include')
            and
        defined( $_[1]->module() )
            and
        $_[1]->module() eq 'Moo'
            and
        $_[1]->type() eq 'use'
            and
        _find_package( $_[1] ) eq $package
    });

    return if !$included;

    return $self->violation( $DESC, $EXPL, $start_word );
}

sub _find_package {
    my ($element) = @_;

    my $original = $element;

    while ($element) {
        if ($element->isa('PPI::Statement::Package')) {
            # If this package statements is a block package, meaning: package { # stuff in package }
            # then if we're a descendant of it its our package.
            return $element->namespace() if $element->ancestor_of( $original );

            # If we've hit a non-block package then thats our package.
            my $blocks = $element->find_any('PPI::Structure::Block');
            return $element->namespace() if !$blocks;
        }

        # Keep walking backwards until we match the above logic or we get to
        # the document root (main).
        $element = $element->sprevious_sibling() || $element->parent();
    }

    return 'main';
}

1;
__END__

=head1 NAME

Perl::Critic::Policy::Moo::ProhibitMakeImmutable - Makes sure that Moo classes
do not contain calls to make_immutable.

=head1 DESCRIPTION

When migrating from L<Moose> to L<Moo> it can be a common issue to accidentally
leave in:

    __PACKAGE__->meta->make_immutable;

This policy complains if this exists in a Moo class as it triggers Moose to be
loaded and metaclass created, which defeats some of the benefits you get using
Moo instead of Moose.

=head1 AUTHORS

    Aran Clary Deltac <bluefeet@gmail.com>
    Kivanc Yazan <kyzn@users.noreply.github.com>
    Graham TerMarsch <graham@howlingfrog.com>

=head1 ACKNOWLEDGEMENTS

Thanks to L<ZipRecruiter|https://www.ziprecruiter.com/>
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

