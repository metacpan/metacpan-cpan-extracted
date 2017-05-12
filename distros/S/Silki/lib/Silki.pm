package Silki;
{
  $Silki::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use 5.10.0;

use Catalyst::Runtime 5.8;

use CatalystX::RoleApplicator;
use Catalyst::Plugin::Session 0.27;
use Catalyst::Request::REST::ForBrowsers;
use HTTP::Body 1.09; # for temp file upload suffix preservation
use Silki::Config;
use Silki::I18N ();
use Silki::Request;
use Silki::Schema;
use Silki::Types qw( Str );
use Silki::Web::Session;

use Moose;

my $Config;

BEGIN {
    extends 'Catalyst';

    $Config = Silki::Config->instance();

    my @imports = qw(
        AuthenCookie
        +Silki::Plugin::ErrorHandling
        Session::AsObject
        Session::State::URI
        +Silki::Plugin::Session::Store::Silki
        RedirectAndDetach
        SubRequest
        Unicode::Encoding
    );

    push @imports, 'Static::Simple'
        if $Config->serve_static_files();

    push @imports, 'StackTrace'
        unless $Config->is_production() || $Config->is_profiling();

    Catalyst->import(@imports);

    Silki::Schema->LoadAllClasses();
}

with qw(
    Silki::AppRole::Domain
    Silki::AppRole::RedirectWithError
    Silki::AppRole::Tabs
    Silki::AppRole::User
);

{
    my %config = (
        name              => 'Silki',
        default_view      => 'Mason',
        'Plugin::Session' => {
            expires => ( 60 * 5 ),

            # Need to quote it for Pg
            dbi_table        => q{"Session"},
            dbi_dbh          => 'Silki::Plugin::Session::Store::Silki',
            object_class     => 'Silki::Web::Session',
            rewrite_body     => 0,
            rewrite_redirect => 1,
        },
        authen_cookie => {
            name       => 'Silki-user',
            path       => '/',
            mac_secret => $Config->secret(),
        },
        encoding => 'UTF-8',
        root     => $Config->share_dir()->stringify(),
    );

    unless ( $Config->is_production() ) {
        $config{static} = {
            dirs         => [qw( files images js css static )],
            include_path => [
                map { $Config->$_()->stringify() }
                    qw( cache_dir var_lib_dir share_dir )
            ],
            debug => 1,
        };
    }

    __PACKAGE__->config(\%config);
}

__PACKAGE__->apply_request_class_roles('Silki::Request');

Silki::Schema->EnableObjectCaches();

__PACKAGE__->setup();

__PACKAGE__->meta()->make_immutable( replace_constructor => 1 );

1;

# ABSTRACT: Silki is a Catalyst-based wiki hosting platform



=pod

=head1 NAME

Silki - Silki is a Catalyst-based wiki hosting platform

=head1 VERSION

version 0.29

=head1 DESCRIPTION

Silki is a wiki hosting application with several core goals.

Usability is a core value for Silki. Many wiki applications seem to be aimed
at geeks, which is great, but wikis are useful in many fields, not just
geekery. Ease of use means providing a simple, well thought-out UI, offering
hand-holding wherever it's needed, and avoiding jargon. It also means that
features take a back seat to usability. A bloated application is a hard-to-use
application.

Silki is a I<wiki hosting platform>. That means that it can host multiple
wikis in a single installation. User identity is global to the installation,
and users are members of zero or more wikis. Silki supports various degrees of
openness in each wiki, from "guests can edit" to "members only".

Silki is built with Modern Perl, including L<Catalyst>, L<Moose>, and
L<Fey::ORM>. One of my goals for Silki is to explore modern best practices in
creating web applications.

=head2 Alpha Warning

This software is still in the early stages of development, and should not be
considered stable. It is being released to "get it out there" and to let
people play with it.

=head1 REQUIREMENTS

Silki requires the following software:

=over 4

=item * Perl 5, Version 10 (5.10.0)

=item * Postgres 8.4+

Silki has been tested with Postgres 8.3 and 8.4. Silki uses the built-in
Postgres full text search engine, which was integrated into the Postgres core
in 8.3. It may be possible to use Silki with an earlier version of Postgres,
using the full text search included as a contrib module.

Silki also uses the citext contrib module, which ships with Postgres 8.4. If
you are running Postgres 8.3 and you install citext yourself under your contrib
dir, you should be able to run Silki (I think).

=back

=head1 INSTALLATION

Please see L<Silki::Manual::Admin> for details.

=head1 BUGS

Please report any bugs or feature requests to C<bug-silki@rt.cpan.org>, or
through the web interface at L<http://rt.cpan.org>.  I will be notified, and
then you'll automatically be notified of progress on your bug as I make
changes.

=head1 DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that B<I am not suggesting that you must do this> in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time, which seems unlikely at best.

To donate, log into PayPal and send money to autarch@urth.org or use the
button on this page: L<http://www.urth.org/~autarch/fs-donation.html>

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut


__END__

