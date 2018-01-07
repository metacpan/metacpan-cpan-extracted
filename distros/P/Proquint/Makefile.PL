#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use ExtUtils::MakeMaker::CPANfile;
use Pod::Text;

WriteMakefile(
    NAME         => 'Proquint',
    ABSTRACT     => 'Convert to and from proquints',
    AUTHOR       => 'Mark Lawrence <nomad@null.net>',
    VERSION_FROM => 'lib/Proquint.pm',
    LICENSE      => 'gpl_3',
    META_ADD     => {
        resources => {
            repository => 'https://github.com/mlawren/p5-Proquint',
        }
    },
#    META_MERGE => {
#        no_index => {
#            package => [qw(Proquint::Boolean)],
#        },
#    },
);

if ( -e '.git' ) {
    my $parser = Pod::Text->new( sentence => 0 );

    # Read POD from file.pod and write to file.txt.
    $parser->parse_from_file( 'lib/Proquint.pm', 'README' );
}

