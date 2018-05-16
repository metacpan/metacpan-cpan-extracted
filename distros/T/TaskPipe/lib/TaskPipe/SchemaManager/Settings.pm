package TaskPipe::SchemaManager::Settings;

use Moose;
with 'MooseX::ConfigCascade';

=head1 NAME

TaskPipe::SchemaManager::Settings - settings for L<TaskPipe::SchemaManager>

=head1 METHODS

=over

=item table_prefix

Table name clashes between taskpipe tables and other tables in your database can be prevented by specifying a table prefix which will be applied to all taskpipe table names

=cut


=item method

The database connection method - e.g. dbi

=cut

has method => (is => 'ro', isa => 'Str', default => 'dbi');





=item type

The database connection type - e.g. mysql

=cut

has type => (is => 'ro', isa => 'Str', default => 'mysql');





=item database

The name of the database to connect to

=cut

has database => (is => 'ro', isa => 'Str');




=item host

The host to use to connect to your database (e.g. 'localhost')

=cut

has host => (is => 'ro', isa => 'Str', default => 'localhost');




=item username

The username to connect to the database

=cut

has username => (is => 'ro', isa => 'Str', default => 'taskpipe_user');



=item password

The password to connect to the database

=back

=cut

has password => (is => 'ro', isa => 'Str');


=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

__PACKAGE__->meta->make_immutable;
1;

