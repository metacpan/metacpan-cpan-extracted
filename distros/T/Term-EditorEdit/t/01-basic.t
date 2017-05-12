#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most 'no_plan';

use Term::EditorEdit;
use Term::EditorEdit::Edit;

my ( $edit, $document );

$document = <<_END_;
A
B
c
 D
_END_

$edit = Term::EditorEdit::Edit->new( file => 0, document => $document );

is( $edit->document, $document ); 
is( $edit->content, $document );
is( $edit->preamble, undef );

is( $edit->join( undef, $document ), $document );
is( $edit->join( "1\n  # 2\n3",  "$document\n" ), <<_END_ );
1\n  # 2\n3
$document
_END_
$edit->separator( '---' );
is( $edit->join( "1\n  # 2\n3",  "$document\n" ), <<_END_ );
1\n  # 2\n3
---
$document
_END_

is( $edit->preamble, undef );
$edit->_initial_preamble( "1\n # 2\n 3" );
$edit->preamble_from_initial( "Xyzzy\n # Apple, Banana\n\n" );
is( $edit->preamble, "Xyzzy\n # Apple, Banana\n\n1\n # 2\n 3\n" );

throws_ok( sub { $edit->retry }, qr/^\s*__Term_EditorEdit_retry__\s*$/ );

$document = <<_END_;
---
A
B
C
_END_

is( $edit->join( $edit->split( $document ) ), <<_END_ )
---
A
B
C
_END_
