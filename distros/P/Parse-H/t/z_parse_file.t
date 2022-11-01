#!/usr/bin/perl -T -w

use strict;
use warnings;

use Fcntl qw(:seek);

use Test::More tests => 13 * 4;
use Parse::H qw(parse_file);

# Test::More:
#plan tests => 1;

open (my $infile, '<', 't/test.h') or die "Cannot open test.h: $!\n";

my ($was_extern, $was_comment, $was_preproc,
	$was_typedef, $was_struct_start, $was_struct_entry,
	$was_struct_end, $was_enum_start, $was_enum_entry_sub,
	$was_enum_end, $was_union_start, $was_union_entry,
	$was_union_end);

my %params = ();

my $extern_sub = sub
{
	$was_extern = 1;
	return shift;
};

my $comment_sub = sub
{
	$was_comment = 1;
	return shift;
};

my $preproc_sub = sub
{
	$was_preproc = 1;
	return shift;
};

my $typedef_sub = sub
{
	$was_typedef = 1;
	return shift;
};

my $struct_start_sub = sub
{
	$was_struct_start = 1;
	return shift;
};

my $struct_entry_sub = sub
{
	$was_struct_entry = 1;
	return shift;
};

my $struct_end_sub = sub
{
	$was_struct_end = 1;
	return shift;
};

my $enum_start_sub = sub
{
	$was_enum_start = 1;
	return shift;
};

my $enum_entry_sub = sub
{
	$was_enum_entry_sub = 1;
	return shift;
};

my $enum_end_sub = sub
{
	$was_enum_end = 1;
	return shift;
};

my $union_start_sub = sub
{
	$was_union_start = 1;
	return shift;
};

my $union_entry_sub = sub
{
	$was_union_entry = 1;
	return shift;
};

my $union_end_sub = sub
{
	$was_union_end = 1;
	return shift;
};

my $output_sub = sub
{
};

#################################################

$was_extern = 0;
$was_comment = 0;
$was_preproc = 0;
$was_typedef = 0;
$was_struct_start = 0;
$was_struct_entry = 0;
$was_struct_end = 0;
$was_enum_start = 0;
$was_enum_entry_sub = 0;
$was_enum_end = 0;
$was_union_start = 0;
$was_union_entry = 0;
$was_union_end = 0;

%params = (
	'infile' => $infile,
	'output_sub' => $output_sub,
	'comment_sub' => $comment_sub,
	'preproc_sub' => $preproc_sub,
	'extern_sub' => $extern_sub,
	'typedef_sub' => $typedef_sub,
	'struct_start_sub' => $struct_start_sub,
	'struct_entry_sub' => $struct_entry_sub,
	'struct_end_sub' => $struct_end_sub,
	'union_start_sub' => $union_start_sub,
	'union_entry_sub' => $union_entry_sub,
	'union_end_sub' => $union_end_sub,
	'enum_start_sub' => $enum_start_sub,
	'enum_entry_sub' => $enum_entry_sub,
	'enum_end_sub' => $enum_end_sub,
	'pointer_size' => 8,
);

parse_file (%params);

is ( $was_extern, 1, '$was_extrn was not set' );
is ( $was_comment, 1, '$was_comment was not set' );
is ( $was_preproc, 1, '$was_preproc was not set' );
is ( $was_typedef, 1, '$was_typedef was not set' );
is ( $was_struct_start, 1, '$was_struct_start was not set' );
is ( $was_struct_entry, 1, '$was_struct_entry was not set' );
is ( $was_struct_end, 1, '$was_struct_end was not set' );
is ( $was_enum_start, 1, '$was_enum_start was not set' );
is ( $was_enum_entry_sub, 1, '$was_enum_entry_sub was not set' );
is ( $was_enum_end, 1, '$was_enum_end was not set' );
is ( $was_union_start, 1, '$was_union_start was not set' );
is ( $was_union_entry, 1, '$was_union_entry was not set' );
is ( $was_union_end, 1, '$was_union_end was not set' );

$was_extern = 0;
$was_comment = 0;
$was_preproc = 0;
$was_typedef = 0;
$was_struct_start = 0;
$was_struct_entry = 0;
$was_struct_end = 0;
$was_enum_start = 0;
$was_enum_entry_sub = 0;
$was_enum_end = 0;
$was_union_start = 0;
$was_union_entry = 0;
$was_union_end = 0;

seek ($infile, 0, SEEK_SET);

%params = ();

parse_file (%params);

is ( $was_extern, 0, '$was_extrn was set' );
is ( $was_comment, 0, '$was_comment was set' );
is ( $was_preproc, 0, '$was_preproc was set' );
is ( $was_typedef, 0, '$was_typedef was set' );
is ( $was_struct_start, 0, '$was_struct_start was set' );
is ( $was_struct_entry, 0, '$was_struct_entry was set' );
is ( $was_struct_end, 0, '$was_struct_end was set' );
is ( $was_enum_start, 0, '$was_enum_start was set' );
is ( $was_enum_entry_sub, 0, '$was_enum_entry_sub was set' );
is ( $was_enum_end, 0, '$was_enum_end was set' );
is ( $was_union_start, 0, '$was_union_start was set' );
is ( $was_union_entry, 0, '$was_union_entry was set' );
is ( $was_union_end, 0, '$was_union_end was set' );

seek ($infile, 0, SEEK_SET);

%params = (
	'infile' => undef,
	'output_sub' => $output_sub,
	'comment_sub' => $comment_sub,
	'preproc_sub' => $preproc_sub,
	'extern_sub' => $extern_sub,
	'typedef_sub' => $typedef_sub,
	'struct_start_sub' => $struct_start_sub,
	'struct_entry_sub' => $struct_entry_sub,
	'struct_end_sub' => $struct_end_sub,
	'union_start_sub' => $union_start_sub,
	'union_entry_sub' => $union_entry_sub,
	'union_end_sub' => $union_end_sub,
	'enum_start_sub' => $enum_start_sub,
	'enum_entry_sub' => $enum_entry_sub,
	'enum_end_sub' => $enum_end_sub,
);

parse_file (%params);

is ( $was_extern, 0, '$was_extrn was set' );
is ( $was_comment, 0, '$was_comment was set' );
is ( $was_preproc, 0, '$was_preproc was set' );
is ( $was_typedef, 0, '$was_typedef was set' );
is ( $was_struct_start, 0, '$was_struct_start was set' );
is ( $was_struct_entry, 0, '$was_struct_entry was set' );
is ( $was_struct_end, 0, '$was_struct_end was set' );
is ( $was_enum_start, 0, '$was_enum_start was set' );
is ( $was_enum_entry_sub, 0, '$was_enum_entry_sub was set' );
is ( $was_enum_end, 0, '$was_enum_end was set' );
is ( $was_union_start, 0, '$was_union_start was set' );
is ( $was_union_entry, 0, '$was_union_entry was set' );
is ( $was_union_end, 0, '$was_union_end was set' );

seek ($infile, 0, SEEK_SET);

%params = (
	'infile' => $infile,
	'output_sub' => undef,
	'comment_sub' => $comment_sub,
	'preproc_sub' => $preproc_sub,
	'extern_sub' => $extern_sub,
	'typedef_sub' => $typedef_sub,
	'struct_start_sub' => $struct_start_sub,
	'struct_entry_sub' => $struct_entry_sub,
	'struct_end_sub' => $struct_end_sub,
	'union_start_sub' => $union_start_sub,
	'union_entry_sub' => $union_entry_sub,
	'union_end_sub' => $union_end_sub,
	'enum_start_sub' => $enum_start_sub,
	'enum_entry_sub' => $enum_entry_sub,
	'enum_end_sub' => $enum_end_sub,
	'pointer_size' => 8,
);

parse_file (%params);

is ( $was_extern, 1, '$was_extrn was not set' );
is ( $was_comment, 1, '$was_comment was not set' );
is ( $was_preproc, 1, '$was_preproc was not set' );
is ( $was_typedef, 1, '$was_typedef was not set' );
is ( $was_struct_start, 1, '$was_struct_start was not set' );
is ( $was_struct_entry, 1, '$was_struct_entry was not set' );
is ( $was_struct_end, 1, '$was_struct_end was not set' );
is ( $was_enum_start, 1, '$was_enum_start was not set' );
is ( $was_enum_entry_sub, 1, '$was_enum_entry_sub was not set' );
is ( $was_enum_end, 1, '$was_enum_end was not set' );
is ( $was_union_start, 1, '$was_union_start was not set' );
is ( $was_union_entry, 1, '$was_union_entry was not set' );
is ( $was_union_end, 1, '$was_union_end was not set' );

#################################################

close $infile;

