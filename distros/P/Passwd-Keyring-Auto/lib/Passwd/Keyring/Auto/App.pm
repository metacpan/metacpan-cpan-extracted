package Passwd::Keyring::Auto::App;
use strict; use warnings;
use MooseX::App 1.30  (
    # 'BashCompletion',    # Komenda bash_completion 
    'Color',
    # 'Man',
    'Term',   # prompt missing params
    # 'Typo',   # prompt for correct command
    'Version', # versions, license, copyright
   );

use Passwd::Keyring::Auto;

# Abort on unknown params
app_strict(1);

# Global options

option 'debug' => (
    is => 'rw', isa => 'Bool',
    cmd_aliases => ['d'],
    documentation => q[Show various debugging info on stderr.]);

option 'config' => (
    is => 'rw', isa => 'Str',
    cmd_aliases => ['c'],
    documentation => q[Passwd::Keyring config file location (if non-default).]);

has 'keyring' => (is => 'ro', 'lazy_build' => 1);

1;

# Note: usage description can be replaced using SYNOPSIS in POD

__END__

=head1 DESCRIPTION

Helper tool for L<Passwd::Keyring::Auto>. Setup/review configuration,
manage or delete saved passwords.

=head1 COMMANDS

=head2 create-config

Creates initial version of the configuration file (mostly commented
out examples).

=head2 set-password

Sets (or changes) password for given site in given password group.

If backend parameter is given, uses this very backend, otherwise picks
one just like L<Passwd::Keyring::Auto> does.

=head2 clear-password

Removes password for given site in given password group.

If backend parameter is given, uses this very backend, otherwise picks one just like
L<Passwd::Keyring::Auto> does.

=cut

