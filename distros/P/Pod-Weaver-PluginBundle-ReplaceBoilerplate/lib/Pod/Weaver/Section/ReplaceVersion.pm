package Pod::Weaver::Section::ReplaceVersion;

use Moose;

# ABSTRACT: Add or replace a VERSION section.

extends 'Pod::Weaver::Section::Version';
with 'Pod::Weaver::Role::SectionReplacer';

our $VERSION = '1.00';

sub default_section_name { 'VERSION' }

no Moose;
1;

__END__


=pod

=head1 NAME

Pod::Weaver::Section::ReplaceVersion - Add or replace a VERSION section.

=head1 VERSION

version 1.00

=head1 OVERVIEW

This section plugin provides the same behaviour as
L<Pod::Weaver::Section::Version> but with the
L<Pod::Weaver::Role::SectionReplacer> role applied.

It will produce a hunk of Pod meant to indicate the version of
the document being viewed, like this:

  =head1 VERSION

  version 1.234

It will do nothing if there is no C<version> entry in the input.

=for readme stop

=begin :internal

=head1 INTERNAL METHODS

=over

=item default_section_name

Gives the name used as the heading for this section.

=back

=end :internal

=for readme continue

=head1 AUTHOR

Sam Graham <libpod-weaver-pluginbundle-replaceboilerplate-perl BLAHBLAH illusori.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Sam Graham <libpod-weaver-pluginbundle-replaceboilerplate-perl BLAHBLAH illusori.co.uk>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
