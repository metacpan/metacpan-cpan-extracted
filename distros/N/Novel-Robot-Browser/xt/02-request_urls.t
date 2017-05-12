#!/usr/bin/perl
use utf8;
use Novel::Robot::Browser;
use Test::More ;
use Data::Dump qw/dump/;

my $browser = Novel::Robot::Browser->new(retry => 3, max_process_num=>8);

my $src_arr = [ 
    'http://202.38.64.10' ,
    'http://www.ustc.edu.cn/', 
    'http://202.38.64.10' ,
    'http://www.ustc.edu.cn/', 
    'http://202.38.64.10' ,
    'http://www.ustc.edu.cn/', 
    'http://202.38.64.10' ,
    'http://www.ustc.edu.cn/', 
    'http://202.38.64.10' ,
    'http://www.ustc.edu.cn/', 
    'http://202.38.64.10' ,
    'http://www.ustc.edu.cn/', 
    'http://202.38.64.10' ,
    'http://www.ustc.edu.cn/', 
    'http://202.38.64.10' ,
    'http://www.ustc.edu.cn/', 
    'http://202.38.64.10' ,
    'http://www.ustc.edu.cn/', 
    'http://202.38.64.10' ,
    'http://www.ustc.edu.cn/', 
    'http://202.38.64.10' ,
    'http://www.ustc.edu.cn/', 
    'http://202.38.64.10' ,
    'http://www.ustc.edu.cn/', 
    'http://202.38.64.10' ,
    'http://www.ustc.edu.cn/', 
    'http://202.38.64.10' ,
    'http://www.ustc.edu.cn/', 
    'http://202.38.64.10' ,
];

my $res = $browser->request_urls( $src_arr, 
    deal_sub => sub { 
        my ($r, $data) = @_; 
        return { url => $r, length => length($$data) };
    }, 
    #request_sub => sub {
    #my ($r) = @_;
    # ...
    #return $data;
    #},
); 
dump($res);

done_testing;
