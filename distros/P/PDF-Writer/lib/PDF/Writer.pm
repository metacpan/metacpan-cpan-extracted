package PDF::Writer;

use strict;
use warnings;

our $VERSION = '0.06';

our $Backend;

sub import {
    my $class = shift;
    $Backend = shift if @_;
    require "PDF/Writer/$Backend.pm" if $Backend && $Backend eq 'mock';
}

sub new {
    my $class = shift;

    my $backend = $Backend || (
        eval { require PDF::API2; 1 } ? 'pdfapi2' :
        eval { require pdflib_pl; 1 } ? 'pdflib' : undef
    );

    if ($backend) {
        require "PDF/Writer/$backend.pm";
    }
    else {
        die "No supported PDF backends found!";
    }

    $class .= "::$backend";
    return $class->new(@_);
}

1;
__END__

=head1 NAME

PDF::Writer - PDF writer abstraction layer

=head1 VERSION

This document describes version 0.05 of PDF::Writer, released Oct 25,
2005.

=head1 SYNOPSIS

  use PDF::Writer;

  # Or, to explicitly specify a back-end ...
  use PDF::Writer 'pdflib';
  use PDF::Writer 'pdfapi2';
  use PDF::Writer 'mock';

  my $writer = PDF::Writer->new;

=head1 DESCRIPTION

This is a generalized API that allows a module that generates PDFs to
transparently target multiple backends without changing its code. The
currently supported backends are:

=over 4

=item * PDF::API2

Available from CPAN

=item * PDFlib (versions 3+)

Available from L<http;//www.pdflib.com>. There is both a pay and free version.
PDF::Writer will work with both, within their limitations. Please see the
appropriate documentation for details.

=item * Mock

This allows modules that target PDF::Writer to write their tests against a
mock interface. Please see L<PDF::Writer::mock> for more information.

=back

If both PDF::API2 and pdflib_pl are available, PDF::API2 is preferred. If
neither is available, a run-time exception will be thrown. You must explicitly
load the PDF::Writer::mock driver, if you wish to use it.

=head1 METHODS

=over 4

=item * B<new()>

This acts as a factory, loading the appropriate PDF::Writer driver.

=back

=head1 CODE COVERAGE

We use L<Devel::Cover> to test the code coverage of our tests. Below is the
L<Devel::Cover> report on this module's test suite.

=head1 AUTHORS

Originally written by:

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

Currently maintained by:

Rob Kinyon E<lt>rob.kinyon@iinteractive.comE<gt>

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

Thanks to Infinity Interactive for generously donating our time.

=head1 COPYRIGHT

Copyright 2004, 2005 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
