#!/usr/bin/perl

# Load test the Perl::Signature module

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 79;
use File::Spec::Functions ':ALL';
use File::Copy;
use Perl::Signature;
use Perl::Signature::Set;
use PPI;

my $basic   = catfile( 't', 'data', 'basic.pl'   );
my $changed = catfile( 't', 'data', 'changed.pl' );
my $object  = catfile( 't', 'data', 'object.pl'  );

# Apparently "somewhere near Perl::Signature" we don't localise $_
# Test this. See Regression tests at bottom for actual check.
$_ = 1234;

# Basics
my $Document = PPI::Document->new(\'my $foo = bar();');
isa_ok( $Document, 'PPI::Document' );

my $docsig1 = Perl::Signature->document_signature( $Document );
is( $_, 1234, '$_ is unchanged after much stuff' );

ok( defined $docsig1, '->document_signature returns defined' );
is( length($docsig1), 32, '->document_signature returns a 32 char thing' );
ok( $docsig1 =~ /^[abcdef01234567890]{32}$/, 'Signature is a hexidecimal string' );


my $source = ' my $foo= bar(); # comment';
my $docsig2 = Perl::Signature->source_signature( $source );
ok( defined $docsig2, '->source_signature returns defined' );
is( length($docsig2), 32, '->source_signature returns a 32 char thing' );

my $docsig3 = Perl::Signature->file_signature( $basic );
ok( defined $docsig3, '->source_signature returns defined' );
is( length($docsig3), 32, '->source_signature returns a 32 char thing' );

is( $docsig1, $docsig2, 'Document and source signatures match' );
is( $docsig1, $docsig3, 'Document and file signatures match' );

open( FILE, ">$object" ) or die "Failed to open object file";
print FILE 'my $foo = bar();';
close FILE;

END {
	unlink $object if -f $object;
}

# Create the object
my $Signature = Perl::Signature->new( $object );
isa_ok( $Signature, 'Perl::Signature' );
is( $Signature->file, $object, '->file matches expected' );
is( $Signature->original, $docsig1, '->original matches expected' );
is( $Signature->current, $docsig1, '->current matches expected' );
is( $Signature->changed, '', '->changed returns false' );
is( $Signature->unchanged, 1, '->unchanged returns true' );

# Change the file
open( FILE, ">$object" ) or die "Failed to open object file";
print FILE "print 'Hello World!';";
close FILE;

# Now check the object's methods again
is( $Signature->file, $object, '->file matches expected' );
is( $Signature->original, $docsig1, '->original matches expected' );
is( length($Signature->current), 32, '->current is a signature' );
ok( $Signature->current =~ /^[abcdef01234567890]{32}$/, 'Signature is a hexidecimal string' );
isnt( $Signature->current, $Signature->original, '->current matches expected' );
is( $Signature->changed, 1, '->changed returns true' );
is( $Signature->unchanged, '', '->unchanged returns false' );

# Create and check a set
my $Set = Perl::Signature::Set->new(undef);
is( $Set, undef, '->new(undef) returns undef' );
$Set = Perl::Signature::Set->new(1);
isa_ok( $Set, 'Perl::Signature::Set' );
$Set = Perl::Signature::Set->new(2);
isa_ok( $Set, 'Perl::Signature::Set' );
$Set = Perl::Signature::Set->new;
isa_ok( $Set, 'Perl::Signature::Set' );
my @null_list = $Set->files;
is_deeply( \@null_list, [], '->files returns correctly in list context' );
my $null_list = $Set->files;
is( $null_list, 0, '->signatures returns correctly in scalar context' );
is( $Set->file('foo'), undef, '->file(bad) returns undef' );
is( $Set->file,        undef, '->file() returns undef' );
is( $Set->file(undef), undef, '->file(undef) returns undef' );
is( $Set->file([]),    undef, '->file(evil) returns undef' );
@null_list = $Set->signatures;
is_deeply( \@null_list, [], '->files returns correctly in list context' );
$null_list = $Set->signatures;
is( $null_list, 0, '->signatures returns correctly in scalar context' );

# Add a known file
my $rv = $Set->add($basic);
isa_ok( $rv, 'Perl::Signature' );
is( $rv->file, $basic, '->file matches expected' );
is( $rv->original, $docsig3, '->original matches expected' );
is( length($rv->current), 32, '->current is a signature' );
is( $rv->current, $docsig3, 'Signature matches expected' );
is( $rv->current, $rv->original, '->current matches expected' );
is( $rv->changed, '', '->changed returns true' );
is( $rv->unchanged, 1, '->unchanged returns false' );

# There should be only one file
my @files = $Set->files;
is( scalar(@files), 1, '->files returns one file' );
is( $files[0], $basic, 'The one file is the one we added' );
my $files = $Set->files;
is( $files, 1, '->files returns one file' );
@files = $Set->signatures;
is( scalar(@files), 1, '->signatures returns one file' );
isa_ok( $files[0], 'Perl::Signature' );
$files = $Set->signatures;
is( $files, 1, '->signatures returns one file' );

# Try to add the same file
$rv = $Set->add($basic);
is( $rv, undef, '->add for an existing file returns null' );

# Add an additional known file
$rv = $Set->add($object);
my $docsig4 = Perl::Signature->source_signature( "print 'Hello World!';" );
is( $rv->file, $object, '->file matches expected' );
is( $rv->original, $docsig4, '->original matches expected' );
is( length($rv->current), 32, '->current is a signature' );
is( $rv->current, $docsig4, 'Signature matches expected' );
is( $rv->current, $rv->original, '->current matches expected' );
is( $rv->changed, '', '->changed returns true' );
is( $rv->unchanged, 1, '->unchanged returns false' );

# Now there should be two files
@files = $Set->files;
is( scalar(@files), 2, '->signatures returns one file' );
is( $files[0], $basic, 'First item is the one expected' );
is( $files[1], $object, 'Second item is the one expected' );
@files = $Set->signatures;
is( scalar(@files), 2, '->signatures returns one file' );
isa_ok( $files[0], 'Perl::Signature' );
isa_ok( $files[1], 'Perl::Signature' );

# Set the ->file method
isa_ok( $Set->file($basic), 'Perl::Signature' );
isa_ok( $Set->file($object), 'Perl::Signature' );
is( $Set->file($basic)->file, $basic, '->file returns expected Signature object' );
is( $Set->file($object)->file, $object, '->file returns expected Signature object' );

# Try the changes method with no changes
my $changes = $Set->changes;
is( $changes, '', '->changes returns false with no changes' );

# Change the second file
open( FILE, ">$object" ) or die "Failed to open object file";
print FILE 'my $foo = bar();';
close FILE;

# Now check for changes
$changes = $Set->changes;
is_deeply( $changes, { $object => 'changed' }, '->changes returns as expected after change' );

# Next, delete the file
unlink $object;
$changes = $Set->changes;
is_deeply( $changes, { $object => 'removed' }, '->changes returns as expected after deletion' );

# Check the serialized form
my $config = $Set->write_string;
is( $config, <<"END_CONFIG", '->write_string returns as expected' );
[files]
$basic=$docsig1
$object=$docsig4

[signature]
layer=1
END_CONFIG

# Do a round trip sanity check
my $Set2 = Perl::Signature::Set->read_string( $config );
isa_ok( $Set2, 'Perl::Signature::Set' );
is_deeply( $Set, $Set2, 'Round trip check ok' );
$changes = $Set->changes;
is_deeply( $changes, { $object => 'removed' }, '->changes returns as expected after deletion' );

# Do a write/read test
ok( $Set->write( $object ), '->write works ok' );
$Set2 = Perl::Signature::Set->read( $object );
unlink $object;
isa_ok( $Set2, 'Perl::Signature::Set' );
is_deeply( $Set, $Set2, 'Round trip check ok' );
$changes = $Set->changes;
is_deeply( $changes, { $object => 'removed' }, '->changes returns as expected after deletion' );





#####################################################################
# Regressions Tests

# rt.cpan.org: Ticket #16671 $_ is not localized 

# is( $_, 1234, '$_ is unchanged after much stuff' );

1;
