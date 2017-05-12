package Passwd::Keyring::Auto::App::PasswordSet;
use strict; use warnings;
use MooseX::App::Command;

extends 'Passwd::Keyring::Auto::App';

command_short_description q[NOT YET IMPLEMENTED];
command_long_description q[NOT YET IMPLEMENTED];

sub run {
  my ($self, $opt, $arg) = @_;
}

1;

__END__

=head2 EXAMPLES

   passwd_keyring set-password --group=Scrappers somesite.com

   passwd_keyring set-password --app=IntegrationTests --group=Testing admin@production-db

   passwd_keyring clear-password --app=Demo --group=Helpers 
                         Removes given password.



   passwd_keyring dump-config

   passwd_keyring set-password --group=PwdGroup blahblah.com

   passwd_keyring set-password --group=PwdGroup --backend=Gnome  blahblah.com

   passwd_keyring clear-password --group=PwdGroup blahblah.com

(also C<--config=/some/path/to.cfg> to create or use non-standard config file).

