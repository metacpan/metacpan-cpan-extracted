
use Test::More tests => 5;

sub IP () { '127.0.0.1' }
sub PORT () { 30337 }
sub HOSTNAME () { 'test' }
sub APPNAME () { 'controlport_test' }

use POE;


SKIP: {
    skip("Need local network (and permission) to run these tests", 5) unless -f 'run_network_tests';
    use_ok("POE::Component::ControlPort");

    eval "require POE::Component::Client::TCP";
    skip("POE::Component::Client::TCP needed",4) if $@;

    
    eval {
        POE::Component::ControlPort->create(
            local_address => IP,
            local_port => PORT,
            hostname => HOSTNAME,
            appname => APPNAME,
            commands => [
                { 
                    name => 'rot13',
                    help_text => 'rot13 text',
                    usage => 'rot13 [ some text ]',
                    topic => 'silly',
                    command => sub {
                        my %input = @_;
                        my $str;
                        foreach my $bit ( @{ $input{args} } ) {
                            $bit =~ y/A-Za-z/N-ZA-Mn-za-m/;
                            $str .= $bit;
                        }
                        return $str;
                    },
                },
            ]
        );
    };
    is($@, '', 'create() exception check');


    eval {
        close STDERR;
        POE::Component::Client::TCP->new(
            RemoteAddress => IP,
            RemotePort => PORT,
            ConnectTimeout => 5,
            ConnectError => \&error,
            ServerError => \&error,
            Started => sub {
                ok(1,"Successful TCP connection");
                $_[KERNEL]->delay('timeout' => 5);
            },
            
            Connected => \&run_tests,
            ServerInput => \&input,
            InlineStates => {
                timeout => \&timeout,
                crap_out => \&crap_out,
            },
        );
    };
    skip("POE::Session creation failed: $@", 3) if $@;

   
    
    # wrapped in an eval so we *cough* shut things down by force with die.
    eval { POE::Kernel->run(); };

    ok(1,"Finished POE run");
}


########################################################################


sub error {
    my ($op, $num, $str) = @_[ARG0 .. ARG2];
    if($num != 0) {
        ok(0, "Fatal error ($num : $op : $str)");
    }
    $_[KERNEL]->yield('crap_out');
}

sub run_tests {
    $_[HEAP]->{server}->put('rot13 pie');

}

sub input {
    my $input = $_[ARG0];

    if($input =~ /Done\./) {
        my $buf = $_[HEAP]->{buffer};
        delete $_[HEAP]->{buffer};
        like($buf, qr/cvr/, "silly rot13 command output check");
        $_[HEAP]->yield('crap_out');
        
    } else {
        $_[HEAP]->{buffer} .= $input."\n";
    }
}

sub timeout {
    ok(0,"Timeout reached");
    $_[KERNEL]->yield('crap_out');
}

sub crap_out {
    die;
}
