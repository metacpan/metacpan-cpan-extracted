# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################
sub mkTST(@)
{
	my ($line, $opt) = @_;

	unlink "/tmp/_tst_.log";
	open FH, '> _TST_';
	print FH $line . "\n";
	close \*FH;

	$opt = '' if( !defined $opt);
    my $perlexe = $^X;
	my $rc = system( "$perlexe _TST_  $opt >>/tmp/_tst_.log 2>&1" );

	open( FH , "/tmp/_tst_.log" );
	@x = <FH>;

	unlink "/tmp/_tst_.log";
	unlink "_TST_";
	return $rc/256, \@x;
}
#########################

use Test::More tests => 11;
################################# Test 1 ####################################
BEGIN { use_ok('Script::Toolbox') };

#########################

$OP = {file => {'mod'=>'=s', 'desc'=>'the input file', 'mand' => 0 }};

## Test 2-3 ##################################################################
$op = Script::Toolbox->new( $OP );
is( ref($op), 'Script::Toolbox', 'New' );
can_ok( $op, 'GetOpt');

## Test 4-5 ###################################################################
$op = Script::Toolbox->new();
is( ref($op), 'Script::Toolbox', 'New 2' );
is( $op->GetOpt('file'), undef, 'No Option def' );


### Test 6 ####################################################################
($rc, $x) = mkTST( q(use Script::Toolbox qw(:all); Script::Toolbox->new({'xx' => 'yy'});) );
like( $x->[0], qr/.*Invalid .*invalid./, 'Invalid Option def 1' );

## Test 8 #####################################################################
($rc, $x) = mkTST( q(use Script::Toolbox qw(:all); Script::Toolbox->new({'file'=>{}});) );
like( $x->[0], qr/.*Invalid .*invalid./, 'Invalid Option def 1' );

## Test 9 #####################################################################
($rc, $x) = mkTST( q(use Script::Toolbox qw(:all);
					  Script::Toolbox->new({'falseOption'=>{}});) );
like( $x->[0], qr/.*Invalid .*invalid./, 'Invalid Option def 1' );

# Test 10 #####################################################################
($rc, $x) = mkTST( q(	use Script::Toolbox qw(:all);
	$op=Script::Toolbox->new({'file'=>{'mod'=>'=s', 'desc'=>'the input file', 'mand' => 0 }});
	print $op->GetOpt('file'). "\n";
	),
	'-file meier'
	);
like( $x[0], qr/meier/, 'Valid option read.' );


### Test 11 #####################################################################
($rc, $x) = mkTST( q(	use Script::Toolbox qw(:all);
	$op=Script::Toolbox->new({'file'=>{'mod'=>'=s', 'desc'=>'the input file', 'mand' => 1 }});
	print $op->GetOpt('file'). "\n";
	)
	);
like( $x[0], qr/Missing mandatory option 'file'./, 'Print usage 1.' );


### Test 12 #####################################################################
($rc, $x) = mkTST( q(	use Script::Toolbox qw(:all);
	$op=Script::Toolbox->new({'file'=>{'mod'=>'=s', 'desc'=>'the input file', 'mand' => 1,'default'=>'meier' }});
	print $op->GetOpt('file'). "\n";));
like( $x[0], qr/meier/, 'Use default value.' );

unlink "/tmp/_TST_.log";
unlink "/tmp/_tst_.log";

