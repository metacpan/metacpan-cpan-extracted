use 5.012;
use strict;
use warnings;

package SpecioX::XS;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

use Type::Tiny::XS ();

sub tamper {
	my ( $specio_object, $xs_name, $tamper_inlined_too ) = @_;
	$specio_object or return;
	
	my $coderef = Type::Tiny::XS::get_coderef_for( $xs_name );
	my $subname = Type::Tiny::XS::get_subname_for( $xs_name );
	$coderef or return;
	
	$specio_object->{_xs_name} = $xs_name;
	$specio_object->{_optimized_constraint} = $coderef;
	
	if ( $tamper_inlined_too ) {
		$specio_object->{_inline_generator} = sub {
			my ( undef, $var ) = @_;
			return "$subname($var)";
		};
	}
}

use Specio::Library::Builtins;
my $exported = Specio::Exporter::exportable_types_for_package( 'Specio::Library::Builtins' );

# Many similarly named types differ between Specio and Types::Common,
# and only these seem to be exactly equivalent. This is mostly because
# Specio accepts overloaded objects in place of primatives everywhere.
#
tamper $exported->{'Item'},       'Any';
tamper $exported->{'Defined'},    'Defined';
tamper $exported->{'Undef'},      'Undef';
tamper $exported->{'Ref'},        'Ref';
tamper $exported->{'Value'},      'Value';
tamper $exported->{'Object'},     'Object';
tamper $exported->{'ArrayRef'},   'ArrayLike',    !!1;
tamper $exported->{'HashRef'},    'HashLike',     !!1;
tamper $exported->{'CodeRef'},    'CodeLike',     !!1;
tamper $exported->{'Str'},        'StringLike',   !!1;

# You thought that was bad? It's about to get worse!
#

do {
	my $orig = $exported->{'ArrayRef'}{_parameterized_inline_generator};
	$exported->{'ArrayRef'}{_parameterized_inline_generator} = sub {
		my ( $type, $parameter, $var ) = @_;
		my $param_check = $parameter->_optimized_constraint;
		if ( my $name = Type::Tiny::XS::is_known($param_check) ) {
			my $xsub = Type::Tiny::XS::get_coderef_for( "ArrayLike[$name]" );
			if ( $xsub ) {
				$type->{_optimized_constraint} = $xsub;
				my $xsubname = Type::Tiny::XS::get_subname_for( "ArrayLike[$name]" );
				return "$xsubname($var)" if $xsubname;
			}
		}
		goto $orig;
	};
};

do {
	my $orig = $exported->{'HashRef'}{_parameterized_inline_generator};
	$exported->{'HashRef'}{_parameterized_inline_generator} = sub {
		my ( $type, $parameter, $var ) = @_;
		my $param_check = $parameter->_optimized_constraint;
		if ( my $name = Type::Tiny::XS::is_known($param_check) ) {
			my $xsub = Type::Tiny::XS::get_coderef_for( "HashLike[$name]" );
			if ( $xsub ) {
				$type->{_optimized_constraint} = $xsub;
				my $xsubname = Type::Tiny::XS::get_subname_for( "HashLike[$name]" );
				return "$xsubname($var)" if $xsubname;
			}
		}
		goto $orig;
	};
};

do {
	use Specio::Constraint::ObjectIsa ();
	no warnings 'redefine';
	my $orig = \&Specio::Constraint::ObjectIsa::_build_inline_generator;
	*Specio::Constraint::ObjectIsa::_build_inline_generator = sub {
		return sub {
			my ( $type, $var ) = @_;
			my $class = $type->class;
			my $xsub = Type::Tiny::XS::get_coderef_for("InstanceOf[$class]");
			if ( $xsub ) {
				$type->{_optimized_constraint} = $xsub;
				my $xsubname = Type::Tiny::XS::get_subname_for("InstanceOf[$class]");
				return "$xsubname($var)" if $xsubname;
			}
			goto $orig;
		};
	};
};

do {
	use Specio::Constraint::ObjectCan ();
	no warnings 'redefine';
	my $orig = \&Specio::Constraint::ObjectCan::_build_inline_generator;
	*Specio::Constraint::ObjectCan::_build_inline_generator = sub {
		return sub {
			my ( $type, $var ) = @_;
			my $methods = join q{,}, @{ $type->methods };
			my $xsub = Type::Tiny::XS::get_coderef_for("HasMethods[$methods]");
			if ( $xsub ) {
				$type->{_optimized_constraint} = $xsub;
				my $xsubname = Type::Tiny::XS::get_subname_for("HasMethods[$methods]");
				return "$xsubname($var)" if $xsubname;
			}
			goto $orig;
		};
	};
};

1;

__END__

=pod

=encoding utf-8

=head1 NAME

SpecioX::XS - [PROOF OF CONCEPT] speed boost for Specio using Type::Tiny::XS

=head1 SYNOPSIS

A rather contrived benchmark, using a type constraint which in L<Types::Common>
would be called B<< ArrayLike[HashLike[StringLike]] >>, so an arrayref of
hashrefs of strings, but which allows objects overloading C<< %{} >>,
C<< @{} >>, and C<< "" >>.

  # bin/benchmark.pl
  #
  use Benchmark;
  
  timethis( -3, q{
    use Specio::Library::Builtins;
    my $type = t( 'ArrayRef', of => t( 'HashRef', of => t( 'Str' ) ) );
    my $arr  = [ map { foo => $_ }, 1 .. 100 ];
    for ( 0 .. 100 ) {
      $type->check( $arr ) or die;
    }
  } );

And running the benchmarks:

  $ perl -Ilib bin/benchmark.pl
  timethis for 3:  3 wallclock secs ( 3.20 usr +  0.00 sys =  3.20 CPU) @ 271.25/s (n=868)
  $ perl -Ilib -MSpecioX::XS bin/benchmark.pl
  timethis for 3:  4 wallclock secs ( 3.48 usr +  0.01 sys =  3.49 CPU) @ 918.91/s (n=3207)

On my laptop, the check runs more than three times faster with L<SpecioX::XS>.

=head1 DESCRIPTION

This module pokes around in Specio internals quite badly.
Do not use it in production situations.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=SpecioX-XS>.

=head1 SEE ALSO

L<Specio>, L<Type::Tiny::XS>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
