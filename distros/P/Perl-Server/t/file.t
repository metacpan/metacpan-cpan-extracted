use Test::More;
use Perl::Server;
use Test::Requires qw/LWP::UserAgent/;
use Net::EmptyPort qw/empty_port check_port/;

my $port = empty_port();
my $pid = fork;
if ($pid == 0) {
    close STDERR;
    exec($^X, '-Ilib', 'script/perl-server', 't/files/ok.pl', '-p', $port) or die $@;
} else {
    $SIG{INT} = 'IGNORE';
    sleep 1;
    
    unless (check_port($port)) {
        kill 'INT', $pid;
        
        plan skip_all => "Fail to open port!";
    }
    
    my $ua  = LWP::UserAgent->new;
    my $url = "http://localhost:$port";  
    
    my $res3 = $ua->get("$url");
    
    is $res3->code, 200;  
    is $res3->content, 'ok';
    
    kill 'INT', $pid;
    wait;
}

done_testing;
