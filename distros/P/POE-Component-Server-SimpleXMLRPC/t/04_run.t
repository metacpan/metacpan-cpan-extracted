use strict;
use Test::More;

#plan skip_all => 'MSWin32 does not have a proper fork()' if $^O eq 'MSWin32';

plan tests => 4;

use Frontier::Client;
use POE qw(Wheel::Run Filter::Reference Filter::Line);
use POE::Kernel;
use POE::Component::Server::SimpleXMLRPC;

my $PORT = 2080;
my $IP = "localhost";

POE::Component::Server::SimpleXMLRPC->new(
                'ADDRESS'       =>      "$IP",
                'PORT'          =>      $PORT,
		'RPC_MAP'       =>      { 
		    test1 => sub { return 'test_ok' },
		    test2 => sub { return { result => 'test_ok', input => @{$_[0]}[0]->{arg} } },
		},
    );
POE::Session->create(
                inline_states => {
                        '_start'        => sub {   $poe_kernel->alias_set( 'TESTER' );
			    $poe_kernel->delay( '_tests', 2 );
						   return;
					   },
                        '_tests'        => \&_start_tests,
                        '_close'        => \&_close,
                        '_stdout'       => \&_stdout,
                        '_stderr'       => \&_stderr,
                        '_sig_chld'     => \&_sig_chld,
                },
);
$poe_kernel->run;
exit 0;

sub _start_tests {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  $heap->{_wheel} = POE::Wheel::Run->new(
	Program => \&_tests,
	StdioFilter  => POE::Filter::Reference->new(),
	StderrFilter => POE::Filter::Line->new(),
	CloseEvent => '_close',
	ErrorEvent => '_close',
	StdoutEvent => '_stdout',
	StderrEvent => '_stderr',
	CloseOnCall => 1
  );
  $kernel->sig_child( $heap->{_wheel}->PID(), '_sig_chld' ) unless $^O eq 'MSWin32';
  return;
}

sub _close {
  delete $_[HEAP]->{_wheel};
  $poe_kernel->call( 'HTTP_GET', 'SHUTDOWN' );
  $poe_kernel->alias_remove( 'TESTER' );
  return;
}

sub _stdout {
  ok( $_[ARG0]->{result}, $_[ARG0]->{test} );
  return;
}

sub _stderr {
  print STDERR $_[ARG0], "\n";
  return;
}

sub _sig_chld {
  return $poe_kernel->sig_handled();
}

####################################################################
sub _tests
{                      
    sleep 1;
    binmode(STDOUT) if $^O eq 'MSWin32';
    my $filter = POE::Filter::Reference->new();

    my $results = [ ];
    my $rpc_client = Frontier::Client->new( url => "http://$IP:$PORT/" );

    my $resp = $rpc_client->call( 'test1', '' );

    die "undef response from test1" unless $resp;
    push @$results, { test => "test1", result => $resp eq 'test_ok' };

    $resp = $rpc_client->call( 'test2', { arg => 'value1' } );

    die "undef response from test2" unless $resp;
    push @$results, { test => "test2 hash return", result => ( ref $resp eq 'HASH' ) };
    push @$results, { test => "test2 result return", result => $resp->{result} eq 'test_ok' };
    push @$results, { test => "test2 args return", result => $resp->{input} eq 'value1' };

    my $replies = $filter->put( $results );
    print STDOUT @$replies;
    return;
}


