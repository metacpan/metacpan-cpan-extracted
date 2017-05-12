package TeX::AutoTeX::ConcatPDF;
#
# $Id: ConcatPDF.pm,v 1.2.2.7 2011/01/27 18:56:29 thorstens Exp $
# $Revision: 1.2.2.7 $
# $Source: /cvsroot/arxivlib/arXivLib/lib/TeX/AutoTeX/ConcatPDF.pm,v $
#
# $Date: 2011/01/27 18:56:29 $
# $Author: thorstens $
#
use strict;
### use warnings;

use version; our $VERSION = qv('0.94');
use parent qw(Exporter);
our @EXPORT_OK = qw(concatenate_pdf);

use CAM::PDF;
use Carp qw(croak carp);

sub concatenate_pdf {
  my ($combinedfile, $listref) = @_;

  return if @{$listref} < 2;

  my $combineddoc = CAM::PDF->new(shift @{$listref}) ||
    croak $CAM::PDF::errstr;

  foreach my $file (@{$listref}) {
    my $doc = CAM::PDF->new($file) || croak $CAM::PDF::errstr;
    carp 'Appending ', $doc->numPages(),
      ' page(s) to original ',$combineddoc->numPages(), ' page(s)';
    $combineddoc->appendPDF($doc);
  }
  $combineddoc->preserveOrder();
  $combineddoc->clearAnnotations();
  $combineddoc->cleanoutput($combinedfile);
  return;
}

1;

__END__

=for stopwords PDF Schwander arxiv.org perlartistic pdflatex pdfpages arXiv .pdf www-admin

=head1 NAME

TeX::AutoTeX::ConcatPDF - concatenate a list of PDF files

=head1 VERSION

This documentation refers to TeX::AutoTeX::ConcatPDF version 0.9

=head1 SYNOPSIS

use TeX::AutoTeX::ConcatPDF qw(concatenate_pdf);

stamp_pdf($pdfoutfile, $list_ref);

=head1 DESCRIPTION

This module creates a PDF file which consists of the concatenation of the
list of PDF files passed in.

There are many tools which provide similar functionality. Most of them seem
to mangle annotations, in particular hyperlinks, in confusing ways.

The combination of pdflatex and pdfpages, which arXiv uses in production, does
not carry forward hyperlinks, which is preferable to incorrect hyperlinks.

An easy alternative to the fairly involved procedure used here is a
straightforward system call to C<ghostscript> with appropriate arguments,
e.g.

C<gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=combined.pdf file1.pdf file2.pdf>

with the mentioned drawbacks for the resulting file B<combined.pdf>.

=head1 SUBROUTINES/METHODS

The single subroutine exported by this package is C<concatenate_pdf>.

=head2 concatenate_pdf

C<concatenate_pdf> takes 2 arguments, the name of a file to which the
generated PDF file will be written, and a reference to a list, which contains
the ordered list of PDF files to be concatenated.

=head1 DIAGNOSTICS

croak and die

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

CAM::PDF

=head1 INCOMPATIBILITIES

none

=head1 BUGS AND LIMITATIONS

C<CAM::PDF> sometimes chokes on large and/or complex PDF files.

Please report bugs to L<www-admin|http://arxiv.org/help/contact>

=head1 AUTHOR

Thorsten Schwander <schwande@cs.cornell.edu>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 - 2011 arxiv.org L<http://arxiv.org/help/contact>

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See
L<perlartistic|http://www.opensource.org/licenses/artistic-license-2.0.php>.

=cut
