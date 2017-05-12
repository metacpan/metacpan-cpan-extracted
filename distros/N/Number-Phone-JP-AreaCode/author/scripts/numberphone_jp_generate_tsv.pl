#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Number::Phone::JP::AreaCode::MasterData::Word2TSV;

my $tsvfile = $ARGV[0] or help();

if ($tsvfile) {
    generate_tsv($tsvfile);
}

sub generate_tsv {
    my $tsvfile = shift;
    my $obj = Number::Phone::JP::AreaCode::MasterData::Word2TSV->new;
    my $text = $obj->to_tsv;
    my ($fh, $guard) = $obj->_openfile('>:utf8', $tsvfile);
    print $fh $text;
}

sub help {
    my $text = do {local $/; <DATA>};
    my $filename = __FILE__;
    $text =~ s/_SCRIPT_/$filename/g;
    print $text;
}

__DATA__
usage
 _SCRIPT_ output.tsv

