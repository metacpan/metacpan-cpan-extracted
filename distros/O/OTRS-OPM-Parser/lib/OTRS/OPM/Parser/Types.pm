package OTRS::OPM::Parser::Types;

# ABSTRACT: types for OTRS::OPM::Parser

use v5.10;

use strict;
use warnings;

use Type::Library
   -base,
;

use Type::Utils -all;
use Types::Standard -types;

our $VERSION = '0.01';

Type::Utils::extends('Types::Standard');

declare VersionString =>
    as Str,
    where {
        $_ =~ m{ \A (?:[0-9]+) (?:\.[0-9]+){0,2} (?:_\d+)? \z }xms
    };

declare FrameworkVersionString =>
    as Str,
    where {
        $_ =~ m{ \A (?: (?:x|[0-9]+x?) \. ){1,2} (?: x | [0-9]+x? ) \z }xms
    };

declare XMLTree =>
    as InstanceOf['XML::LibXML::Document'];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OTRS::OPM::Parser::Types - types for OTRS::OPM::Parser

=head1 VERSION

version 1.05

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
