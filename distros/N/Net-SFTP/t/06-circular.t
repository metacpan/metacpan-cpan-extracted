# $Id: 06-circular.t,v 1.3 2003/12/03 15:39:44 autarch Exp $

use strict;

use Net::SFTP;

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
        my $ssh = Net::SFTP->new( $ENV{PERL_SSH_HOST} );

        $ssh->{__foobar__} = bless {}, 'FooBar';
    }

    ok( FooBar->count, 1, "one object destroyed" );
}
else
{
    ok( 1, 1, "cannot test without login" );
}
