
use strict;
use warnings;

use Test::More;

BEGIN {use_ok('Net::Mailboxlayer')};

my $class = 'Net::Mailboxlayer';

subtest 'bare create' => sub {
  plan tests => 2;
  my $obj = new_ok($class);
  can_ok($obj, qw(access_key email_address smtp format callback catch_all user_agent_opts user_agent json_decoder check));
};

subtest 'create with options' => sub {
  plan tests => 1;
  my $obj = $class->new(access_key => 'abc123');
  is ($obj->access_key, 'abc123', 'set access_key on new');
};

subtest 'create with options' => sub {
  plan tests => 1;
  my $obj = $class->new(access_key => 'abc123');
  $obj->smtp(1);
  is ($obj->smtp, 1, 'set smtp on object');
};

subtest 'live connect' => sub {
  if (not $ENV{NET_MAILBOXLAYER_ACCESS_KEY}) {
    plan(skip_all => 'NET_MAILBOXLAYER_ACCESS_KEY env. variable must be set to run the live connect tests');
  }

  my $key = $ENV{NET_MAILBOXLAYER_ACCESS_KEY};
  my $email = 'this.is.a@test.io';

  my $obj = $class->new(
    access_key => $key,
    email_address => $email,
  );

  {
    my $result = $obj->check;

    if ($result->has_error and $result->code == 101)
    {
      plan skip_all => 'Invalid Access Key';
    }

    is($result->user, 'this.is.a', 'user name');
    is($result->domain, 'test.io', 'domain');
    is($result->catch_all, undef, 'catch_all (undef)');
  }
  {
    $obj->catch_all(1);
    my $result = $obj->check;

    if ($result->has_error)
    {
      is($result->success, 0, 'success is false when plan does not support catch_all');
      is($result->code, 310, 'correct code when plan does not support catch_all');
      is($result->type, 'catch_all_access_restricted', 'correct type when plan does not support catch_all');
    }
    else
    {
      is($result->user, 'this.is.a', 'user name');
      is($result->domain, 'test.io', 'domain');
      is($result->catch_all, 1, 'catch_all true');
    }
  }

};

done_testing();
