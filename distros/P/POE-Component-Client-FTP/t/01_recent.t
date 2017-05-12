use Test::More;

unless ( -e 'network.tests' ) {
  plan skip_all => 'No network tests';
}

plan tests => 3;

use POE qw(Filter::Line); 

use_ok('POE::Component::Client::FTP');

my $server = 'ftp.funet.fi';
my $file = '/pub/CPAN/RECENT';

diag("Going to try and get '$file' from '$server', wish me luck\n");

POE::Session->create(
      package_states => [
        'main' => [qw(_start _stop _shutdown)],
	'main' => { 
		      connect_error => '_connect_error',
		      login_error   => '_login_error', 
		      get_error     => '_get_error',
		      authenticated => '_authenticated',
		      get_data      => '_get_data',
		      get_done      => '_get_done',
	},
      ],
);

$poe_kernel->run();
exit 0;

sub _start {
  my ($kernel,$session) = @_[KERNEL,SESSION];
  POE::Component::Client::FTP->spawn(
        Alias => 'ftpclient' . $session->ID(),
        Username => 'anonymous',
        Password => 'anon@anon.org',
        RemoteAddr => $server,
        Events => [qw(connect_error login_error get_error authenticated get_data get_done)],
        Filters => { get => POE::Filter::Line->new(), },
  );
  return;
}

sub _stop {
  pass("Everything stopped");
  return;
}

sub _shutdown {
  my ($kernel,$session) = @_[KERNEL,SESSION];
  $kernel->post( 'ftpclient' . $session->ID(), 'quit' );
  return;
}

sub _connect_error {
  my ($kernel,@args) = @_[KERNEL,ARG0..$#_];
  warn join(' ', '#', @args), "\n";
  $kernel->yield( '_shutdown' );
  return;
}

sub _login_error {
  my ($kernel,@args) = @_[KERNEL,ARG0..$#_];
  warn join(' ', '#', @args), "\n";
  $kernel->yield( '_shutdown' );
  return;
}

sub _get_error {
  my ($kernel,@args) = @_[KERNEL,ARG0..$#_];
  warn join(' ', '#', @args), "\n";
  $kernel->yield( '_shutdown' );
  return;
}

sub _authenticated {
  my ($kernel,$sender) = @_[KERNEL,SENDER];
  $kernel->post( $sender, 'get', $file);
  return;
}

sub _get_data {
  my ($kernel,$data) = @_[KERNEL,ARG0];
  return;
}

sub _get_done {
  pass("get done");
  $poe_kernel->yield( '_shutdown' );
  return;
}

