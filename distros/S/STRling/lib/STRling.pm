package STRling;

use 5.010;
use strict;
use warnings;
use Exporter qw(import);

use STRling::NativeClient ();
use STRling::Requests ();
use STRling::StdlibGenerated ();

our $VERSION = '4.0.1';
our @EXPORT_OK = qw(
    load_native source_compile_request stdlib_helper simply_builder_request
    date_time email ip url uuid
);

# STRling-public-arity: load_native=1
sub load_native { return STRling::NativeClient->load(@_); }
# STRling-public-arity: source_compile_request=1..2
sub source_compile_request { return STRling::Requests::source_compile_request(@_); }
# STRling-public-arity: stdlib_helper=2..3
sub stdlib_helper { return STRling::Requests::stdlib_helper(@_); }
# STRling-public-arity: simply_builder_request=2..3
sub simply_builder_request { return STRling::Requests::simply_builder_request(@_); }
# STRling-public-arity: date_time=1
sub date_time { return STRling::StdlibGenerated::date_time(@_); }
# STRling-public-arity: email=1
sub email { return STRling::StdlibGenerated::email(@_); }
# STRling-public-arity: ip=1..2
sub ip { return STRling::StdlibGenerated::ip(@_); }
# STRling-public-arity: url=1
sub url { return STRling::StdlibGenerated::url(@_); }
# STRling-public-arity: uuid=1..2
sub uuid { return STRling::StdlibGenerated::uuid(@_); }

1;

__END__

=head1 NAME

STRling - thin Perl adapter over the canonical STRling native interop boundary

=head1 DESCRIPTION

This package projects canonical request and response data through a
caller-selected C<strling.c-abi> version 1 library. It contains no parser,
compiler, validator, emitter, or target semantics.

=cut
