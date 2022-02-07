package Telebot::Plugin::DB;

use Mojo::Base 'Mojolicious::Plugin', -signatures;
use Mojo::Pg;

has [qw(app connection dbh)];

sub register ($self, $app, $conf) {
    $self->app($app);
    $self->connection($conf->{connection} || $app->config->{connection});

    $app->helper('connect.dbh' => sub {
        my ($c) = @_; 
        die "Connection not found" if !$self->connection;
        if (!$self->dbh || !$self->dbh->db->ping) {
            $self->dbh(Mojo::Pg->new($self->connection));
        }
        $self->dbh;
    });
    $app->helper('connect.db' => sub {
        shift->connect->dbh->db;
    });
    $self;
}

1;

=pod
 
=encoding utf8

=head1 NAME
 
Telebot::Plugin::DB - Helpers for work with database.

=head1 SYNOPSIS

    my $dbh = $app->connect->dbh;
    $dbh->db->select('messages', '*');

    my $db = $app->connect->db;
    $db->select('messages', '*');
    
=head1 DESCRIPTION

L<Telebot::Plugin::DB> - plugin with some helpers for work with database.

=head1 HELPERS

L<Telebot::Plugin::DB> implements the following helpers.

=head2 connect->dbh

Connects to database and returns instance to Mojo::Pg

=head2 connect->db

Connects to database and returns instance to Mojo::Pg->db

=head1 METHODS

L<Telebot::Plugin::DB> inherits all methods from L<Mojolicious::Plugin> and implements the following new ones.

=head2 register
    
    my $tg = $plugin->register(Mojolicious->new);

Register plugin in Mojolicious application and define helpers.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022, Igor Lobanov.
This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version
2.0.

=head1 SEE ALSO

L<https://github.com/igorlobanov/telebot>, L<Mojolicious::Guides>, L<https://mojolicious.org>,
L<https://core.telegram.org/bots/api>.

=cut
