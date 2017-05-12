package Plucene::SearchEngine::Index::XLS;
use strict;
use warnings;
our $VERSION = '0.001'; # VERSION
# ABSTRACT: a Plucene backend for indexing Microsoft Excel spreadsheets

use parent qw(Plucene::SearchEngine::Index::Base);

__PACKAGE__->register_handler('application/xls', '.xls');
use File::Temp qw/tmpnam/;
use Spreadsheet::ParseExcel;



sub gather_data_from_file {
    my ($self, $file) = @_;
    return unless $file =~ m/\.xls$/;

    if ($file =~ m/\.xls$/) {    # Process only xls file data.
        my $txtfile = tmpnam();
        _exceltotext($file, $txtfile);
        $file = $txtfile;
    }
    my $in;
    if (exists $self->{encoding}) {
        my $encoding = $self->{encoding}{data}[0];
        open $in, "<:encoding($encoding)", $file
            or die "Couldn't open $file: $!";
    } else {
        open $in, '<', $file
            or die "Couldn't open $file: $!";
    }
    while (<$in>) {
        $self->add_data('text' => 'UnStored' => $_);
    }
    unlink $file; #Remove the  text file, part of maintenance.
    return $self;
}

sub _exceltotext {
    ##This is the standard code taken from SpreadSheet::ParseExcel Module.
    my  $excel = shift;
    my  $output = shift;

    my $oExcel = Spreadsheet::ParseExcel->new();
    open my $txt_out, '>', $output or die "Not able to open file : $!";

    my $oBook = $oExcel->Parse($excel);

    print $txt_out "FILE  :", $oBook->{File} , "\n";
    print $txt_out "COUNT :", $oBook->{SheetCount} , "\n";

    print $txt_out "AUTHOR:", $oBook->{Author} , "\n"
        if defined $oBook->{Author};

    for(my $iSheet=0; $iSheet < $oBook->{SheetCount} ; $iSheet++) {
        my $oWkS = $oBook->{Worksheet}[$iSheet];
        print OUTPUT  $oWkS->{Name}, "\n";
        for(my $iR = $oWkS->{MinRow} ;
            defined $oWkS->{MaxRow} && $iR <= $oWkS->{MaxRow} ;
             $iR++)
        {
            for(my $iC = $oWkS->{MinCol} ;
                defined $oWkS->{MaxCol} && $iC <= $oWkS->{MaxCol} ;
                $iC++)
            {
                my $oWkC = $oWkS->{Cells}[$iR][$iC];
                print OUTPUT $oWkC->Value, "\n" if($oWkC);
            }
        }
    }
    close($txt_out);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Plucene::SearchEngine::Index::XLS - a Plucene backend for indexing Microsoft Excel spreadsheets

=head1 VERSION

version 0.001

=head1 DESCRIPTION

This backend converts the .xls file into text file and the text file
is used similar to Text.pm module.

B<This code is not currently actively maintained.>

=head1 METHODS

=head2 gather_data_from_file

Overrides the method from L<Plucene::SearchEngine::Index::Base>
to provide XLS parsing.

=head1 NAME

Plucene::SearchEngine::Index::Xls - Backend for plain text files

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Plucene::SearchEngine::Index::MSOffice/>.

=head1 SOURCE

The development version is on github at L<http://github.com/doherty/Plucene-SearchEngine-Index-MSOffice>
and may be cloned from L<git://github.com/doherty/Plucene-SearchEngine-Index-MSOffice.git>

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/doherty/Plucene-SearchEngine-Index-MSOffice/issues>.

=head1 AUTHORS

=over 4

=item *

Sopan Shewale <sopan.shewale@gmail.com>

=item *

Mike Doherty <doherty@pythian.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Sopan Shewale <sopan.shewale@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
