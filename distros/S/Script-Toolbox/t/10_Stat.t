# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'


use Test::More tests => 19;
BEGIN { use_ok('Script::Toolbox') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

##############################################################################

$F = Script::Toolbox->new();
##############################################################################
############################### TEST 2 #####################################

$d = $F->Stat('.');
foreach my $x ( keys %{$d} )
{
	ok( $d->{$x}{atime} > 0 );
	last;
}

############################### TEST 3-15 #####################################
$d = $F->Stat('./t/','10_Stat.t');
ok( $d->{'10_Stat.t'}{atime} 	>  0 );
ok( $d->{'10_Stat.t'}{blksize} 	>  0 );
ok( $d->{'10_Stat.t'}{blocks} 	>  0 );
ok( $d->{'10_Stat.t'}{ctime} 	>  0 );
ok( $d->{'10_Stat.t'}{dev} 		>  0 );
ok( $d->{'10_Stat.t'}{gid} 		>= 0 );
ok( $d->{'10_Stat.t'}{ino} 		>  0 );
ok( $d->{'10_Stat.t'}{mode} 	>  0 );
ok( $d->{'10_Stat.t'}{mtime} 	>  0 );
ok( $d->{'10_Stat.t'}{nlink} 	>  0 );
ok( $d->{'10_Stat.t'}{rdev} 	>= 0 );
ok( $d->{'10_Stat.t'}{size} 	>  0 );
ok( $d->{'10_Stat.t'}{uid} 		>= 0 );


############################### TEST 16-17 #####################################
$F->File("> /tmp/__KEY__", "a,b,AAA\n");
$F->File("/tmp/__KEY__",   "a,c,BBB\n");

sub LC($) {
	my ($i) = @_;
	my @O;
	foreach my $l ( @{$i} )
	{
		push @O, lc $l;
	}
	return \@O;
}

$k = $F->KeyMap("> /tmp/__KEY__");
ok( $k->{"a"}{"b"} eq "AAA" );
ok( $k->{"a"}{"c"} eq "BBB" );

$x = $F->KeyMap("> /tmp/__KEY__", \&LC);
ok( $x->{"a"}{"b"} eq "aaa" );
ok( $x->{"a"}{"c"} eq "bbb" );

unlink "/tmp/__KEY__";
