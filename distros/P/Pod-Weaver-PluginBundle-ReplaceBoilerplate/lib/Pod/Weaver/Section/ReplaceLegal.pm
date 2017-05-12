package Pod::Weaver::Section::ReplaceLegal;

# ABSTRACT: Add or replace a COPYRIGHT AND LICENSE section.

use Moose;

extends 'Pod::Weaver::Section::Legal';
with 'Pod::Weaver::Role::SectionReplacer';

our $VERSION = '1.00';

has year => (
  is  => 'ro',
  isa => 'Str',
  );

around weave_section => sub
{
    my ( $orig, $self, $document, $input ) = @_;

    if( my $year = $self->year )
    {
        return unless $input->{license};
        $year =~ s/current/(localtime)[ 5 ] + 1900/e;
        $input->{ license }->{ year } = $year;
    }

    return( $self->$orig( $document, $input ) );
};

sub default_section_name { 'COPYRIGHT AND LICENSE' }
sub default_section_aliases
{
    [
        'LICENSE AND COPYRIGHT',
        'LICENSE & COPYRIGHT',
        'COPYRIGHT & LICENSE',
    ]
}

no Moose;
1;

__END__


=pod

=head1 NAME

Pod::Weaver::Section::ReplaceLegal - Add or replace a COPYRIGHT AND LICENSE section.

=head1 VERSION

version 1.00

=head1 OVERVIEW

This section plugin provides the same behaviour as
L<Pod::Weaver::Section::Legal> but with the
L<Pod::Weaver::Role::SectionReplacer> role applied.

It will produce a hunk of Pod giving the copyright and license
information for the document, like this:

  =head1 COPYRIGHT AND LICENSE

  This document is copyright (C) 1991, Ricardo Signes.

  This document is available under the blah blah blah.

This plugin will do nothing if no C<license> input parameter is available.  The
C<license> is expected to be a L<Software::License> object.

=head1 CUSTOMIZATION

In addition to the standard L<Pod::Weaver::Section::Legal> behaviour,
you may customize the behaviour of L<Pod::Weaver::Section::ReplaceLegal>
with the following options in your C<weaver.ini>:

=over

=item B<year> = I<year string>

You may supply a copyright year, to be used by L<Software::License> via the
C<year> parameter.

The year may be a number or it may be an arbitrary string.

Within any string the word 'current' will be replaced by the current year.

For example in your C<weaver.ini>:

  [ReplaceLegal]
  year = 2005-current

This will, in the year 2010, produce the year string 2005-2010 for use
within the L<Software::License> object.

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
