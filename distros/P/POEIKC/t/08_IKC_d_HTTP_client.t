use Test::Base;
use strict;
use lib qw(t);
eval q{ use IKC_d_HTTP_client };
plan skip_all => "IKC_d_HTTP_client is not installed." if $@;

BEGIN {
eval q{ use Net::Config qw(%NetConfig) };
plan skip_all => "Net::Config is not installed." if $@;

eval q{ use HTTP::Request::Common qw(GET) };
plan skip_all => "HTTP::Request::Common is not installed." if $@;

eval q{ use POE::Component::Client::HTTP qw(GET) };
plan skip_all => "POE::Component::Client::HTTP is not installed." if $@;

eval q{ use POE::Component::Client::HTTP qw(GET) };
plan skip_all => "POE::Component::Client::Keepalive is not installed." if $@;
}
BEGIN {
no warnings;
my $may_make_connections = $NetConfig{test_hosts};
skip_all => "No network connection", unless $may_make_connections;
}

use POE qw(
	Sugar::Args
	Loop::IO_Poll
	Component::IKC::Server
	Component::IKC::Client
	Component::IKC::ClientLite
);
use POEIKC::Daemon;
use Data::Dumper;
use Errno qw(EAGAIN);
my $DEBUG = shift || '';

$| = 1;

#  'debug' => $DEBUG,
my $options = {
  'INC' => [
             './t'
           ],
  'alias' => 'POEIKCd_t',
  'port' => 49225
};

if ($DEBUG) {
	$DEBUG =~ /a/i ? $options->{debug}=1 : $DEBUG=1;
}

my $pid;
FORK: {
	if( $pid = fork ) {
	    # Parent process
	} elsif (defined $pid) {
	    # Child process
		POEIKC::Daemon->daemon(%{$options});
		#	my $pikcd = POEIKC::Daemon->init(%{$options});
		#	POE::Session->create(
		#		package_states => [ main => Class::Inspector->methods('main') ],
		#	);
		#	$pikcd->spawn();
		#	$pikcd->poe_run();
	    exit;
	} elsif ( $! == EAGAIN) {
	    sleep 1;
	    redo FORK;
	} else {
	    die "Can't fork: $\n";
	}
} # End Of Label:FORK

	sleep 1;
		*POEIKC::Daemon::Utility::DEBUG = $DEBUG;

		my ($name) = $0 =~ /(\w+)\.\w+/;
		$name .= $$;
		my %cicopt = (
			ip => '127.0.0.1',
			port => $options->{port},
			name => $name,
		);

		$DEBUG and POEIKC::Daemon::Utility::_DEBUG_log(\%cicopt);

		if( Proc::ProcessTable->use ){
			my $port = $options->{port};
			for my $ps( @{Proc::ProcessTable->new->table} ) {
				if ($ps->{pid} != $$ and $ps->{fname} eq 'poeikcd' and $ps->{cmndline} =~ /--port=$port/){
					plan skip_all => $ps->{cmndline}." .... already running \n";
					die;
				}
			}
		}

		my $ikc = create_ikc_client(%cicopt);
		$ikc ? 	plan(tests => 1 * blocks) : plan skip_all => '';

		my $r;
		my $c;
		run {
			my $t = shift;
			my ($no, $type, $state, $name, $comment) = split /\t/, $t->name ;

			my $i = $t->input ;
			my $e;
			my $seq_num = $t->seq_num ;

			$r = $ikc->post_respond(
				$state => eval $i) if $type ne 'pass';
				$ikc->error and die($ikc->error);

#			POEIKC::Daemon::Utility::_DEBUG_log($seq_num,$c);
			eval $state if defined $state and $type eq 'pass';

#			POEIKC::Daemon::Utility::_DEBUG_log($seq_num,$c);
			$e = $type ne 'like' ? eval $t->expected : $t->expected;
			$e = ref $e ? Dumper($e):$e;
			$r = ref $r ? Dumper($r):$r;

			for ($type) {
				$_ eq 'isnt'	and isnt($r , $e, $name), last;
				$_ eq 'is'		and is	($r , $e, $name), last;
				$_ eq 'ok_r'	and ok	($r ,     $name), last;
				$_ eq 'ok_e'	and ok	($e ,     $name), last;
				$_ eq 'like'	and like($r , qr/$e/, $name ), last; # ."\t like($r, qr/$e/)"
			}
#			POEIKC::Daemon::Utility::_DEBUG_log(
#				sprintf "[%2d] t=%s, n=%s, \ni=%s, \ne=%s, \nr=%s, \nc=%s, \nv=%s, \ncomment=%s",
#				$seq_num, $type, $name, ($i||"`'"), ($e||"`'"), ($r||"`'"), (Dumper($c||"`'")), $v||"`'", $comment||"`'",
#			);
			$type eq 'pass'	and pass('...');
		};

		# 'POEIKCd_t/method_respond' => ['POEIKC::Daemon::Utility','stop','POEIKC::Daemon::Utility','stop']
		$ikc->post_respond($options->{alias}.'/method_respond',
			['POEIKC::Daemon::Utility','shutdown']
		);
		$ikc->error and die($ikc->error);

    #wait;
	waitpid($pid, 0);

__END__

=== 1	is	POEIKCd_t/method_respond	POEIKC::Daemon::Utility=>get_VERSION
--- input: ['POEIKC::Daemon::Utility' => 'get_VERSION']
--- expected: $POEIKC::Daemon::VERSION

=== 2	like	POEIKCd_t/method_respond	'IKC_d_HTTP_client' => 'spawn'
--- input: ['IKC_d_HTTP_client' => 'spawn']
--- expected: ^\d+$

=== 3	is	POEIKCd_t/event_respond	'IKC_d_HTTP','enqueue','http://search.cpan.org/~suzuki/'
--- input: ['IKC_d_HTTP','enqueue','http://search.cpan.org/~suzuki/']
--- expected: 1

=== 6	is	POEIKCd_t/method_respond	'POEIKCd_t/method_respond' => ['POEIKC::Daemon::Utility','publish_IKC','IKC_d_HTTP','IKC_d_HTTP_client']
--- input: ['POEIKC::Daemon::Utility','publish_IKC','IKC_d_HTTP','IKC_d_HTTP_client']
--- expected: 1

=== 7	is	IKC_d_HTTP/enqueue_respond	'IKC_d_HTTP/enqueue_respond' => ['http://search.cpan.org/~suzuki/']
--- input: ['http://search.cpan.org/~suzuki/']
--- expected: 1

