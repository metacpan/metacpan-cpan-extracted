package Nephia::Plugin::Teng;
use 5.008005;
use strict;
use warnings;
use Teng::Schema::Loader;
use DBI;
use parent 'Nephia::Plugin';

our $VERSION = "0.04";

sub new {
    my ($class, %opts) = @_;
    my $self = $class->SUPER::new(%opts);
    $self->{RUN_SQL} = [];
    return $self;
}

sub exports { qw/database_do teng/ }

sub database_do {
    my $self = shift;
    my $context = shift;
    $self->_load_context_config($context);
    return sub ($) {
        my $sql = shift;
        push @{$self->{RUN_SQL}}, $sql;
    };
}

sub _on_connect_do {
    my $self = shift;
    my $dbh = $self->_create_dbh();
    my @RUN_SQL = @{$self->{RUN_SQL}};
    for my $sql (@RUN_SQL) {
        $dbh->do($sql);
    }
}

sub teng {
    my $self = shift;
    my $context = shift;
    $self->_load_context_config($context);
    return sub (@) {
        $self->{teng} ||= $self->_create_teng();
    };
}

sub _create_teng {
    my $self = shift;
    my $config = $self->{opts};
    my $pkg = $config->{teng_namespace} // $self->app->{caller}.'::DB';

    $self->_on_connect_do();

    my $teng =
        Teng::Schema::Loader->load(
            dbh => $self->_create_dbh(),
            namespace => $pkg
        );

    for my $plugin (@{$config->{teng_plugins}}) {
        $pkg->load_plugin($plugin);
    }

    return $teng;
};

sub _create_dbh {
    my $self = shift;
    my @connect_info;

    @connect_info = @{$self->{opts}->{connect_info}}
        if exists $self->{opts}->{connect_info}
            && ref $self->{opts}->{connect_info} eq "ARRAY";
    @connect_info = @{$self->{config}->{DBI}->{connect_info}}
        if !@connect_info
            && exists $self->{config}->{DBI}->{connect_info}
            && ref $self->{config}->{DBI}->{connect_info} eq "ARRAY";

    return DBI->connect(@connect_info);
}

sub _load_context_config {
    my $self = shift;
    my $context = shift;
    $self->{config} = $context->get('config');
}

1;
__END__

=encoding utf-8

=head1 NAME

Nephia::Plugin::Teng - Simple ORMapper Plugin For Nephia

=head1 SYNOPSIS

    use Nephia plugins => [qw/Teng/];

    path '/person/:id' => sub {
        my $id = path_param('id');
        my $row = teng->lookup('person', { id => $id });
        return res { 404 } unless $row;

        return {
            id => $id,
            name => $row->get_column('name'),
            age => $row->get_column('age'),
        };
    };

Read row from person table in database in this code.

=head1 DESCRIPTION

=head2 configuration - configuration for Teng.

configuration file:

    'DBI' => {
        connect_info => ['dbi:SQLite:dbname=data.db'],
        teng_plugins => [qw/Lookup Pager/]
    },

The "connect_info" is connect information for L<DBI>.

Enumerate in "plugins" option if you want load Teng plugins.

=head2 teng - Create Teng Object

"teng" DSL create the Teng Object.

=head2 database_do - load SQL before plackup.

In this example to create table before plackup.

in controller :

    database_do "CREATE TABLE IF NOT EXISTS person (id INTEGER, name TEXT, age INTEGER);"

    path '/' => sub {
        ...
    };

=head1 SEE ALSO

L<Nephia>

L<Teng>

=head1 LICENSE

Copyright (C) macopy.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

mackee E<lt>macopy123[attttt]gmai.comE<gt>

ichigotake

=cut

