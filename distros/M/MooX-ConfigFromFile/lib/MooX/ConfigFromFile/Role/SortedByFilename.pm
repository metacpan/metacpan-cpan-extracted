package MooX::ConfigFromFile::Role::SortedByFilename;

use strict;
use warnings;

our $VERSION = '0.009';

use File::Basename ();

use Moo::Role;

requires "raw_loaded_config";

sub _build_filename_sorted_loaded_config
{
    my ($next, $class, $params) = @_;

    defined $params->{raw_loaded_config} or $params->{raw_loaded_config} = $class->_build_raw_loaded_config($params);
    return [] if !@{$params->{raw_loaded_config}};

    defined $params->{config_dirs}       or $params->{config_dirs}       = $class->_build_config_dirs($params);
    defined $params->{config_extensions} or $params->{config_extensions} = $class->_build_config_extensions($params);

    my %config_dir_order = map { $params->{config_dirs}->[$_] . "/" => $_ } 0 .. $#{$params->{config_dirs}};

    [
        ## no critic (BuiltinFunctions::RequireSimpleSortBlock)
        sort {
            my @a = %{$a};
            my @b = %{$b};
            my ($fa, $pa, $sa) = File::Basename::fileparse($a[0], map { "." . $_ } @{$params->{config_extensions}});
            my ($fb, $pb, $sb) = File::Basename::fileparse($b[0], map { "." . $_ } @{$params->{config_extensions}});
            # uncoverable branch true
            $fa cmp $fb || $sa cmp $sb || $config_dir_order{$pa} <=> $config_dir_order{$pb};
        } @{$params->{raw_loaded_config}}
    ];
}

around _build_sorted_loaded_config => \&_build_filename_sorted_loaded_config;

1;

=head1 NAME

MooX::ConfigFromFile::Role::SortedByFilename - allows filename based sort algorithm for multiple config files

=head1 SYNOPSIS

  package MyApp::Cmd::TPau;

  use DBI;
  use Moo;
  use MooX::Cmd with_configfromfile => 1;
  
  with "MooX::ConfigFromFile::Role::SortedByFilename";
  with "MooX::ConfigFromFile::Role::HashMergeLoaded";

  # ensure hashes are merged by top-most scalar wins
  around _build_config_merge_behavior => sub { 'RIGHT_PRECEDENT' };

  has csv => (is => "ro", required => 1);

  sub execute
  {
      my $self = shift;
      DBI->connect("DBI::csv:", undef, undef, $self->csv);
  }

  __END__
  $ cat etc/myapp.json
  {
    "csv": {
      "f_ext": ".csv/r",
      "f_dir": "data"
      "csv_sep_char": ";",
      "csv_class": "Text::CSV_XS"
    }
  }
  $cat etc/myapp-tpau.json
  {
    "csv": {
      "f_dir": "data/tpau"
    }
  }

=head1 DESCRIPTION

This is an additional role for MooX::ConfigFromFile to allow merging loaded
configurations in a more predictable order: filename > extension > path.
(Read: When the filename is identical, the extensions are compared, when
they are identical, the locations are compared).

While filename and file extension are compared on character basis, the
sort order of the file locations (path) is based on precedence in
L<MooX::File::ConfigDir> or L<File::ConfigDir>, respectively. This order
is defined internally in C<@File::ConfigDir::extensible_bases>.

=head1 ATTRIBUTES

=head2 sorted_loaded_config

This role modifies the builder for I<sorted_loaded_config> by sorting
the loaded files from I<raw_loaded_config> by filename, extension
and location in the filesystem, respectively.

Let's assume the affected setup has a I<CLI> interface named C<oper>
with I<sub commands> like C<git> provides them, too. And the company
using the application does it well by defining staging environments
like C<DEV> (Development), C<TEST> (Testing), C<INT> (Integration) and
C<PROD> (Production).  For the example, the I<sub commands> shall be
C<deploy> and C<report>.

This will give you possible C<config_prefix_map>s of

  # main command
  ['oper']
  ['oper', 'dev']
  ['oper', 'test']
  ['oper', 'int']
  ['oper', 'prod']
  # deploy sub-command
  ['oper', 'deploy']
  ['oper', 'deploy', 'dev']
  ['oper', 'deploy', 'test']
  ['oper', 'deploy', 'int']
  ['oper', 'deploy', 'prod']
  # report sub-command
  ['oper', 'report']
  ['oper', 'report', 'dev']
  ['oper', 'report', 'test']
  ['oper', 'report', 'int']
  ['oper', 'report', 'prod']

This will result in (let's further assume, developers prefer C<JSON>,
operators prefer C<YAML>) following possible config filenames:

  [
    # main command
    'oper.json',
    'oper.yaml',
    'oper-dev.json',
    'oper-dev.yaml',
    'oper-test.json',
    'oper-test.yaml',
    'oper-int.json',
    'oper-int.yaml',
    'oper-prod.json',
    'oper-prod.yaml',
    # deploy sub-command
    'oper-deploy.json',
    'oper-deploy.yaml',
    'oper-deploy-dev.json',
    'oper-deploy-dev.yaml',
    'oper-deploy-test.json',
    'oper-deploy-test.yaml',
    'oper-deploy-int.json',
    'oper-deploy-int.yaml',
    'oper-deploy-prod.json',
    'oper-deploy-prod.yaml',
    # report sub-command
    'oper-report.json',
    'oper-report.yaml',
    'oper-report-dev.json',
    'oper-report-dev.yaml',
    'oper-report-test.json',
    'oper-report-test.yaml',
    'oper-report-int.json',
    'oper-report-int.yaml',
    'oper-report-prod.json',
    'oper-report-prod.yaml',
  ]

For a particular invoking (C<oper report> in C<int> stage) following
files exists:

  [
    '/etc/oper.json',                 # global configuration by developers
    '/etc/oper.yaml',                 # global configuration by operating policy
    '/opt/ctrl/etc/oper.json',        # vendor configuration by developers
    '/opt/ctrl/etc/oper.yaml',        # vendor configuration by operating policy
    '/opt/ctrl/etc/oper-int.yaml',    # vendor configuration by stage operating policy
    '/opt/ctrl/etc/oper-report.yaml', # vendor configuration by report operating team
    '/home/usr4711/oper-report.yaml', # usr4711 individual configuration (e.g. for template adoption)
  ]

The default sort algorithm will deliver

  [
    "/etc/oper.json",
    "/etc/oper.yaml",
    "/home/usr4711/oper-report.yaml",
    "/opt/ctrl/etc/oper-int.yaml",
    "/opt/ctrl/etc/oper-report.yaml",
    "/opt/ctrl/etc/oper.json",
    "/opt/ctrl/etc/oper.yaml"
  ]

This role will change the sort algorithm to deliver

  [
    "/etc/oper.json",
    "/opt/ctrl/etc/oper.json",
    "/etc/oper.yaml",
    "/opt/ctrl/etc/oper.yaml",
    "/opt/ctrl/etc/oper-int.yaml",
    "/opt/ctrl/etc/oper-report.yaml",
    "/home/usr4711/oper-report.yaml"
  ]

Which will cause that all policy configuration will override the
developer defaults and user configuration override policy settings.

=head1 AUTHOR

Jens Rehsack, C<< <rehsack at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

