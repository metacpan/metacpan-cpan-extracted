# -*- Mode: Perl; -*-

=head1 NAME

Port_Configuration.t - Test different ways of specifying the port

=cut

package FooServer;

use strict;
use FindBin qw($Bin);
use lib $Bin;
use NetServerTest qw(prepare_test ok is use_ok diag skip);
prepare_test({
    n_tests   => 51,
    plan_only => 1,
    hostname  => 'localhost', # passing in an explicit one keeps it from doing IPv* resolution
});
#use CGI::Ex::Dump qw(debug);

use_ok('Net::Server');

@FooServer::ISA = qw(Net::Server);

### override these to make run not run
### this will allow all configuration cycles to be run
sub bind {}
sub post_bind {}
sub loop {}
sub log {}
sub server_close {
    my $self = shift;
    return $self;
}
sub fatal {
    my ($self, $msg) = @_;
    die $msg;
}
sub SSL_cert_file { 'somecert' }

my $dump; # poormans dumper - concise but not full bore
$dump = sub {
    my $ref = shift;
    my $ind = shift || '';
    return (!defined $ref) ? 'undef' : ($ref eq '0') ? 0 : ($ref=~/^[1-9]\d{0,12}$/) ? $ref : "'$ref'" if ! ref $ref;
    return "[".join(', ',map {$dump->($_)} @$ref).']' if ref $ref eq 'ARRAY';
    return "{".join(',',map {"\n$ind  $_ => ".$dump->($ref->{$_},"$ind  ")} sort keys %$ref)."\n$ind}";
};

sub p_c { # port check
    my ($pkg, $file, $line) = caller;
    my ($args, $hash, $args_to_new) = @_;
    my $prop = eval { ($args_to_new ? FooServer->new(@$args)->run : FooServer->run(@$args))->{'server'} }
        || do { diag "$@ at line $line"; {} };
#    use CGI::Ex::Dump qw(debug);
#    debug $prop;
    my $got = {bind => $prop->{'_bind'}};
    if ($hash->{'sock'}) {
        push @{ $got->{'sock'} }, NS_props($_) for @{ $prop->{'sock'} || [] };
    }
    my $result = $dump->($got);
    my $test   = $dump->($hash);
    (my $str = $dump->({ref($args->[0]) eq 'HASH' ? %{$args->[0]} : @$args})) =~ s/\s*\n\s*/ /g;
    $str =~ s/^\{/(/ && $str =~ s/\}$/)/ if ref($args->[0]) ne 'HASH';
    $str .= "  ==>  [ '".join("', '", map {$_->hup_string} @{ $prop->{'sock'} || [] })."' ]";
    $str = ($args_to_new ? 'new' : 'run')." $str";
    if ($result eq $test && $str !~ /\|\|/) {
        ok(1, "$str");
    } else {
        diag "Failed at line $line";
        is($result, $test, "$str");
        exit;
    }
}

my %class_m;
sub NS_props {
    no strict 'refs';
    my $sock = shift || return {};
    my $pkg  = ref($sock);
    my $m = $class_m{$pkg} ||= {map {$_ => 1} qw(NS_port NS_host NS_proto NS_ipv), grep {/^(?:SSL|NS)_\w+$/ && defined(&{"${pkg}::$_"})} keys %{"${pkg}::"}};
    return {map {$_ => $sock->$_()} keys %$m};
}

###----------------------------------------------------------------###
# tcp, udp

if (!eval {
    IO::Socket::INET->new->configure({LocalPort => 20203, Proto => 'tcp', Listen => 1, ReuseAddr => 1}) or die;
}) {
    chomp(my $err = $@);
  SKIP: {
      skip "Cannot load Socket6 libraries - skipping IPv6 proto tests ($err)", 25;
    };
} else {
    local $ENV{'IPV'} = 4; # pretend to be on a system without IPv6
    p_c([], {
        bind => [{
            host => '*',
            port => Net::Server::default_port(),
            ipv  => '4',
            proto => 'tcp',
        }],
        sock => [{
            NS_host => '*',
            NS_port => Net::Server::default_port(),
            NS_ipv  => '4',
            NS_proto => 'TCP',
            NS_listen => eval { Socket::SOMAXCONN() },
        }],
    });

    p_c([port => 20201], {
        bind => [{host => '*', port => 20201, proto => 'tcp', ipv => '4'}],
    });


    p_c([port => "localhost:20202"], {
        bind => [{host => 'localhost', port => 20202, proto => 'tcp', ipv => '4'}],
    });

    p_c([port => ["localhost:20202/tcp"]], {
        bind => [{host => 'localhost', port => 20202, proto => 'tcp', ipv => '4'}],
    });

    p_c([port => "localhost:20202/ipv4"], {
        bind => [{host => 'localhost', port => 20202, proto => 'tcp', ipv => '4'}],
    });

    p_c([port => ["localhost:20201/ipv4/tcp", "localhost:20202/tcp/IPv4"]], {
        bind => [{host => 'localhost', port => 20201, proto => 'tcp', ipv => '4'}, {host => 'localhost', port => 20202, proto => 'tcp', ipv => '4'}],
    });

    p_c([port => ["localhost|20201|ipv4|tcp", "localhost,20202,tcp,IPv4"]], {
        bind => [{host => 'localhost', port => 20201, proto => 'tcp', ipv => '4'}, {host => 'localhost', port => 20202, proto => 'tcp', ipv => '4'}],
    });

    p_c([port => ["localhost 20201 ipv4 tcp", "localhost, 20202, tcp, IPv4"]], {
        bind => [{host => 'localhost', port => 20201, proto => 'tcp', ipv => '4'}, {host => 'localhost', port => 20202, proto => 'tcp', ipv => '4'}],
    });

    p_c([port => "localhost:20202/udp"], {
        bind => [{host => 'localhost', port => 20202, proto => 'udp', ipv => '4'}],
        sock => [{
            NS_broadcast => undef,
            NS_host => 'localhost',
            NS_port => 20202,
            NS_ipv  => '4',
            NS_proto => 'UDP',
            NS_recv_flags => 0,
            NS_recv_len => 4096,
        }],
    });

    p_c([port => 20202, listen => 5], {
        bind => [{host => '*', port => 20202, proto => 'tcp', ipv => '4'}],
        sock => [{
            NS_host => '*',
            NS_port => 20202,
            NS_proto => 'TCP',
            NS_listen => 5,
            NS_ipv => '4',
        }],
    });



    p_c([port => ["bar.com:20201/udp", "foo.com:20202/tcp"]], {bind => [
                                                                   {host => 'bar.com', port => 20201, proto => 'udp', ipv => '4'},
                                                                   {host => 'foo.com', port => 20202, proto => 'tcp', ipv => '4'},
                                                                   ]});


    p_c([port => 20201, host => 'bar.com', proto => 'UDP'], {
        bind => [{host => 'bar.com', port => 20201, proto => 'UDP', ipv => '4'}],
    });


    p_c([{port => 20201, host => 'bar.com', proto => 'UDP', udp_recv_len => 400}], {
        bind => [{host => 'bar.com', port => 20201, proto => 'UDP', ipv => '4'}],
        sock => [{NS_host => 'bar.com', NS_port => 20201, NS_proto => 'UDP', NS_ipv => '4', NS_recv_len => 400, NS_recv_flags => 0, NS_broadcast => undef}],
    });


    p_c([port => 20201, host => 'bar.com', proto => 'UDP'], {
        bind => [{host => 'bar.com', port => 20201, proto => 'UDP', ipv => 4}],
    }, 'new');


    p_c([{port => 20201, host => 'bar.com', proto => 'UDP'}], {
        bind => [{host => 'bar.com', port => 20201, proto => 'UDP', ipv => 4}],
    }, 'new');


    p_c([port => [20201, "foo.com:20202/tcp"], host => 'bar.com', proto => 'UDP'], {bind => [
                                                                                        {host => 'bar.com', port => 20201, proto => 'UDP', ipv => 4},
                                                                                        {host => 'foo.com', port => 20202, proto => 'tcp', ipv => 4},
                                                                                        ]});


    p_c([port => ["localhost|20202|tcp"]], {
        bind => [{host => 'localhost', port => 20202, proto => 'tcp', ipv => 4}],
    });


    p_c([port => ["localhost,20202,tcp"]], {
        bind => [{host => 'localhost', port => 20202, proto => 'tcp', ipv => 4}],
    });


    p_c([port => ["[localhost]:20202/tcp"]], {
        bind => [{host => 'localhost', port => 20202, proto => 'tcp', ipv => 4}],
    });

    p_c([port => ["localhost,20202,Net::Server::Proto::TCP"]], {
        bind => [{host => 'localhost', port => 20202, proto => 'Net::Server::Proto::TCP', ipv => 4}],
    });


    p_c([port => {port => 20201}], {
        bind => [{host => '*', port => 20201, proto => 'tcp', ipv => 4}],
    });

    p_c([port => [{port => 20201}]], {
        bind => [{host => '*', port => 20201, proto => 'tcp', ipv => 4}],
    });


    p_c([port => [{port => 20201, host => 'foo.com', proto => 'udp'}]], {
        bind => [{host => 'foo.com', port => 20201, proto => 'udp', ipv => 4}],
    });


    p_c([port => [{port => 20201}], host => 'foo.com', proto => 'udp'], {
        bind => [{host => 'foo.com', port => 20201, proto => 'udp', ipv => 4}],
    });

    p_c([port => [{port => 20202, listen => 6}]], {
        bind => [{host => '*', port => 20202, proto => 'tcp', listen => 6, ipv => 4}],
        sock => [{
            NS_host => '*',
            NS_port => 20202,
            NS_proto => 'TCP',
            NS_listen => 6,
            NS_ipv => 4,
        }],
    });
}

###----------------------------------------------------------------###
# unix, unixdgram

if (!eval { require IO::Socket::UNIX }) {
    my $err = $@;
  SKIP: {
      skip "Cannot load IO::Socket::UNIX - skipping UNIX proto tests", 8;
    };
} else {
    p_c([port => 'foo/bar/unix'], {
        bind => [{host => '*', port => 'foo/bar', proto => 'unix', ipv => '*'}],
    });

    p_c([port => '/foo/bar|unix', udp_recv_len => 500], {
        bind => [{host => '*', port => '/foo/bar', proto => 'unix', ipv => '*'}],
        sock => [{NS_host => '*', NS_port => '/foo/bar', NS_proto => 'UNIX', NS_ipv => '*', NS_listen => Socket::SOMAXCONN(), NS_unix_type => 'SOCK_STREAM', NS_unix_path => '/foo/bar'}],
    });

    p_c([port => '/foo/bar|unixdgram', udp_recv_len => 500], {
        bind => [{host => '*', port => '/foo/bar', proto => 'unixdgram', ipv => '*'}],
        sock => [{NS_host => '*', NS_port => '/foo/bar', NS_proto => 'UNIXDGRAM', NS_recv_len => 500, NS_recv_flags => 0, NS_unix_type => 'SOCK_DGRAM', NS_ipv => '*'}],
    });

    p_c([port => 'foo/bar|sock_dgram|unix'], {
        bind => [{host => '*', port => 'foo/bar', proto => 'unix', unix_type => 'sock_dgram', ipv => '*'}],
    });

    p_c([port => {port => '/foo/bar', proto => 'unix', unix_type => 'sock_stream', listen => 7}], {
        bind => [{host => '*', port => '/foo/bar', proto => 'unix', unix_type => 'sock_stream', listen => 7, ipv => '*'}],
        sock => [{NS_host => '*', NS_port => '/foo/bar', NS_proto => 'UNIX', NS_unix_type => 'SOCK_STREAM', NS_listen => 7, NS_ipv => '*', NS_unix_path => '/foo/bar'}],
    });

    p_c([port => {port => '/foo/bar', proto => 'unix', unix_type => 'sock_dgram'}], {
        bind => [{host => '*', port => '/foo/bar', proto => 'unix', unix_type => 'sock_dgram', ipv => '*'}],
    });

    p_c([port => {port => '/foo/bar', proto => 'unixdgram'}], {
        bind => [{host => '*', port => '/foo/bar', proto => 'unixdgram', ipv => '*'}],
    });

    p_c([port => 'foo/bar/unix', ipv => "*"], {
        bind => [{host => '*', port => 'foo/bar', proto => 'unix', ipv => '*'}],
    });

}

###----------------------------------------------------------------###
# ssl

if (!eval { require Net::SSLeay; 1 }) {
    my $err = $@;
  SKIP: {
      skip "Cannot load Net::SSLeay - skipping SSLEAY proto tests", 3;
    };
} elsif (!eval {
    IO::Socket::INET->new->configure({LocalPort => 20203, Proto => 'tcp', Listen => 1, ReuseAddr => 1}) or die;
}) {
    chomp(my $err = $@);
  SKIP: {
      skip "Cannot load Socket6 libraries - skipping IPv6 proto tests ($err)", 3;
    };
} else {
    local $ENV{'IPV'} = 4; # pretend to be on a system without IPv6

    p_c([proto => 'ssleay'], {
        bind => [{host => '*', port => Net::Server::default_port(), proto => 'ssleay', ipv => 4}],
        sock => [{NS_host => '*', NS_port => 20203, NS_proto => 'SSLEAY', NS_ipv => 4, NS_listen => eval { Socket::SOMAXCONN() }, SSL_cert_file => FooServer::SSL_cert_file()}],
    });

    %class_m = (); # setting SSL_key_file may dynamically change the package methods
    p_c([port => '20203/ssleay', listen => 4, SSL_key_file => "foo/bar"], {
        bind => [{host => '*', port => 20203, proto => 'ssleay', ipv => 4}],
        sock => [{NS_host => '*', NS_port => 20203, NS_proto => 'SSLEAY', NS_ipv => 4, NS_listen => 4, SSL_key_file => "foo/bar", SSL_cert_file => FooServer::SSL_cert_file()}],
    });

    %class_m = (); # setting SSL_key_file may dynamically change the package methods
    p_c([port => {port => '20203', proto => 'ssleay', listen => 6, SSL_key_file => "foo/bar"}], {
        bind => [{host => '*', port => 20203, proto => 'ssleay', listen => 6, SSL_key_file => "foo/bar", ipv => 4}],
        sock => [{NS_host => '*', NS_port => 20203, NS_proto => 'SSLEAY', NS_ipv => 4, NS_listen => 6, SSL_key_file => "foo/bar", SSL_cert_file => FooServer::SSL_cert_file()}],
    });

}

if (!eval { require IO::Socket::SSL }) {
  SKIP: {
      skip "Cannot load Net::SSLeay - skipping SSLEAY proto tests", 1;
    };
} elsif (!eval {
    IO::Socket::INET->new->configure({LocalPort => 20203, Proto => 'tcp', Listen => 1, ReuseAddr => 1}) or die;
}) {
    chomp(my $err = $@);
  SKIP: {
      skip "Cannot load Socket6 libraries - skipping IPv6 proto tests ($err)", 1;
    };
} else {
    local $ENV{'IPV'} = 4; # pretend to be on a system without IPv6

    p_c([proto => 'ssl'], {
        bind => [{host => '*', port => Net::Server::default_port(), proto => 'ssl', ipv => 4}],
        sock => [{NS_host => '*', NS_port => 20203, NS_proto => 'SSL', NS_ipv => 4, NS_listen => eval { Socket::SOMAXCONN() }, SSL_cert_file => FooServer::SSL_cert_file()}],
    });
}


###----------------------------------------------------------------###
# ipv6

if (!eval {
    require Socket6;
    require IO::Socket::INET6;
    IO::Socket::INET6->new->configure({LocalPort => 20203, Proto => 'tcp', Listen => 1, ReuseAddr => 1, Domain => Socket6::AF_INET6()}) or die;
    IO::Socket::INET6->new->configure({LocalAddr => '::1', LocalPort => 20203, Proto => 'tcp', Listen => 1, ReuseAddr => 1, Domain => Socket6::AF_INET6()}) or die;
    IO::Socket::INET6->new->configure({LocalAddr => 'localhost', LocalPort => 20203, Proto => 'tcp', Listen => 1, ReuseAddr => 1, Domain => Socket6::AF_INET6()}) or die;
}) {
    chomp(my $err = $@);
  SKIP: {
      skip "Cannot load Socket6 libraries - skipping IPv6 proto tests ($err)", 13;
    };

} else {
    local $ENV{'IPV'} = 4; # skew the default back to 4 for now

    p_c([port => 20201], {
        bind => [{host => '*', port => 20201, proto => 'tcp', ipv => 4}], # still defaults off even with library loaded
        sock => [{NS_host => '*', NS_port => 20201, NS_proto => 'TCP', NS_ipv => 4, NS_listen => eval { Socket::SOMAXCONN() }}],
    });

    p_c([port => 20201, ipv => 6], { # explicit request
        bind => [{host => '*', port => 20201, proto => 'tcp', ipv => 6}],
        sock => [{NS_host => '*', NS_port => 20201, NS_proto => 'TCP', NS_ipv => 6, NS_listen => eval { Socket::SOMAXCONN() }}],
    });

    p_c([port => [{port => 20201, ipv => 6}]], {
        bind => [{host => '*', port => 20201, proto => 'tcp', ipv => 6}],
    });

    p_c([port => '[*]:20201:IPv6'], {
        bind => [{host => '*', port => 20201, proto => 'tcp', ipv => 6}],
        sock => [{NS_host => '*', NS_port => 20201, NS_proto => 'TCP', NS_ipv => 6, NS_listen => eval { Socket::SOMAXCONN() }}],
    });

    p_c([port => ['[localhost]:IPv6:20201']], {
        bind => [{host => 'localhost', port => 20201, proto => 'tcp', ipv => 6}],
        sock => [{NS_host => 'localhost', NS_port => 20201, NS_proto => 'TCP', NS_ipv => 6, NS_listen => eval { Socket::SOMAXCONN() }}],
    });

    p_c([port => 20201, host => 'localhost/IPv6'], {
        bind => [{host => 'localhost', port => 20201, proto => 'tcp', ipv => 6}],
        sock => [{NS_host => 'localhost', NS_port => 20201, NS_proto => 'TCP', NS_ipv => 6, NS_listen => eval { Socket::SOMAXCONN() }}],
    });

    p_c([port => 20201, host => 'localhost', proto => 'udp IPv6'], {
        bind => [{host => 'localhost', port => 20201, proto => 'udp', ipv => 6}],
    });

    p_c([port => ['[localhost]:20201:IPv4', 'localhost:20201:IPv6']], {
        bind => [{host => 'localhost', port => 20201, proto => 'tcp', ipv => 4}, {host => 'localhost', port => 20201, proto => 'tcp', ipv => 6}],
        sock => [{NS_host => 'localhost', NS_port => 20201, NS_proto => 'TCP', NS_ipv => 4, NS_listen => eval { Socket::SOMAXCONN() }},
                 {NS_host => 'localhost', NS_port => 20201, NS_proto => 'TCP', NS_ipv => 6, NS_listen => eval { Socket::SOMAXCONN() }}],
    });

    p_c([port => 'localhost, 20201, IPv6, IPv4'], {
        bind => [{host => 'localhost', port => 20201, proto => 'tcp', ipv => 6}, {host => 'localhost', port => 20201, proto => 'tcp', ipv => 4}],
    });

    p_c([port => [{port => '20201', host => 'localhost', ipv => [6, 4]}]], {
        bind => [{host => 'localhost', port => 20201, proto => 'tcp', ipv => 6}, {host => 'localhost', port => 20201, proto => 'tcp', ipv => 4}],
    });

    p_c([port => 'localhost, 20201', ipv => 'IPv4, IPv6'], {
        bind => [{host => 'localhost', port => 20201, proto => 'tcp', ipv => 6}, {host => 'localhost', port => 20201, proto => 'tcp', ipv => 4}],
    });

    p_c([port => [{port => '20201', host => 'localhost', ipv => 'IPv6, IPv4'}]], {
        bind => [{host => 'localhost', port => 20201, proto => 'tcp', ipv => 6}, {host => 'localhost', port => 20201, proto => 'tcp', ipv => 4}],
    });

    p_c([port => 20201, host => '::1', ipv => '*'], {
        bind => [{host => '::1', port => 20201, proto => 'tcp', ipv => 6}],
    });

    #p_c([port => 20201, host => 'localhost', ipv => '*'], {
    #    bind => [{host => '::1', port => 20201, proto => 'tcp', ipv => 6}, {host => '127.0.0.1', port => 20201, proto => 'tcp', ipv => 4}],
    #});
    #
    #p_c([port => 20201, host => 'localhost IPv*'], {
    #    bind => [{host => '::1', port => 20201, proto => 'tcp', ipv => 6}, {host => '127.0.0.1', port => 20201, proto => 'tcp', ipv => 4}],
    #});
    #
    #p_c([port => 20201, host => '*', ipv => '*'], { # BSD will have two by default, linux has 1
    #    bind => [{host => '::', port => 20201, proto => 'tcp', ipv => 6}],
    #});
    #
    #delete $ENV{'IPV'};
    #p_c([port => 20201], { # BSD will have two by default, linux has 1
    #    bind => [{host => '::', port => 20201, proto => 'tcp', ipv => 6}],
    #});


}
