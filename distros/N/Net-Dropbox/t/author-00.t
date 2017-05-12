#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}


use Test::NoWarnings;
use Test::More tests => 1;

use Net::Dropbox;

my $nd;
$nd = Net::Dropbox->new();
$nd = Net::Dropbox->new(command_socket => '/home/sungo/.dropbox/command_socket');