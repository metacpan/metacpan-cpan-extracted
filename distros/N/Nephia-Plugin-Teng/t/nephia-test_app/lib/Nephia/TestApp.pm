package Nephia::TestApp;
use strict;
use warnings;
use Nephia plugins => [qw/Dispatch Teng JSON/];
use Try::Tiny;
use utf8;

database_do <<'SQL';
CREATE TABLE IF NOT EXISTS `person` (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    age INTEGER
);
SQL

database_do <<'SQL';
INSERT INTO "person"
    ("id", "name", "age")
    VALUES (1, "bob", "20");
SQL

app {
    get '/person/:id' => sub {
        my $id = path_param('id');
        return [ 422 ] unless $id =~ /^[0-9]+$/;

        my $row = teng->single('person', { id => $id });
        return [ 404 ] unless $row;

        json_res {
            id => $id,
            name => $row->get_column('name'),
            age => $row->get_column('age'),
        };
    };
    
    post '/register' => sub {
        my $name = param->{name};
        return [ 422 ] unless $name;
        my $age = param->{age};
        return [ 422 ] unless $age =~ /^[0-9]+$/;

        my $id = teng->fast_insert('person', { name => $name, age => $age });

        json_res {
            id => $id,
            name => $name,
            age => $age,
        };
    };
};

1;

=head1 NAME

MyApp - Web Application

=head1 SYNOPSIS

  $ plackup

=head1 DESCRIPTION

MyApp is web application based Nephia.

=head1 AUTHOR

clever guy

=head1 SEE ALSO

Nephia

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

