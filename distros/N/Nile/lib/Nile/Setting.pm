#   Copyright Infomation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author : Dr. Ahmed Amin Elsheshtawy, Ph.D.
# Website: https://github.com/mewsoft/Nile, http://www.mewsoft.com
# Email  : mewsoft@cpan.org, support@mewsoft.com
# Copyrights (c) 2014-2015 Mewsoft Corp. All rights reserved.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Nile::Setting;

our $VERSION = '0.55';
our $AUTHORITY = 'cpan:MEWSOFT';

=pod

=encoding utf8

=head1 NAME

Nile::Setting - Application global settings database table manager.

=head1 SYNOPSIS
        
    # get setting object instance
    $setting = $self->app->setting;

    # load settings from database to the setting object.
    $setting->load("settings", "name", "value");

    # get settings
    say $setting->get("email");
    say $setting->get("website", "default value");
        
    # automatic getter support
    say $setting->email; # same as $setting->get('email');

    # set settings variables.
    $setting->set("page_views", $count);
    $setting->set(%vars);

    # automatic setter support
    $setting->email('ahmed@mewsoft.com'); # same as $setting->set('email', 'ahmed@mewsoft.com');

    # delete settings from memory and database table.
    $setting->delete(@names);

=head1 DESCRIPTION

Nile::Setting - Application global settings database table manager.

This class to manage an optional application shared settings database table the same way you share the var and config object.

Example of a suggested database table structure.

    CREATE TABLE settings (
        name varchar(255),      # name_column
        value varchar(255)      # value_column, change type to TEXT if needed
    ) ENGINE=InnoDB default CHARACTER SET=utf8;

Then you need to call the load setting once at the start of the application after you connect to the
database.
    
    # get setting object instance
    $setting = $self->app->setting;

    # load settings from database to the setting object.
    $setting->load("settings", "name", "value");

Now you can get, set and delete the settings anywhere in your application.

    # get settings
    say $setting->get("email");
    say $setting->get("website", "default value");
        
    # automatic getter support
    say $setting->email; # same as $setting->get('email');

    # set settings variables.
    $setting->set("page_views", $count);
    $setting->set(%vars);

    # automatic setter support
    $setting->email('ahmed@mewsoft.com'); # same as $setting->set('email', 'ahmed@mewsoft.com');

    # delete settings from memory and database table.
    $setting->delete(@names);

=cut

use Nile::Base;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 setting_table_name()
    
    # set database settings table name
    $setting->setting_table_name("settings");

    # get database settings table name
    $setting->setting_table_name;

Get and set the settings database table name.

=cut

has 'setting_table_name' => (
    is          => 'rw',
    default => 'settings',
  );

=head2 setting_name_column()
    
    # set settings table column name for the 'name_column'.
    $setting->setting_name_column("name");

    # get settings table column name for the 'name_column'.
    $setting->setting_name_column;

Get and set the settings database table column name.

=cut

has 'setting_name_column' => (
    is          => 'rw',
    default => 'name',
  );

=head2 setting_value_column()
    
    # set settings table column name for the 'value_column'.
    $setting->setting_value_column("value");

    # get settings table column name for the 'value_column'.
    $setting->setting_value_column;

Get and set the settings database table column value_column.

=cut

has 'setting_value_column' => (
    is          => 'rw',
    default => 'value',
  );
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub AUTOLOAD {
    my ($self) = shift;

    my ($class, $method) = our $AUTOLOAD =~ /^(.*)::(\w+)$/;

    if ($self->can($method)) {
        return $self->$method(@_);
    }

    if (@_) {
        $self->{vars}->{$method} = $_[0];
    }
    else {
        return $self->{vars}->{$method};
    }
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub main {
    my ($self, $arg) = @_;
    my $app = $self->app;
    $self->load;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 load()
    
    # load settings from database to the setting object.
    $setting->load($db_table, $name_column, $value_column);

Load the settings from database table to the setting object. This method can be chained.

=cut

sub load {
    my ($self, $table, $name, $value) = @_;
    
    $table ||= $self->app->config->get("settings/table");
    $name ||= $self->app->config->get("settings/name");
    $value ||= $self->app->config->get("settings/value");

    $self->table($table) if ($table);
    $self->name($name) if ($name);
    $self->value($value) if ($value);

    $self->{vars} = $self->app->db->colhash("select ".$self->name.", ".$self->value." from ".$self->table);
    $self;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 unload()
    
    # clears all settings from memory.
    $setting->unload;

Resets the setting object and clear all settings from memory. This does not update the database table.
This method can be chained.

=cut

sub unload {
    my ($self) = @_;
    $self->{vars} = +{};
    $self;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 vars()
    
    # get all settings as a hash or a hash ref.
    %vars = $setting->vars();
    $vars = $setting->vars();

Returns all settings as a hash or a hash reference.

=cut

sub vars {
    my ($self) = @_;
    return $self->{vars};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 set()
    
    # set settings variables.
    $setting->set("page_views", $count);
    $setting->set(%vars);

    # automatic setter support
    $setting->email('ahmed@mewsoft.com'); # same as $setting->set('email', 'ahmed@mewsoft.com');

Set settings variables.

=cut

sub set {
    my ($self, %vars) = @_;
    my ($name, $value, $n, $v);
    
    while (($name, $value) = each %vars) {
        $n = $self->app->db->quote($name);
        $v = $self->app->db->quote($value);
        if (exists $self->{vars}->{$name}) {
            $self->app->db->run(qq{update $self->table set $self->name=$n, $self->value=$v});
        }
        else {
            $self->app->db->run(qq{insert into $self->table set $self->name=$n, $self->value=$v});
        }
        $self->{vars}->{$name} = $value;
    }

    $self;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 get()
    
    # get settings
    say $setting->get("email");
    say $setting->get("website", "default value");
        
    # automatic getter support
    say $setting->email; # same as $setting->get('email');

Returns settings variables.

=cut

sub get {
    my ($self, $name, $default) = @_;
    exists $self->{vars}->{$name}? $self->{vars}->{$name} : $default;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 list()
    
    # get a list of settings variables.
    @vars = $setting->list(@names);

Returns a list of  settings variables.

=cut

sub list {
    my ($self, @n) = @_;
    @{$self->{vars}}{@n};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 keys()
    
    # returns all settings names.
    @names = $setting->keys;

Returns all settings names.

=cut

sub keys {
    my ($self) = @_;
    (keys %{$self->{vars}});
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 exists()
    
    # check if a setting variable exist or not.
    $found = $setting->exists($name);

Check if a setting variable exist or not.

=cut

sub exists {
    my ($self, $name) = @_;
    exists $self->{vars}->{$name};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 delete()
    
    # delete settings from memory and database table.
    $setting->delete(@names);

Delete a list of settings from memory and database table..

=cut

sub delete {
    my ($self, @n) = @_;
    $self->app->db->run(qq{delete from $self->table where $self->name=} . $self->app->db->quote($_)) for @n;
    delete $self->{vars}->{$_} for @n;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 clear()
    
    # delete all settings from memory and database table.
    $setting->clear(1);

Delete all settings from memory and database table. This can not be undone. You must pass a true value for the
function as a confirmation that you want to do the job.

=cut

sub clear {
    my ($self, $confirm) = @_;
    return unless ($confirm);
    $self->app->db->run(q{delete from $self->table});
    $self->{vars} = +{};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub DESTROY {
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=pod

=head1 Bugs

This project is available on github at L<https://github.com/mewsoft/Nile>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Nile>.

=head1 SOURCE

Source repository is at L<https://github.com/mewsoft/Nile>.

=head1 SEE ALSO

See L<Nile> for details about the complete framework.

=head1 AUTHOR

Ahmed Amin Elsheshtawy,  احمد امين الششتاوى <mewsoft@cpan.org>
Website: http://www.mewsoft.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2015 by Dr. Ahmed Amin Elsheshtawy احمد امين الششتاوى mewsoft@cpan.org, support@mewsoft.com,
L<https://github.com/mewsoft/Nile>, L<http://www.mewsoft.com>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
