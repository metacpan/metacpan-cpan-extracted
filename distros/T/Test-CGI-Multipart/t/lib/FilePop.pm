package FilePop;
use Test::CGI::Multipart;
use Readonly;

my $fileindex = 0;

Readonly my  @FILE_STASH => (
    'doo_doo.blah',
    'nah_nah.blah',
    'noo_noo.blah',
);


Test::CGI::Multipart->register_callback(
    callback => sub {
        my $hash = shift;
        $hash->{file} = $FILE_STASH[$fileindex++];
        return $hash;
    }
);

1
