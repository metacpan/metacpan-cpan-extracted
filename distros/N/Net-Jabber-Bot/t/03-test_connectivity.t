#!perl -T

BEGIN {
    use Test::More;

    plan skip_all => "\$ENV{AUTHOR_TESTING} required for these tests" if(!$ENV{AUTHOR_TESTING});
    plan skip_all => "t/test_config.cfg required for connectivity tests" if(! -f 't/test_config.cfg');
}

use Net::Jabber::Bot;
use Log::Log4perl qw(:easy);
use Test::NoWarnings;  # This breaks the skips in CPAN.
# Otherwise it's 7 tests
plan tests => 7;

# Load config file (simple INI parser, replaces Config::Std).
my $config_file = 't/test_config.cfg';
my %config_file_hash;
if (open my $fh, '<', $config_file) {
    my $section = '';
    while (my $line = <$fh>) {
        chomp $line;
        $line =~ s/^\s+//; $line =~ s/\s+$//;
        next if $line eq '' || $line =~ /^[#;]/;
        if ($line =~ /^\[(.+)\]$/) { $section = $1; next; }
        if ($line =~ /^([^:=]+?)\s*[:=]\s*(.*)$/) {
            $config_file_hash{$section}{$1} = $2;
        }
    }
    close $fh;
}
ok(scalar keys %config_file_hash, "Load config file")
    or die("Can't test without config file $config_file");

my $alias = 'make_test_bot';
my $loop_sleep_time = 5;
my $server_info_timeout = 5;

my %forums_and_responses;
$forums_and_responses{$config_file_hash{'main'}{'test_forum1'}} = ["jbot:", ""];
$forums_and_responses{$config_file_hash{'main'}{'test_forum2'}} = ["notjbot:"];

my $bot = Net::Jabber::Bot->new(
    server => $config_file_hash{'main'}{'server'}
    , conference_server => $config_file_hash{'main'}{'conference'}
    , port => $config_file_hash{'main'}{'port'}
    , username => $config_file_hash{'main'}{'username'}
    , password => $config_file_hash{'main'}{'password'}
    , alias => $alias
    , forums_and_responses => \%forums_and_responses
    );

isa_ok($bot, "Net::Jabber::Bot");

ok(defined $bot->Process(), "Bot connected to server");
sleep 5;
ok($bot->Disconnect() > 0, "Bot successfully disconnects"); # Disconnects
is($bot->Disconnect(), undef,  "Bot fails to disconnect cause it already is"); # If already disconnected, we get a negative number

eval{Net::Jabber::Bot->Disconnect()};
like($@, qr/^\QCan't use string ("Net::Jabber::Bot") as a HASH ref while "strict refs" in use\E/, "Error when trying to disconnect not as an object");    

