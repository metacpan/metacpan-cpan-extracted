use warnings;
use strict;

package Wifty::UI;
use base qw/Template::Declare/;
use Template::Declare::Tags;

template simple => sub {

    html {
        head {};
        body { show 'private-content'; 
         show 'other-content'; };
        }

};

private template 'private-content' => sub {
    with( id => 'private-content-body' ), div {
        outs('This is my content');
    };

};


private template 'other-content' => sub {
    with( id => 'other-content-body' ), div {
        outs('This is other content');
    };

};


template 'private_not_found' => sub {
    show('does_not_exist');
};


package main;
use Template::Declare::Tags;
Template::Declare->init(dispatch_to => ['Wifty::UI']);

use Test::More tests => 14;
use Test::Warn;
require "t/utils.pl";

{
    my $simple = ( show('simple') );
   like( $simple,  qr'This is my content' );
   like( $simple,  qr'This is other content' );
    ok_lint($simple);
}
{
    my $simple;
    warning_like
      { $simple = ( show('does_not_exist') )||''; }
      qr/could not be found.*private/,
      "got warning";
    unlike( $simple , qr'This is my content' );
    ok_lint($simple);
}
{
    my $simple;
    warning_like
      { $simple = ( show('private_not_found') ); }
      qr/could not be found/,
      "got warning";
    unlike( $simple , qr'This is my content' );
    ok_lint($simple);
}
{
    my $simple;
    warning_like
      { $simple = ( show('private-content') ||''); }
      qr/could not be found.*private/,
      "got warning";
    unlike( $simple , qr'This is my content', "Can't call private templates" );
    ok_lint($simple);
}

{
    my $simple;
    warning_like
      { $simple = ( Template::Declare->show('private-content') ); }
      qr/could not be found.*private/,
      "got warning";
    is($simple, '');
}


1;
