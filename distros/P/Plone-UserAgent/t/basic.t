use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;

use Plone::UserAgent;


{
    no warnings 'redefine';
    local *File::HomeDir::my_home = sub
    {
        return '/does not exist, I hope!';
    };

    throws_ok( sub { Plone::UserAgent->new( base_uri => 'http://example.com' ) },
               qr/\QMust provide a username and password or a valid config file/,
               'cannot create a new ua without a username & password' );

    local *Plone::UserAgent::_build_config_data = sub
    {
        return { '-' => {} };
    };

    throws_ok( sub { Plone::UserAgent->new( base_uri => 'http://example.com' ) },
               qr/\QMust provide a username and password or a valid config file/,
               'cannot create a new ua without a username & password' );
}

{
    my $ua = Plone::UserAgent->new( base_uri => 'http://example.com',
                                    username => 'foo',
                                    password => 'bar',
                                  );

    is( $ua->make_uri('/whatever'),
        'http://example.com/whatever',
        'make_uri uses base uri' );
}

{
    my $ua = Plone::UserAgent->new( base_uri => 'http://example.com',
                                    username => 'foo',
                                    password => 'bar',
                                  );

    my @post;
    my $rc = 301;

    no warnings 'redefine';
    local *LWP::UserAgent::post = sub { shift; @post = @_; return HTTP::Response->new($rc); };

    $ua->login();

    is_deeply( \@post,
               [ 'http://example.com/login_form',
                 { __ac_name     => 'foo',
                   __ac_password => 'bar',
                   came_from        => $ua->base_uri(),
                   cookies_enabled  => q{},
                   'form.submitted' => 1,
                   js_enabled       => q{},
                   login_name       => q{},
                   submit           => 'Log in',
                 },
               ],
               'login method makes expected post' );

    $rc = 500;
    throws_ok( sub { $ua->login() },
               qr{\QCould not log in to http://example.com/login_form},
               'throws an error when login fails' );
}

