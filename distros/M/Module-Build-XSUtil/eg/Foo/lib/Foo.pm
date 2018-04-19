package Foo;
use strict;
use warnings;
use XSLoader;

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT_OK = qw(ok);

BEGIN {
    our $VERSION = '0.19';
    XSLoader::load __PACKAGE__, $VERSION;
}

1;
__END__

=head1 NAME

Foo - Perl extension for blah blah blah

=head1 DESCRIPTION

Stub documentation for Foo.

=head1 AUTHOR

A. U. Thor, author\@example.com
