#!perl -w
# A test for Parse::H - A parser module for C header files.
#
#	Copyright (C) 2022-2023 Bogdan 'bogdro' Drozdowski,
#	  bogdro (at) users . sourceforge . net
#	  bogdro /at\ cpan . org
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#

use strict;
use warnings;

use Fcntl qw(:seek);

use Test::More tests => 13 * 33;
use Parse::H qw(parse_file parse_struct parse_union);

# Test::More:
#plan tests => 1;

open (my $infile, '<', 't/test.h') or die "Cannot open test.h: $!\n";

my ($was_extern, $was_comment, $was_preproc,
	$was_typedef, $was_struct_start, $was_struct_entry,
	$was_struct_end, $was_enum_start, $was_enum_entry_sub,
	$was_enum_end, $was_union_start, $was_union_entry,
	$was_union_end);

my %params = ();
my $debug = 0;

my $extern_sub = sub
{
	my $name = shift;
	print STDERR "Extern: '$name'\n" if $debug;
	$was_extern = 1;
	return $name;
};

my $comment_sub = sub
{
	my $line = shift;
	#print STDERR "Comment: '$line'\n" if $debug;
	$was_comment = 1;
	return $line;
};

my $preproc_sub = sub
{
	my $line = shift;
	#print STDERR "Preprocessor line: '$line'\n" if $debug;
	$was_preproc = 1;
	return $line;
};

my $typedef_sub = sub
{
	my $old_type = shift;
	my $new_type = shift;
	print STDERR "Typedef: old='$old_type', new='$new_type'\n" if $debug;
	$was_typedef = 1;
	return $new_type;
};

my $struct_start_sub = sub
{
	my $name = shift;
	print STDERR "Structure start: '$name'\n" if $debug;
	$was_struct_start = 1;
	return $name;
};

my $struct_entry_sub = sub
{
	my $name = shift;
	my $size = shift;
	print STDERR "Structure entry: '$name' of size $size\n" if $debug;
	$was_struct_entry = 1;
	return $name;
};

my $struct_end_sub = sub
{
	my $name = shift;
	print STDERR "Structure end: '$name'\n" if $debug;
	$was_struct_end = 1;
	return $name;
};

my $enum_start_sub = sub
{
	my $name = shift;
	print STDERR "Enum start: '$name'\n" if $debug;
	$was_enum_start = 1;
	return $name;
};

my $enum_entry_sub = sub
{
	my $name = shift;
	my $value = shift;
	print STDERR "Enum entry: '$name' of value $value\n" if $debug;
	$was_enum_entry_sub = 1;
	return $name;
};

my $enum_end_sub = sub
{
	print STDERR "Enum end.\n" if $debug;
	$was_enum_end = 1;
	return '';
};

my $union_start_sub = sub
{
	my $name = shift;
	print STDERR "Union start: '$name'\n" if $debug;
	$was_union_start = 1;
	return $name;
};

my $union_entry_sub = sub
{
	my $name = shift;
	my $size = shift;
	print STDERR "Union entry: '$name' of size $size\n" if $debug;
	$was_union_entry = 1;
	return $name;
};

my $union_end_sub = sub
{
	my $name = shift;
	print STDERR "Union end: '$name'\n" if $debug;
	$was_union_end = 1;
	return $name;
};

my $output_sub = sub {};

my $ret_undef = sub { return undef; };

#################################################

sub reset_vars
{
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

	%params = ();

	seek ($infile, 0, SEEK_SET);
}

#################################################

sub should_have_var($$)
{
	my $params = shift;
	my $name = shift;
	return defined ($params->{'infile'}) && defined ($params->{$name})? 1 : 0;
}

sub validate_vars(\%)
{
	my $params = shift;

	is ( $was_comment, should_have_var ($params, 'comment_sub'), '$was_comment was not set properly' );
	is ( $was_preproc, should_have_var ($params, 'preproc_sub'), '$was_preproc was not set properly' );
	is ( $was_extern, should_have_var ($params, 'extern_sub'), '$was_extern was not set properly' );
	is ( $was_typedef, should_have_var ($params, 'typedef_sub'), '$was_typedef was not set properly' );
	is ( $was_struct_start, should_have_var ($params, 'struct_start_sub'), '$was_struct_start was not set properly' );
	is ( $was_struct_entry, should_have_var ($params, 'struct_entry_sub'), '$was_struct_entry was not set properly' );
	is ( $was_struct_end, should_have_var ($params, 'struct_end_sub'), '$was_struct_end was not set properly' );
	is ( $was_union_start, should_have_var ($params, 'union_start_sub'), '$was_union_start was not set properly' );
	is ( $was_union_entry, should_have_var ($params, 'union_entry_sub'), '$was_union_entry was not set properly' );
	is ( $was_union_end, should_have_var ($params, 'union_end_sub'), '$was_union_end was not set properly' );
	is ( $was_enum_start, should_have_var ($params, 'enum_start_sub'), '$was_enum_start was not set properly' );
	is ( $was_enum_entry_sub, should_have_var ($params, 'enum_entry_sub'), '$was_enum_entry_sub was not set properly' );
	is ( $was_enum_end, should_have_var ($params, 'enum_end_sub'), '$was_enum_end was not set properly' );
}

#################################################

## ---------------- Normal conditions

reset_vars;

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
validate_vars (%params);

## ---------------- Empty parameters

reset_vars;

parse_file (%params);
validate_vars (%params);
parse_struct (%params);
validate_vars (%params);
parse_union (%params);
validate_vars (%params);

## ---------------- No pointer size

reset_vars;

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
);

parse_file (%params);
validate_vars (%params);

## ---------------- No file

reset_vars;

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
validate_vars (%params);

## ---------------- No output (but should still parse and not crash)

reset_vars;

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
validate_vars (%params);

## ---------------- Comments are undef

reset_vars;

%params = (
	'infile' => $infile,
	'output_sub' => $output_sub,
	'comment_sub' => undef,
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
validate_vars (%params);

## ---------------- Comments return undef

reset_vars;

%params = (
	'infile' => $infile,
	'output_sub' => $output_sub,
	'comment_sub' => $ret_undef,
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
$params{'comment_sub'} = undef; # just for validation
validate_vars (%params);

## ---------------- Preprocessing directives are undef

reset_vars;

%params = (
	'infile' => $infile,
	'output_sub' => $output_sub,
	'comment_sub' => $comment_sub,
	'preproc_sub' => undef,
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
validate_vars (%params);

## ---------------- Preprocessing directives return undef

reset_vars;

%params = (
	'infile' => $infile,
	'output_sub' => $output_sub,
	'comment_sub' => $comment_sub,
	'preproc_sub' => $ret_undef,
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
$params{'preproc_sub'} = undef; # just for validation
validate_vars (%params);

## ---------------- Extern directives are undef

reset_vars;

%params = (
	'infile' => $infile,
	'output_sub' => $output_sub,
	'comment_sub' => $comment_sub,
	'preproc_sub' => $preproc_sub,
	'extern_sub' => undef,
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
validate_vars (%params);

## ---------------- Extern directives return undef

reset_vars;

%params = (
	'infile' => $infile,
	'output_sub' => $output_sub,
	'comment_sub' => $comment_sub,
	'preproc_sub' => $preproc_sub,
	'extern_sub' => $ret_undef,
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
$params{'extern_sub'} = undef; # just for validation
validate_vars (%params);

## ---------------- Typedef directives are undef

reset_vars;

%params = (
	'infile' => $infile,
	'output_sub' => $output_sub,
	'comment_sub' => $comment_sub,
	'preproc_sub' => $preproc_sub,
	'extern_sub' => $extern_sub,
	'typedef_sub' => undef,
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
validate_vars (%params);

## ---------------- Typedef directives return undef

reset_vars;

%params = (
	'infile' => $infile,
	'output_sub' => $output_sub,
	'comment_sub' => $comment_sub,
	'preproc_sub' => $preproc_sub,
	'extern_sub' => $extern_sub,
	'typedef_sub' => $ret_undef,
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
$params{'typedef_sub'} = undef; # just for validation
validate_vars (%params);

## ---------------- Structures with undef subs

reset_vars;

%params = (
	'infile' => $infile,
	'output_sub' => $output_sub,
	'comment_sub' => $comment_sub,
	'preproc_sub' => $preproc_sub,
	'extern_sub' => $extern_sub,
	'typedef_sub' => $typedef_sub,
	'struct_start_sub' => undef,
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
validate_vars (%params);

reset_vars;

%params = (
	'infile' => $infile,
	'output_sub' => $output_sub,
	'comment_sub' => $comment_sub,
	'preproc_sub' => $preproc_sub,
	'extern_sub' => $extern_sub,
	'typedef_sub' => $typedef_sub,
	'struct_start_sub' => $struct_start_sub,
	'struct_entry_sub' => undef,
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
validate_vars (%params);

reset_vars;

%params = (
	'infile' => $infile,
	'output_sub' => $output_sub,
	'comment_sub' => $comment_sub,
	'preproc_sub' => $preproc_sub,
	'extern_sub' => $extern_sub,
	'typedef_sub' => $typedef_sub,
	'struct_start_sub' => $struct_start_sub,
	'struct_entry_sub' => $struct_entry_sub,
	'struct_end_sub' => undef,
	'union_start_sub' => $union_start_sub,
	'union_entry_sub' => $union_entry_sub,
	'union_end_sub' => $union_end_sub,
	'enum_start_sub' => $enum_start_sub,
	'enum_entry_sub' => $enum_entry_sub,
	'enum_end_sub' => $enum_end_sub,
	'pointer_size' => 8,
);

parse_file (%params);
validate_vars (%params);

## ---------------- Structures return undef

reset_vars;

%params = (
	'infile' => $infile,
	'output_sub' => $output_sub,
	'comment_sub' => $comment_sub,
	'preproc_sub' => $preproc_sub,
	'extern_sub' => $extern_sub,
	'typedef_sub' => $typedef_sub,
	'struct_start_sub' => $ret_undef,
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
$params{'struct_start_sub'} = undef; # just for validation
validate_vars (%params);

reset_vars;

%params = (
	'infile' => $infile,
	'output_sub' => $output_sub,
	'comment_sub' => $comment_sub,
	'preproc_sub' => $preproc_sub,
	'extern_sub' => $extern_sub,
	'typedef_sub' => $typedef_sub,
	'struct_start_sub' => $struct_start_sub,
	'struct_entry_sub' => $ret_undef,
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
$params{'struct_entry_sub'} = undef; # just for validation
validate_vars (%params);

reset_vars;

%params = (
	'infile' => $infile,
	'output_sub' => $output_sub,
	'comment_sub' => $comment_sub,
	'preproc_sub' => $preproc_sub,
	'extern_sub' => $extern_sub,
	'typedef_sub' => $typedef_sub,
	'struct_start_sub' => $struct_start_sub,
	'struct_entry_sub' => $struct_entry_sub,
	'struct_end_sub' => $ret_undef,
	'union_start_sub' => $union_start_sub,
	'union_entry_sub' => $union_entry_sub,
	'union_end_sub' => $union_end_sub,
	'enum_start_sub' => $enum_start_sub,
	'enum_entry_sub' => $enum_entry_sub,
	'enum_end_sub' => $enum_end_sub,
	'pointer_size' => 8,
);

parse_file (%params);
$params{'struct_end_sub'} = undef; # just for validation
validate_vars (%params);

## ---------------- Unions with undef subs

reset_vars;

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
	'union_start_sub' => undef,
	'union_entry_sub' => $union_entry_sub,
	'union_end_sub' => $union_end_sub,
	'enum_start_sub' => $enum_start_sub,
	'enum_entry_sub' => $enum_entry_sub,
	'enum_end_sub' => $enum_end_sub,
	'pointer_size' => 8,
);

parse_file (%params);
validate_vars (%params);

reset_vars;

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
	'union_entry_sub' => undef,
	'union_end_sub' => $union_end_sub,
	'enum_start_sub' => $enum_start_sub,
	'enum_entry_sub' => $enum_entry_sub,
	'enum_end_sub' => $enum_end_sub,
	'pointer_size' => 8,
);

parse_file (%params);
validate_vars (%params);

reset_vars;

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
	'union_end_sub' => undef,
	'enum_start_sub' => $enum_start_sub,
	'enum_entry_sub' => $enum_entry_sub,
	'enum_end_sub' => $enum_end_sub,
	'pointer_size' => 8,
);

parse_file (%params);
validate_vars (%params);

## ---------------- Unions return undef

reset_vars;

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
	'union_start_sub' => $ret_undef,
	'union_entry_sub' => $union_entry_sub,
	'union_end_sub' => $union_end_sub,
	'enum_start_sub' => $enum_start_sub,
	'enum_entry_sub' => $enum_entry_sub,
	'enum_end_sub' => $enum_end_sub,
	'pointer_size' => 8,
);

parse_file (%params);
$params{'union_start_sub'} = undef; # just for validation
validate_vars (%params);

reset_vars;

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
	'union_entry_sub' => $ret_undef,
	'union_end_sub' => $union_end_sub,
	'enum_start_sub' => $enum_start_sub,
	'enum_entry_sub' => $enum_entry_sub,
	'enum_end_sub' => $enum_end_sub,
	'pointer_size' => 8,
);

parse_file (%params);
$params{'union_entry_sub'} = undef; # just for validation
validate_vars (%params);

reset_vars;

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
	'union_end_sub' => $ret_undef,
	'enum_start_sub' => $enum_start_sub,
	'enum_entry_sub' => $enum_entry_sub,
	'enum_end_sub' => $enum_end_sub,
	'pointer_size' => 8,
);

parse_file (%params);
$params{'union_end_sub'} = undef; # just for validation
validate_vars (%params);

## ---------------- Enums with undef subs

reset_vars;

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
	'enum_start_sub' => undef,
	'enum_entry_sub' => $enum_entry_sub,
	'enum_end_sub' => $enum_end_sub,
	'pointer_size' => 8,
);

parse_file (%params);
validate_vars (%params);

reset_vars;

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
	'enum_entry_sub' => undef,
	'enum_end_sub' => $enum_end_sub,
	'pointer_size' => 8,
);

parse_file (%params);
validate_vars (%params);

reset_vars;

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
	'enum_end_sub' => undef,
	'pointer_size' => 8,
);

parse_file (%params);
validate_vars (%params);

## ---------------- Enums return undef

reset_vars;

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
	'enum_start_sub' => $ret_undef,
	'enum_entry_sub' => $enum_entry_sub,
	'enum_end_sub' => $enum_end_sub,
	'pointer_size' => 8,
);

parse_file (%params);
$params{'enum_start_sub'} = undef; # just for validation
validate_vars (%params);

reset_vars;

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
	'enum_entry_sub' => $ret_undef,
	'enum_end_sub' => $enum_end_sub,
	'pointer_size' => 8,
);

parse_file (%params);
$params{'enum_entry_sub'} = undef; # just for validation
validate_vars (%params);

reset_vars;

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
	'enum_end_sub' => $ret_undef,
	'pointer_size' => 8,
);

parse_file (%params);
$params{'enum_end_sub'} = undef; # just for validation
validate_vars (%params);

#################################################

close $infile;
