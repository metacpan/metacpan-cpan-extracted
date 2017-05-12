use strict;
use warnings;

# for the time being
use Test::More qw( no_plan );

use Template::JavaScript;

my $ctx = Template::JavaScript->new(
    bind => [
        [
            iloveyou => {
                banana => 1,
                rama => 2,
                cazzi_mazzi => 0,
            }
        ],
    ],
);

my $three_loops = <<'TEMPLATE';
header

% if( iloveyou.banana ){
  <h1>banana active</h1>
% } else {
  (no banana)
% }

% if( typeof cazzi != 'undefined' && cazzi.mazzi );
% else say('nothing here');

% var foobar = function( me ){
%    say ("I am foobar and <" + me + ">");
% };
% var baz = function ( sumthin ){ };

<footeR>
TEMPLATE

$ctx->output( \my $out );

$ctx->tmpl_string( $three_loops );

$ctx->run;

is_deeply( $out, <<'OUTPUT', 'can do variable includes' );
header

  <h1>banana active</h1>

nothing here


<footeR>
OUTPUT


# :)


