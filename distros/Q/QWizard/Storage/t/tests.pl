#!/usr/bin/perl

use QWizard::Storage::Memory;

$maxtests = 15 if (!$maxtests);

use Test::More tests => $maxtests || 15;

# 1: basic object exist
ok(defined($stobj), "defined");

# 2: basic set/get retrival
$stobj->set('test1','value1');
ok($stobj->get('test1') eq 'value1', "value set and retrieved");

exit if ($maxtests == 2);

# 3-5: testing get_all() returning a hash
my $hash = $stobj->get_all();
ok(ref($hash) eq 'HASH', "get_all returns hash");
ok($hash->{'test1'} eq 'value1', "get_all test hash value");
my @keys = keys(%$hash);
ok($#keys == 0, "correct number of hash elements returned");

# 6-9: testing set_all() to clear everything out with new stuff
$stobj->set_all({ newtoken => 'newval'});
ok($stobj->get('newtoken') eq 'newval', "retrieved new val after set_all");
$hash = $stobj->get_all();
ok(ref($hash) eq 'HASH', "get_all returned hash (again)");
ok($hash->{'newtoken'} eq 'newval', "get_all returned the new hash value after set_all");

SKIP: 
{
    skip "expectedly fails for the CGIParam generator", 1
      if (ref($stobj) eq 'xxxQWizard::Storage::CGIParam');
    @keys = keys(%$hash);
    ok($#keys == 0, "correct number of hash elements returned after set_all");
}


# 10-11: reset
$stobj->reset();
$hash = $stobj->get_all();
ok(ref($hash) eq 'HASH', "get_all still returned hash after reset");
SKIP: 
{
    skip "expectedly fails for the CGIParam generator", 1
      if (ref($stobj) eq 'xxxQWizard::Storage::CGIParam');
    @keys = keys(%$hash);
    ok($#keys == -1, "hash returned from get_all is now empty");
}

my $newmemobj = new QWizard::Storage::Memory();
$newmemobj->set('myname','Wes');

# 12: copy_from
$stobj->copy_from($newmemobj);
ok($stobj->get('myname') eq 'Wes', "retrieved new value after copy_from");

# 13: to_string
SKIP: 
{
    skip "expectedly fails for the CGIParam generator", 2
      if (ref($stobj) eq 'xxxQWizard::Storage::CGIParam');
    $stobj->set('othername','Yamar');
    my $str = $stobj->to_string;
    ok($str eq 'myname_-Wes_-othername_-Yamar' ||
       $str eq 'othername_-Yamar_-myname_-Wes', "Encoding to a string works");

    # 14: from_string
    $stobj->reset();
    $stobj->from_string($str);
    ok($stobj->get('myname') eq 'Wes', "Parsing from a string works");
}

# 15: access wrapper
$stobj->access('myname', 'Wesley');
ok($stobj->access('myname') eq 'Wesley', "The generic access() wrapper works");

#
# NOTE: must end with myname eq 'Wesley' for file-read test to succeed.
#
