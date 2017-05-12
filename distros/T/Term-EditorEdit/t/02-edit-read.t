#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;

use Term::EditorEdit;
use Term::EditorEdit::Edit;
use IO::File;

my ( $edit, $document );

$document = <<_END_;
A
B
c
 D
_END_

$Term::EditorEdit::Edit::Test_edit = sub {
    my $tmp = shift;
    my $tmpw = IO::File->new( $tmp->filename, 'w' );
    $tmpw->print( "Xyzzy\n" );
    $tmpw->flush;
    $tmpw->close;
};

$document = Term::EditorEdit->edit( document => $document );

is( $document, "Xyzzy\n" );

done_testing;
