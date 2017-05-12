package SWISH::Filters::ID3toHTML;
use strict;
use vars qw( $VERSION @ISA );
$VERSION = '0.191';
@ISA = ('SWISH::Filters::Base');

# Convert known ID3v2 tags to metanames.

my %id3v2_tags = (
    TIT2 => 'song',         # 4.2.1 TIT2 Title/songname/content description
    TYER => 'year',         # 4.2.1 TYER Year
    TRCK => 'track',        # 4.2.1 TRCK Track number/Position in set
    TCOP => 'copyright',    # 4.2.1 TCOP Copyright message
                            # * WinAMP seems to prepend a (C) to this value.

    TPE1 => 'artist',             # 4.2.1 TPE1 Lead performer(s)/Soloist(s)
    TALB => 'album',              # 4.2.1 TALB Album/Movie/Show title
    TENC => 'encoded',            # 4.2.1 TENC Encoded by
    TOPE => 'artist_original',    # 4.2.1 TOPE Original artist(s)/performer(s)
    TCOM => 'composer',           # 4.2.1 TCOM Composer
    TCON => 'genre',              # 4.2.1 TCON Content type

    # 4.3.2 WXXX User defined URL link frame
    WXXX_URL => 'url',            #  * URL => http://URL/HERE
    WXXX_Description =>
        'url_description',  #  * Description => WinAMP provides no description

    # 4.11 COMM Comments
    COMM_Text     => 'comment',         # * Text => COMMENT
    COMM_Language => 'comment_lang',    # * Language => eng
    COMM_short    => 'comment_short'    # * short => WinAMP provides no short

);

sub new {
    my ($class) = @_;

    my $self = bless { mimetypes => [qr!audio/mpeg!], }, $class;
    return $self->use_modules(qw( MP3::Tag ));
}

sub filter {
    my ( $self, $doc ) = @_;

    # We need a file name to pass to the conversion function
    my $file = $doc->fetch_filename;

    my ( $content_ref, $meta ) = $self->get_id3_content_ref( $file, $doc );
    return unless $content_ref;

    # update the document's content type
    $doc->set_content_type('text/html');

    # If filtered must return either a reference to the doc or a pathname.
    return ( \$content_ref, $meta );
}

# =======================================================================
sub get_id3_content_ref {
    my ( $self, $filename, $doc ) = @_;
    my $mp3 = MP3::Tag->new($filename);

    # return unless we have a file with tags
    return format_empty_doc($filename)
        unless ref $mp3 && $mp3->get_tags();

    # Here we will store all of the tag info
    my %metadata;

    # Convert tags to metadata giving ID3v2 precedence
    get_id3v1_tags( $mp3, \%metadata );

    # will replace any v1 tags that are the same
    get_id3v2_tags( $mp3, \%metadata );

    my $user_meta = $doc->meta_data || {};
    $metadata{$_} = $user_meta->{$_} for keys %$user_meta;

    # HTML or bust
    return (
          %metadata
        ? $self->format_as_html( \%metadata )
        : $self->format_empty_doc($filename)
    );
}

sub get_id3v1_tags {
    my ( $mp3, $metadata ) = @_;

    return unless exists $mp3->{ID3v1};

    # Read all ID3v1 tags into metadata hash
    my $id3v1 = $mp3->{ID3v1};
    for (qw/ artist album comment genre song track year /) {
        $metadata->{$_} = $id3v1->$_ if $id3v1->$_;
    }
}

sub get_id3v2_tags {
    my ( $mp3, $metadata ) = @_;

    # Do we even have an ID3 v2 tag?
    return unless exists $mp3->{ID3v2};

    # Get the tag and a hash of frame ids.
    my $id3v2 = $mp3->{ID3v2};

    # keys are 4-character-codes and values are the long names
    my $frameIDs_hash = $id3v2->get_frame_ids;

    # Go through each frame and translate it to usable metadata
    foreach my $frame ( keys %$frameIDs_hash ) {
        my ( $info, $name ) = $id3v2->get_frame($frame);

        # We have a user defined frame
        if ( ref $info ) {

            # $$$ We really only want COMM and WXXX
            while ( my ( $key, $val ) = each %$info ) {

                next
                    if $key =~ /^_/
                        || !$val;    # leading underscore means binary data

                # Concatenate frame and key for our lookup hash
                my $code = ${frame} . "_" . ${key};

                # fails when frame is appended with digits (e.g. "COMM01");
                my $metaname = $id3v2_tags{$code} || $code;

                # Assign value if not empty and has a key
                $metadata->{$metaname} = $val if $val;
            }
        }

        # We have a simple frame
        else {
            my $metaname = $id3v2_tags{$frame} || $frame || 'blank frame';
            $metadata->{$metaname} = $info if $info;
        }
    }
}

sub format_as_html {
    my $self     = shift;
    my $metadata = shift;

    my $title 
        = $metadata->{song}
        || $metadata->{album}
        || $metadata->{artist}
        || 'No Title';

    my $headers = $self->format_meta_headers($metadata);

    my $url = '';
    if ( $metadata->{url} ) {
        my $desc = $metadata->{url_description} || $metadata->{url};
        $url
            = '<p><a href="'
            . $self->escapeXML( $metadata->{url} )
            . "\">$desc</a>";
    }

    my $comment = '';
    if ( $metadata->{comment} ) {
        my $lang = get_iso_lang( $metadata->{comment_lang} || 'en' )
            ;    # wrong assuming "en"?
        $comment = qq[<p name="comment" lang="$lang">]
            . $self->escapeXML( $metadata->{comment} ) . '</p>';
    }

    my $txt = <<EOF;
<html>
 <head>
   <title>$title</title>
   $headers
 </head>
 <body>
   $url
   $comment
  </body>
</html>
EOF

    return ( $txt, $metadata );

}

sub format_empty_doc {
    my $self     = shift;
    my $filename = shift;
    require File::Basename;
    my $base = File::Basename::basename( $filename, '.mp3' );

    return $self->format_as_html( { song => $base, notag => 1 } );
}

sub get_iso_lang {
    my $lang = shift;

    # Do we need to translate undocumented ID3 Lang codes to ISO?
    # 4.11.Comments
    #   Language $xx xx xx
    #   *  WinAMP may be mistaken for using "eng" instead of an ISO designator

    return $lang unless $lang == "eng";
    return "en";
}

1;
__END__

=head1 NAME

SWISH::Filters::ID3toHTML - ID3 tag to HTML filter module

=head1 DESCRIPTION

SWISH::Filters::ID3toHTML translates ID3 tags into HTML
metadata for use by the SWISH::Filter module and SWISH-E.

Requires CPAN module B<MP3::Tag>.
    
=head1 SUPPORT

Please contact the Swish-e discussion list.
http://swish-e.org/

=cut

