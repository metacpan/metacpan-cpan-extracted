#!/usr/local/bin/perl

use Mojolicious::Lite;

plugin 'basic_auth_plus';

# Use a callback requiring user ID 'foo' and password 'bar'
get '/callback' => sub {
    my $self = shift;

    $self->render(text => 'ok')
        if $self->basic_auth(
        "Callback Test" => sub { return 1 if "@_" eq 'foo bar' } );
};

# Explicit username and password without using a callback
get '/futurama' => sub {
    my $self = shift;

    $self->render( 'text' => "Whoop whoop whoop!" )
        if $self->basic_auth(
            "Futurama Rules!" => {
                username => 'zoidberg',
                password => 'decapod10'
            }
        );
};

# With encrypted password
get '/crypt' => sub {
    my $self = shift;

    $self->render( 'text' => "Hooray!" )
        if $self->basic_auth(
            "Dr. Zoidberg" => {
                username => 'zoidberg',
                password => 'JVkvO/y7RL9M.'
            }
        );
};

# LDAP authentication (with anonymous bind)
get '/ldap' => sub {
    my $self = shift;

    $self->render(text => 'ok')
        if $self->basic_auth(
            "Some Realm" => {
                host   => 'ldap.company.com',
                basedn => 'ou=People,dc=company,dc=com'
            }
        );
};

# Active Directory authentication (with authenticated bind)
get '/activedirectory' => sub {
    my $self = shift;

    $self->render(text => 'ok')
        if $self->basic_auth(
            "Another Realm" => {
                host   => 'ldap.company.com',
                basedn => 'dc=company,dc=com',
                binddn => 'ou=People,dc=company,dc=com',
                bindpw => 'secret'
            }
        );
};

# Passwd file authentication
under sub {
    my $self = shift;
    return 1
        if $self->basic_auth(
            "Your Realm" => { path => '/path/to/some/passwd/file.txt' } );
};

get '/farnsworth' => sub { shift->render('Good news, everyone!') };
get '/bender' =>
    sub { shift->render( text => 'What do you mean "we", flesh-tube? ' ) };

app->start;

