package MusicBrainz::Collection;

use strict;

use Audio::Scan;
use File::Next;
use HTTP::Request::Common qw(POST);
use LWP::UserAgent;

our $VERSION = '0.01';

sub new {
    my ( $class, %opts ) = @_;
    
    my $self = {
        user    => $opts{user} || '',
        pass    => $opts{pass} || '',
        albums  => {},
        verbose => $opts{verbose} || 0,
    };
    
    bless $self, $class;
    
    if ( !$self->{user} ) {
        $self->_load_auth;
        
        unless ( $self->{user} && $self->{pass} ) {
            die "No login information found\n";
        }
    }
    
    return $self;
}

sub process {
    my ( $self, $dir ) = @_;
    
    if ( my $albums = $self->_find_albums($dir) ) {
        print "Uploading " . scalar( @{$albums} ) . " albums to collection...\n";
        
        my $ua = LWP::UserAgent->new;
        $ua->credentials(
            'musicbrainz.org:80',
            'musicbrainz.org',
            $self->{user} => $self->{pass}
        );
        
        my $req = POST "http://musicbrainz.org/ws/1/collection/", [
            addAlbums => join( ',', @{$albums} ),
        ];
        
        $self->{verbose} && print $req->as_string;
        
        my $response = $ua->request($req);
        
        if ( $response->is_success ) {
            print "Done!\n";
        }
        else {
            print "Error: " . $response->status_line . "\n";
        }
    }
    else {
        print "No album ID tags found\n";
    }
}

sub _load_auth {
    my $self = shift;
    
    require File::Spec;
    my $file = File::Spec->catfile( $ENV{HOME}, '.musicbrainz' );
    
    if ( -e $file ) {
        open my $fh, '<', $file or die "Unable to read .musicbrainz file: $!\n";
        my $prefs = do { local $/; <$fh> };
        close $fh;
        
        ($self->{user}) = $prefs =~ m/user\s+(.+)/;
        ($self->{pass}) = $prefs =~ m/pass\s+(.+)/;
    }
}

sub _find_albums {
    my ( $self, $dir ) = @_;
    
    my $iter = File::Next::files( {
        file_filter => sub { Audio::Scan->is_supported( $File::Next::name ) },
    }, $dir );
    
    # Speed up scanning a bit by ignoring artwork
    local $ENV{AUDIO_SCAN_NO_ARTWORK} = 1;
    
    while ( defined ( my $file = $iter->() ) ) {
        $self->{verbose} && print "$file\n";
        
        my $s = Audio::Scan->scan_tags($file);
        my $tags = $s->{tags};
        
        my $albumid
            =  $tags->{'MusicBrainz Album Id'}
            || $tags->{'MUSICBRAINZ ALBUM ID'}
            || $tags->{'MUSICBRAINZ_ALBUMID'}
            || $tags->{'MusicBrainz/Album Id'};
        
        if ( $albumid ) {
            $self->{albums}->{$albumid} = 1;
        }
    }
    
    return [ keys %{ $self->{albums} } ];
}

1;
__END__

=head1 NAME

MusicBrainz::Collection - Upload album collection list to MusicBrainz

=head1 SYNOPSIS

    use MusicBrainz::Collection;
  
    my $mbcol = MusicBrainz::Collection->new(
        user => 'musicbrainz@example.com',
        pass => '12345',
    );
    
    $mbcol->process('/path/to/music');

=head1 DESCRIPTION

This script uploads a list of all albums found in a given directory that contain
MusicBrainz Album ID tags. This list can be used by the MusicBrainz website for various
purposes such as determining missing albums by your favorite artists, notifying you
about new releases, and so on.

Supported file formats (from L<Audio::Scan>):
MP3, MP4, FLAC, Ogg Vorbis, WMA, WAV, AIFF, Musepack, Monkey's Audio

=head1 METHODS

=head2 new( %options )

Optional arguments are:

    user
    pass
    verbose

If username and password are not supplied to new(), the file ~/.musicbrainz is checked
for login information. The format of this file should be:

    user sampleuser
    pass 12345

=head2 process( $directory )

Process the given directory recursively, finding all MusicBrainz Album ID tags. After all
unique albums have been found, the list is uploaded to your MusicBrainz account.

=head1 SEE ALSO

L<http://musicbrainz.org/doc/MusicCollectionIntroduction>

=head1 AUTHOR

Andy Grundman, E<lt>andy@hybridized.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Andy Grundman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
