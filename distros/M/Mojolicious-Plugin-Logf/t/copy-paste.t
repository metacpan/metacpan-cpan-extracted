use Test::More;
use Test::Mojo;

plan skip_all => '.git is missing' unless -d '.git';

my ($splice_at, @code, @helper);

{
  open my $FH, '<', 'lib/Mojolicious/Plugin/Logf.pm';
  while (<$FH>) {
    push @code, $_ unless /^\s+helper logf =>/ .. /^\s\s}/;
    chomp;
    next unless /\S/;
    s/\bUNDEF\b/ "__UNDEF__" /;
    push @helper, "  $_" if /sub flatten/ .. /^}/;
    $splice_at ||= $. - 1 if /^\s+helper logf =>/;
  }
}

splice @helper, 0, 2,
  (
  '  helper logf => sub {',
  '    my ($c, $level, $format) = (shift, shift, shift);',
  '    my $log = $c->app->log;',
  '    return $c unless $log->is_level($level);',
  );

splice @helper, -2, 2,
  ('    $log->$level(sprintf $format, @args);', '    return $c;', '  };', '',);

{
  use Mojolicious::Lite;
  local $" = "\n";
  eval "@helper" or die "Unable to create copy/paste code: @helper: $@";
  get "/" => sub {
    my $c = shift;
    $c->logf(warn => 'generated: %s', sub { $c->req->params->to_hash })
      ->render(text => 'code');
  };
}

my $t = Test::Mojo->new;
my @messages;
delete $ENV{MOJO_LOG_LEVEL};

$t->app->log->level('debug');
$t->app->log->unsubscribe('message');
$t->app->log->on(message => sub { shift; push @messages, [@_] if $_[0] =~ /info|warn/; });

$t->get_ok("/?foo=warn")->status_is(200)->content_is('code');
like $messages[0][1], qr{generated:.*foo.*warn}, 'logf code ref';

local $" = "\n";
splice @code, $splice_at, 0, "@helper";
if (ok eval(@code), 'generated code is ok') {
  open my $FH, '>', 'lib/Mojolicious/Plugin/Logf.pm';
  print {$FH} @code;
}

done_testing;
