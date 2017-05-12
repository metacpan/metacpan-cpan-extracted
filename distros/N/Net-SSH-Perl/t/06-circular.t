#!/usr/bin/perl

# $Id: 06-circular.t,v 1.4 2008/10/02 20:46:44 turnstep Exp $

use strict;
use warnings;

use Net::SSH::Perl;

use Test;
plan tests => 1;

{
    package FooBar;

    my $count = 0;
    sub DESTROY { $count++ }

    sub count { $count }
}

# Login doesn't need to succeed for this test to work
if ( $ENV{PERL_SSH_HOST} &&
     $ENV{PERL_SSH_USER} &&
     $ENV{PERL_SSH_PASSWORD} )
{
    {
        my $ssh = Net::SSH::Perl->new( $ENV{PERL_SSH_HOST}, protocol => 2 );
        $ssh->login( $ENV{PERL_SSH_USER}, $ENV{PERL_SSH_PASSWORD} );

        $ssh->{__foobar__} = bless {}, 'FooBar';
    }

    ok( FooBar->count, 1, "one object destroyed" );
}
else
{
    ok( 1, 1, "cannot test without login" );
}
