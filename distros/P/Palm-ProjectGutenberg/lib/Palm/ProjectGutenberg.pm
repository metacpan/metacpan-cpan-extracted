package Palm::ProjectGutenberg;

use warnings;
use strict;

use Palm::Doc;

require Exporter;

use vars qw($VERSION @EXPORT_OK @ISA);

$VERSION = '1.02';
@ISA = qw(Exporter);
@EXPORT_OK = qw(pg2pdb);

=head1 NAME

Palm::ProjectGutenberg - convert PG text files to Palm Doc format

=head1 DESCRIPTION

This is a very simple wrapper around Palm::Doc that re-formats files
from Project Gutenberg so that they look better on a small screen.
It does this by removing line breaks apart from at paragraph breaks.

You are unlikely to want to use this from within your own code, it
really ony exists for the suporting pg2pdb script to use, which is also
distributed and installed with this module.

=head1 SYNOPSIS

    use Palm::ProjectGutenberg qw(pg2pdb);
    pg2pdb($title, $infile, $outfile);

=head1 FUNCTIONS

There is only one function, which can be exported if you wish.

=head2 pg2pdb

This takes three parameters, all of them compulsory.  They are, in
order, the e-book's title, the name of a file containing the plain-text,
and the name of a file to write the encoded version to.

=head1 LIMITATIONS, BUGS and FEEDBACK

This is subject to the limitations of Palm::Doc - eg that all documents
produced are compressed.

There is no way of passing texts back and forth in variables or as
file handles - it's filenames or not at all.  This is because it's
really only intended for use by the pg2pdb script.  If you want that
extra functionality, please provide a patch with tests.

I welcome feedback about my code, including constructive criticism.
Bug reports should be made using L<http://rt.cpan.org/> or by email,
and should include the smallest possible chunk of code, along with
any necessary text data, which demonstrates the bug.  Ideally, this
will be in the form of files which I can drop in to the module's
test suite.

=head1 SEE ALSO

L<Palm::Doc>

L<http://gutenberg.org>

=head1 AUTHOR, COPYRIGHT and LICENCE

David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

Copyright 2009 David Cantrell E<lt>david@cantrell.org.ukE<gt>

This software is free-as-in-speech software, and may be used,
distributed, and modified under the terms of either the GNU
General Public Licence version 2 or the Artistic Licence.  It's
up to you which one you use.  The full text of the licences can
be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=head1 CONSPIRACY

This module is also free-as-in-mason software.

=cut

sub pg2pdb {
    local $/ = undef;
    my($title, $infile, $outfile) = @_;
    my $pdb = Palm::Doc->new();
    open(my $infh, $infile) || die("Couldn't open $infile\n");
    my $text = <$infh>;
    close($infh);
    $text =~ s/\r//g; # DOS line-endings MUST DIE
    $text =~ s/\n\n+/{PARABREAK}/g;
    $text =~ s/\n/ /g;
    $text =~ s/{PARABREAK}/\n\n/g;

    $pdb->text($text);
    $pdb->{name} = $title;
    $pdb->Write($outfile);
}

1;
