use v5.40;
use lib 'lib';
use Net::BitTorrent::Protocol::BEP03::Bencode qw[bdecode];
use Path::Tiny;
use Digest::SHA qw[sha1];
#
my $file = shift // die "Usage: $0 <torrent_file>\n";
my $path = path($file);
#
die "File not found: $file\n" unless $path->exists;
#
my $raw  = $path->slurp_raw;
my $data = bdecode($raw);
#
say 'Torrent: ' .  ( $data->{info}{name} // 'Unknown' );
say 'Announce: ' . ( $data->{announce}   // 'N/A' );
#
if ( $data->{info} ) {

    # The info hash is the SHA1 of the bencoded 'info' dictionary
    # We'd need to re-encode it to get the exact bytes if we only have the decoded hash
    # But for a simple example, let's just show some metadata
    if ( $data->{info}{length} ) {
        say 'Size: ' . $data->{info}{length} . ' bytes';
    }
    if ( $data->{info}{files} ) {
        say 'Files:';
        for my $f ( @{ $data->{info}{files} } ) {
            say '  - ' . join( '/', @{ $f->{path} } ) . ' (' . $f->{length} . ' bytes)';
        }
    }
}
say 'Created By: ' . ( $data->{'created by'} // 'Unknown' );
say 'Comment:    ' . ( $data->{comment}      // 'N/A' );
