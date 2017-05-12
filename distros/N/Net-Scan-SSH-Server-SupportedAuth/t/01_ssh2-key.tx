# -*- mode: cperl; -*-
use Test::Base;
use Net::Scan::SSH::Server::SupportedAuth;

plan tests => 5 * blocks;

sub numeric { $_ = +($_[0] || 0); }

filters {
    map { $_ => ['numeric'] } qw(publickey_2 password_2 password_1 publickey_1)
};

run {
    my $block = shift;
    my $scanner = Net::Scan::SSH::Server::SupportedAuth->new(
        host => $block->host,
        port => $block->port,
       );

    my $result = $scanner->scan_as_hash;

    is($scanner->dump,
       $block->dump,
       $block->name . ' dump'
      );

    for my $v (2,1) {
        for my $auth (qw(publickey password)) {
            my $auth_v = "${auth}_${v}";
            is($result->{$v}->{$auth},
               $block->$auth_v,
               $block->name . " $auth_v"
              );
        }
    }
};

__END__
=== key
--- host: localhost
--- port: 22
--- dump: {"1":{"password":0,"publickey":0},"2":{"password":0,"publickey":1}}
--- publickey_2: 1
--- password_2 : 0
--- publickey_1: 0
--- password_1 : 0

=== no port
--- host: localhost
--- port: 2
--- dump: {"1":{"password":0,"publickey":0},"2":{"password":0,"publickey":0}}
--- publickey_2: 0
--- password_2 : 0
--- publickey_1: 0
--- password_1 : 0
