use strict;

sub api {
   die "you must definie TEST_API_KEY and TEST_API_SECRET env variables"
        unless $ENV{TEST_API_KEY} && $ENV{TEST_API_SECRET};

   return Pikeo::API->new({
                api_key   => $ENV{TEST_API_KEY},
                api_secret=> $ENV{TEST_API_SECRET}
   });
}

sub login {
   die "you must define TEST_USERNAME and TEST_PASSWORD env variables"
        unless $ENV{TEST_USERNAME} && $ENV{TEST_PASSWORD};

   my $api = shift;
   $api->login({username=>$ENV{TEST_USERNAME},password=>$ENV{TEST_PASSWORD}});
}

1;
