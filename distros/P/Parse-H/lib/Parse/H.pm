# Parse::H - A parser for C header files that calls the given
#  subroutines when a symbol of a specified type is encountered.
#
#	Copyright (C) 2022 Bogdan 'bogdro' Drozdowski,
#	  bogdro (at) users . sourceforge . net
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#

package Parse::H;

use warnings;

require Exporter;
@ISA = (Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(parse_struct parse_union parse_file);

use strict;

=head1 NAME

Parse::H - A parser for C header files that calls the given subroutines when a symbol of a specified type is encountered.

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.11';

=head1 DESCRIPTION

This module provides subroutines for parsing C language header files
(*.h files) while calling user-provided callback subroutines on various
found elements.

=head1 SYNOPSIS

    use Parse::H qw(parse_file);

    open (my $infile, '<', 'test.h') or die "Cannot open test.h: $!\n";

    my $extern_sub = sub { ... }
    my $comment_sub = sub { ... }
    my $preproc_sub = sub { ... }
    my $typedef_sub = sub { ... }
    my $struct_start_sub = sub { ... }
    my $struct_entry_sub = sub { ... }
    my $struct_end_sub = sub { ... }
    my $enum_start_sub = sub { ... }
    my $enum_entry_sub = sub { ... }
    my $enum_end_sub = sub { ... }
    my $union_start_sub = sub { ... }
    my $union_entry_sub = sub { ... }
    my $union_end_sub = sub { ... }
    my $output_sub = sub { ... }

    my %params = (
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

    parse_file (\%params);

    close $infile;

=head1 EXPORT

 Nothing is exported by default.

 The following functions are exported on request:
	parse_struct
	parse_union
	parse_file

 These parse a C "struct" type, a C "union" type or a whole C header
 file, respectively.

=head1 DATA

=cut

# =head2 _max
#
#  PRIVATE SUBROUTINE.
#  Returns the greater of 2 numbers.
#
# =cut
sub _max
{
	my $a = shift, $b = shift;
	return $a if $a > $b;
	return $b;
}

# =head2 _get_param
#
#  PRIVATE SUBROUTINE.
#  Returns the value specified by name (parameter 2) from the
#	hashref specified in parameter 1, or undef.
#
# =cut
sub _get_param
{
	my $hash = shift;
	my $name = shift;
	return defined($hash->{$name})? $hash->{$name} : undef;
}

sub parse_union(\%);
sub parse_struct(\%);

=head2 parse_struct

 Parses a C "structure" type, calling the provided subroutines when
  a symbol of a specified type is encountered.
 Parameters: a hash containing the input file handle and references to
  the subroutines. All subroutines should return a line of text (which
  may later go to $output_sub) after their processing of the given parameter.
 If a key is not present in the hash, its functionality is not used
  (unless a default value is specified).
 Hash keys:

        'infile' => input file handle (required),
        'line' => the current line to process (default: empty line),
        'output_sub' => a subroutine that processes the output.
        	Takes the line to output as its single parameter,
        'comment_sub' => a subroutine that processes comments.
        	Takes the current line as its single parameter,
        'preproc_sub' => a subroutine that processes preprocessor lines.
        	Takes the current line as its single parameter,
        'struct_start_sub' => a subroutine that processes the beginning of a structure.
        	Takes the structure name as its single parameter,
        'struct_entry_sub' => a subroutine that processes an entry of a structure.
        	Takes the symbol name as its first parameter, its size as the second and the structure name as the third,
        'struct_end_sub' => a subroutine that processes the end of a structure.
        	Takes the structure name as its first parameter and its size as the second,
        'union_start_sub' => a subroutine that processes the beginning of a union.
        	Takes the union name as its single parameter,
        'union_entry_sub' => a subroutine that processes an entry of a union.
        	Takes the symbol name as its first parameter and its size as the second,
        'union_end_sub' => a subroutine that processes the end of a union.
        	Takes the symbol name as its first parameter, its size as the second and the union name as the third,
        'pointer_size' => the pointer size to use, in bytes (default: 8),

=cut

sub parse_struct(\%)
{
	my $params = shift;

	my $infile = _get_param($params, 'infile'); # input file handle
	my $output_sub = _get_param($params, 'output_sub'); # output subroutine
	$_ = _get_param($params, 'line');
	$_ = '' unless defined($_);
	my $struct_start_sub = _get_param($params, 'struct_start_sub'); # subroutine that converts structures
	my $struct_entry_sub = _get_param($params, 'struct_entry_sub'); # subroutine that converts structures
	my $struct_end_sub = _get_param($params, 'struct_end_sub'); # subroutine that converts structures
	my $union_start_sub = _get_param($params, 'union_start_sub'); # subroutine that converts unions
	my $union_entry_sub = _get_param($params, 'union_entry_sub'); # subroutine that converts unions
	my $union_end_sub = _get_param($params, 'union_end_sub'); # subroutine that converts unions
	my $comment_sub = _get_param($params, 'comment_sub'); # subroutine that converts comments
	my $preproc_sub = _get_param($params, 'preproc_sub'); # subroutine that converts proceprocessor directives
	my $pointer_size = _get_param($params, 'pointer_size'); # pointer size in bytes
	$pointer_size = 8 unless defined($pointer_size);

	return unless $infile;

	my %sub_params = (
		'infile' => $infile,
		'output_sub' => $output_sub,
		'comment_sub' => $comment_sub,
		'preproc_sub' => $preproc_sub,
		'extern_sub' => undef,
		'typedef_sub' => undef,
		'struct_start_sub' => undef,
		'struct_entry_sub' => undef,
		'struct_end_sub' => undef,
		'union_start_sub' => undef,
		'union_entry_sub' => undef,
		'union_end_sub' => undef,
		'enum_start_sub' => undef,
		'enum_entry_sub' => undef,
		'enum_end_sub' => undef,
		'pointer_size' => $pointer_size,
	);

	# skip over "struct foo;"
	if ( /^\s*struct\s+[\w\s\$\*]+(\[[^\]]*\])?;/o && ! /{/o )
	{
		# changing the comments
		if ( $comment_sub )
		{
			$_ = &$comment_sub($_);
			&$output_sub($_) if $output_sub and $_;
		}
		return (0, '');
	}

	# the name of the structure
	my $str_name = '';
	if ( /^\s*struct\s+(\w+)/o )
	{
		if ( $1 and $1 ne '' and $1 !~ /\{/o )
		{
			$str_name = $1;
		}
		s/^\s*struct\s+\w+//o;
	}
	my $size = 0;
	my ($memb_size, $name);
	my $line;
	$line = &$struct_start_sub($str_name) if $struct_start_sub;
	&$output_sub($line) if $output_sub and $line;

	# a structure can end in the same line or contain many declaration per line
	#   we simply put a newline after each semicolon and go on

	s/;/;\n/go;
	# changing the comments
	if ( $comment_sub )
	{
		$_ = &$comment_sub($_);
	}

	do
	{
		s/{//go;
		# joining lines
		while ( /[\\,]$/o )
		{
			s/\\\n//o;
			$_ .= <$infile>;
		}

		# many variables of the same type - we put each on a separate line together with its type
		if ( m#/\*#o )
		{
			while ( /,\s*$/o )
			{
				s/\n//o;
				$_ .= <$infile>;
			}
			while ( m#,.*/\*#o && !/\(/o )
			{
				if ( m#\[.*/\*#o )
				{
					s/([\w ]*)\s+(\w+)\s*(\[\w+\]),\s*(.*)/$1 $2$3;\n$1 $4/;
				}
				else
				{
					s/([\w ]*)\s+([\w\*]+)\s*,\s*(.*)/$1 $2;\n$1 $3/;
				}
			}
		}
		else
		{
			while ( /,\s*$/o )
			{
				s/\n//o;
				$_ .= <$infile>;
			}
			while ( /,.*/o && !/\(/o )
			{
				if ( /\[/o )
				{
					s/([\w ]*)\s+(\w+)\s*(\[\w+\]),\s*(.*)/$1 $2$3;\n$1 $4/;
				}
				else
				{
					s/([\w ]*)\s+([\w\*]+)\s*,\s*(.*)/$1 $2;\n$1 $3/;
				}
			}
		}

		# changing the comments
		if ( $comment_sub )
		{
			$_ = &$comment_sub($_);
		}

		while ( /^\s*union\s+(\w+)/o )
		{
			$sub_params{'line'} = $_;
			($memb_size, $name) = parse_union(%sub_params);
			$line = &$struct_entry_sub($name, $memb_size) if $struct_entry_sub;
			&$output_sub($line) if $output_sub and $line;
			$_ = '';
			$size += $memb_size;
			goto STR_END;
		}

		while ( /^\s*union/o )
		{
			$sub_params{'line'} = $_;
			my ($memb_size, $name) = parse_union(%sub_params);
			$line = &$struct_entry_sub($name, $memb_size) if $struct_entry_sub;
			&$output_sub($line) if $output_sub and $line;
			$_ = '';
			$size += $memb_size;
			goto STR_END;
		}

		# first we remove the ":digit" from the structure fields
		s/(.*):\s*\d+\s*/$1/g;

		# skip over 'volatile'
		s/_*volatile_*//gio;

		# pointers to functions
		while ( /.+\(\s*\*\s*(\w+)\s*\)\s*\(.*\)\s*;/o )
		{
			$line = &$struct_entry_sub($1, $pointer_size) if $struct_entry_sub;
			&$output_sub($line) if $output_sub and $line;
			# remove the parsed element
			s/^[^;]*;//o;
			$size += $pointer_size;
		}
		# pointer type
		while ( /.+\*\s*(\w+)\s*;/o )
		{
			$line = &$struct_entry_sub($1, $pointer_size) if $struct_entry_sub;
			&$output_sub($line) if $output_sub and $line;
			# remove the parsed element
			s/^[^;]*;//o;
			$size += $pointer_size;
		}

		# arrays
		while ( /.*struct\s+(\w+)\s+(\w+)\s*\[(\w+)\]\s*;/o )
		{
			$line = &$struct_entry_sub($2, 0) if $struct_entry_sub;
			&$output_sub($line) if $output_sub and $line;
			# remove the parsed element
			s/.*struct\s+(\w+)\s+(\w+)\s*\[(\w+)\]\s*;//o;
		}
		while ( /.*(signed|unsigned)?\s+long\s+long(\s+int)?\s+(\w+)\s*\[(\w+)\]\s*;/o )
		{
			my $var_name = $3;
			my $count = $4;
			if ( $count =~ /^0/o )
			{
				$count = oct("$count");
			}
			$line = &$struct_entry_sub($var_name, 8 * $count) if $struct_entry_sub;
			&$output_sub($line) if $output_sub and $line;
			# remove the parsed element
			s/^[^;]*;//o;
			$size += 8 * $count;
		}
		while ( /.*long\s+double\s+(\w+)\s*\[(\w+)\]\s*;/o )
		{
			my $var_name = $1;
			my $count = $2;
			if ( $count =~ /^0/o )
			{
				$count = oct("$count");
			}
			$line = &$struct_entry_sub($var_name, 10 * $count) if $struct_entry_sub;
			&$output_sub($line) if $output_sub and $line;
			# remove the parsed element
			s/^[^;]*;//o;
			$size += 10 * $count;
		}
		while ( /.*(char|unsigned\s+char|signed\s+char)\s+(\w+)\s*\[(\w+)\]\s*;/o )
		{
			my $var_name = $2;
			my $count = $3;
			if ( $count =~ /^0/o )
			{
				$count = oct("$count");
			}
			$line = &$struct_entry_sub($var_name, 1 * $count) if $struct_entry_sub;
			&$output_sub($line) if $output_sub and $line;
			# remove the parsed element
			s/^[^;]*;//o;
			$size += 1 * $count;
		}
		while ( /.*float\s+(\w+)\s*\[(\w+)\]\s*;/o )
		{
			my $var_name = $1;
			my $count = $2;
			if ( $count =~ /^0/o )
			{
				$count = oct("$count");
			}
			$line = &$struct_entry_sub($var_name, 4 * $count) if $struct_entry_sub;
			&$output_sub($line) if $output_sub and $line;
			# remove the parsed element
			s/^[^;]*;//o;
			$size += 4 * $count;
		}
		while ( /.*double\s+(\w+)\s*\[(\w+)\]\s*;/o )
		{
			my $var_name = $1;
			my $count = $2;
			if ( $count =~ /^0/o )
			{
				$count = oct("$count");
			}
			$line = &$struct_entry_sub($var_name, 8 * $count) if $struct_entry_sub;
			&$output_sub($line) if $output_sub and $line;
			# remove the parsed element
			s/^[^;]*;//o;
			$size += 8 * $count;
		}
		while ( /.*(short|signed\s+short|unsigned\s+short){1}(\s+int)?\s+(\w+)\s*\[(\w+)\]\s*;/o )
		{
			my $var_name = $3;
			my $count = $4;
			if ( $count =~ /^0/o )
			{
				$count = oct("$count");
			}
			$line = &$struct_entry_sub($var_name, 2 * $count) if $struct_entry_sub;
			&$output_sub($line) if $output_sub and $line;
			# remove the parsed element
			s/^[^;]*;//o;
			$size += 2 * $count;
		}
		while ( /.*(long|signed|signed\s+long|unsigned|unsigned\s+long|int){1}(\s+int)?\s+(\w+)\s*\[(\w+)\]\s*;/o )
		{
			my $var_name = $3;
			my $count = $4;
			if ( $count =~ /^0/o )
			{
				$count = oct("$count");
			}
			# NOTE: assuming 'long int' is the same size as a pointer (should be on 32- and 64-bit systems)
			$line = &$struct_entry_sub($var_name, $pointer_size * $count) if $struct_entry_sub;
			&$output_sub($line) if $output_sub and $line;
			# remove the parsed element
			s/^[^;]*;//o;
			$size += $pointer_size * $count;
		}

		# variables' types
		while ( /.*struct\s+(\w+)\s+(\w+)\s*;/o )
		{
			$line = &$struct_entry_sub($2, 0) if $struct_entry_sub;
			&$output_sub($line) if $output_sub and $line;
			# remove the parsed element
			s/.*struct\s+\w+\s+\w+\s*;//o;
		}
		while ( /^\s*struct/o )
		{
			$sub_params{'line'} = $_;
			my ($memb_size, $name) = parse_struct(%sub_params);
			$line = &$struct_entry_sub($name, $memb_size) if $struct_entry_sub;
			&$output_sub($line) if $output_sub and $line;
			$_ = '';
			$size += $memb_size;
			goto STR_END;
		}

		# all "\w+" stand for the variable name
		while ( /.*(signed|unsigned)?\s+long\s+long(\s+int)?\s+(\w+)\s*;/o )
		{
			$line = &$struct_entry_sub($3, 8) if $struct_entry_sub;
			&$output_sub($line) if $output_sub and $line;
			# remove the parsed element
			s/^[^;]*;//o;
			$size += 8;
		}
		while ( /.*long\s+double\s+(\w+)\s*;/o )
		{
			$line = &$struct_entry_sub($1, 10) if $struct_entry_sub;
			&$output_sub($line) if $output_sub and $line;
			# remove the parsed element
			s/^[^;]*;//o;
			$size += 10;
		}
		while ( /.*(char|unsigned\s+char|signed\s+char)\s+(\w+)\s*;/o )
		{
			$line = &$struct_entry_sub($2, 1) if $struct_entry_sub;
			&$output_sub($line) if $output_sub and $line;
			# remove the parsed element
			s/^[^;]*;//o;
			$size += 1;
		}
		while ( /.*float\s+(\w+)\s*;/o )
		{
			$line = &$struct_entry_sub($1, 4) if $struct_entry_sub;
			&$output_sub($line) if $output_sub and $line;
			# remove the parsed element
			s/^[^;]*;//o;
			$size += 4;
		}
		while ( /.*double\s+(\w+)\s*;/o )
		{
			$line = &$struct_entry_sub($1, 8) if $struct_entry_sub;
			&$output_sub($line) if $output_sub and $line;
			# remove the parsed element
			s/^[^;]*;//o;
			$size += 8;
		}
		while ( /.*(short|signed\s+short|unsigned\s+short){1}(\s+int)?\s+(\w+)\s*;/o )
		{
			$line = &$struct_entry_sub($3, 2) if $struct_entry_sub;
			&$output_sub($line) if $output_sub and $line;
			# remove the parsed element
			s/^[^;]*;//o;
			$size += 2;
		}
		while ( /.*(long|signed|signed\s+long|unsigned|unsigned\s+long|int){1}(\s+int)?\s+(\w+)\s*;/o )
		{
			# NOTE: assuming 'long int' is the same size as a pointer (should be on 32- and 64-bit systems)
			$line = &$struct_entry_sub($3, $pointer_size) if $struct_entry_sub;
			&$output_sub($line) if $output_sub and $line;
			# remove the parsed element
			s/^[^;]*;//o;
			$size += $pointer_size;
		}

		# look for the end of the structure
		if ( /}/o )
		{
			# add a structure size definition
			my $var_name = '';
			if ( /\}\s*(\*?)\s*(\w+)[^;]*;/o )
			{
				$var_name = $2;
			}
			if ( /\}\s*\*/o )
			{
				$size = $pointer_size;
			}
			$line = &$struct_end_sub($var_name, $size, $str_name) if $struct_end_sub;
			&$output_sub($line) if $output_sub and $line;
			$_ = '';
			return ($size, $var_name);
		}

		# processing of conditional compiling directives
		if ( $preproc_sub )
		{
			$_ = &$preproc_sub($_);
		}
		&$output_sub($_) if $output_sub and $_;

	STR_END: } while ( <$infile> );
}

=head2 parse_union

 Parses a C "union" type, calling the provided subroutines when
  a symbol of a specified type is encountered.
 Parameters: a hash containing the input file handle and references to
  the subroutines. All subroutines should return a line of text (which
  may later go to $output_sub) after their processing of the given parameter.
 If a key is not present in the hash, its functionality is not used
  (unless a default value is specified).
 Hash keys:

        'infile' => input file handle (required),
        'line' => the current line to process (default: empty line),
        'output_sub' => a subroutine that processes the output.
        	Takes the line to output as its single parameter,
        'comment_sub' => a subroutine that processes comments.
        	Takes the current line as its single parameter,
        'preproc_sub' => a subroutine that processes preprocessor lines.
        	Takes the current line as its single parameter,
        'struct_start_sub' => a subroutine that processes the beginning of a structure.
        	Takes the structure name as its single parameter,
        'struct_entry_sub' => a subroutine that processes an entry of a structure.
        	Takes the symbol name as its first parameter, its size as the second and the structure name as the third,
        'struct_end_sub' => a subroutine that processes the end of a structure.
        	Takes the structure name as its first parameter and its size as the second,
        'union_start_sub' => a subroutine that processes the beginning of a union.
        	Takes the union name as its single parameter,
        'union_entry_sub' => a subroutine that processes an entry of a union.
        	Takes the symbol name as its first parameter and its size as the second,
        'union_end_sub' => a subroutine that processes the end of a union.
        	Takes the symbol name as its first parameter, its size as the second and the union name as the third,
        'pointer_size' => the pointer size to use, in bytes (default: 8),


=cut

sub parse_union(\%)
{
	my $params = shift;

	my $infile = _get_param($params, 'infile'); # input file handle
	my $output_sub = _get_param($params, 'output_sub'); # output subroutine
	$_ = _get_param($params, 'line');
	$_ = '' unless defined($_);
	my $struct_start_sub = _get_param($params, 'struct_start_sub'); # subroutine that converts structures
	my $struct_entry_sub = _get_param($params, 'struct_entry_sub'); # subroutine that converts structures
	my $struct_end_sub = _get_param($params, 'struct_end_sub'); # subroutine that converts structures
	my $union_start_sub = _get_param($params, 'union_start_sub'); # subroutine that converts unions
	my $union_entry_sub = _get_param($params, 'union_entry_sub'); # subroutine that converts unions
	my $union_end_sub = _get_param($params, 'union_end_sub'); # subroutine that converts unions
	my $comment_sub = _get_param($params, 'comment_sub'); # subroutine that converts comments
	my $preproc_sub = _get_param($params, 'preproc_sub'); # subroutine that converts proceprocessor directives
	my $pointer_size = _get_param($params, 'pointer_size'); # pointer size in bytes
	$pointer_size = 8 unless defined($pointer_size);

	return unless $infile;

	my %sub_params = (
		'infile' => $infile,
		'output_sub' => $output_sub,
		'comment_sub' => $comment_sub,
		'preproc_sub' => $preproc_sub,
		'extern_sub' => undef,
		'typedef_sub' => undef,
		'struct_start_sub' => undef,
		'struct_entry_sub' => undef,
		'struct_end_sub' => undef,
		'union_start_sub' => undef,
		'union_entry_sub' => undef,
		'union_end_sub' => undef,
		'enum_start_sub' => undef,
		'enum_entry_sub' => undef,
		'enum_end_sub' => undef,
		'pointer_size' => $pointer_size,
	);

	# skip over "union foo;"
	if ( /^\s*union\s+[^;{}]*;/o )
	{
		# changing the comments
		if ( $comment_sub )
		{
			$_ = &$comment_sub($_);
			&$output_sub($_) if $output_sub and $_;
		}
		return (0, '');
	}

	# the name of the union
	my $union_name = '';

	if ( /^\s*union\s+(\w+)/o )
	{
		if ( $1 and $1 ne '' and $1 !~ /\{/o )
		{
			$union_name = $1;
		}
		s/^\s*union\s+\w+//o;
	}
	my $size = 0;
	my ($memb_size, $name);
	my $line;
	$line = &$union_start_sub($union_name) if $union_start_sub;
	&$output_sub($line) if $output_sub and $line;

	# if there was a '{' in the first line, we put it in the second
	if ( !/union/o )
	{
		s/\s*\{/\n\{\n/o;
	}
	else
	{
		s/\s*union\s*{//o;
		s/\s*union//o;
	}

	# an union can end in the same line or contain many declaration per line
	#   we simply put a newline after each semicolon and go on

	s/;/;\n/go;

	do
	{
		s/{//go;
		# changing the comments
		if ( $comment_sub )
		{
			$_ = &$comment_sub($_);
		}

		# pointer type
		while ( /.+\*\s*(\w+)\s*;/o )
		{
			$line = &$union_entry_sub($1, $pointer_size) if $union_entry_sub;
			&$output_sub($line) if $output_sub and $line;
			# remove the parsed element
			s/^[^;]*;//o;
			$size = _max($size, $pointer_size);
		}

		while ( /.*struct\s+(\w+)\s+(\w+)\s*;/o )
		{
			$line = &$union_entry_sub($2, 0) if $union_entry_sub;
			&$output_sub($line) if $output_sub and $line;
			# remove the parsed element
			s/.*struct\s+\w+\s+\w+\s*;//o;
		}

		while ( /^\s*struct/o )
		{
			$sub_params{'line'} = $_;
			my ($memb_size, $name) = parse_struct(%sub_params);
			$line = &$union_entry_sub($name, $memb_size) if $union_entry_sub;
			&$output_sub($line) if $output_sub and $line;
			$size = _max($size, $memb_size);
			$_ = '';
			goto STR_END;
		}

		# variables' types
		# all "\w+" stand for the variable name
		while ( /.*(signed|unsigned)?\s+long\s+long(\s+int)?\s+(\w+)\s*;/o )
		{
			$line = &$union_entry_sub($3, 8) if $union_entry_sub;
			&$output_sub($line) if $output_sub and $line;
			# remove the parsed element
			s/^[^;]*;//o;
			$size = _max($size, 8);
		}

		while ( /.*long\s+double\s+(\w+)\s*;/o )
		{
			$line = &$union_entry_sub($1, 10) if $union_entry_sub;
			&$output_sub($line) if $output_sub and $line;
			# remove the parsed element
			s/^[^;]*;//o;
			$size = _max($size, 10);
		}

		while ( /.*(char|unsigned\s+char|signed\s+char)\s+(\w+)\s*;/o )
		{
			$line = &$union_entry_sub($2, 1) if $union_entry_sub;
			&$output_sub($line) if $output_sub and $line;
			# remove the parsed element
			s/^[^;]*;//o;
			$size = _max($size, 1);
		}

		while ( /.*float\s+(\w+)\s*;/o )
		{
			$line = &$union_entry_sub($1, 4) if $union_entry_sub;
			&$output_sub($line) if $output_sub and $line;
			# remove the parsed element
			s/^[^;]*;//o;
			$size = _max($size, 4);
		}

		while ( /.*double\s+(\w+)\s*;/o )
		{
			$line = &$union_entry_sub($1, 8) if $union_entry_sub;
			&$output_sub($line) if $output_sub and $line;
			# remove the parsed element
			s/^[^;]*;//o;
			$size = _max($size, 8);
		}

		while ( /.*(short|signed\s+short|unsigned\s+short){1}(\s+int)?\s+(\w+)\s*;/o )
		{
			$line = &$union_entry_sub($3, 2) if $union_entry_sub;
			&$output_sub($line) if $output_sub and $line;
			# remove the parsed element
			s/^[^;]*;//o;
			$size = _max($size, 2);
		}

		while ( /.*(long|signed|signed\s+long|unsigned|unsigned\s+long|int){1}(\s+int)?\s+(\w+)\s*;/o )
		{
			# NOTE: assuming 'long int' is the same size as a pointer (should be on 32- and 64-bit systems)
			$line = &$union_entry_sub($3, $pointer_size) if $union_entry_sub;
			&$output_sub($line) if $output_sub and $line;
			# remove the parsed element
			s/^[^;]*;//o;
			$size = _max($size, $pointer_size);
		}

		# arrays

		while ( /.*struct\s+(\w+)\s+(\w+)\s*\[(\w+)\]\s*;/o )
		{
			$line = &$union_entry_sub($2, 0) if $union_entry_sub;
			&$output_sub($line) if $output_sub and $line;
			# remove the parsed element
			s/.*struct\s+(\w+)\s+(\w+)\s*\[(\w+)\]\s*;//o;
		}

		while ( /.*(signed|unsigned)?\s+long\s+long(\s+int)?\s+(\w+)\s*\[(\d+)\]\s*;/o )
		{
			my $var_name = $3;
			my $count = $4;
			if ( $count =~ /^0/o )
			{
				$count = oct("$count");
			}
			$line = &$union_entry_sub($var_name, 8 * $count) if $union_entry_sub;
			&$output_sub($line) if $output_sub and $line;
			# remove the parsed element
			s/^[^;]*;//o;
			$size = _max($size, 8 * $count);
		}

		while ( /.*long\s+double\s+(\w+)\s*\[(\d+)\]\s*;/o )
		{
			my $var_name = $1;
			my $count = $2;
			if ( $count =~ /^0/o )
			{
				$count = oct("$count");
			}
			$line = &$union_entry_sub($var_name, 10 * $count) if $union_entry_sub;
			&$output_sub($line) if $output_sub and $line;
			# remove the parsed element
			s/^[^;]*;//o;
			$size = _max($size, 10 * $count);
		}

		while ( /.*(char|unsigned\s+char|signed\s+char)\s+(\w+)\s*\[(\d+)\]\s*;/o )
		{
			my $var_name = $2;
			my $count = $3;
			if ( $count =~ /^0/o )
			{
				$count = oct("$count");
			}
			$line = &$union_entry_sub($var_name, 1 * $count) if $union_entry_sub;
			&$output_sub($line) if $output_sub and $line;
			# remove the parsed element
			s/^[^;]*;//o;
			$size = _max($size, 1 * $count);
		}

		while ( /.*float\s+(\w+)\s*\[(\d+)\]\s*;/o )
		{
			my $var_name = $1;
			my $count = $2;
			if ( $count =~ /^0/o )
			{
				$count = oct("$count");
			}
			$line = &$union_entry_sub($var_name, 4 * $count) if $union_entry_sub;
			&$output_sub($line) if $output_sub and $line;
			# remove the parsed element
			s/^[^;]*;//o;
			$size = _max($size, 4 * $count);
		}

		while ( /.*double\s+(\w+)\s*\[(\d+)\]\s*;/o )
		{
			my $var_name = $1;
			my $count = $2;
			if ( $count =~ /^0/o )
			{
				$count = oct("$count");
			}
			$line = &$union_entry_sub($var_name, 8 * $count) if $union_entry_sub;
			&$output_sub($line) if $output_sub and $line;
			# remove the parsed element
			s/^[^;]*;//o;
			$size = _max($size, 8 * $count);
		}

		while ( /.*(short|signed\s+short|unsigned\s+short){1}(\s+int)?\s+(\w+)\s*\[(\d+)\]\s*;/o )
		{
			my $var_name = $3;
			my $count = $4;
			if ( $count =~ /^0/o )
			{
				$count = oct("$count");
			}
			$line = &$union_entry_sub($var_name, 2 * $count) if $union_entry_sub;
			&$output_sub($line) if $output_sub and $line;
			# remove the parsed element
			s/^[^;]*;//o;
			$size = _max($size, 2 * $count);
		}

		while ( /.*(long|signed|signed\s+long|unsigned|unsigned\s+long|int){1}(\s+int)?\s+(\w+)\s*\[(\d+)\]\s*;/o )
		{
			my $var_name = $3;
			my $count = $4;
			if ( $count =~ /^0/o )
			{
				$count = oct("$count");
			}
			# NOTE: assuming 'long int' is the same size as a pointer (should be on 32- and 64-bit systems)
			$line = &$union_entry_sub($var_name, $pointer_size * $count) if $union_entry_sub;
			&$output_sub($line) if $output_sub and $line;
			# remove the parsed element
			s/^[^;]*;//o;
			$size = _max($size, $pointer_size * $count);
		}

		while ( /^\s*union/o )
		{
			$sub_params{'line'} = $_;
			my ($memb_size, $name) = parse_union(%sub_params);
			$line = &$struct_entry_sub($name, $memb_size) if $struct_entry_sub;
			&$output_sub($line) if $output_sub and $line;
			$_ = '';
			$size = _max($size, $memb_size);
		}

		# look for the end of the union
		if ( /\s*\}.*/o )
		{
			my $var_name = '';
			if ( /\s*\}\s*(\w+)[^;]*;/o )
			{
				$var_name = $1;
			}
			$line = &$union_end_sub($var_name, $size, $union_name) if $union_end_sub;
			&$output_sub($line) if $output_sub and $line;
			$_ = '';
			return ($size, $var_name);
		}

		# processing of conditional compiling directives
		if ( $preproc_sub )
		{
			$_ = &$preproc_sub($_);
		}
		&$output_sub($_) if $output_sub and $_;

	STR_END: } while ( <$infile> );
}

=head2 parse_file

 Parses a C header file, calling the provided subroutines when
  a symbol of a specified type is encountered.
 Parameters: a hash containing the input file handle and references to
  the subroutines. All subroutines should return a line of text (which
  may later go to $output_sub) after their processing of the given parameter.
 If a key is not present in the hash, its functionality is not used
  (unless a default value is specified).
 Hash keys:

        'infile' => input file handle (required),
        'output_sub' => a subroutine that processes the output.
        	Takes the line to output as its single parameter,
        'comment_sub' => a subroutine that processes comments.
        	Takes the current line as its single parameter,
        'preproc_sub' => a subroutine that processes preprocessor lines.
        	Takes the current line as its single parameter,
        'extern_sub' => a subroutine that processes external symbol declarations.
        	Takes the symbol name as its single parameter,
        'typedef_sub' => a subroutine that processes typedefs.
        	Takes the old type's name as its first parameter and the new type's name as the second,
        'struct_start_sub' => a subroutine that processes the beginning of a structure.
        	Takes the structure name as its single parameter,
        'struct_entry_sub' => a subroutine that processes an entry of a structure.
        	Takes the symbol name as its first parameter, its size as the second and the structure name as the third,
        'struct_end_sub' => a subroutine that processes the end of a structure.
        	Takes the structure name as its first parameter and its size as the second,
        'union_start_sub' => a subroutine that processes the beginning of a union.
        	Takes the union name as its single parameter,
        'union_entry_sub' => a subroutine that processes an entry of a union.
        	Takes the symbol name as its first parameter and its size as the second,
        'union_end_sub' => a subroutine that processes the end of a union.
        	Takes the symbol name as its first parameter, its size as the second and the union name as the third,
        'enum_start_sub' => a subroutine that processes the beginning of an enumeration.
        	Takes the enum's name as its single parameter,
        'enum_entry_sub' => a subroutine that processes an entry of an enumeration.
        	Takes the symbol name as its first parameter and its value as the second,
        'enum_end_sub' => a subroutine that processes the end of an enumeration.
        	Takes no parameters,
        'pointer_size' => the pointer size to use, in bytes (default: 8),

=cut

sub parse_file(\%)
{
	my $params = shift;

	my $infile = _get_param($params, 'infile'); # input file handle
	my $output_sub = _get_param($params, 'output_sub'); # output subroutine
	my $extern_sub = _get_param($params, 'extern_sub'); # subroutine that converts external declarations
	my $typedef_sub = _get_param($params, 'typedef_sub'); # subroutine that converts typedefs
	my $comment_sub = _get_param($params, 'comment_sub'); # subroutine that converts comments
	my $preproc_sub = _get_param($params, 'preproc_sub'); # subroutine that converts proceprocessor directives
	my $pointer_size = _get_param($params, 'pointer_size'); # pointer size in bytes
	$pointer_size = 8 unless defined($pointer_size);
	my $struct_start_sub = _get_param($params, 'struct_start_sub'); # subroutine that converts structures
	my $struct_entry_sub = _get_param($params, 'struct_entry_sub'); # subroutine that converts structures
	my $struct_end_sub = _get_param($params, 'struct_end_sub'); # subroutine that converts structures
	my $union_start_sub = _get_param($params, 'union_start_sub'); # subroutine that converts unions
	my $union_entry_sub = _get_param($params, 'union_entry_sub'); # subroutine that converts unions
	my $union_end_sub = _get_param($params, 'union_end_sub'); # subroutine that converts unions
	my $enum_start_sub = _get_param($params, 'enum_start_sub'); # subroutine that converts enumerations
	my $enum_entry_sub = _get_param($params, 'enum_entry_sub'); # subroutine that converts enumerations
	my $enum_end_sub = _get_param($params, 'enum_end_sub'); # subroutine that converts enumerations

	return unless $infile;

	my %sub_params = (
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
		'pointer_size' => $pointer_size,
	);

	my $line;
	READ: while ( <$infile> )
	{
		# empty lines go without change
		if ( /^\s*$/o )
		{
			&$output_sub("\n") if $output_sub;
			next;
		}

		# joining lines
		while ( /[\\,]$/o )
		{
			s/\\\n//o;
			s/,\n/,/o;
			$_ .= <$infile>;
		}

		# check if a comment is the only thing on this line
		if ( m#^\s*/\*.*\*/\s*$#o || m#^\s*//#o )
		{
			if ( $comment_sub )
			{
				$_ = &$comment_sub($_);
			}
			else
			{
				$_ = '';
			}
			&$output_sub($_) if $output_sub and $_;

			next;
		}

		# processing of preprocessor directives
		if ( /^\s*#/o )
		{
			if ( $comment_sub )
			{
				$_ = &$comment_sub($_);
			}
			if ( $preproc_sub )
			{
				$_ = &$preproc_sub($_);
			}
			else
			{
				$_ = '';
			}
			&$output_sub($_) if $output_sub and $_;

			next;
		}

		# externs
		if ( /^\s*extern/o )
		{
			if ( $comment_sub )
			{
				$_ = &$comment_sub($_);
			}

			# joining lines
			while ( ! /;/o )
			{
				s/\n//o;
				$_ .= <$infile>;
			}

			# external functions

			# extern "C", extern "C++"
			s/^\s*extern\s+"C"\s*{//o;
			s/^\s*extern\s+"C"/extern/o;
			s/^\s*extern\s+"C\+\+"\s*{//o;
			s/^\s*extern\s+"C\+\+"/extern/o;

			# first remove: extern MACRO_NAME ( fcn name, args, ... )
			s/^\s*\w*\s*extern\s+\w+\s*\([^*].*//o;
			# 	type	     ^^^

			# extern pointers to functions:
			if ( /^\s*\w*\s*extern\s+[\w\*\s]+\(\s*\*\s*(\w+)[()\*\s\w]*\)\s*\(.*/o )
			{
				if ( $extern_sub )
				{
					$_ = &$extern_sub($1);
				}
				else
				{
					$_ = '';
				}
			}

			if ( /^\s*\w*\s*extern\s+[\w\*\s]+?(\w+)\s*\(.*/o )
			{
				if ( $extern_sub )
				{
					$_ = &$extern_sub($1);
				}
				else
				{
					$_ = '';
				}
			}

			# external variables
			if ( /^\s*extern[\w\*\s]+\s+\**(\w+)\s*;/o )
			{
				if ( $extern_sub )
				{
					$_ = &$extern_sub($1);
				}
				else
				{
					$_ = '';
				}
			}
			&$output_sub($_) if $output_sub and $_;

			next;
		}

		# typedef
		if ( /^\s*typedef/o )
		{
			if ( /\(/o )
			{
				while ( ! /\)/o or /,\s*$/o )
				{
					s/\n//og;
					$_ .= <$infile>;
				}
			}

			if ( /\(/o )
			{
				s/^.*$/\n/o;
			}
			elsif ( !/{/o && /;/o )
			{
				/\s*typedef([\w\*\s]+)\s+\**(\w+)(\[[^\]]*\])?\s*;/o;
				if ( $typedef_sub )
				{
					$_ = &$typedef_sub($1, $2);
				}
				else
				{
					$_ = '';
				}
				&$output_sub($_) if $output_sub and $_;

				next;
			}
			# "typedef struct ...."  ----> "struct ....."
			elsif ( /(struct|union|enum)/o )
			{
				s/^\s*typedef\s+//i;
			}
			# no NEXT here
		}

		# structures:

		if ( /^\s*struct/o )
		{
			# skip over expressions of the type:
			# struct xxx;
			# struct xxx function(arg1, ...);
			if ( /^\s*struct[^{;]+;.*$/o || /\(/o )
			{
				$_ = '';
			}
			else
			{
				$sub_params{'line'} = $_;
				parse_struct(%sub_params);
			}
			next;
		}

		# enumerations
		if ( /^\s*enum/o )
		{
			# remove the 'enum' and its name
			if ( /^.*enum\s+(\w+)\s*\{?/o )
			{
				$line = &$enum_start_sub($1) if $enum_start_sub;
				&$output_sub($line) if $output_sub and $line;
				s/^.*enum\s+\w+\s*\{?//o;
			}
			my $curr_value = 0;

			# check if one-line enum
			if ( /}/o )
			{
				# there are no conditional compiling directives in one-line enums
				#if ( $preproc_sub )
				#{
				#	$_ = &$preproc_sub($_);
				#}
				#else
				#{
				#	$_ = '';
				#}

				while ( /,.*;/o )
				{
					if ( /([\w\s]*)\s+(\w+)\s*=\s*(\w+)\s*,/o )
					{
						$line = &$enum_entry_sub ($2, $3) if $enum_entry_sub;
						&$output_sub($line) if $output_sub and $line;
						$curr_value = $3+1;
						s/[\w\s]*\s+\w+\s*=\s*\w+\s*,//o
					}
					if ( /([\w\s]*)\s+(\w+)\s*,/o )
					{
						$line = &$enum_entry_sub ($2, $curr_value) if $enum_entry_sub;
						&$output_sub($line) if $output_sub and $line;
						$curr_value++;
						s/[\w\s]*\s+\w+\s*,//o
					}
				}

				# the last line has no comma
				if ( /^\s*(\w+)\s*=\s*(\w+)\s*\}\s*;/o )
				{
					$line = &$enum_entry_sub ($1, $2) if $enum_entry_sub;
					&$output_sub($line) if $output_sub and $line;
					s/^\s*\w+\s*=\s*\w+\s*\}\s*;//o
				}
				if ( /^\s*(\w+)\s*\}\s*;/o )
				{
					$line = &$enum_entry_sub ($1, $curr_value) if $enum_entry_sub;
					&$output_sub($line) if $output_sub and $line;
					s/^\s*\w+\s*\}\s*;//o
				}

				$line = &$enum_end_sub() if $enum_end_sub;
				&$output_sub($line) if $output_sub and $line;
				# changing the comments
				if ( $comment_sub )
				{
					$_ = &$comment_sub($_);
					&$output_sub($_) if $output_sub and $_;
				}
				next;
			}
			else
			{
				while ( <$infile> )
				{
					# processing of conditional compiling directives
					if ( /^\s*#/o )
					{
						if ( $preproc_sub )
						{
							$_ = &$preproc_sub($_);
						}
						else
						{
							$_ = '';
						}
						&$output_sub($_) if $output_sub and $_;

						next;
					}

					# skip over the first '{' character
					#next if /^\s*\{\s*$/o;
					s/{//go;

					next if /^\s*;/o;

					# if the constant has a value, we don't touch it
					if ( /=/o )
					{
						if ( /^\s*(\w+)\s*=\s*(\w+)\s*,?/o )
						{
							$line = &$enum_entry_sub ($1, $2) if $enum_entry_sub;
							&$output_sub($line) if $output_sub and $line;
							$curr_value = $2 + 1;
							s/^\s*\w+\s*=\s*\w+\s*,?//o;
						}
					}
					else
					{
						# assign a subsequent value
						if ( /^\s*(\w+)\s*,?/o )
						{
							$line = &$enum_entry_sub ($1, $curr_value) if $enum_entry_sub;
							&$output_sub($line) if $output_sub and $line;
							$curr_value++;
							s/^\s*\w+\s*,?//o;
						}
					}

					# changing the comments
					if ( $comment_sub )
					{
						$_ = &$comment_sub($_);
					}

					# look for the end of the enum
					if ( /\s*\}.*/o )
					{
						$line = &$enum_end_sub() if $enum_end_sub;
						&$output_sub($line) if $output_sub and $line;
						next READ;
					}

					&$output_sub($_) if $output_sub and $_;
				}
			}
		}

		if ( /^\s*union/o )
		{
			# skip over expressions of the type:
			# union xxx;
			# union xxx function(arg1, ...);
			if ( /^\s*union[^{;]+;.*$/o || /\(/o )
			{
				$_ = '';
			}
			else
			{
				$sub_params{'line'} = $_;
				parse_union(%sub_params);
			}
			next;
		}

		# remove any }'s left after <extern "C">, for example
		s/}//go;
		if ( $comment_sub )
		{
			$_ = &$comment_sub($_);
		}
		&$output_sub($_) if $output_sub and $_;
	}
}


=head1 SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the perldoc command.

    perldoc Parse::H

You can also look for information at:

    Search CPAN
        https://metacpan.org/release/Parse-H

    CPAN Request Tracker:
        https://rt.cpan.org/Public/Dist/Display.html?Name=Parse-H

    CPAN Ratings:
        https://cpanratings.perl.org/dist/Parse-H

=head1 AUTHOR

Bogdan Drozdowski, C<< <bogdro at cpan.org> >>

=head1 COPYRIGHT

Copyright 2022 Bogdan Drozdowski, all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Parse::H
