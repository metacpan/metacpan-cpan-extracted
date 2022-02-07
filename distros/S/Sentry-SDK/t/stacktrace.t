use Mojo::Base -strict, -signatures;

use Mojo::Exception;
use Mojo::Util 'dumper';
use Sentry::Stacktrace;
use Test::Exception;
use Test::Spec;

{

  package My::Exeption;
  use Mojo::Base -base;
}

describe 'Sentry::SDK' => sub {
  my $stacktrace;
  my $exception;

  before each => sub {
    $exception = Mojo::Exception->new('my exception');
    $exception->frames([
      ['My::Module', 'MyModule.pm', 1, 'my_method'],
      ['My::Module', 'MyModule.pm', 2, 'my_method2'],
    ]);

    $stacktrace = Sentry::Stacktrace->new(
      exception    => $exception,
      frame_filter => sub {1},
    );
  };

  describe 'prepare_frames()' => sub {
    it 'filters frames' => sub {
      is scalar $stacktrace->prepare_frames->@*, 2;
    };

    it
      'does not throw if `exception` is an exception object other than Mojo::Exception'
      => sub {
        $stacktrace->exception(My::Exeption->new);
        lives_ok { $stacktrace->prepare_frames };
      };
  };
};

runtests;

