use Test::More;
use Perl::Server;
use Test::Requires qw/LWP::UserAgent/;
use Net::EmptyPort qw/empty_port check_port/;

my $port = empty_port();
my $pid = fork;
if ($pid == 0) {
    close STDERR;
    exec($^X, '-Ilib', 'script/perl-server', 't', '-p', $port) or die $@;
} else {
    $SIG{INT} = 'IGNORE';
    sleep 1;
    
    unless (check_port($port)) {
        kill 'INT', $pid;
        
        plan skip_all => "Fail to open port!";
    }    
    
    my $ua  = LWP::UserAgent->new;
    my $url = "http://localhost:$port";
    
    my $res1 = $ua->get("$url/");
    is $res1->code, 200;    
    like $res1->content, qr/\.\./;
    like $res1->content, qr/load\.t/;
    like $res1->content, qr/folder\.t/;
    like $res1->content, qr/test\.t/;
    
    my $res2 = $ua->get("$url/files");
    is $res2->code, 200;  
    is $res2->content, 'index';    
    
    my $res3 = $ua->get("$url/files/ok.pl");
    is $res3->code, 200;  
    is $res3->content, 'ok';
    
    kill 'INT', $pid;
    wait;
}

done_testing;
