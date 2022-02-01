use Test2::V0;
use Mojo::Netdata::Collector;

subtest 'basics' => sub {
  my $collector = Mojo::Netdata::Collector->new;
  is $collector->charts, {}, 'charts';
  is $collector->update_every, 1, 'update_every';

  eval { $collector->type };
  like $@, qr{"type" cannot}, 'type';

  is $collector->register({}, bless({}, 'Mojo::Netdata')), undef, 'register';

  my $update = 0;
  $collector->update_p->then(sub { $update++ })->wait;
  is $update, 1, 'update_p';
};

subtest emit_charts => sub {
  my $collector = Mojo::Netdata::Collector->new(type => 'print');
  my $stdout    = '';
  $collector->on(stdout => sub { $stdout .= $_[1] });

  is $collector->emit_charts, exact_ref($collector), 'emit_charts returns collector';
  is $stdout,                 '',                    'no charts';

  $collector->chart('foo')->dimensions->{xyz} = {};
  $collector->emit_charts;
  like $stdout, qr{^CHART print\.foo.*DIMENSION xyz}s, 'got charts and dimensions';
};

subtest emit_data => sub {
  my $collector = Mojo::Netdata::Collector->new(type => 'print');
  my $stdout    = '';
  $collector->on(stdout => sub { $stdout .= $_[1] });

  is $collector->emit_data, exact_ref($collector), 'emit_data returns collector';
  is $stdout,               '',                    'no charts';

  $collector->chart('foo')->dimensions->{xyz} = {value => 42};
  $collector->emit_data;
  like $stdout, qr{^BEGIN print\.foo.*SET xyz = 42.*END}s, 'got charts and dimensions';
};

subtest recurring_update_p => sub {
  my $collector = Mojo::Netdata::Collector->new(type => 'recurring');
  my $stdout    = '';
  $collector->on(stdout => sub { $stdout .= $_[1] });

  my $n = 0;
  no warnings qw(redefine);
  local *Mojo::Netdata::Collector::update_p = sub {
    return Mojo::Promise->reject("Not cool $n") if $n++ > 1;
    return Mojo::Promise->resolve;
  };

  my ($t0, $t1, $err) = (Time::HiRes::time());
  $collector->update_every(0.2);
  $collector->recurring_update_p->catch(sub { $err = shift; $t1 = Time::HiRes::time() })->wait;
  like $err, qr{Not cool 3}, 'catch';
  is + ($t1 - $t0), within(0.4, 0.15), "runtime @{[$t1 - $t0]}s";
};

done_testing;
