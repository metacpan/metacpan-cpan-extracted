#
# This file is part of Pod-Weaver-Section-CollectWithIntro
#
# This software is Copyright (c) 2012 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Pod::Weaver::Section::CollectWithIntro;
{
  $Pod::Weaver::Section::CollectWithIntro::VERSION = '0.001';
}

# ABSTRACT: Preface pod collections

use Moose;
use namespace::autoclean;
use autobox::Core;
use aliased 'Pod::Elemental::Element::Pod5::Ordinary';

extends 'Pod::Weaver::Section::Collect';


has content => (is => 'ro', isa => 'Str', required => 1);

before weave_section => sub {
    my ($self, $document, $input) = @_;

    return unless $self->__used_container;

    ### make our paragraph node here...
    my $para = Ordinary->new(
        content => $self->content,
    );

    ### and add to the beginning of the node list..
    $self->__used_container->children->unshift($para);

    return;
};

__PACKAGE__->meta->make_immutable;
!!42;

__END__

=pod

=encoding utf-8

=for :stopwords Chris Weyl

=head1 NAME

Pod::Weaver::Section::CollectWithIntro - Preface pod collections

=head1 VERSION

This document describes version 0.001 of Pod::Weaver::Section::CollectWithIntro - released October 29, 2012 as part of Pod-Weaver-Section-CollectWithIntro.

=head1 SYNOPSIS

    ; weaver.ini
    [CollectWithIntro / ATTRIBUTES]
    command = attr
    content = These attributes are especially tasty in the fall.

    # in your Perl...
    =attr blueberries

    Holds our blueberries.

    =cut

    # in the output pod...
    =head1 ATTRIBUTES

    These attributes are especially tasty in the fall.

    =head2 blueberries

    # ... you get the idea.

=head1 DESCRIPTION

This is a subclass of L<Pod::Weaver::Section::Collect> that allows one to
attach a prefix paragraph to the collected section/node.

=head1 ATTRIBUTES

=head2 content *required*

The intro paragraph.  Right now this is expected to be a bog-simple string.
Using POD or other bits will probably be supported down the road, but for now,
it's just a string.

This is wrapped in a L<Pod::Elemental::Element::Pod5::Ordinary> and included
after the section header but before any of the elements.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Pod::Weaver::Section::Collect>

=back

=head1 SOURCE

The development version is on github at L<http://github.com/RsrchBoy/Pod-Weaver-Section-CollectWithIntro>
and may be cloned from L<git://github.com/RsrchBoy/Pod-Weaver-Section-CollectWithIntro.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/RsrchBoy/Pod-Weaver-Section-CollectWithIntro/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
