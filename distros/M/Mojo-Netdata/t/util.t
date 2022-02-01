use Test2::V0;
use Mojo::Netdata::Util qw(logf safe_id);
use Mojo::URL;

subtest logf => sub {
  open my $FH, '>', \(my $stderr = '');
  local $Mojo::Netdata::Util::STDERR = $FH;
  local $ENV{HARNESS_ACTIVE};
  local $ENV{HARNESS_IS_VERBOSE};

  logf(debug => 'ignored');

  logf(info     => 'info with %s', {ref => 1});
  logf(warnings => 'warn with %s', undef);
  logf(error    => 'some url %s',  Mojo::URL->new('https://example.com'));
  logf(fatal    => 'and fatal');

  $ENV{NETDATA_DEBUG_FLAGS} = 1;
  logf(debug => 'log %s and %s', qw(this that));

  close $FH;
  ok $stderr =~ s!^\d+-\d+-\d+\s\d+:\d+:\d+!!gm, 'removed timestamps';

  is(
    [split /\n/, $stderr],
    [
      ': util.t: INFO: main: info with {"ref":1}',
      ': util.t: WARNINGS: main: warn with null',
      ': util.t: ERROR: main: some url https://example.com',
      ': util.t: FATAL: main: and fatal',
      ': util.t: DEBUG: main: log this and that',
    ],
    'logged to stderr'
  );
};

subtest safe_id => sub {
  is safe_id('aBC'),        'aBC',        'aBC';
  is safe_id('abc.-%{}_X'), 'abc______X', 'abc______X';
};

done_testing;
