package TaskPipe::SchemaManager::Settings_Project;

use Moose;
extends 'TaskPipe::SchemaManager::Settings';
with 'MooseX::ConfigCascade';

=head1 NAME

TaskPipe::SchemaManager::Settings_Project - project schema settings for TaskPipe

=head1 METHODS

=over

=item table_prefix

Table name clashes between taskpipe tables and other tables in your database can be prevented by specifying a table prefix which will be applied to all taskpipe table names


=cut

has table_prefix => (is => 'ro', isa => 'Str', default => 'tp_');



=item method

The database connection method - e.g. dbi

=item type

The database connection type - e.g. mysql


=item database

The name of the database to connect to


=item host

The host to use to connect to your database (e.g. 'localhost')


=item username

The username to connect to the database


=item password

The password to connect to the database


=item module

The package name of the module to use to keep the database schema (e.g. 'MyProject::Schema')

=back

=cut

has module => (is => 'ro', isa => 'Str', default => 'TaskPipe::Schema');

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

__PACKAGE__->meta->make_immutable;
1;
