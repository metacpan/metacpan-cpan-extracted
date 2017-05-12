#!/usr/bin/perl

# Compile-testing for Process::Launcher

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 21;
use File::Spec::Functions ':ALL';
use Probe::Perl       ();
use Process::Launcher ();

my $perl = Probe::Perl->find_perl_interpreter;
my @base = ( $perl,
	'-I' . catdir('blib', 'lib'),
	'-MProcess::Launcher',
);





#####################################################################
# Simulated test the Process::Launcher 'run' command

use_ok( 't::lib::MySimpleProcess' );
SCOPE: {
	@ARGV = qw{t::lib::MySimpleProcess foo bar};
	my $class  = Process::Launcher::load(shift @ARGV);
	is( $class, 't::lib::MySimpleProcess', 'load(t::lib::MySimpleProcess) returned ok' );
	my $object = $class->new( @ARGV );
	isa_ok( $object, $class );
}





#####################################################################
# Live test the Process::Launcher 'run' command

use IPC::Run3 ();
use_ok( 't::lib::MyStorableProcess' );
SCOPE: {
	# Build the complex, uglyish cmd list
	my @cmd = ( @base, '-e run', 't::lib::MyStorableProcess', 'foo', 'bar' );
	my $out = '';
	my $err = '';
	ok( IPC::Run3::run3( \@cmd, \undef, \$out, \$err ), 'run3 returns true' );
	is( $out, "OK\n", 'STDOUT gets OK' );
	is( $err, "foo=bar\nprepare=1\n", "STDERR gets expected output" );
}





#####################################################################
# Test the Process::Launcher 'run3' command

SCOPE: {
	# Build the complex, uglyish cmd list
	my @cmd = ( @base, '-e run3', 't::lib::MyStorableProcess' );
	my $inp  = "foo2=bar2\n";
	my $out = "";
	my $err = '';
	ok( IPC::Run3::run3( \@cmd, \$inp, \$out, \$err ), 'run3 returns true' );
	is( $out, "OK\n", 'STDOUT gets OK' );
	is( $err, "foo2=bar2\nprepare=1\n", "STDERR gets expected output" );
}




#####################################################################
# Test the Process::Launcher 'serialized' command with Storable

use Storable ();
ok(
	t::lib::MyStorableProcess->isa('Process::Storable'),
	'Confirm MyStorableProcess isa Process::Storable',
);
SCOPE: {
	my $object = t::lib::MyStorableProcess->new( 'foo3' => 'bar3' );
	isa_ok( $object, 't::lib::MyStorableProcess' );
	isa_ok( $object, 'Process::Storable'         );
	isa_ok( $object, 'Process'                   );

	# Get the Storablised version
	my @cmd = ( @base, '-e serialized', 't::lib::MyStorableProcess' );
	my $inp = File::Temp::tempfile();
	my $out = File::Temp::tempfile();
	ok( $object->serialize( $inp ), '->serialize returns ok' );
	ok( seek( $inp, 0, 0 ), 'Seeked on tempfile for input' );

	my $err = '';
	ok( IPC::Run3::run3( \@cmd, $inp, $out, \$err ), 'serialized returns true' );
	is( $err, "foo3=bar3\nprepare=1\n", "STDERR gets expected output" );
	ok( seek( $out, 0, 0 ), 'seeked STDOUT to 0' );
	my $header = <$out>;
	is( $header, "OK\n", 'STDOUT has OK header' );

	SKIP: {
		skip("Nothing to deserialize", 1) unless $header eq "OK\n";

		my $after = t::lib::MyStorableProcess->deserialize($out);
		is_deeply( $after,
			(bless {
				foo3    => 'bar3',
				prepare => 1,
				run     => 1,
			}, 'MyStorableProcess'),
			'Returned object matches expected',
		);
	}
}
