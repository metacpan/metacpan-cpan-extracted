package RDF::Cowl::Lib::Gen::Class::RDFVocab;
# ABSTRACT: Private class for RDF::Cowl::RDFVocab
$RDF::Cowl::Lib::Gen::Class::RDFVocab::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::RDFVocab;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


# cowl_rdf_vocab
$ffi->attach( [
 "COWL_WRAP_cowl_rdf_vocab"
 => "new" ] =>
	[
	],
	=> "CowlRDFVocab"
	=> sub {
		my $RETVAL;
		my $xs    = shift;
		my $class = shift;


		$RETVAL = $xs->( @_ );

		return $RETVAL;
	}
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::Lib::Gen::Class::RDFVocab - Private class for RDF::Cowl::RDFVocab

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
