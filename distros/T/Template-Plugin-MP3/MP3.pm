package Template::Plugin::MP3;

# ----------------------------------------------------------------------
# $Id: MP3.pm,v 1.1.1.1 2003/06/24 13:42:29 dlc Exp $
# ----------------------------------------------------------------------

use strict;
use vars qw( $VERSION $AUTOLOAD );
use base qw( Template::Plugin );

my $ETYPE = "plugin.mp3";

use File::Spec;
use MP3::Info ();
use Template::Plugin;

$VERSION = 1.02;

# ----------------------------------------------------------------------
# new($context, $name, \%config)
#
# Creates a new MP3 instance.  Requires the name of an MP3 file,
# either as the first positional argument or as the 'name' element of
# the configuration hash.  The user can also specify a base directory
# (using 'dir'), which will be used as a base for the aforementioned
# name.
# ----------------------------------------------------------------------
sub new {
    my $config = ref($_[-1]) eq 'HASH' ? pop @_ : { };
    my ($class, $context, $file) = @_;
    my ($dir, $mp3);

    # Allow filename to be positional or named
    $file = $config->{'name'}
        if (! defined $file && defined $config->{'name'});

    # Allowances for Template::Plugin::File instances
    $file = $file->name
        if (UNIVERSAL::can($file, "name"));

    # Allow filename to be relative to a root directory
    $file = File::Spec->catfile($config->{'dir'}, $file)
        if defined $config->{'dir'};

    -e $file or $context->throw($ETYPE, "File '$file' does not exist");

    $mp3 = MP3::Info->new($file)
        || $context->throw($ETYPE,
            "Can't create MP3::Info object for mp3 file '$file'");

    if (defined $config->{'utf8'}) {
        MP3::Info::use_mp3_utf8($config->{'utf8'});
    }

    bless {
        _CONTEXT => $context,
        _MP3     => $mp3,
    } => $class;
}

sub AUTOLOAD {
    my $self = shift;
   (my $a = $AUTOLOAD) =~ s/.*:://;

    if (exists $self->{ _MP3 }->{uc $a}) {
        return $self->{ _MP3 }->$a(@_) ;
    }
    else {
        return;
    }
}

sub mp3_genres    { [ @MP3::Info::mp3_genres    ] }
sub winamp_genres { [ @MP3::Info::winamp_genres ] }

sub genres {
    my @mp3_genres = mp3_genres;
    my @winamp_genres = winamp_genres;
    return [ @mp3_genres, @winamp_genres ]
}

1;

__END__

=head1 NAME

Template::Plugin::MP3 - Interface to the MP3::Info Module

=head1 SYNOPSIS

    [% USE mp3 = MP3("Montana.mp3") %]

    [% mp3.title %]
    [% mp3.album %]

    # perldoc MP3::Info for more ideas

=head1 DESCRIPTION

C<Template::Plugin::MP3> provides a simple wrapper for using
C<MP3::Info> in object oriented mode; see L<MP3::Info> for more
details.

=head1 CONSTRUCTOR and CONFIGURATION 

C<Template::Plugin::MP3> takes a filename as its primary argument:

    [% USE MP3("Tryin_To_Grow_A_Chin.mp3") %]

Optional configuration info can also be specified in the constructor:

    [% USE MP3("Camarillo_Brillo.mp3", utf8 => 1, dir => "/mp3") %]

The name of the file can also be specified as a named parameter
(C<name>):

    [% USE MP3(name => "A_Token_Of_My_Extreme.mp3", dir => "/mp3") %]

C<Template::Plugin::MP3> understands the following options:

=over 8

=item B<name>

The name of the MP3 file.  Note that if both a positional argument and
a C<name> parameter are passed the positional argument will take
precedence.

=item B<dir>

Specify a base directory name; will be prepended to the filename, if
it is defined.

=item B<utf8>

Determines whether results should be returned in UTF-8, as handled by
C<MP3::Info>'s use_mp3_utf8() function.  See
L<MP3::Info/use_mp3_utf8>.  Note that this requires
L<Unicode::String|Unicode::String>.

=back

If the constructor cannot create an instance using the filename
passed, a C<plugin.mp3> Exception is thrown, which will need to be
caught appropriately:

    [% TRY %]
        [% USE mp3 = MP3("Willie The Pimp.mp3") %]
    [% CATCH plugin.mp3 %]
        Can't find that MP3; are you sure you spelled it right?
    [% CATCH %]
        Unexpected exception: [% error %]
    [% END %]

=head1 METHODS

C<Template::Plugin::MP3> provides the following, mostly intuitive,
methods:

=over 16

=item B<file>

Name of the file.

=item B<artist>

Name of the artist.

=item B<album>

Name of the album.

=item B<bitrate>

Bitrate at which the mp3 was encoded.

=item B<size>

Size of the file, in bytes.

=item B<time>, B<secs>, B<mm>, B<ss>, B<ms>

Length of the song, in various permutations.  For example:

=over 8

=item B<time>

03:37

=item B<secs>

217.0253125

=item B<mm>

3

=item B<ss>

27

=item B<ms>

25.3125000000125

=back

=item B<genre>

Genre of the MP3.

=item B<tagversion>

Full name of the version of the MP3 tag, e.g. "ID3v1.1"

=item B<version>

Version of the MP3 tag: 1 or 2

=back

C<MP3::Info> defines some other fields that I don't grok; try

    [% MP3.Dump %]

to see them all.

Of course, all of the above methods don't return the advertised value
if the tag being read does not contain useful information.

=head1 OTHER STUFF

C<Template::Plugin::MP3> provides access to the @mp3_genres and
@winamp_genres arrays via the mp3_genres() and winamp_genres() class
methods, or collectively through the genres() class method:

    [% FOREACH genre = MP3.genres %]
       * [% genre;
    END %]

=head1 AUTHORS

darren chamberlain E<lt>darren@cpan.orgE<gt>

Doug Gorley E<lt>douggorley@shaw.caE<gt>

=head1 COPYRIGHT

(C) 2003 darren chamberlain

This library is free software; you may distribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Template::Plugin>, L<MP3::Info>
