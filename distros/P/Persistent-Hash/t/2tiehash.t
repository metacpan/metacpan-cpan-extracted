# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
plan tests => 12;

use strict;
use Persistent::Hash;
use Persistent::Hash::TestHash;

my $phash = Persistent::Hash::TestHash->new();
if(defined $phash)
{
	ok(1);
}
else
{	
	ok(0);
}

$phash->{tk1} = 'tk1v';
if($phash->{tk1} eq 'tk1v')
{
	ok(1);
}
else
{
	ok(0);
}

$phash->{itk1} = 'itk1';
if($phash->{itk1} eq 'itk1')
{
	ok(1);
}
else
{
	ok(0);
}

$phash = Persistent::Hash::TestHash->new();
if(defined $phash)
{
	ok(1);
}
else
{	
	ok(0);
}

$phash->{tk3} = 'tk3';
$phash->{itk2} = 'itk2';
my $untied_phash = tied %$phash;
if(defined $untied_phash)
{
	ok(1);
}
else
{
	ok(0);
}

if($untied_phash->{_data_dirty} == 1)
{
	ok(1);
}
else
{
	ok(0);
}

if($untied_phash->{_index_dirty} == 1)
{
	ok(1);
}
else
{
	ok(0);
}


if($untied_phash->{_index_data}->{'itk2'} eq 'itk2')
{
	ok(1);
}
else
{
	ok(0);
}

if($untied_phash->{_data}->{'tk3'} eq 'tk3')
{
	ok(1);
}
else
{
	ok(0);
}


my $keys = [keys %$phash];
if(defined $keys)
{
	ok(1);
}
else
{
	ok(0);
}

my $kcount = @$keys;
if($kcount == 2)
{
	ok(1);
}
else
{
	ok(0);
}

my $kc = 0;
foreach my $key (@$keys)
{
	$kc++;
}
if($kc == 2)
{
	ok(1);
}
else
{
	ok(0);
}



#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

