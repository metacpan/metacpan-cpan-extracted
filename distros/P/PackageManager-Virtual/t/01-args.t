use strict;
use warnings;

package TestObj;
use Moose;
sub list    { }
sub install { }
sub remove  { }
with 'PackageManager::Base';

package Main;
use Test::More;
use Test::Exception;
use TestObj;

sub check_no_exception {
    my $test = shift;
    my $func = $test->{func};
    my $obj  = TestObj->new();
    lives_ok { $func->($obj) } $test->{name};
}

sub check_exception {
    my $test = shift;
    my $func = $test->{func};
    my $obj  = TestObj->new();
    throws_ok { $func->($obj) } qr/$test->{check}/, $test->{name};
}

sub run {
    my $valid_list   = shift;
    my $invalid_list = shift;

    plan tests => 2;

    subtest 'test valid args' => sub {
        plan tests => scalar @$valid_list;
        check_no_exception $_ foreach @$valid_list;
    };

    subtest 'test invalid args' => sub {
        plan tests => scalar @$invalid_list;
        check_exception $_ foreach @$invalid_list;
    };
}

my @should_work = (

    # list
    {
        name => 'list: no args',
        func => sub { $_[0]->list() }
    },
    {
        name => 'list: verbose=0',
        func => sub { $_[0]->list( verbose => 0 ) }
    },
    {
        name => 'list: verbose=1',
        func => sub { $_[0]->list( verbose => 1 ) }
    },
    {
        name => 'list: unhandled parameters',
        func => sub { $_[0]->list( other => 'abc' ) }
    },

    # install
    {
        name => 'install: just an app',
        func => sub { $_[0]->install( name => 'cool_app' ) }
    },
    {
        name => 'install: verbose=0',
        func => sub { $_[0]->install( name => 'cool_app', verbose => 0 ) }
    },
    {
        name => 'install: verbose=1',
        func => sub { $_[0]->install( name => 'cool_app', verbose => 1 ) }
    },
    {
        name => 'install: unhandled parameters',
        func => sub { $_[0]->install( name => 'cool_app', other => 'abc' ) }
    },
    {
        name => 'install: specify version',
        func => sub { $_[0]->install( name => 'cool_app', version => '1.0' ) }
    },

    # remove
    {
        name => 'remove: just an app',
        func => sub { $_[0]->remove( name => 'app1' ) }
    },
    {
        name => 'remove: verbose=0',
        func => sub { $_[0]->remove( name => 'cool_app', verbose => 0 ) }
    },
    {
        name => 'remove: verbose=1',
        func => sub { $_[0]->remove( name => 'cool_app', verbose => 1 ) }
    },
    {
        name => 'remove: unhandled parameters',
        func => sub { $_[0]->remove( name => 'cool_app', other => 'abc' ) }
    },
);

my @exception_expected = (

    # list
    {
        name  => 'list: invalid verbose',
        func  => sub { $_[0]->list( verbose => 'abc' ) },
        check => qr/Key 'verbose' \(abc\) is of invalid type/
    },

    # install
    {
        name  => 'install: invalid verbose',
        func  => sub { $_[0]->install( name => 'cool_app', verbose => 'abc' ) },
        check => qr/Key 'verbose' \(abc\) is of invalid type/
    },
    {
        name  => 'install: app missing',
        func  => sub { $_[0]->install() },
        check => qr/Required option 'name' is not provided/
    },
    {
        name  => 'install: empty version',
        func  => sub { $_[0]->install( name => 'cool_app', version => '' ) },
        check => qr/Key 'version' \(\) is of invalid type/
    },

    # remove
    {
        name  => 'remove: invalid verbose',
        func  => sub { $_[0]->remove( name => 'cool_app', verbose => 'abc' ) },
        check => qr/Key 'verbose' \(abc\) is of invalid type/
    },
    {
        name  => 'remove: app missing',
        func  => sub { $_[0]->remove() },
        check => qr/Required option 'name' is not provided/
    }
);

run( \@should_work, \@exception_expected );

1;
