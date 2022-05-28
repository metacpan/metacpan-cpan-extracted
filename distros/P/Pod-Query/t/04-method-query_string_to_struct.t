#!perl
use v5.16;
use strict;
use warnings;
use Test::More;

#TODO: Remove this debug code !!!
use feature qw(say);
use Mojo::Util qw(dumper);

BEGIN {
   use_ok( 'Pod::Query' ) || print "Bail out!\n";
}

diag( "Testing Pod::Query $Pod::Query::VERSION, Perl $], $^X" );

my @cases = (

   # In use - Original.
   {
      name                  => "Original - find_title",
      query_string          => q(head1=NAME[0]/Para[0]),
      expected_query_struct => [
         {
            tag  => "head1",
            text => "NAME",
            nth  => 0,
         },
         {
            tag => "Para",
            nth => 0,
         },
      ],
   },
   {
      name                  => "Original - find_method",
      query_string          => q(~^head\d$=method\b[0]**),
      expected_query_struct => [
         {
            tag      => qr/^head\d$/,
            text     => 'method\b',
            nth      => 0,
            keep_all => 1,
         },
      ],
   },
   {
      name                  => "Original - find_method_summary",
      query_string          => q(~^head\d$=method\b[0]/~(Data|Para)[0]),
      expected_query_struct => [
         {
            tag  => qr/^head\d$/,
            text => 'method\b',
            nth  => 0,
         },
         {
            tag => qr/(Data|Para)/,
            nth => 0,
         },
      ],
   },
   {
      name                  => "Original - find_events",
      query_string          => q(~^head\d$=EVENTS[0]/~^head\d$*/(Para)[0]),
      expected_query_struct => [
         {
            tag  => qr/^head\d$/,
            text => "EVENTS",
            nth  => 0,
         },
         {
            tag  => qr/^head\d$/,
            keep => 1,
         },
         {
            tag          => "Para",
            nth_in_group => 0,
         },
      ],
   },

   # In use - Current.
   {
      name                  => "Current - find_title",
      query_string          => 'head1=NAME[0]/Para[0]',
      expected_query_struct => [
         {
            tag  => "head1",
            text => "NAME",
            nth  => 0,
         },
         {
            tag => "Para",
            nth => 0,
         },
      ],
   },
   {
      name                  => "Current - find_method",
      query_string          => q(~head=~^method\b.*$[0]**),
      expected_query_struct => [
         {
            tag      => qr/head/,
            text     => qr/^method\b.*$/,
            nth      => 0,
            keep_all => 1,
         },
      ],
   },
   {
      name                  => "Current - find_method with ()",
      query_string          => q(~head=~^method\\(\\)\b.*$[0]**),
      expected_query_struct => [
         {
            tag      => qr/head/,
            text     => qr/^method\(\)\b.*$/,
            nth      => 0,
            keep_all => 1,
         },
      ],
   },
   {
      name                  => "Current - find_method_summary",
      query_string          => q(~head=~method\b[0]/~(Data|Para)[0]),
      expected_query_struct => [
         {
            tag  => qr/head/,
            text => qr/method\b/,
            nth  => 0,
         },
         {
            tag => qr/(Data|Para)/,
            nth => 0,
         },
      ],
   },
   {
      name                  => "Current - find_events",
      query_string          => q(~head=EVENTS[0]/~head*/(Para)[0]),
      expected_query_struct => [
         {
            tag  => qr/head/,
            text => "EVENTS",
            nth  => 0,
         },
         {
            tag  => qr/head/,
            keep => 1,
         },
         {
            tag          => "Para",
            nth_in_group => 0,
         },
      ],
   },

   # Scenarios - nth vs nth_in_group.
   {
      name                  => "find_title - nth_in_group first",
      query_string          => q(head1=(NAME)[0]/Para[0]),
      expected_query_struct => [
         {
            tag          => "head1",
            text         => "NAME",
            nth_in_group => 0,
         },
         {
            tag => "Para",
            nth => 0,
         },
      ],
   },
   {
      name                  => "find_title - nth_in_group last",
      query_string          => q(head1=NAME[0]/(Para)[0]),
      expected_query_struct => [
         {
            tag  => "head1",
            text => "NAME",
            nth  => 0,
         },
         {
            tag          => "Para",
            nth_in_group => 0,
         },
      ],
   },
   {
      name                  => "find_title - nth_in_group both",
      query_string          => q(head1=(NAME)[0]/(Para)[0]),
      expected_query_struct => [
         {
            tag          => "head1",
            text         => "NAME",
            nth_in_group => 0,
         },
         {
            tag          => "Para",
            nth_in_group => 0,
         },
      ],
   },

   # Scenarios - keep vs keep_all.
   {
      name                  => "find_method - keep",
      query_string          => q(~head=~method\b[0]*),
      expected_query_struct => [
         {
            tag  => qr/head/,
            text => qr/method\b/,
            nth  => 0,
            keep => 1,
         },
      ],
   },
   {
      name                  => "find_method - also keep",
      query_string          => q(~head*=~method\b[0]*),
      expected_query_struct => [
         {
            tag  => qr/head*/,
            text => qr/method\b/,
            nth  => 0,
            keep => 1,
         },
      ],
   },


   # Scenarios - nth_in_group vs regex group.
   {
      name                  => "find_method_summary - regex group",
      query_string          => q(~head=~method\b[0]/~(Data|Para)[0]),
      expected_query_struct => [
         {
            tag  => qr/head/,
            text => qr/method\b/,
            nth  => 0,
         },
         {
            tag => qr/(Data|Para)/,
            nth => 0,
         },
      ],
   },
   {
      name                  => "find_method_summary - nth_in_group",
      query_string          => q(~head=~method\b[0]/(~Data|Para)[0]),
      expected_query_struct => [
         {
            tag  => qr/head/,
            text => qr/method\b/,
            nth  => 0,
         },
         {
            tag          => qr/Data|Para/,
            nth_in_group => 0,
         },
      ],
   },

   # Scenarios - using quotes.
   {
      name                  => "find_method_summary - quotes - error",
      query_string          => q(hea=d1'='Text with [0]\b'),
      expected_query_struct => [],
   },
   {
      name                  => "find_method_summary - quotes - error 2",
      query_string          => q(hea=d'1='Text with [0]\b'),
      expected_query_struct => [],
   },
   {
      name         => "find_method_summary - single quotes - equal sign",
      query_string => q('='),
      expected_query_struct => [
         {
            tag => q(=),
         },
      ],
   },
   {
      name         => "find_method_summary - double quotes - equal sign",
      query_string => q("="),
      expected_query_struct => [
         {
            tag => q(=),
         },
      ],
   },
   {
      name => "find_method_summary - quotes - head1 - backslash is literal",
      query_string          => q(hea\=d1='Text with [0]\b'),
      expected_query_struct => [
         {
            tag  => q(hea\=d1),
            text => 'Text with [0]\b',
         },
      ],
   },
   {
      name                  => "find_method_summary - inner quotes are kept",
      query_string          => q(he'a=d'1='Text with [0]\b'),
      expected_query_struct => [
         {
            tag  => q(he'a=d'1),
            text => 'Text with [0]\b',
         },
      ],
   },
   {
      name                  => "find_method_summary - quotes - head1",
      query_string          => q('hea=d1'='Text with [0]\b'),
      expected_query_struct => [
         {
            tag  => 'hea=d1',
            text => 'Text with [0]\b',
         },
      ],
   },
   {
      name                  => "find_method_summary - quotes - head1 regex 1",
      query_string          => q(~'head1'),
      expected_query_struct => [
         {
            tag => qr/'head1'/,
         },
      ],
   },
   {
      name                  => "find_method_summary - quotes - head1 regex 2",
      query_string          => q('~head1'),
      expected_query_struct => [
         {
            tag => qr/head1/,
         },
      ],
   },
   {
      name                  => "find_method_summary - quotes precendence 1",
      query_string          => q(~head=~'meth/od'\b[0]/(~'Da=ta'|Para)[0]),
      expected_query_struct => [
         {
            tag  => qr/head/,
            text => qr{'meth/od'\b},
            nth  => 0,
         },
         {
            tag          => qr/'Da=ta'|Para/,
            nth_in_group => 0,
         },
      ],
   },
   {
      name                  => "find_method_summary - quotes precendence 2",
      query_string          => q(~head='~meth/od\b'[0]/('~Da=ta|Para')[0]),
      expected_query_struct => [
         {
            tag  => qr/head/,
            text => qr{meth/od\b},
            nth  => 0,
         },
         {
            tag          => qr/Da=ta|Para/,
            nth_in_group => 0,
         },
      ],
   },
);


for my $case ( @cases ) {
   last
     unless is_deeply(
      Pod::Query->_query_string_to_struct( $case->{query_string} ),
      $case->{expected_query_struct},
      "query to string: $case->{name}",
     );
}

done_testing();

