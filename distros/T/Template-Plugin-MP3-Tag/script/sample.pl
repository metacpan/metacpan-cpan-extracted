#! /usr/bin/perl -w

# ----------------------------------------------------------------------
# $Id: sample.pl,v 1.2 2006/04/18 17:38:07 travail Exp $
# ----------------------------------------------------------------------

use strict;
use warnings;
use Template;

use Data::Dumper;

main();

sub main {
    my ( $file ) = @_;

    my $tt = Template->new(
        INCLUDE_PATH => '../template/'
    );

    my @file = grep { chomp $_ } `find /home/public/trickster/mp3/AIR -type f -name *.mp3`;
    my $vars = {
        files => \@file,
    };
    my $result = '';
    $tt->process( 'sample.tt', $vars, $result );
    print $result;
}
