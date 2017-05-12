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

$app = builder {
   enable 'ReviseEnv', revisors => {
      some_value     => 'simple straight value',
      test_from_ENV  => '[% ENV:WHATEVER %]',
      test_from_env  => '[% env:REQUEST_METHOD %]',
      test_from_ENVx => {value => '[% ENV:WHATEVER %]', override => 0},
      test_from_envx =>
        {value => '[% env:REQUEST_METHOD %]', override => 0},
      test_delete_pliz => {value => undef},
      test_deleted     => {value => ':[%env:none%]', require_all => 1},
      test_require_ok => {value => '[% ENV:WHATEVER %]', require_all => 1},

      a_port =>
        {key => test_port => value => ':[% ENV:PORT %]', require_all => 1},
      a_oport => {
         key         => test_otherport => value => ':[% ENV:OTHERPORT %]',
         require_all => 1
      },
      a_dport => {
         key           => test_defport => value => ':[% ENV:DEFPORT %]',
         require_all   => 1,
         default_value => ':8080'
      },

      test_hostport      => '[% ENV:HOST %][% env:test_port %]',
      test_hostotherport => '[% ENV:HOST %][% env:test_otherport %]',
      test_hostdefport   => '[% ENV:HOST %][% env:test_defport %]',

      z_test_port      => {key => test_port      => value => undef},
      z_test_otherport => {key => test_otherport => value => undef},

      test_empty => {value => '[% ENV:EMPTY %]', require_all => 1},
      a_test_empty_disappears => {
         key => test_empty_disappears => value => 'I will not survive',
      },
      b_test_empty_disappears => {
         key => test_empty_disappears => value => '[% ENV:EMPTY %]',
         require_all      => 1,
         empty_as_default => 1,
      },

      'psgi.url_scheme' => 'https'
   };

   $app;
};

{
   my $oa = $app;
   $app = sub {
      my $env = shift;
      $env->{test_delete_pliz} = 'I will not survive';
      $env->{test_deleted}     = 'I will not survive';
      $env->{test_from_ENVx}   = 'I will survive';
      $env->{test_from_env}    = 'I will be overridden';
      $env->{test_from_ENV}    = 'I will be overridden';
      delete $env->{none};
      return $oa->($env);
     }
}

test_psgi $app, sub {
   my $cb = shift;

   local %ENV = %ENV;
   $ENV{WHATEVER} = 'here I am';
   $ENV{HOST}     = 'www.example.com';
   $ENV{PORT}     = '80';
   delete $ENV{OTHERPORT};
   delete $ENV{DEFPORT};
   $ENV{EMPTY} = '';    # exists but is empty

   my $res = $cb->(GET "/path/to/somewhere/else");
   is $res->content, "Hello World!", 'sample content';

   is $last_env->{some_value}, 'simple straight value', 'a variable';

   is $last_env->{'psgi.url_scheme'}, 'https', 'psgi variable overridden';

   my %vars = map { $_ => $last_env->{$_} }
     grep { /^test_/ }
     keys %$last_env;
   is_deeply \%vars, {
      test_from_ENV      => 'here I am',
      test_from_ENVx     => 'I will survive',
      test_from_env      => 'GET',
      test_from_envx     => 'GET',
      test_require_ok    => 'here I am',
      test_hostport      => 'www.example.com:80',
      test_hostotherport => 'www.example.com',
      test_hostdefport   => 'www.example.com:8080',
      test_defport => ':8080',    # this was not cleared on purpose
      test_empty   => '',
     },
     'other revised variables as expected'
     or diag explain \%vars;
};

done_testing();
