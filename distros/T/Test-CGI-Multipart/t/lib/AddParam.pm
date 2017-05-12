package AddParam;
use Test::CGI::Multipart;
use Readonly;

Readonly my  %PARAM_LOOKUP => (
    'doo_doo.blah' => 'files',
    'nah_nah.blah' => 'files',
    'noo_noo.blah' => 'files2',
);


Test::CGI::Multipart->register_callback(
    callback => sub {
        my $hash = shift;
        $hash->{name} = $PARAM_LOOKUP{$hash->{file}};
        return $hash;
    }
);

1
