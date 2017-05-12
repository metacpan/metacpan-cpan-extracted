#!/usr/bin/perl
use strict;
use warnings;
use SVN::Dump;

die "svndump_replace_author.pl <from> <to> [file]" if @ARGV < 2;

my ( $from, $to ) = splice( @ARGV, 0, 2 );

my $dump = SVN::Dump->new( { file => @ARGV ? $ARGV[0] : '-' } );

while ( my $rec = $dump->next_record() ) {
    if (   $rec->type() eq 'revision'
        && $rec->get_header( 'Revision-number' ) != 0
        && $rec->get_property('svn:author') eq $from )
    {
        $rec->set_property( 'svn:author' => $to );
    }
    print $rec->as_string();
}

