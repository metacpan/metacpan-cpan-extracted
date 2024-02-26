package RDF::Cowl::Lib::Gen::Class::UIStream;
# ABSTRACT: Private class for RDF::Cowl::Ulib::UIStream
$RDF::Cowl::Lib::Gen::Class::UIStream::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::Ulib::UIStream;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


# uistream_deinit
$ffi->attach( [
 "COWL_WRAP_uistream_deinit"
 => "deinit" ] =>
	[
		arg "UIStream" => "stream",
	],
	=> "ustream_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UIStream, { name => "stream", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uistream_reset
$ffi->attach( [
 "COWL_WRAP_uistream_reset"
 => "reset" ] =>
	[
		arg "UIStream" => "stream",
	],
	=> "ustream_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UIStream, { name => "stream", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


## # uistream_read
## $ffi->attach( [
##  "COWL_WRAP_uistream_read"
##  => "read" ] =>
## 	[
## 		arg "UIStream" => "stream",
## 		arg "void *" => "buf",
## 		arg "size_t" => "count",
## 		arg "size_t *" => "read",
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
## 				UIStream, { name => "stream", },
## 				Void *, { name => "buf", },
## 				PositiveOrZeroInt, { name => "count", },
## 				Size_t *, { name => "read", },
## 			],
## 		);
## 
## 		$RETVAL = $xs->( &$signature );
## 
## 		return $RETVAL;
## 	}
## );

# uistream_std
$ffi->attach( [
 "COWL_WRAP_uistream_std"
 => "std" ] =>
	[
	],
	=> "UIStream"
);


# uistream_from_path
$ffi->attach( [
 "COWL_WRAP_uistream_from_path"
 => "from_path" ] =>
	[
		arg "UIStream" => "stream",
		arg "string" => "path",
	],
	=> "ustream_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UIStream, { name => "stream", },
				Str, { name => "path", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uistream_from_file
$ffi->attach( [
 "COWL_WRAP_uistream_from_file"
 => "from_file" ] =>
	[
		arg "UIStream" => "stream",
		arg "FILE" => "file",
	],
	=> "ustream_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UIStream, { name => "stream", },
				InstanceOf["FFI::C::File"], { name => "file", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


## # uistream_from_buf
## $ffi->attach( [
##  "COWL_WRAP_uistream_from_buf"
##  => "from_buf" ] =>
## 	[
## 		arg "UIStream" => "stream",
## 		arg "void const *" => "buf",
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
## 				UIStream, { name => "stream", },
## 				Void const *, { name => "buf", },
## 				PositiveOrZeroInt, { name => "size", },
## 			],
## 		);
## 
## 		$RETVAL = $xs->( &$signature );
## 
## 		return $RETVAL;
## 	}
## );

# uistream_from_strbuf
$ffi->attach( [
 "COWL_WRAP_uistream_from_strbuf"
 => "from_strbuf" ] =>
	[
		arg "UIStream" => "stream",
		arg "UStrBuf" => "buf",
	],
	=> "ustream_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UIStream, { name => "stream", },
				UStrBuf, { name => "buf", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uistream_from_string
$ffi->attach( [
 "COWL_WRAP_uistream_from_string"
 => "from_string" ] =>
	[
		arg "UIStream" => "stream",
		arg "string" => "string",
	],
	=> "ustream_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UIStream, { name => "stream", },
				Str, { name => "string", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uistream_from_ustring
$ffi->attach( [
 "COWL_WRAP_uistream_from_ustring"
 => "from_ustring" ] =>
	[
		arg "UIStream" => "stream",
		arg "UString" => "string",
	],
	=> "ustream_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UIStream, { name => "stream", },
				UString, { name => "string", },
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

RDF::Cowl::Lib::Gen::Class::UIStream - Private class for RDF::Cowl::Ulib::UIStream

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
