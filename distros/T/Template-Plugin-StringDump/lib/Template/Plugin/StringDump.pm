package Template::Plugin::StringDump;

use 5.006;
use strict;
use warnings;
use utf8;
use parent qw( Template::Plugin::Filter );
use String::Dump qw( :all );

our $VERSION = '0.05';

sub init {
    my ($self) = @_;

    for my $filter (qw<
        dump_hex
        dump_dec
        dump_oct
        dump_bin
        dump_names
        dump_codes
    >) {
        $self->{_CONTEXT}->define_filter($filter => \&$filter);
    }

    return $self;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Template::Plugin::StringDump - String::Dump filter for TT

=head1 VERSION

This document describes Template::Plugin::StringDump version 0.05.

=head1 SYNOPSIS

Template:

    [% USE StringDump %]

    [% SET msg = 'Ĝis! ☺' %]

    hex: [% msg | dump_hex %]
    dec: [% msg | dump_dec %]
    oct: [% msg | dump_oct %]
    bin: [% msg | dump_bin %]

Output:

    hex: C4 9C 69 73 21 20 E2 98 BA
    dec: 196 156 105 115 33 32 226 152 186
    oct: 304 234 151 163 41 40 342 230 272
    bin: 11000100 10011100 1101001 1110011 100001 100000 11100010 10011000 10111010

=head1 DESCRIPTION

This L<Template::Toolkit> plugin adds six filters for dumping strings for
display and debugging: C<dump_hex>, C<dump_dec>, C<dump_oct>, C<dump_bin>,
C<dump_names>, and C<dump_codes>.  Each byte is dumped for byte strings and each
code point for Unicode strings.  These filters are simple wrappers around the
functions of the same names from L<String::Dump>.  See that module for details.

=head1 AUTHOR

Nick Patch <patch@cpan.org>

=head1 COPYRIGHT AND LICENSE

© 2011–2012 Nick Patch

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
