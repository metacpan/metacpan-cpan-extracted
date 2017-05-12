use strict;
use Crypt::PWSafe3 1.04;

my $vault = new Crypt::PWSafe3(file => 'test.psafe3', password => '10101010');
 
binmode STDOUT, ":utf8";

foreach my $uuid ($vault->looprecord) {
    $vault->modifyrecord($uuid, passwd => 'new-password');
}

$vault->save(file => "another.psafe3", passwd => 'blah blah');

