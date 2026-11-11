#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Punk::Test;

# The auth guard's role ladder: a roles hook that returns one arrayref, a
# rank of the application's own, a role the ladder does not name, a role
# guard on an application whose auth has no roles hook, and auth_guard on an
# application with no auth keyword at all.

local $Punk::Auth::Password::ITERATIONS = 1_000;
{
    package T::Backend::Memory;
    sub new { my ($class, %a) = @_; bless { primary => $a{primary} || 'id', rows => {}, seq => 0 }, $class }
    sub get { my ($s, %k) = @_; my $r = $s->{rows}{ $k{ $s->{primary} } }; return $r ? { %$r } : undef }
    sub search { return { rows => [], has_more_data => 0, next => undef } }
    sub all    { return $_[0]->search }
    sub create { my ($s, $d) = @_; my $id = ++$s->{seq}; my $row = { %$d, $s->{primary} => $id }; $s->{rows}{$id} = $row; return { %$row } }
    sub update { my ($s, $d) = @_; my $row = $s->{rows}{ $d->{ $s->{primary} } } or return undef; %$row = (%$row, %$d); return { %$row } }
    sub delete { my ($s, %k) = @_; return delete $s->{rows}{ $k{ $s->{primary} } } ? 1 : 0 }
}
{
    package LadderApp::Model::User;
    use Punk::Model;
    table 'users';
    field id            => { type => 'integer' };
    field email         => { type => 'string' };
    field password_hash => { type => 'string',  required => 0 };
    field verified      => { type => 'integer', required => 0 };
    field roles         => { type => 'string',  required => 0 };
    package LadderApp;
    use Punk;
    use Punk::Auth::Password;
    session secret => 'test-key';
    database backend => 'T::Backend::Memory';
    model 'User';
    auth model => 'User', rank => [ 'reader', 'staff', 'admin' ],
         roles => sub { [ split /,/, ($_[1]->{roles} // '') ] };   # one arrayref, flattened
    under('/staff' => auth_guard(role => 'staff'))->get('/x' => sub { $_[0]->text('staff ok') });
    under('/admin' => auth_guard(role => 'admin'))->get('/x' => sub { $_[0]->text('admin ok') });
    under('/ghost' => auth_guard(role => 'ghost'))->get('/x' => sub { $_[0]->text('ghost ok') });
    post '/signup' => sub {
        my ($c) = @_;
        my $u = $c->model('User')->create({
            email => $c->param('email'), password_hash => Punk::Auth::Password::hash('pw'),
            verified => 1, roles => $c->param('roles') // '',
        });
        $c->login($u);
        $c->json({ id => $u->{id} });
    };
    package main;
}
{
    my $t = Punk::Test->new('LadderApp');
    $t->post_ok('/signup', form => { email => 's@example', roles => 'staff' })->status_is(200);
    $t->get_ok('/staff/x')->status_is(200)->content_is('staff ok', 'a staff member passes a staff guard');
    $t->get_ok('/admin/x')->status_is(401, 'but not an admin guard, higher on the ladder');
    $t->get_ok('/ghost/x')->status_is(401, 'nor a guard for a role the ladder does not name');
    $t->reset_session;
    $t->post_ok('/signup', form => { email => 'a@example', roles => 'reader,admin' })->status_is(200);
    $t->get_ok('/staff/x')->status_is(200, 'an admin, higher on the ladder, passes a staff guard');
    $t->get_ok('/admin/x')->status_is(200, 'and an admin one');
    $t->reset_session;
    $t->post_ok('/signup', form => { email => 'n@example', roles => '' })->status_is(200);
    $t->get_ok('/staff/x')->status_is(401, 'no role at all fails every role guard');
}
{
    package NoRolesApp::Model::User;
    use Punk::Model;
    table 'users';
    field id            => { type => 'integer' };
    field email         => { type => 'string' };
    field password_hash => { type => 'string', required => 0 };
    field verified      => { type => 'integer', required => 0 };
    package NoRolesApp;
    use Punk;
    use Punk::Auth::Password;
    session secret => 'test-key';
    database backend => 'T::Backend::Memory';
    model 'User';
    auth model => 'User';
    under('/admin' => auth_guard(role => 'admin'))->get('/x' => sub { $_[0]->text('never') });
    post '/signup' => sub {
        my ($c) = @_;
        my $u = $c->model('User')->create({ email => 'x@example', password_hash => Punk::Auth::Password::hash('pw'), verified => 1 });
        $c->login($u);
        $c->json({ id => $u->{id} });
    };
    package main;
    my $t = Punk::Test->new('NoRolesApp');
    $t->post_ok('/signup')->status_is(200);
    $t->get_ok('/admin/x')->status_is(500, 'a role guard on an auth without a roles hook is a server error');
}
{
    package NoAuthApp;
    use Punk;
    under('/p' => auth_guard)->get('/x' => sub { $_[0]->text('never') });
    package main;
    my $t = Punk::Test->new('NoAuthApp');
    $t->get_ok('/p/x')->status_is(500, 'auth_guard without the auth keyword is a server error when it runs');
}

done_testing;
