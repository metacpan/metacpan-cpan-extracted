package Mojolicious::Plugin::ConfigAny;
use Mojo::Base 'Mojolicious::Plugin';
use Config::Any;
use File::ConfigDir qw(config_dirs);
use IO::All;
our $VERSION = '0.1.3'; # VERSION
# ABSTRACT: Mojolicious Plugin for Config::Any support


sub register {
  my ($self, $app, $conf) = @_;
  # config_dirs
  my $identifier = $conf->{identifier} // $app->moniker;
  my $prefix = $conf->{prefix} // $app->moniker;
  my $mode = $conf->{mode} // $app->mode // 'production';
  my @config_dirs = config_dirs($identifier);
  # TODO: extensions might need checking.
  my @config_extentions = $conf->{extensions} ? @{$conf->{extensions}} : Config::Any->extensions();
  my $ext_pattern = join '|', @config_extentions;
  my $config_files_pattern = qr/^$prefix(\.$mode)?\.($ext_pattern)$/;
  my @config_files = map {
    my $dir = $_;
    map { $_->pathname } io->dir($dir)->filter(sub {
        $_->filename =~ $config_files_pattern;
      }
    )->All_Files();
  } @config_dirs;
  $app->helper(config_dirs => sub { @config_dirs });
  $app->helper(config_files => sub { @config_files });

  if (@config_files) {
    my $configs = Config::Any->load_files(
      {
        files   => \@config_files,
        use_ext => 1
      }
    );
    my %configs = map { %$_ } map { values %$_ } @$configs;
    $app->defaults(config => $app->config)->config(%configs)->config;
  }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::ConfigAny - Mojolicious Plugin for Config::Any support

=head1 VERSION

version 0.1.3

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('ConfigAny');
  $self->plugin(ConfigAny => {
      identifier => 'foo' # identifier for config directories
      prefix => 'bar'     # config files prefix
      extensions => [     # file extensions to search
        qw(json yml perl)
      ]
    }
  );

  # Mojolicious::Lite
  plugin 'ConfigAny';

=head1 DESCRIPTION

L<Mojolicious::Plugin::ConfigAny> is a L<Mojolicious> plugin.

=head1 CONFIGRATION

The plugin configration options listed as following:

=over 4

=item * identifier

Should be a string or not setted - plugin will use C<$app-E<gt>moniker>
as default.

=item * prefix

Config file prefix, default is C<$app-E<gt>moniker> too.

=item * extensions

This is an TODO option, an array reference that used as file extension,
by default we use C<Config::Any-E<gt>extensions> in direct.
If you want to set the C<extensions> option, you could
only use subset of them.

=back

=head1 METHODS

L<Mojolicious::Plugin::ConfigAny> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 config_dirs

L<Mojolicious::Plugin::ConfigAny> will generate a helper listing
all avaliable config directories.

=head2 config_files

L<Mojolicious::Plugin::ConfigAny> will generate a helper listing
all avaliable config files.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Config::Any>, L<File::ConfigDir>,
L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=head1 AUTHOR

Huo Linhe <huolinhe@berrygenomics.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Berry Genomics.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
