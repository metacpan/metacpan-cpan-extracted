package Pod::Weaver::Section::ReplaceAuthors;

# ABSTRACT: Add or replace an AUTHOR or AUTHORS section.

use Moose;

extends 'Pod::Weaver::Section::Authors';
with 'Pod::Weaver::Role::SectionReplacer';

our $VERSION = '1.00';

sub default_section_name { 'AUTHORS' }
sub default_section_aliases { [ 'AUTHOR' ] }

no Moose;
1;

__END__

=pod

=head1 NAME

Pod::Weaver::Section::ReplaceAuthors - Add or replace an AUTHOR or AUTHORS section.

=head1 VERSION

version 1.00

=head1 OVERVIEW

This section plugin provides the same behaviour as
L<Pod::Weaver::Section::Authors> but with the
L<Pod::Weaver::Role::SectionReplacer> role applied.

It will add or replace a listing of the document's authors.
It expects the C<authors> input parameter to be an arrayref of strings.
If no C<authors> parameter is given, it will do nothing.
Otherwise, it produces a hunk like this:

  =head1 AUTHOR

  Author <a@example.com>

Or in the case of multiple authors:

  =head1 AUTHORS

  =over
  
  =item Author One <a1@example.com>

  =item Author Two <a2@example.com>

  =back

=for readme stop

=begin :internal

=head1 INTERNAL METHODS

=over

=item default_section_name

Gives the name used as the heading for this section.

=item default_section_aliases

Gives alternative names that an existing section might be using.

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
