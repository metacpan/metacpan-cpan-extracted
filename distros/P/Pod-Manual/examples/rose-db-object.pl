#!/usr/bin/perl 

use strict;
use warnings;

use Pod::Manual;

my $manual = Pod::Manual->new({ title => 'Rose::DB::Object' });

$manual->add_chapters( qw/ Rose::DB::Object::Tutorial 
                           Rose::DB::Tutorial
                           Rose::DB::Object
                           Rose::DB::Object::Metadata
                           Rose::DB::Object::Manager
                           Rose::DB::SQLite
                         / );

my $pdf_file = 'rose-db-object_manual.pdf';
$manual->save_as_pdf( $pdf_file );

print "pdf document '$pdf_file' created\n";
