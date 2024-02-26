package RDF::Cowl::Lib::Gen::Class::UVersion;
# ABSTRACT: Private class for RDF::Cowl::Ulib::UVersion
$RDF::Cowl::Lib::Gen::Class::UVersion::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::Ulib::UVersion;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


## # uversion
## $ffi->attach( [
##  "COWL_WRAP_uversion"
##  => "_new" ] =>
## 	[
## 		arg "unsigned" => "major",
## 		arg "unsigned" => "minor",
## 		arg "unsigned" => "patch",
## 	],
## 	=> "UVersion"
## 	=> sub {
## 		my $RETVAL;
## 		my $xs    = shift;
## 
## 
## 		state $signature = signature(
## 			strictness => STRICT,
## 			pos => [
## 				Unsigned, { name => "major", },
## 				Unsigned, { name => "minor", },
## 				Unsigned, { name => "patch", },
## 			],
## 		);
## 
## 		$RETVAL = $xs->( &$signature );
## 
## 		return $RETVAL;
## 	}
## );

## # uversion_compare
## $ffi->attach( [
##  "COWL_WRAP_uversion_compare"
##  => "compare" ] =>
## 	[
## 		arg "UVersion" => "lhs",
## 		arg "UVersion" => "rhs",
## 	],
## 	=> "int"
## 	=> sub {
## 		my $RETVAL;
## 		my $xs    = shift;
## 
## 
## 		state $signature = signature(
## 			strictness => STRICT,
## 			pos => [
## 				UVersion, { name => "lhs", },
## 				UVersion, { name => "rhs", },
## 			],
## 		);
## 
## 		$RETVAL = $xs->( &$signature );
## 
## 		return $RETVAL;
## 	}
## );

# uversion_to_string
$ffi->attach( [
 "COWL_WRAP_uversion_to_string"
 => "to_string" ] =>
	[
		arg "UVersion" => "version",
	],
	=> "UString"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UVersion, { name => "version", },
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

RDF::Cowl::Lib::Gen::Class::UVersion - Private class for RDF::Cowl::Ulib::UVersion

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
