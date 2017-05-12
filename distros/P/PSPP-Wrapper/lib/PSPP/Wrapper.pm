package PSPP::Wrapper;

use 5.005;
use warnings;
use strict;
use IPC::Run qw( run timeout );
use Text::CSV_XS;
use File::Temp;
use Cwd;
use Carp;

=head1 NAME

PSPP::Wrapper - Wrapper for the pspp command-line interface

=head2 DESCRIPTION

PSPP is a program for statistical analysis of sampled data. 
It is a Free replacement for the proprietary program SPSS, and appears very similar to it with a few exceptions.
PSPP is particularly aimed at statisticians, social scientists and students requiring fast convenient analysis of sampled data.

For more information, see L<http://www.gnu.org/software/pspp/>

You need to install the PSPP binary to use this module.

This module currently only contains one useful method, L<save>, which makes it easy to generate PSPP/SPSS-compatible .sav files.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    # Generate a SPSS-compatible .sav file from an array of data
    my $pspp     = PSPP::Wrapper->new( verbose => 0 );
    my $rows     = [
        [ "AMC Concord",   22, 2930, 4099 ],
        [ "AMC Pacer",     17, 3350, 4749 ],
        [ "AMC Spirit",    22, 2640, 3799 ],
        [ "Buick Century", 20, 3250, 4816 ],
        [ "Buick Electra", 15, 4080, 7827 ],
    ];
    $pspp->save(
        variables => 'make (A15) mpg weight price',
        rows      => $rows,
        outfile   => $outfile1,
    ) or warn "An error occurred";

    # Generate a csv file ourselves from $rows
    my $csv = Text::CSV_XS->new( { binary => 1 } );
    my $fh = File::Temp->new( SUFFIX => '.csv' );
    for my $row (@$rows) {
        $csv->print( $fh, $row );
        print $fh "\n";
    }
    $fh->close;
    $pspp->save(
        variables => 'make (A15) mpg weight price',
        infile    => $fh->filename,
        outfile   => $outfile2,
    ) or warn "An error occurred";

=head1 methods

=head2 new

Constructor. Acceptions the following options:

=over 4

=item verbose

=item timeout

The L<IPC::Run::run> timeout value

=item pspp_binary

The location of the C<pspp> binary. Defaults to C<pspp>.

=back

=cut

sub new {
    my $invocant = shift;
    my $class = ref $invocant || $invocant;
    bless {
        pspp_binary => 'pspp',
        timeout     => 10,
        verbose     => 0,
        @_,
    }, $class;
}

=head2 save

Generate a PSPP (and hence SPSS) compatible .sav file

You must specify either C<rows> or C<infile>. Accepts the following options:

=over 4

=item outfile

The name of the file to generate (defaults to out.sav)

=item variables

The PSPP/SPSS variables definition

=item rows

An array reference of rows to include in the data (optional)

=item infile

A data-file to read from (optional)

=back

=cut

sub save {
    my $self      = shift;
    my %opts      = @_;
    my $outfile   = $opts{outfile} || 'out.sav';
    my $variables = $opts{variables} or croak "Mandatory param: variables not supplied";
    my $rows      = $opts{rows};
    my $infile    = $opts{infile};
    if ( !$rows && !$infile ) {
        croak "You must specify either an infile or a rows arrayref";
    }

    my $fh;    # in outer scope so that tmp file doesn't disappear to early
    if ( !$infile ) {

        # Infile not provided, so use CSV_XS to turn $rows into tmp infile
        my $csv = Text::CSV_XS->new( { binary => 1 } );
        $fh = File::Temp->new( SUFFIX => '.csv' );
        for my $row (@$rows) {
            $csv->print( $fh, $row );
            print $fh "\n";
        }
        $fh->close;
        $infile = $fh->filename;
    }

    # Generate PSPP program
    my $syntax = <<END_SYNTAX;
DATA LIST LIST FILE="$infile"
 / $variables .
LIST.
SAVE OUTFILE="$outfile".
END_SYNTAX

    print "Syntax:\n$syntax\n\n" if $self->verbose;

    # Run in a temp dir so that pspp-generated files don't clash
    my $cwd = cwd();
    my $tmpdir = File::Temp->newdir();
    chdir $tmpdir;
    
    # Use IPC::Run to call PSPP binary
    my $pspp_binary = $self->{pspp_binary};
    run [$pspp_binary], \$syntax, \( my $out ), \( my $err ), timeout( $self->{timeout} )
        or croak "$pspp_binary: $?";
    carp $err if $err;
    print "Output:\n$out\n" if $self->verbose;
    
    # Clean up
    chdir $cwd;
    return -e $outfile;
}

=head2 verbose

Returns true if the verbose flag is set

=cut

sub verbose { return $_[0]->{verbose} }

=head1 AUTHOR

Patrick Donelan, C<< <pdonelan at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-pspp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PSPP::Wrapper>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PSPP::Wrapper


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=PSPP::Wrapper>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/PSPP::Wrapper>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/PSPP::Wrapper>

=item * Search CPAN

L<http://search.cpan.org/dist/PSPP::Wrapper/>

=back

=head1 SEE ALSO

For a module that actually groks PSPP (rather than just wrapping it) and hence allows you to read/write 
PSPP and/or SPSS native files, see: L<PSPP>

=head1 ACKNOWLEDGEMENTS

L<http://www.gnu.org/software/pspp/>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Patrick Donelan, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
