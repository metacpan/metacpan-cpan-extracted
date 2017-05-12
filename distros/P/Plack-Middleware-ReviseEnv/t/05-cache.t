use strict;
use Test::More;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;

my $last_env;

my $app = sub {
   $last_env = shift;
   return [
      200,
      [
         'Content-Type'   => 'text/plain',
         'Content-Length' => 12
      ],
      ['Hello World!']
   ];
};

my @revisors = (
   {
      key       => 'cache-default',
      value     => '[% ENV:A %]',
      _expected => 'A',
      _message  => 'default caching, keeps first value',
   },
   {
      key       => 'cache-disabled-undef',
      value     => '[% ENV:A %]',
      cache     => undef,
      _expected => 'a',
      _message  => 'disabled caching, takes new value',
   },
   {
      key       => 'cache-disabled-0',
      value     => '[% ENV:A %]',
      cache     => 0,
      _expected => 'a',
      _message  => 'disabled caching, takes new value',
   },
   {
      key       => 'cache-disabled-empty',
      value     => '[% ENV:B %]',
      cache     => '',
      _expected => 'b',
      _message  => 'disabled caching, takes new value',
   },
   {
      key       => 'cache-enabled-explicitly',
      value     => '[% ENV:B %]',
      cache     => 1,
      _expected => 'B',
      _message  => 'enabled caching, keeps first value',
   },
);

$app = builder {
   enable 'ReviseEnv', revisors => \@revisors;
   $app;
};

test_psgi $app, sub {
   my $cb = shift;

   local %ENV = (
      %ENV,
      A => 'A',
      B => 'B',
   );

   my $res = $cb->(GET "/path/to/somewhere");
   is $res->content, "Hello World!", 'sample content, 1st call';

   # turn to lowercase... see what happens!
   %ENV = (
      %ENV,
      A => 'a',
      B => 'b',
   );

   my $res = $cb->(GET "/path/to/somewhere/else");
   is $res->content, "Hello World!", 'sample content, 2nd call';

   for my $revisor (@revisors) {
      my $key      = $revisor->{_key} || $revisor->{key};
      my $expected = $revisor->{_expected};
      my $got      = $last_env->{$key};
      my $message =
        exists($revisor->{_message}) ? " ($revisor->{_message})" : '';
      is $got, $expected, "\$env->{'$key'}$message";
   } ## end for my $revisor (@revisors)
};

done_testing();
