#!/usr/bin/perl -w

use strict;
use Benchmark qw(cmpthese);
use Session;
use Apache::Session::Flex;

my %conf =
  (
   Store => 'File',
   Lock => 'Null',
   Generate => 'MD5',
   Serialize => 'Storable',
   Directory => '/tmp',
  );

my $session = new Session undef, %conf;
my $id = $session->session_id();
$session->set(item=>'test');

cmpthese(1000, {
                'Apache::Session' => \&apache_session,
                Session => \&session,
               });

sub apache_session
{
    my %session;
    tie %session, 'Apache::Session::Flex', $id, \%conf;
    my $item = $session{item};
    $session{item} = 'test';
}

sub session
{
    my $session = new Session $id, %conf;
    my $item = $session->get('item');
    $session->set(item => 'test');
}
