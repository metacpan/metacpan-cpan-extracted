#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use VAPID ();
use Punk ();
use Punk::Plugin::Push ();

my ($PUB, $PRIV) = VAPID::generate_vapid_keys();

our %OPTS;
my $N = 0;

# Real Punk classes: register installs helpers through $app->helper, and a
# hand-rolled Punk::App gets as far as the option check and then croaks for a
# reason that has nothing to do with the options.
sub build {
    my (%o) = @_;
    local %OPTS = (subject => 'mailto:ops@example.com',
                   public_key => $PUB, private_key => $PRIV, %o);
    delete $OPTS{$_} for grep { !defined $OPTS{$_} && !exists $o{$_} } ();
    for my $k (keys %o) { delete $OPTS{$k} unless defined $o{$k} or exists $o{$k} }
    my $pkg = 'PushOpt' . ++$N;
    local $@;
    my $ok = eval "package $pkg; use Punk; plugin 'Push' => { \%main::OPTS }; 1";
    return $ok ? ($pkg->punk_app, undef) : (undef, $@);
}

sub cfg { $_[0] && $_[0]->{push_config} }

# ---- the three that are required ------------------------------------------

for my $missing (qw(subject public_key private_key)) {
    my %o = (subject => 'mailto:ops@example.com',
             public_key => $PUB, private_key => $PRIV);
    delete $o{$missing};
    local %OPTS = %o;
    my $pkg = 'PushMiss' . ++$N;
    local $@;
    eval "package $pkg; use Punk; plugin 'Push' => { \%main::OPTS }; 1";
    like($@, qr/`\Q$missing\E` is required/, "$missing is required");
}

{
    my (undef, $err) = build(public_key => '');
    like($err, qr/`public_key` is required/, 'an empty key is no key');
}

# The croak has to say where a keypair comes from, or the reader is left
# searching for how to make a P-256 pair.
{
    my %o = (subject => 'mailto:ops@example.com', private_key => $PRIV);
    local %OPTS = %o;
    my $pkg = 'PushHint' . ++$N;
    local $@;
    eval "package $pkg; use Punk; plugin 'Push' => { \%main::OPTS }; 1";
    like($@, qr/punk push keys/, 'the key croak names the command that makes one');
    like($@, qr/differ per worker/, '  and says why one is not invented');
}

{
    my %o = (public_key => $PUB, private_key => $PRIV);
    local %OPTS = %o;
    my $pkg = 'PushSubj' . ++$N;
    local $@;
    eval "package $pkg; use Punk; plugin 'Push' => { \%main::OPTS }; 1";
    like($@, qr/RFC 8292/, 'the subject croak says which RFC demands it');
}

# ---- a typo must not pass silently ----------------------------------------

{
    my (undef, $err) = build(urgencey => 'high');
    like($err, qr/unknown option 'urgencey'/, 'a misspelled option croaks');
    like($err, qr/known: .*urgency/,          '  and says what was available');
}

# ---- keys are validated, not just present ---------------------------------

{
    my (undef, $err) = build(public_key => 'dG9vLXNob3J0');
    like($err, qr/65 bytes/, 'a short public key is refused at the plugin line');
}

{
    my (undef, $err) = build(private_key => 'dG9vLXNob3J0');
    like($err, qr/32 bytes/, 'and a short private key');
}

{
    my (undef, $err) = build(subject => 'not-a-url-or-mailto');
    like($err, qr/not a url or mailto/, 'the subject must be a mailto: or a URL');
}

# ---- defaults --------------------------------------------------------------

{
    my ($app, $err) = build();
    is($err, undef, 'the three required options are enough') or diag $err;
    my $c = cfg($app);
    is($c->{prefix},  '/push',             'prefix defaults to /push');
    is($c->{ttl},     2419200,             'ttl defaults to four weeks');
    is($c->{urgency}, 'normal',            'urgency defaults to normal');
    is($c->{assets},  1,                   'assets are served by default');
    is($c->{queue},   0,                   'the queue is off by default');
    is($c->{timeout}, 10,                  'timeout defaults to 10');
    is($c->{subject}, 'mailto:ops@example.com', 'the subject is kept');
    is($c->{public_key}, $PUB,             'and the public key');
}

# ---- the ones with a shape -------------------------------------------------

for my $u (qw(very-low low normal high)) {
    my ($app, $err) = build(urgency => $u);
    is($err, undef, "urgency => '$u' is accepted") or next;
    is(cfg($app)->{urgency}, $u, "  and kept as '$u'");
}

{
    my (undef, $err) = build(urgency => 'urgent');
    like($err, qr/`urgency` must be one of/, 'an unknown urgency croaks');
}

for my $bad ('push', '//evil.example/push', '/push/:name') {
    my (undef, $err) = build(prefix => $bad);
    like($err, qr/`prefix` must be a rooted path/, "prefix '$bad' is refused");
}

{
    my (undef, $err) = build(ttl => -1);
    like($err, qr/`ttl` must not be negative/, 'a negative ttl croaks');
}

{
    my ($app) = build(ttl => 0);
    is(cfg($app)->{ttl}, 0, 'ttl => 0 is allowed - deliver now or discard');
}

{
    my (undef, $err) = build(timeout => 0);
    like($err, qr/`timeout` must be a positive/, 'a zero timeout croaks');
}

# ---- the model -------------------------------------------------------------

{
    my ($app) = build();
    is(cfg($app)->{model}, 'Punk::Model::PushSubscription',
        'the shipped model is registered by its full class name');
}

{
    my ($app) = build(model => 'Punk::Model::PushSubscription');
    is(cfg($app)->{model}, 'Punk::Model::PushSubscription',
        'a name with :: is taken as a class and left alone');
}

# ---- the helper that needs nothing else -----------------------------------

{
    my $pkg = 'PushKeyHelper';
    local %OPTS = (subject => 'mailto:ops@example.com',
                   public_key => $PUB, private_key => $PRIV,
                   guard => sub { 1 });
    eval "package $pkg; use Punk;
          host 'https://example.com';
          plugin 'Push' => { \%main::OPTS };
          get '/k' => sub { \$_[0]->text(\$_[0]->push_key) };
          1" or die $@;
    require Punk::Test;
    my $t = Punk::Test->new($pkg);
    $t->get_ok('/k')->status_is(200)->content_is($PUB);
}

done_testing;
