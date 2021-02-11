package MyLib;
use Mojo::Base -base, -signatures;

use Carp 'croak';
use LWP::Simple qw();
use Mojo::Exception;
use Mojo::UserAgent;
use Mojo::Util 'dumper';
use MyDB;
use Sentry::SDK;
use Sentry::Severity;

has _db => sub { MyDB->new };
has foo => undef;
has ua  => sub { Mojo::UserAgent->new };

sub foo1 ($self, $value) {
  LWP::Simple::get('https://example.com/');
  $self->foo2($self->foo, $value);
}

sub foo2 ($self, $value, $x = undef) {
  $self->ua->get('https://www.google.com/?rnd=' . rand());
  $self->ua->get('https://www.google.com/?rnd=' . rand());
  $self->ua->get('https://www.google.com/?rnd=' . rand());
  $self->ua->get('https://www.google.com/?rnd=' . rand());

  my $url = 'https://www.heise.de/select/?rnd=' . rand();
  $self->ua->get('https://www.heise.de/does-not-exist');
  my $tx = $self->ua->get($url);

  Sentry::SDK->add_breadcrumb({
    message  => 'breadcrumb in foo2',
    type     => 'debug',
    category => 'ui.click',
    data     => { some => 'data', bla => ['a', 'b'] }
  });

  $self->_db->insert('abc');
  $self->_db->insert('def');
  $self->_db->do_slow_stuff();

  $self->foo3;
}

sub foo3 {
  Sentry::SDK->add_breadcrumb({
    type     => 'http',
    category => 'xhr',
    level    => Sentry::Severity->Debug,
    data     => {
      url         => "http://example.com/api/1.0/users",
      method      => "GET",
      status_code => 200,
      reason      => "OK"
    }
  });

  die 'exception aus ScriptLib.pm';
  # Mojo::Exception->throw('exception aus ScriptLib.pm');
  # croak 'exception aus ScriptLib.pm';
}

1;
