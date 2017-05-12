package Pod::Weaver::Plugin::Encoding; # git description: v0.02-9-g9f8a221
# ABSTRACT: (DEPRECATED) Add an encoding command to your POD

our $VERSION = '0.03';

use Moose;
use List::Util 1.33 'any';
use MooseX::Types::Moose qw(Str);
use aliased 'Pod::Elemental::Node';
use aliased 'Pod::Elemental::Element::Pod5::Command';
use namespace::autoclean -also => 'find_encoding_command';

with 'Pod::Weaver::Role::Finalizer';

#pod =head1 SYNOPSIS
#pod
#pod In your weaver.ini:
#pod
#pod   [-Encoding]
#pod
#pod or
#pod
#pod   [-Encoding]
#pod   encoding = koi8-r
#pod
#pod =head1 DESCRIPTION
#pod
#pod This section will add an C<=encoding> command like
#pod
#pod   =encoding UTF-8
#pod
#pod to your POD.
#pod
#pod =attr encoding
#pod
#pod The encoding to declare in the C<=encoding> command. Defaults to
#pod C<UTF-8>.
#pod
#pod =cut

has encoding => (
    is      => 'ro',
    isa     => Str,
    default => 'UTF-8',
);

#pod =method finalize_document
#pod
#pod This method prepends an C<=encoding> command with the content of the
#pod C<encoding> attribute's value to the document's children.
#pod
#pod Does nothing if the document already has an C<=encoding> command.
#pod
#pod =cut

sub finalize_document {
    my ($self, $document) = @_;

    return if find_encoding_command($document->children);

    unshift @{ $document->children },
        Command->new({
            command => 'encoding',
            content => $self->encoding,
        }),
}

sub find_encoding_command {
    my ($children) = @_;
    return any {
        ($_->isa(Command) && $_->command eq 'encoding')
        || ($_->does(Node) && find_encoding_command($_->children));
    } @$children;
}

#pod =head1 SEE ALSO
#pod
#pod L<Pod::Weaver::Section::Encoding> is very similar to this module, but
#pod expects the encoding to be specified in a special comment within the
#pod document that's being woven.
#pod
#pod L<Pod::Weaver::Plugin::SingleEncoding> can be considered the successor to this
#pod module, and is a core part of L<Pod::Weaver> version 4. It is contained within
#pod L<[@Default]|Pod::Weaver::PluginBundle::Default>, and you should be using
#pod that plugin rather than this one.
#pod
#pod =cut

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Plugin::Encoding - (DEPRECATED) Add an encoding command to your POD

=head1 VERSION

version 0.03

=head1 SYNOPSIS

In your weaver.ini:

  [-Encoding]

or

  [-Encoding]
  encoding = koi8-r

=head1 DESCRIPTION

This section will add an C<=encoding> command like

  =encoding UTF-8

to your POD.

=head1 ATTRIBUTES

=head2 encoding

The encoding to declare in the C<=encoding> command. Defaults to
C<UTF-8>.

=head1 METHODS

=head2 finalize_document

This method prepends an C<=encoding> command with the content of the
C<encoding> attribute's value to the document's children.

Does nothing if the document already has an C<=encoding> command.

=head1 SEE ALSO

L<Pod::Weaver::Section::Encoding> is very similar to this module, but
expects the encoding to be specified in a special comment within the
document that's being woven.

L<Pod::Weaver::Plugin::SingleEncoding> can be considered the successor to this
module, and is a core part of L<Pod::Weaver> version 4. It is contained within
L<[@Default]|Pod::Weaver::PluginBundle::Default>, and you should be using
that plugin rather than this one.

=head1 AUTHOR

Florian Ragwitz <rafl@debian.org>

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Сергей Романов Graham Knop

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Сергей Романов <complefor@rambler.ru>

=item *

Graham Knop <haarg@haarg.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Florian Ragwitz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
