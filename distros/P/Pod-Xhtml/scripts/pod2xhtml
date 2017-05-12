#!/usr/bin/perl

use strict;
use Pod::Xhtml;
use Pod::Usage;
use Getopt::Long;

# Default options
my %opt = (index => 1, toplink => 'Top');
GetOptions(\%opt, qw(css=s toplink|backlink=s help index! infile:s outfile:s))
    || pod2usage();
pod2usage(-verbose => 2) if $opt{help};

my $toplink = $opt{toplink} ?
    sprintf '<p><a href="#TOP" class="toplink">%s</a></p>', $opt{toplink} : '';

my $parser = new Pod::Xhtml(
    MakeIndex  => $opt{index},
    TopLinks   => $toplink,
);
if ($opt{css}) {
    $parser->addHeadText(qq[<link rel="stylesheet" href="$opt{css}"/>]);
}

$parser->parse_from_file($opt{infile}, $opt{outfile});

__DATA__

=pod

=head1 NAME

pod2xhtml - convert .pod files to .xhtml files

=head1 SYNOPSIS

    pod2xhtml [--help] [--infile INFILE] [--outfile OUTFILE] [OPTIONS]

=head1 DESCRIPTION

Converts files from pod format (see L<perlpod>) to XHTML format.

=head1 OPTIONS

pod2xhtml takes the following arguments:

=over 4

=item *

--help - display help

=item *

--infile FILENAME
- the input filename. STDIN is used otherwise

=item *

--outfile FILENAME
- the output filename. STDOUT is used otherwise

=item *

--css URL
- Stylesheet URL

=item *

--index/--noindex
- generate an index, or not. The default is to create an index.

=item *

--toplink LINK TEXT
- set text for "back to top" links. The default is 'Top'.

=back

=head1 BUGS

See L<Pod::Xhtml> for a list of known bugs in the translator.

=head1 AUTHOR

P Kent E<lt>cpan _at_ bbc _dot_ co _dot_ ukE<gt>

=head1 COPYRIGHT

(c) BBC 2004. This program is free software; you can redistribute it and/or
modify it under the GNU GPL.

See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt

=head1 SEE ALSO

L<perlpod>, L<Pod::Xhtml>

=cut
