#!/usr/bin/perl
# See test 03 for notes
use Test::More tests => 4;
use Data::Dumper;
use lib ('..');
use StoredHash;
use DBI;
use strict;
use warnings;

$Data::Dumper::Indent = 1;
$Data::Dumper::Terse = 1;

#$dbh = DBI->connect("DBI:CSV:f_dir=t");
our $dbh = DBI->connect(qq{DBI:CSV:csv_sep_char=\\;;csv_eol=\n;});
if (!$dbh) {die("Cannot connect: " . $DBI::errstr);}
my $debug = 0;
setuptables($dbh);

my $sh = StoredHash->new('table' => 'animfamily', 'pkey' => ['family'],
   'dbh' => $dbh, 'debug' => $debug);
my $arr = $sh->loadset();
#DEBUG:print(Dumper($arr));
ok (ref($arr) eq 'ARRAY', "Got a set of All Entries ($sh->{'table'})");
my $e = $sh->load(['mammal']);
#DEBUG:print(Dumper($e));
ok (ref($e) eq 'HASH', "Got a entry by 'mammal' (from $sh->{'table'})");
note("Loading children by 'slim' child definition ()");
$sh->loadchildren($e, 'ctypes' => ['anim']);
#DEBUG:print(Dumper($e));
ok(ref($e->{'anim'}) eq 'ARRAY', "Got Instances of mammals (in default member)");
# 
my $cts =[{'table' => 'anim','memname' => 'instances', #'parkey' => ['family']
}];
note("Test Experimental loadchildren() method with extended config");
$sh->loadchildren($e, 'ctypes' => $cts);
#DEBUG:print(Dumper($e));
ok (ref($e->{'instances'}) eq 'ARRAY', "Got Instances of mammals (in custom member)");
# TODO: Same as before but with blessing AND parent linking
# 1) Configure
#map({$_->{'blessto'} = $_->{'table'};$_->{'parlinkattr'} = 'parentfamily';} @$cts);
# 2) Load
#$sh->loadchildren($e, 'ctypes' => $cts);

sub setuptables {
   my ($dbh) = @_;
   our $dir = (-f "anim.txt") ? "." : "t";
   my $fname = "$dir/anim.txt";
   if (!-f $fname) {die("No File $fname");}
   my $fname2 = "$dir/animfamily.txt";
   if (!-f $fname2) {die("No File $fname2");}
   $dbh->{'csv_tables'}->{'anim'} = {'file' => $fname};
   $dbh->{'csv_tables'}->{'animfamily'} = {'file' => $fname2};
}
