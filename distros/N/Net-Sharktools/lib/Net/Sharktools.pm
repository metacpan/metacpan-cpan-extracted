package Net::Sharktools;

use 5.008001;
use warnings;
use strict;
use Carp;

our $VERSION = '0.009';
$VERSION = eval $VERSION;

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT_OK = qw( perlshark_read_xs perlshark_read );
our @EXPORT = qw();

eval {
    require XSLoader;
    XSLoader::load('Net::Sharktools', $VERSION);
    1;
} or do {
    require DynaLoader;
    push @ISA, 'DynaLoader';
    bootstrap Net::Sharktools $VERSION;
};

sub perlshark_read {
    my %args;

    if ( ref $_[0] eq 'HASH' ) {
        %args = %{ $_[0] };
    }
    else {
        %args = @_;
    }

    unless (defined $args{filename}) {
        croak 'file name argument is missing';
    }

    unless (defined $args{fieldnames}) {
        croak 'field names argument is missing';
    }

    unless ('ARRAY' eq ref $args{fieldnames}) {
        croak 'field names must be provided in an array reference';
    }

    unless (defined $args{dfilter}) {
        croak 'dfilter argument is missing';
    }

    if ( defined $args{decode_as} ) {
        return perlshark_read_xs(
            @args{qw(filename fieldnames dfilter decode_as)}
        );
    }
    else {
        return perlshark_read_xs(
            @args{qw(filename fieldnames dfilter)}
        );
    }
}


1;
__END__

=head1 NAME

Net::Sharktools - Use Wireshark's packet inspection capabilities in Perl

=head1 SYNOPSIS

    use Net::Sharktools qw(perlshark_read);

    my $frames = perlshark_read(
        filename => 'capture1.pcap',
        fieldnames => [qw( 
            frame.number 
            ip.version
            tcp.seq
            udp.dstport
            frame.len
        )],
        dfilter => 'ip.version eq 4'
        # optional decode_as
    );

or

    use Net::Sharktools qw(perlshark_read_xs);

    my $frames = perlshark_read_xs(
        'capture1.pcap',
        [qw( 
            frame.number 
            ip.version
            tcp.seq
            udp.dstport
            frame.len
        )],
        'ip.version eq 4'
        # optional decode_as
    );

=head1 DESCRIPTION

C<Net::Sharktools> is an adaptation of the Python interface provided with the
C<Sharktools> package which is a "small set of  tools that allow use of
Wireshark's deep packet inspection capabilities in interpreted programming
languages."

Sharktools can be obtained obtained Armen Babikyan's web site at
L<http://www.mit.edu/~armenb/sharktools/>. To use C<Net::Sharktools>, you must
first build the Sharktools C library successfully as described in the README
for the Sharktools package (the version of this file bundled with Sharktools
v.0.1.5 is included in this module for your reference).

C<Net::Sharktools> is almost a direct translation of the Python interface
C<pyshark> included with Sharktools.

=head1 BUILD and INSTALLATION

Sharktools is closely coupled with the internals of Wireshark. Before
attempting to build C<Net::Sharktools>, you should ensure that you are able to
build and run the Python module C<pyshark> distributed with Sharktools. Note
that you should use C<python2> to test C<pyshark>.

The build process for Sharktools requires you to install Wireshark and also
have the full source tree for Wireshark accessible. You will need the same to
build Sharktools as well.

Currently, the C<Makefile.PL> for C<Net::Sharktools> makes no attempt to
automatically deduce the locations for your WireShark and Sharktools
distributions. You will need to provide that information.

You can do that by specifying command line options when you generate the
Makefile:

    perl Makefile.PL --PREFIX=/install/path \
        --sharktools-src /home/user/sharktools-0.1.5/src \
        --wireshark-src /home/user/shark/wireshark-1.4.3 \
        [ --lib-path /additional/library/paths ] \
        [ --inc-path /additional/include/paths ]

C<--inc-path> and C<--lib-path> are array valued options, so they can be
specified multiple times on the command line.

You should definitely specify those (in addition to the Sharktools and
Wireshark source directories) if you encounter any difficulties related to
locating glib headers and/or glib and Wireshark libraries on your system.

I used C<Devel::CheckLib> to perform a sanity check prior to WriteMakefile
using a select few headers and libraries. If the checks fail, no Makefile will
be generated. Ensure that you have the requisite libraries installed, make sure
you have built Sharktools according to its instructions prior to attempting to
build Net::Sharktools, and specified the correct paths when invoking
Makefile.PL.

Once a Makefile is generated, you can do:

    make
    make test
    make install

=head1 EXPORT

The module does not export any functions by default. You can request either
C<perlshark_read> which accepts arguments in a hash ref or as a flattened hash
or C<perlshark_read_xs> which expects positional arguments.

=head2 perlshark_read

You can either pass the arguments to this function in a hashref or as a
flattened hash. The function does some argument checking and passes the
arguments in the correct order to C<perlshark_read_xs> which uses positional
arguments.

The arguments are:

=over 4

=item filename

The name of the capture file to be analyzed.

=item fieldnames

The names of the fields to be extracted.

=item dfilter

Filter expressions to apply.

=item decode_as

From Sharktools README:

Wireshark's packet dissection engine uses a combination of heuristics and
convention to determine what dissector to use for a particular packet. For
example, IP packets with TCP port 80 are, by default, parsed as HTTP packets.
If you wish to have TCP port 800 packets parsed as HTTP packets, you need to
tell the Wireshark engine your explicit intent.

Wireshark adds a "decode as" feature in its GUI that allows for users to
specify this mapping (Analyze Menu -> Decode As...).  Sharktools attempts to
provide a basic interface to this feature as well.  By adding a 4th (optional)
argument to both the matshark and pyshark commands, a user can achieve the
desired effect.  For example, the following "decode as" string will parse TCP
port 60000 packets as HTTP packets: 'tcp.port==60000,http

=back

=head2 perlshark_read_xs

This is the XS routine. It expects 3 or 4 positional arguments.

    perlshark_read_xs(
        $filename, 
        [qw( field1 ... fieldn )],
        $dfilter,
        $decode_as, # optional
    );

=head1 SEE ALSO

Sharktools L<http://www.mit.edu/~armenb/sharktools/> and Wireshark
L<http://www.wireshark.org>.

=head1 ACKNOWLEDGEMENTS

The XS code is a straightforward translation of the Python interface provided
in pyshark.c 

=head1 AUTHOR

A. Sinan Unur, E<lt>nanis@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by The Perl Review, LLC

This work was sponsored by brian d foy and The Perl Review.

This module is free software. You can redistribute it and/or modify it under
the terms of GNU General Public License, version 2. See
L<http://www.gnu.org/licenses/gpl-2.0.html>
