#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 14;
use Test::NoWarnings;
use Test::LongString;
use Padre::Plugin::FormBuilder::Perl;
use Padre::Unload;

sub code {
	my $left    = shift;
	my $right   = shift;
	if ( ref $left ) {
		$left = join '', map { "$_\n" } @$left;
	}
	if ( ref $right ) {
		$right = join '', map { "$_\n" } @$right;
	}
	is_string( $left, $right, $_[0] );
}

sub compiles {
	my $code = shift;
	if ( ref $code ) {
		$code = join '', map { "$_\n" } @$code;
	}
	SKIP: {
		skip("Skipping compile test for release", 1) if $ENV{ADAMK_RELEASE};
		my $rv = eval $code;
		# diag( $@ ) if $@;
		ok( $rv, $_[0] );
	}
}

# Provide a simple slurp implementation
sub slurp {
	my $file = shift;
	local $/ = undef;
	local *FILE;
	open( FILE, '<', $file ) or die "open($file) failed: $!";
	my $text = <FILE>;
	close( FILE ) or die "close($file) failed: $!";
	return $text;
}

# Find the sample files
my $input = File::Spec->catfile( 't', 'data', 'regress.fbp' );
my $naive = File::Spec->catfile( 't', 'data', 'naive.pl'  );
my $strict = File::Spec->catfile( 't', 'data', 'strict.pl' );
ok( -f $input,  "Found test file $input"  );
ok( -f $naive, "Found test file $naive" );
ok( -f $strict, "Found test file $strict" );

# Load the sample file
my $fbp = FBP->new;
isa_ok( $fbp, 'FBP' );
ok( $fbp->parse_file($input), '->parse_file ok' );

# Make sure we have the things we need for the generation
my $project = $fbp->find_first( isa => 'FBP::Project' );
isa_ok( $project, 'FBP::Project' );
my $dialog  = $project->find_first( isa => 'FBP::Dialog' );
isa_ok( $dialog, 'FBP::Dialog' );

# Test in naive mode
SCOPE: {
	# Create the generator object
	my $code = Padre::Plugin::FormBuilder::Perl->new(
		project  => $project,
		version  => '0.04',
		nocritic => 1,
	);
	isa_ok( $code, 'FBP::Perl' );

	# Generate the entire dialog constructor
	my $have = $code->dialog_class($dialog);
	my $want = slurp($naive);
	code( $have, $want, '->dialog_super ok' );
	compiles( $have, 'Dialog class compiled' );
	Padre::Unload::unload($dialog->name);
}

# Test in strict mode
SCOPE: {
	# Create the generator object
	my $code = Padre::Plugin::FormBuilder::Perl->new(
		project     => $project,
		version     => '0.04',
		prefix      => 2,
		encapsulate => 1,
		nocritic    => 1,
	);
	isa_ok( $code, 'FBP::Perl' );

	# Generate the entire dialog constructor
	my $have = $code->dialog_class($dialog);
	my $want = slurp($strict);
	code( $have, $want, '->dialog_super ok' );
	compiles( $have, 'Dialog class compiled' );
}
