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
      key       => '1',
      value     => 'whatever',
      _expected => 'whatever',
      _message  => 'plain string',
   },
   {
      key       => '2',
      value     => '[%   env:1   %]',
      _expected => 'whatever',
      _message  => 'var from $env',
   },
   {
      key       => '3.1',
      value     => '<% env:2 %>',
      start     => '<%',
      stop      => '%>',
      _expected => 'whatever',
      _message => 'alternative start & stop',
   },
   {
      key       => '3.2',
      value     => '<% env:2 %]',
      start     => '<%',
      _expected => 'whatever',
      _message => 'alternative start',
   },
   {
      key       => '3.3',
      value     => '[% env:2 %>',
      stop      => '%>',
      _expected => 'whatever',
      _message => 'alternative stop',
   },
   {
      key       => '<% env:2 %>',
      _key      => 'whatever',
      value     => '<% env:2 %> you like',
      start     => '<%',
      stop      => '%>',
      _expected => 'whatever you like',
      _message  => 'key from $env->{2}',
   },
   {
      key => 'A',
      value => '[%ENV:A%]',
      _expected => 'A',
      _message => '$ENV{"A"}',
   },
   {
      key => 'A.1',
      value => '[%   ENV:A   %]',
      _expected => 'A',
      _message => '$ENV{"A"}, spaces in template var expansion',
   },
   {
      key => 'A.2',
      value => '[%   ENV:A%]',
      _expected => 'A',
      _message => '$ENV{"A"}, spaces before in template var expansion',
   },
   {
      key => 'A.3',
      value => '[%ENV:A   %]',
      _expected => 'A',
      _message => '$ENV{"A"}, spaces after in template var expansion',
   },
   {
      key => 'AB',
      value => '[%ENV:A%][%ENV:B%]',
      _expected => 'AB',
      _message => 'close A and B, no spaces',
   },
   {
      key => 'AB.1',
      value => '[%  ENV:A%][%ENV:B   %]',
      _expected => 'AB',
      _message => 'close A and B, some spaces',
   },
   {
      key => 'AB.2',
      value => '[% ENV:A %]/[% ENV:B %]',
      _expected => 'A/B',
      _message => 'close A and B, some spaces & separator string',
   },
   {
      key => 'escape.1',
      value => '[% ENV:A %]/\\[% ENV:B %][% ENV:B %]',
      _expected => 'A/[% ENV:B %]B',
      _message => 'escaped opener',
   },
   {
      key => 'escape.2',
      value => '[% ENV:A %]/[% ENV:[%F\\%] %]',
      _expected => 'A/F',
      _message => 'escaped closer, i.e. key variable name',
   },
   {
      key => 'escape.3',
      esc => '@',
      value => '[% ENV:A %]/@[% ENV:B %][% ENV:B %]',
      _expected => 'A/[% ENV:B %]B',
      _message => 'escaped opener, alternative escaper',
   },
   {
      key => 'escape.4',
      esc => '@',
      value => '[% ENV:A %]/[% ENV:[%F@%] %]',
      _expected => 'A/F',
      _message => 'escaped closer, alternative escaper',
   },
   {
      key => 'escape.5',
      esc => '@-@',
      value => '[% ENV:A %]/@-@[% ENV:B %][% ENV:B %]',
      _expected => 'A/[% ENV:B %]B',
      _message => 'escaped opener, longer alternative escaper',
   },
   {
      key => 'escape.6',
      esc => '@-@',
      value => '[% ENV:A %]/[% ENV:[%F@-@%] %]',
      _expected => 'A/F',
      _message => 'escaped closer, longer alternative escaper',
   },
   {
      key => 'escape.anything',
      value => '[% ENV:\\A %]\\B',
      _expected => 'AB',
      _message => 'escape chars, even when not needed',
   },
   {
      key => 'space.1',
      value => '[% ENV:C\\ %]',
      _expected => 'C',
      _message => 'trailing space in var name, escape',
   },
   {
      key => 'space.2',
      value => '[% ENV: D %]',
      _expected => 'D',
      _message => 'leading space in var name, no escape',
   },
   {
      key => 'space.3',
      value => '[% ENV: E\\ %]',
      _expected => 'E',
      _message => 'lead/trail space in var name, escape',
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
      A       => 'A',
      B       => 'B',
      'C '    => 'C',
      ' D'    => 'D',
      ' E '   => 'E',
      '[%F%]' => 'F',
   );

   my $res = $cb->(GET "/path/to/somewhere/else");
   is $res->content, "Hello World!", 'sample content';

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
