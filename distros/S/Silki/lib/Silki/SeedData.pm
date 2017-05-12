package Silki::SeedData;
{
  $Silki::SeedData::VERSION = '0.29';
}

use strict;
use warnings;

our $VERBOSE;

sub seed_data {
    my %p = @_;

    local $VERBOSE = $p{verbose};

    require Silki::Schema::Locale;

    Silki::Schema::Locale->CreateDefaultLocales();

    require Silki::Schema::Country;

    Silki::Schema::Country->CreateDefaultCountries();

    require Silki::Schema::TimeZone;

    Silki::Schema::TimeZone->CreateDefaultZones();

    require Silki::Schema::Domain;

    Silki::Schema::Domain->EnsureRequiredDomainsExist();

    require Silki::Schema::User;

    Silki::Schema::User->EnsureRequiredUsersExist();

    require Silki::Schema::Account;

    Silki::Schema::Account->EnsureRequiredAccountsExist();

    require Silki::Schema::Role;

    print "\n" if $VERBOSE;

    my $admin   = _make_admin_user();
    my $regular = _make_regular_user()
        unless $p{production};

    if ( $p{production} ) {
        _make_production_wiki($admin);
    }
    else {
        _make_first_wiki( $admin, $regular );
        _make_second_wiki( $admin, $regular );
        _make_third_wiki( $admin, $regular );
    }
}

sub _make_admin_user {
    my $email
        = 'admin@' . Silki::Schema::Domain->DefaultDomain()->email_hostname();

    my $admin = _make_user( 'Angela D. Min', $email, 1 );

    Silki::Schema::Account->DefaultAccount()->add_admin($admin);

    return $admin;
}

sub _make_regular_user {
    my $email
        = 'joe@' . Silki::Schema::Domain->DefaultDomain()->email_hostname();

    return _make_user( 'Joe Schmoe', $email );
}

sub _make_user {
    my $name     = shift;
    my $email    = shift;
    my $is_admin = shift;

    my $pw = 'changeme';

    my $user = Silki::Schema::User->insert(
        display_name  => $name,
        email_address => $email,
        password      => $pw,
        time_zone     => 'America/Chicago',
        is_admin      => ( $is_admin ? 1 : 0 ),
        user          => Silki::Schema::User->SystemUser(),
    );

    if ($VERBOSE) {
        my $type = $is_admin ? 'an admin' : 'a regular';

        print <<"EOF";
Created $type user:

  email:    $email
  password: $pw

EOF
    }

    return $user;
}

sub _make_first_wiki {
    my $admin   = shift;
    my $regular = shift;

    my $wiki = _make_wiki( 'First Wiki', 'first-wiki' );

    $wiki->set_permissions('public');

    $wiki->add_user( user => $admin, role => Silki::Schema::Role->Admin() );
    $wiki->add_user(
        user => $regular,
        role => Silki::Schema::Role->Member()
    );
}

sub _make_production_wiki {
    my $admin = shift;

    my $wiki = _make_wiki( 'My Wiki', 'my-wiki' );

    $wiki->set_permissions('private');

    $wiki->add_user( user => $admin, role => Silki::Schema::Role->Admin() );
}

sub _make_second_wiki {
    my $admin   = shift;
    my $regular = shift;

    my $wiki = _make_wiki( 'Second Wiki', 'second-wiki' );

    $wiki->set_permissions('private');

    $wiki->add_user( user => $admin, role => Silki::Schema::Role->Admin() );
    $wiki->add_user(
        user => $regular,
        role => Silki::Schema::Role->Member()
    );
}

sub _make_third_wiki {
    my $admin   = shift;
    my $regular = shift;

    my $wiki = _make_wiki( 'Third Wiki', 'third-wiki' );

    $wiki->set_permissions('private');

    $wiki->add_user(
        user => $regular,
        role => Silki::Schema::Role->Member()
    );
}

sub _make_wiki {
    my $title = shift;
    my $name  = shift;

    require Silki::Schema::Wiki;

    my $wiki = Silki::Schema::Wiki->insert(
        title      => $title,
        short_name => $name,
        domain_id  => Silki::Schema::Domain->DefaultDomain()->domain_id(),
        user       => Silki::Schema::User->SystemUser(),
    );

    my $uri = $wiki->uri( with_host => 1 );

    if ($VERBOSE) {
        print <<"EOF";
Created a wiki:

  Title: $title
  URI:   $uri

EOF
    }

    return $wiki;
}

1;

# ABSTRACT: Seeds a fresh database with data

__END__
=pod

=head1 NAME

Silki::SeedData - Seeds a fresh database with data

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

