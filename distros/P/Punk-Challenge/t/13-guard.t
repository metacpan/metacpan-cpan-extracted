#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Punk::Test;
use Punk::Challenge::Token ();

# The ordering. A rule runs ahead of a route's guards, so where a stranger
# should see the login page and not a puzzle, challenge_guard is placed
# after auth_guard. Both orders are legal, and this pins which is which so
# the POD's example stays true.

# ---- an in-memory backend, enough for auth to have a model ------------------------

{
    package T::Backend::Memory;
    sub new {
        my ($class, %a) = @_;
        bless { primary => $a{primary} || 'id', rows => {}, seq => 0 }, $class;
    }
    sub get {
        my ($s, %k) = @_;
        my $r = $s->{rows}{ $k{ $s->{primary} } };
        return $r ? { %$r } : undef;
    }
    sub search { return { rows => [], has_more_data => 0, next => undef } }
    sub all    { return $_[0]->search }
    sub create {
        my ($s, $d) = @_;
        my $id = ++$s->{seq};
        my $row = { %$d, $s->{primary} => $id };
        $s->{rows}{$id} = $row;
        return { %$row };
    }
    sub update {
        my ($s, $d) = @_;
        my $row = $s->{rows}{ $d->{ $s->{primary} } } or return undef;
        %$row = (%$row, %$d);
        return { %$row };
    }
    sub delete {
        my ($s, %k) = @_;
        return delete $s->{rows}{ $k{ $s->{primary} } } ? 1 : 0;
    }
}

{
    package GuardApp::Model::User;
    use Punk::Model;
    table 'users';
    field id    => { type => 'integer' };
    field email => { type => 'string' };
}

{
    package GuardApp;
    use Punk;
    use Punk::Plugin::Challenge;

    session secret => 'test-key';
    database backend => 'T::Backend::Memory';
    model 'User';
    auth model => 'User';
    plugin 'Challenge' => { secret => 'k', bits => 8 };

    # `under` takes one guard; a second one is a nested scope with an empty
    # prefix, whose guard chain runs outer to inner.

    # the documented order: a stranger sees the login page, not a puzzle
    my $acct = under('/account' => auth_guard)->under('' => challenge_guard);
    $acct->get('/' => sub { $_[0]->text('account') });

    # the other order: everybody pays first
    my $other = under('/other' => challenge_guard)->under('' => auth_guard);
    $other->get('/' => sub { $_[0]->text('other') });

    get '/login' => sub { $_[0]->text('login') };
}

my $T = Punk::Challenge::Token::;
my %cfg = ( secret => 'k', bits => 8 );
my $A = { REMOTE_ADDR => '192.0.2.7' };
my $HTML = { Accept => 'text/html' };
my $CLR = { 'X-Clearance' => $T->clear(\%cfg, $T->subject('192.0.2.7')) };

# ---- auth_guard, then challenge_guard ---------------------------------------------------

{
    my $t = Punk::Test->new('GuardApp');
    $t->get_ok('/account', env => $A, headers => $HTML)
      ->status_is(302, "a stranger's GET /account is the login redirect")
      ->header_like('Location', qr{^/login}, '  to the login path')
      ->content_unlike(qr/data-puzzle/, '  and not a puzzle');
    $t->get_ok('/account', env => $A)
      ->status_is(401, '  and for an API client, the 401 auth answers with');
    $t->get_ok('/account', env => $A, headers => { %$HTML, %$CLR })
      ->status_is(302, '  a clearance changes nothing for a stranger: auth still refuses first');

    $t->login_as(1);
    $t->get_ok('/account', env => $A, headers => $HTML)
      ->status_is(503, 'a signed-in user without a clearance gets the puzzle')
      ->content_like(qr/data-puzzle="v1\./, '  the interstitial');
    $t->get_ok('/account', env => $A, headers => { %$HTML, %$CLR })
      ->status_is(200)->content_is('account', '  and with a clearance, the page');
}

# ---- challenge_guard, then auth_guard ---------------------------------------------------

{
    my $t = Punk::Test->new('GuardApp');
    $t->get_ok('/other', env => $A, headers => $HTML)
      ->status_is(503, 'in the other order a stranger gets the puzzle first')
      ->content_like(qr/data-puzzle="v1\./, '  the interstitial');
    $t->get_ok('/other', env => $A, headers => { %$HTML, %$CLR })
      ->status_is(302, '  and having paid, is then sent to log in')
      ->header_like('Location', qr{^/login});

    $t->login_as(1);
    $t->get_ok('/other', env => $A, headers => $HTML)
      ->status_is(503, 'signed in without a clearance: still the puzzle');
    $t->get_ok('/other', env => $A, headers => { %$HTML, %$CLR })
      ->status_is(200)->content_is('other', '  signed in and cleared: the page');
}

done_testing;
