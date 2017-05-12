use warnings;
use strict;
use lib qw(lib);
use Test::More;
use SNMP::Effective;

plan tests => 13;

{
    my $effective = SNMP::Effective->new;
    my $hostlist = $effective->hostlist;
    my $varlist = $effective->_varlist;
    my $host;

    # adding hosts to a clean $effective object
    $effective->add( desthost => '127.0.0.1' );
    $effective->add( desthost => '127.0.0.2' );
    is($hostlist->length, 2, 'got two hosts');
    is(@$varlist, 0, 'got two hosts');

    # adding requests to all hosts
    $effective->add( getnext => '1.2.3', walk => ['1.2.3'] );
    $effective->add( ignored_option => '1.2.3' );
    is(@$varlist, 2, 'two requests added to $effective');
    is(@{ $hostlist->{'127.0.0.1'} }, 2, 'two requests added to 127.0.0.1');
    is(@{ $hostlist->{'127.0.0.2'} }, 2, 'two requests added to 127.0.0.2');

    # adding request to a specific host
    $effective->add( desthost => ['127.0.0.2'], getnext => '2.3.4' );
    is(@{ $hostlist->{'127.0.0.2'} }, 3, 'another request added to just 127.0.0.2');
    is(@$varlist, 2, 'another request for 127.0.0.2, not added to $effective');

    # updating arg
    $effective->add( desthost => '127.0.0.1', arg => { Community => 'foo-community' } );
    is($hostlist->{'127.0.0.1'}->arg->{'Community'}, 'foo-community', 'update Community for 127.0.0.1');
    is(@$varlist, 2, '$effective varlist still has two elements after Community update');
    is(@{ $hostlist->{'127.0.0.1'} }, 2, '127.0.0.1 varlist still has two elements after Community update');

    # setting default community and heap
    $effective->add(
        arg => { Community => 'default-community' },
        heap => { the_answer => 42 },
    );

    # adding new host
    $effective->add( desthost => '127.0.0.3' );
    is(@{ $hostlist->{'127.0.0.3'} }, 2, '127.0.0.3 varlist got two elements from $effective');
    is($hostlist->{'127.0.0.3'}->arg->{'Community'}, 'default-community', 'Community for 127.0.0.3 is from $effective');
    is($hostlist->{'127.0.0.3'}->heap->{'the_answer'}, 42, 'heap for 127.0.0.3 is from $effective');
}
