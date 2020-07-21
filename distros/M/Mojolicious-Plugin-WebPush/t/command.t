use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
use Mojo::JSON qw(encode_json);
use Mojolicious::Command::webpush;
use Mojo::File qw(curfile);
use lib curfile->sibling('lib')->to_string;
use TestUtils qw(webpush_config %userdb);

plugin 'ServiceWorker';
my $plugin = plugin 'WebPush' => webpush_config();
my $cmd = Mojolicious::Command::webpush->new(app => app);

my $bob_data = { endpoint => '/push/bob/v2', keys => { auth => '', p256dh => '' } };

my @TESTS = (
  [ [], qr/Usage/, "" ],
  [ [qw(create bob), encode_json($bob_data)], "1\n", "" ],
  [ [qw(read bob)], encode_json($bob_data)."\n", "" ],
  [ [qw(delete bob)], encode_json($bob_data)."\n", "" ],
  [ [qw(read bob)], "", "Not found: 'bob'\n" ],
  [ [qw(keygen)], qr/BEGIN EC PRIVATE KEY/, "" ],
);
run_test($cmd, @$_) for @TESTS;

done_testing();

sub run_test {
  my ($cmd, $args, $expected_out, $expected_err) = @_;
  my ($out, $err) = ('', '');
  open my $out_handle, '>', \$out;
  local *STDOUT = $out_handle;
  open my $err_handle, '>', \$err;
  local *STDERR = $err_handle;
  $cmd->run(@$args);
  (ref $_->[1] ? \&like : \&is)->(@$_[0,1], "$args->[0] right std$_->[2]")
    for [ $out, $expected_out, 'out' ], [ $err, $expected_err, 'err' ];
}
