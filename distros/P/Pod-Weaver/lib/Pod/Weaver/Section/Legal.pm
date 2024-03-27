package Pod::Weaver::Section::Legal 4.020;
# ABSTRACT: a section for the copyright and license

use Moose;
with 'Pod::Weaver::Role::Section';

# BEGIN BOILERPLATE
use v5.20.0;
use warnings;
use utf8;
no feature 'switch';
use experimental qw(postderef postderef_qq); # This experiment gets mainlined.
# END BOILERPLATE

#pod =head1 OVERVIEW
#pod
#pod This section plugin will produce a hunk of Pod giving the copyright and license
#pod information for the document, like this:
#pod
#pod   =head1 COPYRIGHT AND LICENSE
#pod
#pod   This document is copyright (C) 1991, Ricardo Signes.
#pod
#pod   This document is available under the blah blah blah.
#pod
#pod This plugin will do nothing if no C<license> input parameter is available.  The
#pod C<license> is expected to be a L<Software::License> object.
#pod
#pod =cut

#pod =attr license_file
#pod
#pod Specify the name of the license file and an extra line of text will be added
#pod telling users to check the file for the full text of the license.
#pod
#pod Defaults to none.
#pod
#pod =attr header
#pod
#pod The title of the header to be added.
#pod (default: "COPYRIGHT AND LICENSE")
#pod
#pod =cut

has header => (
  is      => 'ro',
  isa     => 'Str',
  default => 'COPYRIGHT AND LICENSE',
);

has license_file => (
  is => 'ro',
  isa => 'Str',
  predicate => '_has_license_file',
);

sub weave_section {
  my ($self, $document, $input) = @_;

  unless ($input->{license}) {
    $self->log_debug('no license specified, not adding a ' . $self->header . ' section');
    return;
 }

  my $notice = $input->{license}->notice;
  chomp $notice;

  if ( $self->_has_license_file ) {
    $notice .= "\n\nThe full text of the license can be found in the\nF<";
    $notice .= $self->license_file . "> file included with this distribution.";
  }

  $self->log_debug('adding ' . $self->header . ' section');

  push $document->children->@*,
    Pod::Elemental::Element::Nested->new({
      command  => 'head1',
      content  => $self->header,
      children => [
        Pod::Elemental::Element::Pod5::Ordinary->new({ content => $notice }),
      ],
    });
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Section::Legal - a section for the copyright and license

=head1 VERSION

version 4.020

=head1 OVERVIEW

This section plugin will produce a hunk of Pod giving the copyright and license
information for the document, like this:

  =head1 COPYRIGHT AND LICENSE

  This document is copyright (C) 1991, Ricardo Signes.

  This document is available under the blah blah blah.

This plugin will do nothing if no C<license> input parameter is available.  The
C<license> is expected to be a L<Software::License> object.

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl
released in the last two to three years.  (That is, if the most recently
released version is v5.40, then this module should work on both v5.40 and
v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 ATTRIBUTES

=head2 license_file

Specify the name of the license file and an extra line of text will be added
telling users to check the file for the full text of the license.

Defaults to none.

=head2 header

The title of the header to be added.
(default: "COPYRIGHT AND LICENSE")

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
