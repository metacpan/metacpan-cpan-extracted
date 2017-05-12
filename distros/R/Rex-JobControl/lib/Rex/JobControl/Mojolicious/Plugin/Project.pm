#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

package Rex::JobControl::Mojolicious::Plugin::Project;
$Rex::JobControl::Mojolicious::Plugin::Project::VERSION = '0.18.0';
use strict;
use warnings;

use Mojolicious::Plugin;
use Digest::MD5 'md5_hex';
use Rex::JobControl::Helper::Project;

use base 'Mojolicious::Plugin';

sub register {
  my ( $plugin, $app ) = @_;

  $app->helper(
    project => sub {
      my ( $self, $directory ) = @_;

      my $name = $directory;

      if ( $directory !~ m/^[a-f0-9]{32}$/ ) {

        # no md5sum, compat. code
        $directory = md5_hex($directory);
      }

      my $u = Rex::JobControl::Helper::Project->new(
        directory => $directory,
        name      => $name,
        app       => $app
      );
      return $u;
    }
  );
}

1;
