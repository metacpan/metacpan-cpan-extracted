package SVN::Web::I18N;

use strict;
use warnings;

use base qw(Locale::Maketext);
use Locale::Maketext::Lexicon;

our $VERSION = 0.53;

my $lh;

sub loc {
    return $lh->maketext(@_);
}

sub loc_lang {
    $lh = __PACKAGE__->get_handle(@_);

    return;
}

sub add_directory {
    my $directory = shift;

    my $pattern = File::Spec->catfile( $directory, '*.[pm]o' );
    $pattern =~ s{\\}{/}g;    # Deal with Windows paths

    Locale::Maketext::Lexicon->import(
        {
            '*'     => [ Gettext => $pattern ],
            _auto   => 1,
            _style  => 'gettext',
            _decode => 0,
        }
    );

    return;
}

1;

__END__

=head1 NAME

SVN::Web::I18N - SVN::Web internationalisation class

=head1 SYNOPSIS

  use SVN::Web::I18N;                    # Nothing exported

  # Add a directory that contains .po and/or .mo files
  SVN::Web::I18N::add_directory('/path/to/directory');

  # Specify the current language
  SVN::Web::I18N::loc_lang('en');

  # Get a translated string
  my $xlated = SVN::Web::I18N::loc('(a string to translate)');

=head1 DESCRIPTION

SVN::Web::I18N provides the interface through which SVN::Web is
internationalised, and how different localisations are implemented.

=head1 SUBROUTINES

=head2 SVN::Web::I18N::add_directory($path)

Adds a new directory to the list of directories in which localisations
will be found.  Any F<*.po> and F<*.mo> files in this directory will
automatically be scanned for localisations, and added to the language
key given by the file's basename.

In case where two different directories both contain a localisation file
that defines the same localisation key for the same language, the
localisation key from the most recently added directory will be used.

=head2 SVN::Web::I18N::loc_lang($lang)

Selects the language to use for subsequent calls to C<loc()>.  The C<$lang>
parameter should be a valid language name -- i.e., there must exist at
least one F<$lang.po> file in one of the directories used in a call to
C<SVN::Web::I18N::add_directory()>.

=head2 SVN::Web::I18N::loc($text)

and

=head2 SVN::Web::I18N::loc($text, $param1, ...)

Returns the localised form of C<$text> according to the localisation
selected by the most recent call to C<loc_lang()>.

If the localisation expects parameters to I<fill in> the localisation
result they should be passed as the second and subsequent arguments.

If C<$text> does not have a defined localised form it is returned
with the parameters interpolated in to it.

=head1 SEE ALSO

L<Locale::Maketext>, L<Locale::Maketext::Lexicon>, L<SVN::Web>

=head1 AUTHORS

Nik Clayton C<< <nik@FreeBSD.org> >>

=head1 COPYRIGHT

Copyright 2006-2007 by Nik Clayton C<< <nik@FreeBSD.org> >>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
