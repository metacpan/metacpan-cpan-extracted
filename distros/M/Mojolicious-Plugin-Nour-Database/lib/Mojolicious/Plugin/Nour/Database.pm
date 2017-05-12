package Mojolicious::Plugin::Nour::Database;
use Mojo::Base 'Mojolicious::Plugin';
use Nour::Database; has '_nour_db';
# ABSTRACT: Adds an easy to use database handle to your mojo app.

sub register {
    my ( $self, $app, $opts ) = @_;
    $opts->{ '-db-is-mode-by-default' } //= 1 unless exists $opts->{ '-db-is-mode-by-default' };
    my $db_is_mode_by_default = delete $opts->{ '-db-is-mode-by-default' };

    database_setup: {
        $app->helper( _connect_db => sub {
            my ( $c, @args ) = @_; $app->log->debug( '_connect_db' );
            my $mode = $app->mode;
            my $conf = $app->config( 'database' );
            $conf->{default}{database} = $mode if exists $conf->{ $mode } and $db_is_mode_by_default; # e.g., define the default db as "development" if we're in development mode
            $self->_nour_db( new Nour::Database ( %{ $conf } ) );
        } );
        $app->helper( db => sub {
            my ( $c, @args ) = @_;
            $app->_connect_db unless $self->_nour_db;
            return $self->_nour_db->switch_to( @args ) if @args;
            return $self->_nour_db;
        } );

        $app->attr( __worker_pid => sub { 0 } );
        $app->helper( worker_pid => sub { my $self = shift; $self->app->__worker_pid( @_ ); return $self->app->__worker_pid; } );
        $app->worker_pid( $$ );

        $app->hook( before_dispatch => sub { # this hook is important for assigning handlers for each worker
            my ( $c, @args, $spawn ) = @_;
            $spawn = 1 if $$ ne $app->worker_pid;
            $app->worker_pid( $$ ) if $spawn;
            $app->_connect_db if $spawn or not $app->db->dbh->ping;
        } );
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Nour::Database - Adds an easy to use database handle to your mojo app.

=head1 VERSION

version 0.09

=head1 USAGE

Somewhere in your startup routine, include something like this:

    $self->plugin( 'Mojolicious::Plugin::Nour::Database' );

Then from your controllers, you can do things like this:

    sub list {
        my $self = shift;
        my $list = $self->db->query( qq|
            select l.language_code id
                 , l.unicode name_unicode
                 , l.english name_english
                 , l.direction
              from content.resource r
              join i18n.language l using ( language_code )
             group by l.language_code, l.unicode, l.english, l.direction
             order by l.language_code
        | )->hashes;
        $self->render( json => $list );
    }

Or:

    sub list {
        my $self = shift;
        my $list = $self->db( 'audio' )->query( qq|
            select r.reciter_id id
                 , concat( 'http://audio.quran.com:9999/', r.path, '/ogg/' ) base_url
                 , r.arabic name_arabic
                 , r.english name_english
              from audio.reciter r
             order by r.english
        | )->hashes;
        $self->render( json => $list );
    }

This module uses L<Nour::Database> which is a wrapper for L<DBIx::Simple> to provide an app helper
that let's you easily query your databases and get the resultsets you want without having to deal
with bloated, retarded ORMs. SQL is good for you. It also uses L<Nour::Config> to read your db configuration.
See the L<configuration|Mojolicious::Plugin::Nour::Database/"CONFIGURATION"> section for details on how to set that up.

=head1 CONFIGURATION

First, cursorily scan L<Mojolicious::Plugin::Nour::Config/"USAGE"> because it's relevant in
that you should put your configuration under a directory structure that might look like this, for example:

     $ find ./config/
    ./config/
    ./config/application
    ./config/application/nested
    ./config/application/nested/example.yml
    ./config/application.yml
    ./config/database
    ./config/database/private
    ./config/database/private/production.yml
    ./config/database/private/README.md
    ./config/database/config.yml

The only real file you need is C<./config/database/config.yml>.
Overriding configuration in the "private" sub-directory e.g. C<./config/database/private/> is just
a neat feature which let's you override the entire config or just a single nested key/value
that was imported from the "public" configuration i.e. C<./config/database/config.yml>. Why is this useful?
You can `echo '*private*' >> .gitignore` and ensure that your passwords or sensitive tokens or what not don't
get exposed in your public git repository.

=head2 CONFIGURATION EXAMPLES

Here's a couple examples of what C<./config/database/config.yml> might look like:

=over 2

=item Postgresql

    ---
    development:
        dsn: dbi:Pg:dbname=foo;host=bar
        username: foobar
        password: barbaz
    production:
        dsn: dbi:Pg:dbname=bar
    default:
        database: production
        username: barfoo
        password: baroo
        option:
            AutoCommit: 1
            RaiseError: 1
            PrintError: 1
            pg_bool_tf: 0
            pg_enable_utf8: 1

=item MySQL

    ---
    development:
        dsn: dbi:mysql:database=app_dev;host=10.0.1.99
    production:
        dsn: dbi:mysql:database=app_prod;host=10.0.1.99
    production_with_drop_priv:
        dsn: dbi:mysql:database=app_prod;host=10.0.1.99
        username: drop
        password: drop
    otherdb:
        dsn: dbi:mysql:database=dbfoo;host=otherhost
        option:
            AutoCommit: 0
    default:
        database: production
        username: ding
        password: dong
        option:
            AutoCommit: 1
            RaiseError: 1
            PrintError: 1
            mysql_enable_utf8: 1
            mysql_auto_reconnect: 1

=back

=head1 SEE ALSO

=over 2

=item L<Nour::Config>

=item L<Nour::Database>

=item L<DBIx::Simple>

=item L<Mojolicious::Plugin::Nour::Config>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/sharabash/mojolicious-plugin-nour-database/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/sharabash/mojolicious-plugin-nour-database>

  git clone git://github.com/sharabash/mojolicious-plugin-nour-database.git

=head1 AUTHOR

Nour Sharabash <amirite@cpan.org>

=head1 CONTRIBUTOR

Nour Sharabash <nour.sharabash@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Nour Sharabash.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
