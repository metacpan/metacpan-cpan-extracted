package Net::DAAP::Server::AAC::Track;
use strict;
use base qw( Net::DAAP::Server::Track );

use MP4::Info;
use File::Basename qw(basename);

sub new_from_file {
    my $class = shift;
    my $file = shift;
    my $self = $class->new({ file => $file });
    print "Adding $file\n";

    my @stat = stat $file;
    $self->dmap_itemid( $stat[1] ); # the inode should be good enough
    $self->dmap_containeritemid( 0+$self );

    $self->dmap_itemkind( 2 ); # music
    $self->dmap_persistentid( $stat[1] ); # blah, this should be some 64 bit thing
    $self->daap_songbeatsperminute( 0 );

    # All AAC files have 'info'. If it doesn't, give up, we can't read it.
    my $info = MP4::Info::get_mp4info($file) or return;
    $self->daap_songbitrate( $info->{BITRATE} );
    $self->daap_songsamplerate( $info->{FREQUENCY} * 1000 );
    $self->daap_songtime( $info->{SECS} * 1000 );

    # read the tag if we can, fall back to very simple data otherwise.
    my $tag = MP4::Info::get_mp4tag( $file ) || {};
    $self->dmap_itemname( $tag->{TITLE} || basename($file, ".mp3") );
    $self->daap_songalbum( $tag->{ALBUM} );
    $self->daap_songartist( $tag->{ARTIST} );
    $self->daap_songcomment( $tag->{COMMENT} );
    $self->daap_songyear( $tag->{YEAR} || undef );
    my ($number, $count) = split m{/}, ($tag->{TRACKNUM} || "");
    $self->daap_songtrackcount( $count || 0);
    $self->daap_songtracknumber( $number || 0 );

    # from blech:
    # if ($rtag->{TCP} || $rtag->{TCMP}) {
    #     $artist = 'various artists';
    # }
    #
    $self->daap_songcompilation( 0 );
    # $self->daap_songcomposer( );
    $self->daap_songdateadded( $stat[10] );
    $self->daap_songdatemodified( $stat[9] );
    $self->daap_songdisccount( 0 );
    $self->daap_songdiscnumber( 0 );
    $self->daap_songdisabled( 0 );
    $self->daap_songeqpreset( '' );
    $file =~ m{\.(.*?)$};
    $self->daap_songformat( $1 );
    $self->daap_songgenre( '' );
    $self->daap_songgrouping( '' );
    # $self->daap_songdescription( );
    # $self->daap_songrelativevolume( );
    $self->daap_songsize( -s $file );
    $self->daap_songstarttime( 0 );
    $self->daap_songstoptime( 0 );

    $self->daap_songuserrating( 0 );
    $self->daap_songdatakind( 0 );
    # $self->daap_songdataurl( );
    $self->com_apple_itunes_norm_volume( 17502 );

    # $self->daap_songcodectype( 1836082535 ); # mp3?
    # $self->daap_songcodecsubtype( 3 ); # or is this mp3?

    return $self;
}

1;
