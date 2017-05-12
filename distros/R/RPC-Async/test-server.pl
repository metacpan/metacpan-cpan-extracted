#!/usr/bin/env perl -c
use strict;
use warnings;

use RPC::Async::Server;
use IO::EventMux;

use English;

my $mux = IO::EventMux->new;
my $rpc = RPC::Async::Server->new($mux);
init_clients($rpc);

while ($rpc->has_clients()) {
    $rpc->io($mux->mux);
}

#print "RPC server: all clients gone\n";

# Named parameter with positional information because of name
sub def_add_numbers { $_[1] ? { n1 => 'int', n2 => 'int' } : { sum => 'int' }; }
sub rpc_add_numbers {
    my ($caller, %args) = @_;
    my $sum = $args{n1} + $args{n2};
    $rpc->return($caller, sum => $sum);
}

# Named parameter with positional information because of name
sub def_sum { $_[1] ? { numbers => ['int'] } : { sum => 'int' }; }
sub rpc_sum {
    my ($caller, %args) = @_;
    my $sum += $_ foreach @{$args{numbers}};
    $rpc->return($caller, sum => $sum);
}

# Named parameter with positional information, as order is used.
# Also optional parameter for type int, pos given as sub type that will be returned to the user
sub def_get_id { $_[1] ? { } : { 'uid|gid|euid|egid' => 'int:pos' }; }
sub rpc_get_id {
    my ($caller) = @_;
    $rpc->return($caller, uid => $UID, gid => $GID, 
	    euid => $EUID, egid => $EGID);
}

# Named parameter with positional information
sub def_callback { $_[1] ? { calls_01 => 'int', callback_02 => 'sub' } : { }; }
sub rpc_callback {
    my ($caller, %args) = @_;
    my ($count, $wrap) = @args{qw(calls callback)};
    my $callback = ${$wrap->{key}[0]};

    $rpc->return($caller);

    for (1 .. $count) {
        $callback->call($count);
    }
}

sub def_complicated {{ 
        array_of_int_01 => ['int'], 
        array_of_string_02 => ['string'], 
        array_of_bool_03 => ['bool'], 
        array_of_any_04 => [''],
        array_of_hash_any_05 => [{}],
        array_of_hash_string_06 => [{ keyname => 'string' }],
        complicated_07 => {
            'results|persons' => [{
                name => 'string',
                age => 'long',
                largeint => 'int64',
            }],
            has_error => 'bool',
            error => {
                errornum => 'byte',
                errorstr => 'string',
            }
        }
};}
sub rpc_complicated {
    my ($caller, %args) = @_;
    $rpc->return($caller, %args);
}


1;
