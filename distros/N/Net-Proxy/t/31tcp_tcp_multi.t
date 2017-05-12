use Test::More;
use strict;
use warnings;
use IO::Socket::INET;
use t::Util;

use Net::Proxy;

# dummy data
my @lines = (
    "swa_a_p bang swish bap crunch\n",
    "zlonk zok zapeth crunch_eth crraack\n",
    "glipp zwapp urkkk cr_r_a_a_ck glurpp\n",
    "zzzzzwap thwapp zgruppp awk eee_yow\n",
    "ker_plop spla_a_t swoosh cr_r_a_a_ck bang_eth pam uggh\n",
    "AEGEAN_NUMBER_NINETY MATHEMATICAL_SANS_SERIF_ITALIC_SMALL_Y\n",
    "YI_SYLLABLE_SHUX ARABIC_LIGATURE_THEH_WITH_REH_FINAL_FORM\n",
    "TAG_PLUS_SIGN CYPRIOT_SYLLABLE_RE\n",
    "TAG_LATIN_CAPITAL_LETTER_S YI_SYLLABLE_QYRX\n",
    "MATHEMATICAL_DOUBLE_STRUCK_CAPITAL_U HALFWIDTH_HANGUL_LETTER_YEO\n",
    "linguine lasagne_ricce chiocciole\n",
    "fusilli_tricolore sedani_corti galla_mezzana\n",
    "fettucce_ricce maniche chifferi_rigati\n",
    "mista lasagne_festonate_a_nidi nidi\n",
    "capelvenere parigine lacchene\n",
    "occhi_di_passero guanti ditali\n",
);

# compute a seed and show it
init_rand( @ARGV );

# compute random configurations
my @confs = sort { $a->[0] <=> $b->[0] }
    map { [ int rand 16, int rand 8 ] } 1 .. 3;

# compute the total number of tests
my $tests = 1 + ( my $first = int rand 8 );
$tests += $_->[1] for @confs;
$tests += 1 + @confs;

# show the config if 
if( @ARGV ) { 
    diag sprintf "%2d %2d", @$_ for ( [ 0, $first ], @confs );
}
plan tests => $tests;

# lock 2 ports
my @ports = find_free_ports(3);

SKIP: {
    skip "Not enough available ports", $tests if @ports < 3;

    my ($proxy_port, $server_port, $fake_port) = @ports;
    my $pid = fork;

SKIP: {
        skip "fork failed", $tests if !defined $pid;
        if ( $pid == 0 ) {

            # the child process runs the proxy
            my $proxy = Net::Proxy->new(
                {   in => {
                        type => 'tcp',
                        host => 'localhost',
                        port => $proxy_port
                    },
                    out => {
                        type => 'tcp',
                        host => 'localhost',
                        port => $server_port
                    },
                }
            );

            $proxy->register();

            # test unregister()
            my $fake_proxy = Net::Proxy->new(
                {   in => {
                        type => 'tcp',
                        host => 'localhost',
                        port => $fake_port
                    },
                    out => {
                        type => 'tcp',
                        host => 'localhost',
                        port => $server_port
                    },
                }
            );
            $fake_proxy->register();
            $fake_proxy->unregister();

            Net::Proxy->set_verbosity( $ENV{NET_PROXY_VERBOSITY} || 0 );
            Net::Proxy->mainloop( @confs + 1 );
            exit;
        }
        else {

            # wait for the proxy to set up
            sleep 1;

            # start the server
            my $listener = listen_on_port($server_port)
                or skip "Couldn't start the server: $!", $tests;

            # create the first pair
            my %pairs;
            {
                my $pair = (
                    [   connect_to_port($proxy_port),
                        scalar $listener->accept(),
                        $first, 0
                    ]
                );
                %pairs = ( $pair => $pair );
            }

            # check the other proxy is not listening
            {
                my $client = connect_to_port($fake_port);
                is( $client, undef, "Second proxy not here: $!" );
            }

            my $step = my $n = my $count = 0;
            while (%pairs || @confs) {

                # create a new connection
            CONF:
                while ( @confs && $confs[0][0] == $step ) {
                    my $conf   = shift @confs;
                    my $client = connect_to_port($proxy_port)
                        or do {
                        diag "Couldn't start the client: $!";
                        next CONF;
                        };
                    my $server = $listener->accept()
                        or do { diag "Proxy didn't connect: $!"; next CONF; };
                    my $pair = [ $client, $server, $conf->[1], ++$count ];
                    $pairs{$pair} = $pair;
                }

            PAIR:
                for my $pair (values %pairs) {

                    # close the connection if finished
                    if ( $pair->[2] <= 0 ) {
                        $pair->[0]->close();
                        is_closed( $pair->[1],
                            "other socket of pair $pair->[3]" );
                        $pair->[1]->close();
                        delete $pairs{$pair};
                        next PAIR;
                    }

                    # fetch data to send
                    $n %= @lines;
                    my $line = $lines[$n];

                    # randomly swap client/server
                    @{$pair}[ 0, 1 ] = random_swap(@{$pair}[ 0, 1 ]);

                    # send data through the connection
                    print { $pair->[0] } $line;
                    is( $pair->[1]->getline(),
                        $line,
                        "Step $step: line $n sent through pair $pair->[3]" );
                    $pair->[2]--;
                    $n++;

                }
                $step++;
            }
        }
    }
}

