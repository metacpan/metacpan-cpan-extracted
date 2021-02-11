use Mojo::Base -strict, -signatures;

use Mojo::Util 'dumper';
use Test::More;
use Sentry::Util qw(
  uuid4 truncate merge around
);

subtest 'uuid4()' => sub {
  ok(uuid4() =~ m{\A [a-z0-9]{32} \z}xms);
};

subtest 'truncate()' => sub {
  is(truncate('abcdef', 2), 'ab...');
};

subtest 'merge()' => sub {
  my %target = (a => 'a');
  my %source = (b => {}, c => {});
  merge(\%target, \%source, 'b');
  is_deeply(\%target, { a => 'a', b => {} });
};

subtest 'around()' => sub {
  {

    package MyPackage;
    use Mojo::Base -base, -signatures;

    has counter => 0;

    sub increment ($self) {
      $self->counter($self->counter + 1);
    }
  }

  my $called = !1;

  around(
    'MyPackage',
    increment => sub ($orig, $self) {
      $called = 1;
      $orig->($self);
    }
  );

  my $object = MyPackage->new;
  $object->increment();
  $object->increment();

  is($object->counter, 2);
  ok($called, 1);
};

done_testing;
