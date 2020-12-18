# ABSTRACT: prints information about Hannover.pm to the screen

package PerlMongers::Hannover;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

use strict;
use warnings;
require Exporter;

@ISA = qw(Exporter);
@EXPORT_OK = qw(info);

use v5.10.1;
use Pod::Text;

sub info {
    my $parser = Pod::Text->new(sentence => 0, width => 78);
    open my $fh, "<", "README.pod" or die "$!";
    $parser->parse_from_file($fh);
    close $fh;
}

1;

# vim: expandtab shiftwidth=4 softtabstop=4
