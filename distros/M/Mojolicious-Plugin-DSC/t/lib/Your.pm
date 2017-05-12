{

  package    #hide
    Your;    #our second schema
  use 5.010;
  use strict;
  use warnings;
  use utf8;
  use base qw(DBIx::Simple::Class);

  sub dbix {

    # Singleton DBIx::Simple instance
    state $DBIx;
    return ($DBIx = $_[1] ? $_[1] : $DBIx)
      || Carp::croak('DBIx::Simple is not instantiated for schema "Your"');
  }
}
1;
