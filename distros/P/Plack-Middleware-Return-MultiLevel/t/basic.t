use Test::Most;
use Plack::Test;
use Plack::Middleware::Return::MultiLevel;
use Plack::Middleware::Return::MultiLevel::Utils  'return_to_level', 'return_to_default_level';
use HTTP::Request::Common;
use Plack::Builder;

my $app = builder {
  enable "Return::MultiLevel";

  mount "/default" => sub {
    my $env = shift;
    return_to_default_level($env, [200, ['Content-Type', 'text/plain'], ['default']]);
  };

  mount '/layers' => builder {
    enable "Return::MultiLevel", level_name=>'one';
    enable "Return::MultiLevel", level_name=>'two';

    mount '/one' => sub {
      my $env = shift;
      return_to_level($env, 'one', [200, ['Content-Type', 'text/plain'], ['one']]);
    };

    mount '/two' => sub {
      my $env = shift;
      return_to_level($env, 'two', [200, ['Content-Type', 'text/plain'], ['two']]);
    };

  };

};

test_psgi $app, sub {
    my $cb  = shift;

    {
      my $res = $cb->(GET "/default");
      is $res->content, "default";
    }

    {
      my $res = $cb->(GET "/layers/one");
      is $res->content, "one";
    }

    {
      my $res = $cb->(GET "/layers/two");
      is $res->content, "two";
    }
};

done_testing;
