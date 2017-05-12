#Courtesy of chromatic
#http://search.cpan.org/~chromatic/Test-Kwalitee/lib/Test/Kwalitee.pm
 
#Homepage: https://logiclab.jira.com/wiki/display/OPEN/Test-Kwalitee

# $Id$
 
use strict;
use warnings;
use Test::More;
use Env qw($RELEASE_TESTING);
eval { require Test::Kwalitee; };
if ($@) {
    plan( skip_all => 'Test::Kwalitee not installed');
} elsif ($RELEASE_TESTING) {
    Test::Kwalitee->import();
} else {
    plan(skip_all => 'tests for release testing, enable using RELEASE_TESTING');
}