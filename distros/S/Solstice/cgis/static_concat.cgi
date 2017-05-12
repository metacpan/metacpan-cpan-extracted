#!/usr/bin/perl

use 5.006_000;
use strict;
use warnings;

use Solstice::CGI;
use Solstice::Configure;
use Solstice::Server;

my $static_concat_dir = Solstice::Configure->new()->getDataRoot() .'/static_file_concat_cache/';

my ($id) = getURLParams();

my ($file, $type) = split(/\./, $id);

my $server = Solstice::Server->new();
$server->setContentType( 
    $type eq 'js'   ? 'text/javascript'   :
    $type eq 'css'  ? 'text/css'          :
    'text/plain'
);
$server->printHeaders();

if( open(my $cache, '<', $static_concat_dir .'/'. $file) ){
    while(<$cache>){
        print;
    }
}



