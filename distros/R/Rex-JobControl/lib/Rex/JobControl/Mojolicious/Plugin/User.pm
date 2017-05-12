#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

package Rex::JobControl::Mojolicious::Plugin::User;
$Rex::JobControl::Mojolicious::Plugin::User::VERSION = '0.18.0';
use strict;
use warnings;

use Mojolicious::Plugin;
use Rex::JobControl::Helper::Project;
use Digest::Bcrypt;

use base 'Mojolicious::Plugin';

sub register {
  my ( $plugin, $app ) = @_;

  $app->helper(
    get_user => sub {
      my ( $self, $uid ) = @_;

      my @lines =
        eval { local (@ARGV) = ( $self->app->config->{auth}->{passwd} ); <>; };
      chomp @lines;

      for my $l (@lines) {
        my ( $name, $pass ) = split( /:/, $l );
        if ( $name eq $uid ) {
          return { name => $name, password => $pass };
        }
      }

      return undef;
    },
  );

  $app->helper(
    check_password => sub {
      my ( $self, $uid, $pass ) = @_;

      my $user = $app->get_user($uid);

      my $salt = $app->config->{auth}->{salt};
      my $cost = $app->config->{auth}->{cost};

      my $bcrypt = Digest::Bcrypt->new;
      $bcrypt->salt($salt);
      $bcrypt->cost($cost);
      $bcrypt->add($pass);

      my $pw = $bcrypt->hexdigest;

      if ( $user && $user->{password} eq $pw ) {
        return $user->{name};
      }

      return undef;
    },
  );
}

1;
