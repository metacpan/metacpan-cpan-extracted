package Mojolicious::Plugin::GitConfig;
$Mojolicious::Plugin::GitConfig::VERSION = '1.0';
# ABSTRACT: Mojolicious Plugin for using Config::GitLike as the main configuration provider
use Mojo::Base 'Mojolicious::Plugin';
use Mojolicious::Plugin::GitConfig::Config;
use Config::GitLike;
use Try::Tiny;


has 'configdata' => undef;


sub register {
  my $self = shift;
  my $app  = shift;
  my $conf = shift;

  # select config file
  my $file = $conf->{file} || $ENV{MOJO_CONFIG} || "config";

  # if we use the git configuration files we have to do something a bit different
  if ($conf->{git})
  {
    $self->configdata(Mojolicious::Plugin::GitConfig::Config->new(confname=>"config",compatible => 1, cascade => 1));
    $self->configdata()->load();
    $app->log->info("git configuration files loaded");
  }
  else
  {
    try {
      $self->configdata(Config::GitLike->load_file($file));
    } catch {
      $app->log->fatal("could not load configuration file " . $file);
      die("could not load configuration file " . $file);
    };
  }

  $app->log->debug(__PACKAGE__ . ": register helper gitconfig");

  $app->helper(gitconfig => sub {
                shift;
                my $params = shift;
                $self->configdata();
              }
          );


};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::GitConfig - Mojolicious Plugin for using Config::GitLike as the main configuration provider

=head1 VERSION

version 1.0

=head1 DESCRIPTION

This modules uses the Config::GitLike Module to implement the Mojolicious App configuration.

  # uses the default git repository configuration files
  $self->plugin('GitConfig' => {git=>1});

  # uses a given configuration file
  $self->plugin('GitConfig' => {file=>"myconfig.conf"});

  # uses the default Mojolicious configuration files
  $self->plugin('GitConfig');

  $self->gitconfig() returns the Config::GitLike class

=head1 ATTRIBUTES

=head2 configdata

  attribute holding the configuration data after loading the configuration file/files

=head1 METHODS

=head2 register

  method called by Mojolicous while loading this plugin

  @param #1 - the class itself
  @param #2 - the mojolicious app context
  @param #3 - the configuration provided by loading the plugin

=head1 AUTHOR

Dominik Meyer <dmeyer@federationhq.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Dominik Meyer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Mojolicious::Plugin::GitConfig/>.

=head1 BUGS

Please report any bugs or feature requests by email to
L<byterazor@federationhq.de|mailto:byterazor@federationhq.de>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Dominik Meyer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
