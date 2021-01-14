use strict;
use warnings;
use Test::More;

use B ();

sub is_method {
  my ($ns, $sub) = @_;
  no strict 'refs';
  my $cv = B::svref_2object(\&{"${ns}::${sub}"});
  return
    if !$cv->isa('B::CV');
  my $gv = $cv->GV;
  return
    if $gv->isa('B::SPECIAL');

  my $pack = $gv->STASH->NAME
    or return;

  return (
    $pack eq $ns
    || ($pack eq 'constant' && $gv->name eq '__ANON__')
  );
}

BEGIN {
  package Local::Role;
  use Role::Tiny;
  sub foo { 1 };
}

BEGIN {
  package Local::Class;
  use Role::Tiny::With;
  with qw( Local::Role );

  BEGIN {
    # poor man's namespace::autoclean
    no strict 'refs';
    my @subs = grep defined &$_, keys %Local::Class::;
    my @imports = grep !::is_method(__PACKAGE__, $_), @subs;
    delete @Local::Class::{@imports};
  }
}

ok !defined &Local::Class::with, 'imports are cleaned';

can_ok 'Local::Class', 'foo';
can_ok 'Local::Class', 'does';

BEGIN {
  package Local::Role2;
  use Role::Tiny;

  # poor man's namespace::clean
  my @subs;
  BEGIN {
    no strict 'refs';
    @subs = grep defined &$_, keys %Local::Role2::
  }
  delete @Local::Role2::{@subs};

  sub foo { 1 };
}

BEGIN {
  package Local::Role2;
  use Role::Tiny;
}

# this may not be ideal, but we'll test it since it is done explicitly
ok !defined &Local::Role2::with, 'subs are not re-exported';

done_testing;
