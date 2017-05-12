use strict;

use File::Spec;
use FindBin qw($Bin);
use Test::More;

use MusicBrainz::Collection;

plan tests => 1;

# Test that we can read correct album ID tags from different file types
{
    my $wanted = [
      "1f333f1e-e33d-4271-bb7a-9f0dcf7c4988",
      "29d9bf87-2719-46c1-b29f-3bfa87e5d433",
      "45e1d2c7-9427-412d-9a44-e3a6aa980c45",
      "931a2b12-037e-4dfc-8ced-017c4ec7837e",
      "e44c477f-77e7-47e0-a304-effc4e187620",
    ];
    
    my $mbcol = MusicBrainz::Collection->new(
        user => 'foo',
        pass => 'bar',
    );
    
    my $albums = $mbcol->_find_albums(
        File::Spec->catdir( $FindBin::Bin, '..', 't', 'library' )
    );
    
    is_deeply( [ sort @{$albums} ], $wanted, 'Album ID tags read ok' );
}