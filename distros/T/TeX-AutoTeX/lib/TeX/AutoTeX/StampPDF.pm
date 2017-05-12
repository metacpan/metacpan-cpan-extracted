package TeX::AutoTeX::StampPDF;

#
# $Id: StampPDF.pm,v 1.9.2.7 2011/01/27 18:42:29 thorstens Exp $
# $Revision: 1.9.2.7 $
# $Source: /cvsroot/arxivlib/arXivLib/lib/TeX/AutoTeX/StampPDF.pm,v $
#
# $Date: 2011/01/27 18:42:29 $
# $Author: thorstens $
#

use strict;
### use warnings;
use Carp qw(cluck carp);

our ($VERSION) = '$Revision: 1.9.2.7 $' =~ m{ \$Revision: \s+ (\S+) }x;

use parent qw(Exporter);
our @EXPORT_OK = qw(stamp_pdf);
use CAM::PDF;

sub stamp_pdf {
  my ($file, $stampref) = @_;

  if (!(-r $file && ref $stampref eq 'ARRAY')) {
    #FIXME: pod2usage;
    throw TeX::AutoTeX::FatalException "must provide pdf file and stamp contents\n";
  }

  # 6 * 72 - 1/2 * stringlength * 10
  # (10 = approx average char width in 20pt Times-Roman)
  my $yoffset = 432 - 5 * length $stampref->[0];

# minimal arXiv stamp used as a page overlay in grayscale
  my $pdfstamp = <<"EOSTAMP";
q
0.5 G 0.5 g
BT
/arXivStAmP 20 Tf 0 1 -1 0 32 $yoffset Tm
($stampref->[0])Tj
ET
Q
EOSTAMP

  rename($file, "$file.bk") || throw TeX::AutoTeX::FatalException q{couldn't backup PDF file};

  eval {
    my $doc = CAM::PDF->new("$file.bk") || cluck "$CAM::PDF::errstr\n";
    if (!$doc->canModify()) {
      throw TeX::AutoTeX::FatalException "This PDF forbids modification\n";
    }

    $doc->appendPageContent(1, $pdfstamp);
    $doc->addFont(1, 'Times-Roman', 'arXivStAmP') || cluck "$CAM::PDF::errstr\n";
    $doc->preserveOrder();
    $doc->cleanoutput($file) || cluck "$CAM::PDF::errstr\n";
    1;
  } or do {
    rename("$file.bk", $file) || carp 'woe is me, now that failed';
    throw TeX::AutoTeX::FatalException "stamp operation did not complete\n";
  };
  if ($@) {
    rename("$file.bk", $file) || carp 'woe is me, now that failed';
    throw TeX::AutoTeX::FatalException "an error occurred during stamp operation, reverted to original file\n";
  }
  unlink "$file.bk";
  return 0;
}

1;

__END__

=for stopwords PDF PDF-only arXiv arxiv.org pdflatex FontSize writeable euid www-admin Schwander arxiv perlartistic

=head1 NAME

TeX::AutoTeX::StampPDF - watermark PDF files

=head1 VERSION

This documentation refers to TeX::AutoTeX::StampPDF version 1.9.2.5

=head1 SYNOPSIS

use TeX::AutoTeX::StampPDF qw(stamp_pdf);

stamp_pdf($pdffile, $array_ref);

=head1 DESCRIPTION

This module modifies a given PDF file. It prints an arbitrary text string
(within certain length limits) onto the left edge of the 1st page of a well
formed PDF file.

This is intended to be used to put the arXiv stamp onto PDF-only and pdflatex
submissions, but any type of "watermark" text string is possible.

Non adjustable settings are:

Font: Times-Roman

FontSize: 20

X-Y offsets

=head1 SUBROUTINES/METHODS

The single subroutine exported by this package is C<stamp_pdf>.

=head2 stamp_pdf

C<stamp_pdf> takes 2 arguments, the name of a PDF file, which must be apt to be opened C<r/w>, and a reference to an array, which contains a text string in its C<[0]th> element. A backup file of the original PDF is created temporarily, thus the current working directory has to be writeable by euid.

The reason for the second argument to be a reference to an array is that we intend to add an associated hyperlink to the stamp, which will be paired with the C<[0]> element. Current limitations of CAM::PDF make this difficult.

=head1 DIAGNOSTICS

throw a TeX::AutoTeX::FatalException

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

CAM::PDF

=head1 INCOMPATIBILITIES

none

=head1 BUGS AND LIMITATIONS

The placement of the stamp is tuned to US letter size paper and dimensions
are hard-coded. This is easily adaptable to other paper sizes if necessary.

Please report bugs to L<www-admin|http://arxiv.org/help/contact>

=head1 AUTHOR

Thorsten Schwander <schwande@cs.cornell.edu>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007 - 2011 arxiv.org L<http://arxiv.org/help/contact>

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See
L<perlartistic|http://www.opensource.org/licenses/artistic-license-2.0.php>.

=cut
