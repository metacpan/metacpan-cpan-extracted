package TAP::Convert::TET;

use warnings;
use strict;
use Carp;
use TAP::Parser;
use Scalar::Util qw/blessed/;
use POSIX qw/strftime uname/;

use version; our $VERSION = qv( '0.2.1' );

use constant TCC_VERSION     => '3.7a';
use constant TIME_FORMAT     => '%H:%M:%S';           # 20:09:33
use constant DATETIME_FORMAT => '%H:%M:%S %Y%m%d';    # 20:09:33 19961128

my %RESULT_TYPE = (
    0 => "PASS",
    1 => "FAIL",
    2 => "UNRESOLVED",
    3 => "NOTINUSE",
    4 => "UNSUPPORTED",
    5 => "UNTESTED",
    6 => "UNINITIATED",
    7 => "NORESULT",
);

BEGIN {
    for my $attr (
        qw(writer tcc_version time_format datetime_format program
        sequence)
      ) {
        no strict 'refs';
        *$attr = sub {
            my $self = shift;
            return $self->{$attr} unless @_;
            $self->{$attr} = shift;
            return;
        };
    }
}

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->_initialize( @_ );
    return $self;
}

sub _initialize {
    my $self = shift;
    my $args = shift || {};

    croak "The only argument to new must be a hash reference"
      unless 'HASH' eq ref $args;

    $self->writer(
        $self->_writer_for_output( delete $args->{output} || \*STDOUT ) );

    $self->tcc_version( delete $args->{tcc_version} || TCC_VERSION );
    $self->time_format( delete $args->{time_format} || TIME_FORMAT );
    $self->datetime_format( delete $args->{datetime_format}
          || DATETIME_FORMAT );
    $self->program( delete $args->{program} || __PACKAGE__ );
    $self->sequence( 1 );
}

sub _next_sequence { shift->{sequence}++ }

# Return a closure that outputs to the specified reference. Handles
# filehandles, objects that can print, array references, scalar
# references
sub _writer_for_output {
    my ( $self, $output ) = @_;

    if ( my $ref = ref $output ) {
        if ( $ref eq 'GLOB'
            || ( blessed $output && $output->can( 'print' ) ) ) {
            return sub { $output->print( @_, "\n" ) };
        }
        elsif ( $ref eq 'ARRAY' ) {
            return sub { push @$output, @_ };
        }
        elsif ( $ref eq 'SCALAR' ) {
            return sub { $$output .= $_[0] . "\n" };
        }
        else {
            croak "Don't know how to write to a $ref";
        }
    }
    else {
        croak "output must be a reference to an array, scalar or filehandle";
    }

    return;
}

sub write {
    my $self = shift;
    $self->writer->( join( '', @_ ) );
}

sub tet {
    my $self = shift;
    croak "TET lines have three parts"
      unless @_ == 3;
    $self->write( join( '|', @_ ) );
}

sub _timestamp {
    my $self = shift;
    return strftime( $self->time_format, localtime );
}

sub start {
    my $self = shift;

    $self->tet(
        0,
        join( ' ',
            $self->tcc_version, strftime( $self->datetime_format, localtime ) ),
        "User: "
          . ( $ENV{USER} || 'unknown' )
          . " ($<) "
          . $self->program
          . " Start"
    );

    $self->tet( 5, join( ' ', uname ), 'System Information' );
}

sub end {
    my $self = shift;
    $self->tet( 900, $self->_timestamp, 'TCC End' );
}

sub convert {
    my $self   = shift;
    my $parser = shift;

    my $seq  = $self->_next_sequence;
    my $name = shift || "unnamed test $seq";
    my $time = $self->_timestamp;

    $self->tet( 10, "$seq $name $time", 'TC Start' );

    while ( my $result = $parser->next ) {
        if ( $result->is_test ) {
            my $test_number = $result->number;

            $self->tet( 400, "$seq $test_number 1 $time", 'IC Start' );
            $self->tet( 200, "$seq $test_number $time",   'TP Start' );
            $self->tet( 520, "$seq $test_number 000000000 1 1",
                $result->as_string );

            my $rc =
                $result->has_skip ? 3
              : $result->has_todo ? 5
              : $result->is_ok    ? 0
              :                     1;

            $self->tet(
                220,
                "$seq $test_number $rc $time",
                $RESULT_TYPE{$rc} || 'UNKNOWN'
            );

            $self->tet( 410, "$seq $test_number 1 $time", 'IC End' );
        }
        else {
            # Ignore everything else for now
        }
    }

    $self->tet( 80, "$seq 0 $time", 'TC End' );
}

1;
__END__

=head1 NAME

TAP::Convert::TET - Convert TAP to TET

=head1 VERSION

This document describes TAP::Convert::TET version 0.2.1

=head1 SYNOPSIS

    use TAP::Convert::TET;
    use TAP::Parser;
    
    # Output to STDOUT by default
    my $converter = TAP::Convert::TET->new;

    $converter->start;

    my $parser = TAP::Parser->new( { source => $fh } );
    $converter->convert( $parser, 'test' );

    $converter->end;

=head1 DESCRIPTION

Simpleminded converter that turns TAP into a TET journal. See
L<http://tetworks.opengroup.org/> for more information about TET.

TET is used by the Linux Standard Base project. This module and the
associated tap2tet program are intended to help integrate Perl's tests
with LSB as part of an effort to incorporate Perl into LSB 3.2. See:

L<http://www.nntp.perl.org/group/perl.perl5.porters/2007/05/msg124480.html>

for more information.

=head1 INTERFACE 

=over

=item C<< new( $options ) >>

Create a new C<< TAP::Convert::TET >>. Options may be passed as a hash:

    my @buffer = ( );
    # Capture output in an array
    my $converter = TAP::Convert::TET->new( { output => \@buffer } );

Available options are:

=over

=item C<output>

A filehandle, array reference or scalar reference to output the
generated TET journal to. If a filehandle (or object that has a print
method) is passed TET will be output to it. If a reference to an array
is provided lines of TET will be appended to the array. If a scalar
reference is provided the generated TET will be appended to the string.

Defaults to STDOUT.

=item C<< tcc_version >>

The version of C<tcc> to pretend to be. Defaults to '3.7a'.

=item C<< time_format >>

The format string to use for timestamps. Defaults to '%H:%M:%S'.

=item C<< datetime_format >>

The format string to use for date and time fields. Defaults to
'%H:%M:%S %Y%m%d'.

=item C<< program >>

The name of the program generating the TET output. Defaults to
'TAP::Convert::TET'.

=back

=item C<< start >>

Output the TET preamble. Call this before any calls to C<convert>.

=item C<< end >>

Output the TET postamble. Call this after any calls to C<convert>.

=item C<< convert( $parser, $name ) >>

Read test results from a C<TAP::Parser> instance and output them in TET
format. The optional C<$name> parameter may be used to provide the name
of the test script that was the original source of the results.

Convert may be called more than once to merge multiple TAP transcripts
into a single TET journal.

=item C<< write( $string ) >>

Write a line to the TET output stream. Internal use.

=item C<< tet( $code, $data, $text ) >>

Write a formatted TET journal entry to the output stream.

=back

=head2 Accessors

=over

=item C<< datetime_format >>

Get or set the format used for date/time strings.

=item C<< time_format >>

Get or set the time format.

=item C<< tcc_version >>

Get or set the version of C<tcc> we pretend to be.

=item C<< program >>

Get or set the program we pretend to be.

=item C<< sequence >>

Get or set the test sequence number.

=item C<< writer >>

Get or set the closure that is called to handle output.

=back

=head1 CONFIGURATION AND ENVIRONMENT
  
TAP::Convert::TET requires no configuration files or environment variables.

=head1 DEPENDENCIES

    TAP::Parser 0.51

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-tap-convert-tet@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 REFERENCES

=over

=item The TETware User Guide, Appendix C, TETware journal lines

L<http://tetworks.opengroup.org/documents/3.3/uguide.pdf>

=item tjreport

L<http://ftp.freestandards.org/pub/lsb/test_suites/released-3.0.0/source/runtime/tjreport-1.4.tar.gz>

=back

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Andy Armstrong C<< <andy@hexten.net> >>. All
rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
