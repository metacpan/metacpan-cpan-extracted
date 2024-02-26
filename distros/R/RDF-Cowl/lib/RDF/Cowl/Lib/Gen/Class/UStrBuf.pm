package RDF::Cowl::Lib::Gen::Class::UStrBuf;
# ABSTRACT: Private class for RDF::Cowl::Ulib::UStrBuf
$RDF::Cowl::Lib::Gen::Class::UStrBuf::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::Ulib::UStrBuf;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


## # ustrbuf_append_format
## $ffi->attach( [
##  "COWL_WRAP_ustrbuf_append_format"
##  => "ustrbuf_append_format" ] =>
## 	[
## 		arg "UStrBuf" => "buf",
## 		arg "string" => "format",
## 		arg "" => "",
## 	],
## 	=> "uvec_ret"
## 	=> sub {
## 		my $RETVAL;
## 		my $xs    = shift;
## 
## 
## 		state $signature = signature(
## 			strictness => STRICT,
## 			pos => [
## 				UStrBuf, { name => "buf", },
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

## # ustrbuf_append_format_list
## $ffi->attach( [
##  "COWL_WRAP_ustrbuf_append_format_list"
##  => "ustrbuf_append_format_list" ] =>
## 	[
## 		arg "UStrBuf" => "buf",
## 		arg "string" => "format",
## 		arg "va_list" => "args",
## 	],
## 	=> "uvec_ret"
## 	=> sub {
## 		my $RETVAL;
## 		my $xs    = shift;
## 
## 
## 		state $signature = signature(
## 			strictness => STRICT,
## 			pos => [
## 				UStrBuf, { name => "buf", },
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

# ustrbuf_to_ustring
$ffi->attach( [
 "COWL_WRAP_ustrbuf_to_ustring"
 => "ustrbuf_to_ustring" ] =>
	[
		arg "UStrBuf" => "buf",
	],
	=> "UString"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UStrBuf, { name => "buf", },
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

RDF::Cowl::Lib::Gen::Class::UStrBuf - Private class for RDF::Cowl::Ulib::UStrBuf

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
