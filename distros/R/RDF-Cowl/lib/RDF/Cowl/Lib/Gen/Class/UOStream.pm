package RDF::Cowl::Lib::Gen::Class::UOStream;
# ABSTRACT: Private class for RDF::Cowl::Ulib::UOStream
$RDF::Cowl::Lib::Gen::Class::UOStream::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::Ulib::UOStream;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


# uostream_deinit
$ffi->attach( [
 "COWL_WRAP_uostream_deinit"
 => "deinit" ] =>
	[
		arg "UOStream" => "stream",
	],
	=> "ustream_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UOStream, { name => "stream", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uostream_flush
$ffi->attach( [
 "COWL_WRAP_uostream_flush"
 => "flush" ] =>
	[
		arg "UOStream" => "stream",
	],
	=> "ustream_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UOStream, { name => "stream", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


## # uostream_write
## $ffi->attach( [
##  "COWL_WRAP_uostream_write"
##  => "write" ] =>
## 	[
## 		arg "UOStream" => "stream",
## 		arg "void const *" => "buf",
## 		arg "size_t" => "count",
## 		arg "size_t *" => "written",
## 	],
## 	=> "ustream_ret"
## 	=> sub {
## 		my $RETVAL;
## 		my $xs    = shift;
## 
## 
## 		state $signature = signature(
## 			strictness => STRICT,
## 			pos => [
## 				UOStream, { name => "stream", },
## 				Void const *, { name => "buf", },
## 				PositiveOrZeroInt, { name => "count", },
## 				Size_t *, { name => "written", },
## 			],
## 		);
## 
## 		$RETVAL = $xs->( &$signature );
## 
## 		return $RETVAL;
## 	}
## );

## # uostream_writef
## $ffi->attach( [
##  "COWL_WRAP_uostream_writef"
##  => "writef" ] =>
## 	[
## 		arg "UOStream" => "stream",
## 		arg "size_t *" => "written",
## 		arg "string" => "format",
## 		arg "" => "",
## 	],
## 	=> "ustream_ret"
## 	=> sub {
## 		my $RETVAL;
## 		my $xs    = shift;
## 
## 
## 		state $signature = signature(
## 			strictness => STRICT,
## 			pos => [
## 				UOStream, { name => "stream", },
## 				Size_t *, { name => "written", },
## 				Str, { name => "format", },
## 				, { name => "", },
## 			],
## 		);
## 
## 		$RETVAL = $xs->( &$signature );
## 
## 		return $RETVAL;
## 	}
## );

## # uostream_writef_list
## $ffi->attach( [
##  "COWL_WRAP_uostream_writef_list"
##  => "writef_list" ] =>
## 	[
## 		arg "UOStream" => "stream",
## 		arg "size_t *" => "written",
## 		arg "string" => "format",
## 		arg "va_list" => "args",
## 	],
## 	=> "ustream_ret"
## 	=> sub {
## 		my $RETVAL;
## 		my $xs    = shift;
## 
## 
## 		state $signature = signature(
## 			strictness => STRICT,
## 			pos => [
## 				UOStream, { name => "stream", },
## 				Size_t *, { name => "written", },
## 				Str, { name => "format", },
## 				Va_list, { name => "args", },
## 			],
## 		);
## 
## 		$RETVAL = $xs->( &$signature );
## 
## 		return $RETVAL;
## 	}
## );

## # uostream_write_string
## $ffi->attach( [
##  "COWL_WRAP_uostream_write_string"
##  => "write_string" ] =>
## 	[
## 		arg "UOStream" => "stream",
## 		arg "UString" => "string",
## 		arg "size_t *" => "written",
## 	],
## 	=> "ustream_ret"
## 	=> sub {
## 		my $RETVAL;
## 		my $xs    = shift;
## 
## 
## 		state $signature = signature(
## 			strictness => STRICT,
## 			pos => [
## 				UOStream, { name => "stream", },
## 				UString, { name => "string", },
## 				Size_t *, { name => "written", },
## 			],
## 		);
## 
## 		$RETVAL = $xs->( &$signature );
## 
## 		return $RETVAL;
## 	}
## );

## # uostream_write_time
## $ffi->attach( [
##  "COWL_WRAP_uostream_write_time"
##  => "write_time" ] =>
## 	[
## 		arg "UOStream" => "stream",
## 		arg "UTime" => "time",
## 		arg "size_t *" => "written",
## 	],
## 	=> "ustream_ret"
## 	=> sub {
## 		my $RETVAL;
## 		my $xs    = shift;
## 
## 
## 		state $signature = signature(
## 			strictness => STRICT,
## 			pos => [
## 				UOStream, { name => "stream", },
## 				UTime, { name => "time", },
## 				Size_t *, { name => "written", },
## 			],
## 		);
## 
## 		$RETVAL = $xs->( &$signature );
## 
## 		return $RETVAL;
## 	}
## );

## # uostream_write_time_interval
## $ffi->attach( [
##  "COWL_WRAP_uostream_write_time_interval"
##  => "write_time_interval" ] =>
## 	[
## 		arg "UOStream" => "stream",
## 		arg "utime_ns" => "interval",
## 		arg "utime_unit" => "unit",
## 		arg "unsigned" => "decimal_digits",
## 		arg "size_t *" => "written",
## 	],
## 	=> "ustream_ret"
## 	=> sub {
## 		my $RETVAL;
## 		my $xs    = shift;
## 
## 
## 		state $signature = signature(
## 			strictness => STRICT,
## 			pos => [
## 				UOStream, { name => "stream", },
## 				Utime_ns, { name => "interval", },
## 				Utime_unit, { name => "unit", },
## 				Unsigned, { name => "decimal_digits", },
## 				Size_t *, { name => "written", },
## 			],
## 		);
## 
## 		$RETVAL = $xs->( &$signature );
## 
## 		return $RETVAL;
## 	}
## );

## # uostream_write_version
## $ffi->attach( [
##  "COWL_WRAP_uostream_write_version"
##  => "write_version" ] =>
## 	[
## 		arg "UOStream" => "stream",
## 		arg "UVersion" => "version",
## 		arg "size_t *" => "written",
## 	],
## 	=> "ustream_ret"
## 	=> sub {
## 		my $RETVAL;
## 		my $xs    = shift;
## 
## 
## 		state $signature = signature(
## 			strictness => STRICT,
## 			pos => [
## 				UOStream, { name => "stream", },
## 				UVersion, { name => "version", },
## 				Size_t *, { name => "written", },
## 			],
## 		);
## 
## 		$RETVAL = $xs->( &$signature );
## 
## 		return $RETVAL;
## 	}
## );

# uostream_std
$ffi->attach( [
 "COWL_WRAP_uostream_std"
 => "std" ] =>
	[
	],
	=> "UOStream"
);


# uostream_stderr
$ffi->attach( [
 "COWL_WRAP_uostream_stderr"
 => "stderr" ] =>
	[
	],
	=> "UOStream"
);


# uostream_null
$ffi->attach( [
 "COWL_WRAP_uostream_null"
 => "null" ] =>
	[
	],
	=> "UOStream"
);


# uostream_to_path
$ffi->attach( [
 "COWL_WRAP_uostream_to_path"
 => "to_path" ] =>
	[
		arg "UOStream" => "stream",
		arg "string" => "path",
	],
	=> "ustream_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UOStream, { name => "stream", },
				Str, { name => "path", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uostream_to_file
$ffi->attach( [
 "COWL_WRAP_uostream_to_file"
 => "to_file" ] =>
	[
		arg "UOStream" => "stream",
		arg "FILE" => "file",
	],
	=> "ustream_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UOStream, { name => "stream", },
				InstanceOf["FFI::C::File"], { name => "file", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


## # uostream_to_buf
## $ffi->attach( [
##  "COWL_WRAP_uostream_to_buf"
##  => "to_buf" ] =>
## 	[
## 		arg "UOStream" => "stream",
## 		arg "void *" => "buf",
## 		arg "size_t" => "size",
## 	],
## 	=> "ustream_ret"
## 	=> sub {
## 		my $RETVAL;
## 		my $xs    = shift;
## 
## 
## 		state $signature = signature(
## 			strictness => STRICT,
## 			pos => [
## 				UOStream, { name => "stream", },
## 				Void *, { name => "buf", },
## 				PositiveOrZeroInt, { name => "size", },
## 			],
## 		);
## 
## 		$RETVAL = $xs->( &$signature );
## 
## 		return $RETVAL;
## 	}
## );

# uostream_to_strbuf
$ffi->attach( [
 "COWL_WRAP_uostream_to_strbuf"
 => "to_strbuf" ] =>
	[
		arg "UOStream" => "stream",
		arg "UStrBuf" => "buf",
	],
	=> "ustream_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UOStream, { name => "stream", },
				UStrBuf, { name => "buf", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uostream_to_multi
$ffi->attach( [
 "COWL_WRAP_uostream_to_multi"
 => "to_multi" ] =>
	[
		arg "UOStream" => "stream",
	],
	=> "ustream_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UOStream, { name => "stream", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uostream_add_substream
$ffi->attach( [
 "COWL_WRAP_uostream_add_substream"
 => "add_substream" ] =>
	[
		arg "UOStream" => "stream",
		arg "UOStream" => "other",
	],
	=> "ustream_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UOStream, { name => "stream", },
				UOStream, { name => "other", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::Lib::Gen::Class::UOStream - Private class for RDF::Cowl::Ulib::UOStream

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
