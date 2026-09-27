use strict;
use warnings;
use Test::More;
use File::Temp 'tempdir';
use IO::Socket::INET;
use Feersum;
use Plack::Runner;
use Plack::Handler::Feersum::SS;

my $f = Feersum->endjinn;
plan skip_all => 'Feersum built without TLS' unless $f->can('has_tls') && $f->has_tls;

my $dir = tempdir(CLEANUP => 1);
my ($crt, $key, $cnf) = ("$dir/cert.pem", "$dir/key.pem", "$dir/openssl.cnf");
# own config: a bundled openssl (e.g. actions-setup-perl's) may lack its default one
open my $fh, '>', $cnf or die "$cnf: $!";
print $fh "[req]\ndistinguished_name = dn\n[dn]\n";
close $fh;
my $out = `openssl req -config $cnf -x509 -newkey rsa:2048 -nodes -days 1 -subj /CN=localhost -keyout $key -out $crt 2>&1`;
plan skip_all => "cannot create a test certificate with openssl (\$?=$?): "
    . (($out // '') =~ /(\S[^\n]*)/ ? $1 : 'no output') if $?;

my $listen = IO::Socket::INET->new(
    Listen => 5, LocalAddr => '127.0.0.1', LocalPort => 0,
    ReuseAddr => 1, Proto => 'tcp',
) or plan skip_all => "cannot bind 127.0.0.1: $!";
local $ENV{SERVER_STARTER_PORT} = '127.0.0.1:' . $listen->sockport . '=' . $listen->fileno;

my $h2 = $f->can('has_h2') && $f->has_h2 ? 1 : 0;
my $runner = Plack::Runner->new;
$runner->parse_options("--tls-cert-file=$crt", "--tls-key-file=$key", ($h2 ? '--h2=1' : ()));

my %ready;
my $h = Plack::Handler::Feersum::SS->new(@{ $runner->{options} },
    server_ready => sub { %ready = %{ $_[0] } });
ok eval { $h->_prepare; 1 }, 'tls listener prepared' or diag $@;
is_deeply $h->{_tls_config}, { cert_file => $crt, key_file => $key, ($h2 ? (h2 => 1) : ()) },
    'tls config kept for pre_fork respawns';
is $ready{proto}, 'https', 'server_ready reports https';

done_testing;
