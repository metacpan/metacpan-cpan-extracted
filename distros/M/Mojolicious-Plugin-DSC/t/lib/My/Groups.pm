package    #hide
  My::Groups;
use strict;
use warnings;
use utf8;
use My;
use base qw (My);
sub TABLE {'my_groups'}                            #problem
sub COLUMNS { ['id', 'group', 'is\' enabled'] }    #problem

sub ALIASES {
  { 'is\' enabled' => 'is_enabled', }
}

sub WHERE { {'is enabled' => 1} }

sub CHECKS {
  {
    'is\' enabled' => {allow    => qr/^[01]$/},
      id           => {allow    => qr/^\d+$/x},
      group        => {required => 1, allow => qr/^\w+$/}
  }
}
__PACKAGE__->QUOTE_IDENTIFIERS(1);    #no problem now
#__PACKAGE__->BUILD;                   #dbix/dbh must be connected now

