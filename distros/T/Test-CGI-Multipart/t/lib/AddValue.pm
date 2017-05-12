package AddValue;
use Test::CGI::Multipart;
use Readonly;

Readonly my  %VALUE_LOOKUP => (
    'doo_doo.blah' => 'Blah, Blah, Blah,....',
    'nah_nah.blah' => 'Nah, Nah, Nah,....',
    'noo_noo.blah' => 'Noo, Noo, Noo,....',
);


Test::CGI::Multipart->register_callback(
    callback => sub {
        my $hash = shift;
        $hash->{value} = $VALUE_LOOKUP{$hash->{file}};
        return $hash;
    }
);

1
