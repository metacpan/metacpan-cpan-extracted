use v5.36;

use utf8;

use Cpanel::JSON::XS ();
use File::Spec ();
use File::Temp qw(tempdir);
use Test::More;

use OpenSearch::PPLQuery::Config ();

my $directory = tempdir(CLEANUP => 1);
my $path = File::Spec->catfile($directory, 'connections.json');
my $json = Cpanel::JSON::XS->new->utf8(0)->canonical(1);

write_document({
    default => 'local',
    connections => {
        local => {url => 'http://127.0.0.1:9200', authentication => {type => 'none'}},
        staging => {
            url => 'https://search.example',
            authentication => {type => 'basic', username => 'reader'},
            tls => {verify => Cpanel::JSON::XS::true, caFile => "certificates/r\x{F8}ot.pem"},
            timeoutSeconds => 30,
        },
    },
});
my $config = OpenSearch::PPLQuery::Config->load($path);
is($config->path, File::Spec->rel2abs($path), 'configuration path is absolute');
is($config->default_name, 'local', 'default connection is retained');
is_deeply([$config->names], [qw(local staging)], 'connection names are sorted');
is_deeply($config->connection('local'), {url => 'http://127.0.0.1:9200', auth_type => 'none', insecure => 0, timeout => 60}, 'unauthenticated connection is normalized');
my $staging = $config->connection('staging');
is($staging->{user}, 'reader', 'basic-auth username is retained');
is($staging->{timeout}, 30, 'connection timeout is retained');
is($staging->{ca_file}, File::Spec->rel2abs("certificates/r\x{F8}ot.pem", $directory), 'relative CA path is resolved from the configuration directory');
ok(Cpanel::JSON::XS::is_bool($config->descriptions->[0]{tls}{verify}), 'safe descriptions preserve JSON booleans');
like(load_error(qq|{"connections":{},"connections":{}}|), qr/Duplicate keys not allowed/, 'duplicate JSON properties are rejected');

like(document_error({version => 1, connections => {local => {url => 'http://127.0.0.1:9200', authentication => {type => 'none'}}}}), qr/unknown property 'version'/, 'the retired version property is rejected as unknown');
like(document_error({unknown => 1, connections => {local => {url => 'http://127.0.0.1:9200', authentication => {type => 'none'}}}}), qr/unknown property 'unknown'/, 'unknown root properties are rejected');
like(document_error({connections => {'bad name' => {url => 'http://127.0.0.1:9200', authentication => {type => 'none'}}}}), qr/Connection name 'bad name' is invalid/, 'connection names are validated');
like(document_error({connections => {local => {url => 'http://127.0.0.1:9200', authentication => {type => 'none'}, password => 'secret'}}}), qr/unknown property 'password'/, 'passwords cannot be stored in a connection');
like(document_error({connections => {local => {url => 'http://127.0.0.1:9200', authentication => {type => 'basic', username => 'reader'}}}}), qr/basic authentication requires an https URL/, 'basic authentication requires HTTPS');
like(document_error({connections => {local => {url => 'http://127.0.0.1:9200', authentication => {type => 'none'}, tls => {verify => Cpanel::JSON::XS::true}}}}), qr/tls settings require an https URL/, 'TLS settings require HTTPS');
like(document_error({connections => {local => {url => 'https://search.example', authentication => {type => 'none'}, tls => {verify => 1}}}}), qr/verify must be a JSON boolean/, 'TLS verification requires a JSON boolean');
like(document_error({connections => {local => {url => 'https://search.example', authentication => {type => 'none'}, tls => {verify => Cpanel::JSON::XS::false, caFile => 'ca.pem'}}}}), qr/caFile cannot be used when verification is disabled/, 'disabled verification cannot specify a CA file');
like(document_error({connections => {local => {url => 'http://127.0.0.1:9200', authentication => {type => 'none'}, timeoutSeconds => '30'}}}), qr/timeoutSeconds must be a positive integer/, 'timeout must be a JSON integer');
like(document_error({default => 'missing', connections => {local => {url => 'http://127.0.0.1:9200', authentication => {type => 'none'}}}}), qr/Default connection 'missing' does not exist/, 'default must name a configured connection');
like(eval { $config->connection('missing'); '' } // $@, qr/Connection 'missing' does not exist/, 'unknown connection lookup fails');

write_document({
    connections => {
        environment => {
            url => 'https://search.example',
            authentication => {type => 'basic', username => 'reader', passwordEnvironment => 'SEARCH_READER_PASSWORD'},
        },
        file => {
            url => 'https://search.example',
            authentication => {type => 'basic', username => 'auditor', passwordFile => 'secrets/auditor.txt'},
        },
    },
});
my $secret_sources = OpenSearch::PPLQuery::Config->load($path);
is($secret_sources->connection('environment')->{password_environment}, 'SEARCH_READER_PASSWORD', 'connection retains its password environment variable');
is($secret_sources->connection('file')->{password_file}, File::Spec->rel2abs('secrets/auditor.txt', $directory), 'connection password file is resolved from the configuration directory');
is($secret_sources->descriptions->[0]{authentication}{passwordEnvironment}, 'SEARCH_READER_PASSWORD', 'safe description identifies an environment password source');
like(document_error({connections => {local => {url => 'https://search.example', authentication => {type => 'basic', username => 'reader', passwordEnvironment => 'PASSWORD', passwordFile => 'password.txt'}}}}), qr/cannot specify both passwordEnvironment and passwordFile/, 'a connection has only one configured password source');
like(document_error({connections => {local => {url => 'https://search.example', authentication => {type => 'basic', username => 'reader', passwordEnvironment => 'invalid-name'}}}}), qr/not a valid environment variable name/, 'password environment variable names are validated');
like(document_error({connections => {local => {url => 'https://search.example', authentication => {type => 'none', passwordFile => 'password.txt'}}}}), qr/password source requires basic authentication/, 'password sources require basic authentication');

{
    local $ENV{XDG_CONFIG_HOME} = '/tmp/pplquery-config-home';
    is(OpenSearch::PPLQuery::Config->default_path, File::Spec->catfile('/tmp/pplquery-config-home', 'pplquery', 'connections.json'), 'default path honors XDG_CONFIG_HOME');
}

done_testing();

sub write_document {
    my ($document) = @_;
    write_text($json->encode($document));
}

sub write_text {
    my ($text) = @_;
    open my $handle, '>:encoding(UTF-8)', $path or die "Cannot create $path: $!\n";
    print {$handle} $text;
    close $handle or die "Cannot close $path: $!\n";
}

sub document_error {
    my ($document) = @_;
    write_document($document);
    return eval { OpenSearch::PPLQuery::Config->load($path); '' } // $@;
}

sub load_error {
    my ($text) = @_;
    write_text($text);
    return eval { OpenSearch::PPLQuery::Config->load($path); '' } // $@;
}
