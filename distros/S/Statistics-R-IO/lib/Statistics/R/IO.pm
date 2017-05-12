package Statistics::R::IO;
# ABSTRACT: Perl interface to serialized R data
$Statistics::R::IO::VERSION = '1.0001';
use 5.010;
use strict;
use warnings FATAL => 'all';

use Exporter 'import';

our @EXPORT = qw( );
our @EXPORT_OK = qw( readRDS readRData evalRserve );

our %EXPORT_TAGS = ( all => [ @EXPORT_OK ], );

use Statistics::R::IO::REXPFactory;
use Statistics::R::IO::Rserve;
use IO::Uncompress::Gunzip ();
use IO::Uncompress::Bunzip2 ();
use IO::Socket::INET ();
use Carp;


sub readRDS {
    open (my $f, shift) or croak $!;
    binmode $f;
    my ($data, $rc) = '';
    while ($rc = read($f, $data, 8192, length $data)) {}
    croak $! unless defined $rc;
    if (substr($data, 0, 2) eq "\x1f\x8b") {
        ## gzip-compressed file
        seek($f, 0, 0);
        IO::Uncompress::Gunzip::gunzip $f, \$data;
    }
    elsif (substr($data, 0, 3) eq 'BZh') {
        ## bzip2-compressed file
        seek($f, 0, 0);
        IO::Uncompress::Bunzip2::bunzip2 $f, \$data;
    }
    elsif (substr($data, 0, 6) eq "\xfd7zXZ\0") {
        croak "xz-compressed RDS files are not supported";
    }
    
    my ($value, $state) = @{Statistics::R::IO::REXPFactory::unserialize($data)};
    croak 'Could not parse RDS file' unless $state;
    croak 'Unread data remaining in the RDS file' unless $state->eof;
    $value
}


sub readRData {
    open (my $f, shift) or croak $!;
    binmode $f;
    my ($data, $rc) = '';
    while ($rc = read($f, $data, 8192, length $data)) {}
    croak $! unless defined $rc;
    if (substr($data, 0, 2) eq "\x1f\x8b") {
        ## gzip-compressed file
        seek($f, 0, 0);
        IO::Uncompress::Gunzip::gunzip $f, \$data;
    }
    elsif (substr($data, 0, 3) eq 'BZh') {
        ## bzip2-compressed file
        seek($f, 0, 0);
        IO::Uncompress::Bunzip2::bunzip2 $f, \$data;
    }
    elsif (substr($data, 0, 6) eq "\xfd7zXZ\0") {
        croak "xz-compressed RData files are not supported";
    }
    
    if (substr($data, 0, 5) ne "RDX2\n") {
        croak 'File does not start with the RData magic number: ' .
            unpack('H*', substr($data, 0, 5));
    }

    my ($value, $state) = @{Statistics::R::IO::REXPFactory::unserialize(substr($data, 5))};
    croak 'Could not parse RData file' unless $state;
    croak 'Unread data remaining in the RData file' unless $state->eof;
    Statistics::R::IO::REXPFactory::tagged_pairlist_to_rexp_hash $value;
}


sub evalRserve {
    my ($rexp, $server) = (shift, shift);

    my $rserve = Statistics::R::IO::Rserve->new($server // {});

    $rserve->eval($rexp)
}

1; # End of Statistics::R::IO

__END__

=pod

=encoding UTF-8

=head1 NAME

Statistics::R::IO - Perl interface to serialized R data

=head1 VERSION

version 1.0001

=head1 SYNOPSIS

    use Statistics::R::IO;
    
    my $var = Statistics::R::IO::readRDS('file.rds');
    print $var->to_pl;
    
    my %r_workspace = Statistics::R::IO::readRData('.RData');
    while (my ($var_name, $value) = each %r_workspace) {
        print $var_name, $value;
    }

    my $pi = Statistics::R::IO::evalRserve('pi');
    print $pi->to_pl;

=head1 DESCRIPTION

This module is a pure-Perl implementation for reading native data
files produced by the L<R statistical computing
environment|http://www.r-project.org>)

It provides routines for reading files in the two primary file
formats used in R for serializing native objects:

=over

=item RDS

RDS files store a serialization of a single R object (and, if the
object contains references to other objects, such as environments, all
the referenced objects as well). These files are created in R using
the C<readRDS> function and are typically named with the C<.rds> file
extension.

=item RData

RData files store a serialization of a collection of I<named> objects,
typically a workspace. These files are created in R using the C<save>
function and are typically named with the C<.RData> file extension.
(Contents of the R workspace can also be saved automatically on exit
to the file named F<.RData>, which is by default automatically read in
on startup.)

=back

As of version 0.04, the module can also evaluate R code on a remote
host that runs the L<Rserve|http://www.rforge.net/Rserve/> binary R
server. This allows Perl programs to access all facilities of R
without the need to have a local install of R or link to an R library.

See L</SUBROUTINES> for invocation and usage information on individual
subroutines, and the L<R Internals
manual|http://cran.r-project.org/doc/manuals/R-ints.html> for the
specification of the file formats.

=head1 EXPORT

Nothing by default. Optionally, subroutines C<readRDS>, C<readRData>,
and C<evalRserve>, or C<:all> for all three.

=head1 SUBROUTINES

=over 4

=item readRDS EXPR

Reads a file in RDS format whose filename is given by EXPR and returns
a L<Statistics::R::REXP> object.

=item readRData EXPR

Reads a file in RData format whose filename is given by EXPR and
returns a hash whose keys are the names of objects stored in the file
with corresponding values as L<Statistics::R::REXP> instances.

=item evalRserve REXPR [ HOSTNAME [, PORT] | HANDLE]

Evaluates an R expression, given as text string in REXPR, on an
L<Rserve|http://www.rforge.net/Rserve/> server and returns its result
as a L<Statistics::R::REXP> object.

The server location can be specified either by its host name and
(optionally) port or by a connected instance of L<IO::Handle>. The
caller passing the HANDLE is responsible for reading (and checking)
the server ID that is returned in the first 32-byte response when the
connection was established. This allows opening the connection once
and reusing it in multiple calls to 'evalRserve'.

If only REXPR is given, the function assumes that the server runs on
the localhost. If PORT is not specified, it defaults to the standard
Rserve port, 6311.

The function will close the connection to the Rserve host if it has
opened it itself, but not if the connection was passed as a HANDLE.

=back

=head1 DEPENDENCIES

Requires perl 5.010 or newer.

=head2 Core modules

=over

=item * strict

=item * warnings

=item * overload

=item * Carp

=item * Exporter

=item * Module::Build

=item * Scalar::Util

=item * Test::More

=back

=head2 Additional CPAN modules

=over

=item * Class::Tiny

=item * Class::Tiny::Antlers

=item * Class::Method::Modifiers

=item * namespace::clean

=item * Test::Fatal

=back

=head1 BUGS AND LIMITATIONS

The module currently handles the 'version 2' serialization format,
used since R 1.4.0 (released in December 2001). Only XDR and
native-order binary is implemented, and since the R documentation
describes the ASCII save format as "now mainly of historical
interest", this is unlikely to change soon. No check is performed that
a file stored in native-order binary was created on a platform that
used the same order, and it is up to the caller to ensure
compatibility. (Given that the default save format is XDR, and the
prevalence of Intel platforms, this is unlikely to be a problem for
either publicly-distributed or internal data files.)

Data files compressed with 'gzip' and 'bzip2' are supported, but not
'xz' ones. Again, given the R defaults ('gzip') and the fact that
C<IO::Uncompress::UnXz> is not production-ready, this is unlikely to
change soon.

There are some R types that are not (yet) implemented, although all
typical "user-facing" types -- such as vectors, lists, and
environments -- are. The remaining R types will be implemented
as-needed; in other words, if you come across one that you need to
read a particular file, please send me the type (the id will included
in the "unimplemented SEXPTYPE" error message) and, if possible, how
it was generated.

There are no known bugs in this module. Please report any bugs or
feature requests to C<bug-statistics-r-io at rt.cpan.org>, or through
the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Statistics-R-IO>. I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Statistics::R::IO

You can also look for information at:

=over

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Statistics-R-IO>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Statistics-R-IO>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Statistics-R-IO>

=item * Search CPAN

L<http://search.cpan.org/dist/Statistics-R-IO/>

=back

=head1 AUTHOR

Davor Cubranic <cubranic@stat.ubc.ca>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by University of British Columbia.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
