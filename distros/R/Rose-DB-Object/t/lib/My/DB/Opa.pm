package My::DB::Opa;

use strict;

use base qw(Rose::DB);

our $Connection_Count = 0;

__PACKAGE__->use_private_registry;

__PACKAGE__->registry->add_entry(Rose::DB->registry->entry(type => 'sqlite_admin', domain => 'test')->clone);

__PACKAGE__->default_type('sqlite_admin');

sub init_dbh
{
  $Connection_Count++;
  return shift->SUPER::init_dbh(@_);
}

sub connection_count
{
  my ($self, $val) = @_;
  return defined $val ? $Connection_Count = $val : $Connection_Count;
}

1;
