#!/usr/bin/perl


use strict;
use blib;
use Test::More tests => 12;
use Qualys;


my $qapi = new Qualys;


isa_ok( $qapi , 'Qualys');
is($qapi->server(),'qualysapi.qualys.com','Testing server()');
is($qapi->userid('username'),'username','Testing userid()');
is($qapi->passwd('password'),'password','Testing passwd()');
is($qapi->api_path('https://qualysapi.qualys.com/msp/'),'https://qualysapi.qualys.com/msp/','Testing api_path()');

ok(my $att = $qapi->attribs({
  iscanner_name => 'qualys_scanner',
  save_report => 'yes'
  }),'Testing set_attribs');
  
is_deeply($att, {
  iscanner_name => 'qualys_scanner',
  save_report => 'yes'
  }, 'Testing return value of set_attribs');
  
$att = $qapi->attribs({this_that => 'yeah'});

is_deeply($att, {
  'iscanner_name' => 'qualys_scanner',
  save_report => 'yes',
  this_that => 'yeah'
  }, 'Testing appending value of set_attribs');


is($qapi->iscanner_name('other_scanner'),'other_scanner','Testing dynamic function 1');
is($qapi->save_report('no'), 'no','Tetsing dynamic function 2');

is_deeply($att, {
  iscanner_name => 'other_scanner',
  save_report => 'no',
  this_that => 'yeah'
  }, 'Testing dynamic value of creation');


$att = $qapi->clear_attribs();

is_deeply($att, {}, 'Testing value of clear_attribs');



  
  
  
