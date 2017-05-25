package Mojolicious::Plugin::ConfigHashMerge;
use Mojo::Base 'Mojolicious::Plugin::Config';
use Hash::Merge::Simple qw( merge );
use File::Spec::Functions 'file_name_is_absolute';

our $VERSION = '0.04';

sub register {
  my ($self, $app, $conf) = @_;

  # Override
  return $app->config if $app->config->{config_override};

  # Config file
  my $file = $conf->{file} || $ENV{MOJO_CONFIG};
  $file ||= $app->moniker . '.' . ($conf->{ext} || 'conf');

  # Mode specific config file
  my $mode = $file =~ /^(.*)\.([^.]+)$/ ? join('.', $1, $app->mode, $2) : '';

  my $home = $app->home;
  $file = $home->rel_file($file) unless file_name_is_absolute $file;
  $mode = $home->rel_file($mode) if $mode && !file_name_is_absolute $mode;
  $mode = undef unless $mode && -e $mode;

  # Read config file
  my $config = {};
  if (-e $file) { $config = $self->load($file, $conf, $app) }

  # Check for default and mode specific config file
  elsif (!$conf->{default} && !$mode) {
    die qq{Configuration file "$file" missing, maybe you need to create it?\n};
  }

  # Merge everything
  $config = merge($config, $self->load($mode, $conf, $app)) if $mode;
  $config = merge($conf->{default}, $config) if $conf->{default};
  return $app->defaults(config => $app->config)->config($config)->config;
}
1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::ConfigHashMerge - Perlish Configuration, with merging of deeply-nested defaults.

=head1 SYNOPSIS

  # myapp.conf (it's just Perl returning a hash, with possible nesting)
  {
    foo         => "bar",
    watch_dirs  => {
      music => app->home->rel_dir('music'),
      ebooks => app->home->rel_dir('ebooks')
    }
  };

  # Mojolicious
  my $config = $self->plugin('ConfigHashMerge', { options... } );

  # Mojolicious::Lite
  plugin ConfigHashMerge =>
  {
    default =>
    {
      watch_dirs => {
        downloads => app->home->rel_dir('downloads')
      }
    },
    file => 'myapp.conf' # will be loaded anyway
  };
  say $_ for (sort keys %{app->config->{watch_dirs}});
  # will print:
  # downloads
  # ebooks
  # music

=head1 DESCRIPTION

L<Mojolicious::Plugin::ConfigHashMerge> behaves B<exactly> like the standard plugin
L<Mojolicious::Plugin::Config>, except that it merges the defaults with the contents
of the config file using L<Hash::Merge::Simple> instead of flattening the two hashes
into lists. This allows merging of deeply-nested config options.

The only change from the standard Config plugin is the replacement of these two lines:

   $config = {%$config, %{$self->load($mode, $conf, $app)}} if $mode;
   $config = {%{$conf->{default}}, %$config} if $conf->{default};

with these:

   $config = merge($config, $self->load($mode, $conf, $app)) if $mode;
   $config = merge($conf->{default}, $config) if $conf->{default};

So that if your defaults look like this:

  { optA => 42, optB => { victor => 1 }, optC => [2, 7, 8] }

And your config file looks like this:

  { optB => { alpha => 3 }, optC => 7 }

And your mode-specific config file looks like this:

  { optB => { test => 1 } }
The merged config will look like this:

  { optA => 42, optB => { alpha => 3, test => 1, victor => 1 }, optC => 7 }

Instead of like this (with the regular Config plugin):

  { optA => 42, optB => { test => 1 }, optC => 7 }

See L<Mojolicious::Plugin::Config> for more.

Note that this plugin also supports the B<config_override> option in Mojolicious version 7.29+, which
allow you to override the config in your tests.

=head1 OPTIONS

L<Mojolicious::Plugin::ConfigHashMerge> supports all options supported by
L<Mojolicious::Plugin::Config>.

=head1 METHODS

L<Mojolicious::Plugin::ConfigHashMerge> inherits all methods from
L<Mojolicious::Plugin::Config> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new, { file => 'foo.conf', default => { ... } });

Register plugin in L<Mojolicious> application. See L<Mojolicious::Plugin::Config> for available
config options.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>, L<Mojolicious::Plugin::Config>

=cut


