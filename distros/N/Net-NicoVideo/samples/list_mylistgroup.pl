#!/usr/bin/env perl

use strict;
use warnings;
use feature qw/say/;

use Net::NicoVideo;
use Net::NicoVideo::Content::NicoAPI;

binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

my $nnv     = Net::NicoVideo->new;
my $nico    = $nnv->list_mylistgroup;

say 'status: '. $nico->status;

unless( $nico->is_status_ok ){
    say $nico->error_description;
}else{
    for my $mylist ( @{$nico->mylistgroup} ){
    
        say '--';
        for my $mem ( Net::NicoVideo::Content::NicoAPI::MylistGroup->members ){
            say "$mem: ". ($mylist->$mem() // '(undef)');
        }
    }
}

1;
__END__
