package <%= ${class} %>;

use Mojo::Base 'CallBackery';

=head1 NAME

<%= ${class} %> - the application class

=head1 SYNOPSIS

 use Mojolicious::Commands;
 Mojolicious::Commands->start_app('<%= ${class} %>');

=head1 DESCRIPTION

Configure the mojolicious engine to run our application logic

=cut

=head1 ATTRIBUTES

<%= ${class} %> has all the attributes of L<CallBackery> plus:

=cut

=head2 config

use our own plugin directory and our own configuration file:

=cut

has config => sub {
    my $self = shift;
    my $config = CallBackery::Model::ConfigJsonSchema->new(
        app => $self,
        file => $ENV{<%= ${class} %>_CONFIG} || $self->home->rel_file('etc/<%= ${filename} %>.yaml')
    );
    unshift @{$config->pluginPath}, '<%= ${class} %>::GuiPlugin';
    return $config;
};


has database => sub {
    my $self = shift;
    my $database = $self->SUPER::database(@_);
    $database->sql->migrations
        ->name('<%= ${class} %>BaseDB')
        ->from_data(__PACKAGE__,'appdb.sql')
        ->migrate;
    return $database;
};

1;

=head1 COPYRIGHT

Copyright (c) <%= ${year} %> by <%= ${fullName} %>. All rights reserved.

=head1 AUTHOR

S<<%= ${fullName} %> E<lt><%= ${email} %>E<gt>>

=cut

__DATA__

@@ appdb.sql

-- 1 up

CREATE TABLE song (
    song_id    INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    song_title TEXT NOT NULL,
    song_voices TEXT,
    song_composer TEXT,
    song_page INTEGER,
    song_note TEXT
);

-- add an extra right for people who can edit

INSERT INTO cbright (cbright_key,cbright_label)
    VALUES ('write','Editor');

-- 1 down

DROP TABLE song;
