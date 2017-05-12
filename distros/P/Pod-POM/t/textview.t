#!/usr/bin/perl -w                                         # -*- perl -*-

use strict;
use lib qw( ./lib ../lib );
use Pod::POM;
use Pod::POM::View::Text;
use Pod::POM::Test;

ntests(2);

my $file   = -d 't' ? 't/test.pod' : 'test.pod';
my $parser = Pod::POM->new();
my $pom    = $parser->parse_file($file)
    || die $parser->error();

assert( $pom );

$Pod::POM::DEFAULT_VIEW = 'Pod::POM::View::Text';

#print $pom;

# yet another crap test
match( length $pom, 1825 );

