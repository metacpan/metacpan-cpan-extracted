package RDF::Cowl::Lib::cowl_ret;
# ABSTRACT: cowl_ret status used for error checking
$RDF::Cowl::Lib::cowl_ret::VERSION = '1.0.0';
use strict;
use warnings;
use namespace::autoclean;
use RDF::Cowl::Lib;
use FFI::C;

my $ffi = RDF::Cowl::Lib->ffi;

# enum cowl_ret
# From <cowl_ret.h>

my @ENUM_CODES = qw(
    COWL_OK
    COWL_ERR
    COWL_ERR_IO
    COWL_ERR_MEM
    COWL_ERR_SYNTAX
    COWL_ERR_IMPORT
);
my @_COWL_RET_CODE =
	map {
		[ $ENUM_CODES[$_] =~ s/^COWL_//r , $_ ],
	} 0..$#ENUM_CODES;

$ffi->load_custom_type('::Enum', 'cowl_ret',
	{ rev => 'int', package => __PACKAGE__ },
	@_COWL_RET_CODE,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::Lib::cowl_ret - cowl_ret status used for error checking

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
