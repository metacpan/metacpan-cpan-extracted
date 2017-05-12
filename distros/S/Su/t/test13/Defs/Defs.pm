package Defs::Defs;

my $defs = {
  site => {
    proc  => 'Templates::MenuTmpl',
    model => {
      field1 => { type => 'string' },
      field2 => { type => 'number' },
      field3 => { type => 'date' }
    }
  },
  menu => {
    proc  => 'Templates::MenuTmpl',
    model => 'MenuModel'
  },
};

sub defs {
  shift if ( $_[0] eq __PACKAGE__ );

  my $arg = shift;
  if ($arg) {
    $defs = $arg;
  } else {
    return $defs;
  }
} ## end sub defs

