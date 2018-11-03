package TaskPipe::PathSettings::Global;

use Moose;
use Moose::Util::TypeConstraints;
use Cwd 'abs_path';
use File::Path::Expand;
with 'MooseX::ConfigCascade';


sub module_path{ return +abs_path(__FILE__) }

=head1 NAME

TaskPipe::PathSettings::Global - TaskPipe global path settings 

=head1 METHODS

=over

=item global_conf_filename

The name of the taskpipe global configuration file. This file that contains global settings that you will commonly need to review and change.

=cut

has global_conf_filename => (is => 'ro', isa => 'Str', default => 'global.yml');


=item system_conf_filename 

The name of the taskpipe system configuration file. Like the file named in the parameter C<global_conf_filename>, this file contains global settings. However, these may be settings you are less likely to want to change - such as taskpipe command line tool settings. Modify this file only if you are sure you understand the consequences.

=cut

has system_conf_filename => (is => 'ro', isa => 'Str', default => 'system.yml');


=item home_filename

The name of the file in the user's home dir to use to store the taskpipe root directory. During setup, this value can be overwritten (ie the module TaskPipe::PathSettings::Global is edited in place)

=cut

has home_filename => (is => 'ro', isa => 'Str', default => '.taskpipe');



=item default_home_filename

The default value for the home filename in case home_filename needs restoring to the factory default

=cut

has default_home_filename => (is => 'ro', isa => 'Str', default => '.taskpipe');



=item root_dir

The taskpipe root directory. This is normally set from the file found in your home directory (see C<home_filename>), if it is not explicitly provided.

=cut

has root_dir => (is => 'ro', isa => 'Str', trigger => sub { $_[0]->{root_dir} = expand_filename( $_[1] ) });


=item project_dir

The directory inside the root where projects will be stored

=cut

has project_dir => (is => 'ro', isa => 'Str', default => '/projects');


=item global_dir

The directory inside the root where global subdirectories and files will be stored

=cut

has global_dir => (is => 'ro', isa => 'Str', default => '/global');


=item global_conf_dir

The directory inside the global_dir where the global config files will be stored.

=cut

has global_conf_dir => (is => 'ro', isa => 'Str', default => '/conf');


=item global_lib_dir

The directory inside the global_dir where global library files (ie perl packages) will be stored

=cut

has global_lib_dir => (is => 'ro', isa => 'Str', default => '/lib');


=item global_log_dir

The directory inside the global_dir where global log files will be stored

=cut

has global_log_dir => (is => 'ro', isa => 'Str', default => '/logs');



=item project

The default project which will be used if the C<--project> parameter is omitted when running C<taskpipe> commands

=cut

has project => (is => 'ro', isa => 'Str', default => 'default_project');



=item conf_dir

The directory name inside every project where C<taskpipe> will look for the project-specific config file

=cut

has conf_dir => (is => 'ro', isa => 'Str', default => '/conf');



=item conf_filename

The name of the file inside every project conf_dir which C<taskpipe> will load for project-specific config

=back

=cut

has conf_filename => (is => 'ro', isa => 'Str', default => 'project.yml');

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

__PACKAGE__->meta->make_immutable;
1;
__END__
