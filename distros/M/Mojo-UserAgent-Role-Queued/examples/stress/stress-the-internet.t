use Mojo::UserAgent;

use FindBin;
use Benchmark qw(timethese cmpthese :hireswallclock);

use Mojo::Util qw(trim encode);
use Mojo::File;

#my $u = Mojo::UserAgent->with_roles('Mojo::UserAgent::Assistant')->new(max_redirects => 5);

sub handle_result {
        my $tx  = shift;
        my $url = $tx->req->url;
        if ( $tx->success ) {
            $results{$url} = $tx->res->code . ' '
              . trim $tx->res->dom->find(q{title})->map('text')->join('');
        }
        else {
            $results{$url} = ":(";
        }
        print ".";
#        print $url, " ", encode('UTF-8', $results{$url}), "\n";
    };

my @list = map { split(/\n/, $_) } Mojo::File->new( $FindBin::Bin, 'sites_from_feeds.txt' )->slurp;

my %fails;
my $benchtest = timethese(3, {
    "Blocking" => sub {
    my $ua = Mojo::UserAgent->new(max_redirects => 5);
    my %results = ();
    for (@list) {
        $results{$_} = undef;
        my $tx = $ua->get($_);
        handle_result($tx);
    };
    print "\n";
    my $fail = grep { $_ eq ':(' } values %results;
    my $total = scalar keys %results;
    print "Tried $total urls, failed $fail.\n";
    $fails{'Blocking'} = [$fail, $total];
},
    "Non-Blocking" => sub {
    my $ua = Mojo::UserAgent->new(max_redirects => 5);
    my %results = ();
    for (@list) {
        $results{$_} = undef;
        $ua->get( $_ => sub { handle_result(pop) } );
    };
    print "\n";
    my $fail = grep { $_ eq ':(' } values %results;
    my $total = scalar keys %results;
    print "Tried $total urls, failed $fail.\n";
    $fails{'Non-Blocking'} = [$fail, $total];
},
    "Queued" => sub {
        my $ua = Mojo::UserAgent->new(max_redirects => 5)->with_roles('+Queued');
        my %results = ();
    for (@list) {
        $results{$_} = undef;
        $ua->get( $_ => sub { handle_result(pop) } );
    };
    print "\n";
    my $fail = grep { $_ eq ':(' } values %results;
    my $total = scalar keys %results;
    print "Tried $total urls, failed $fail.\n";
    $fails{'Queued'} = [$fail, $total];
}
});

Mojo::IOLoop->start;

print "\n\n\n";
print "$_ failed ", $fails{$_}[0], ' out of ', $fails{$_}[1], "\n" for (qw(Blocking Non-Blocking Queued));
print "\n\n\n";
cmpthese $benchtest;
