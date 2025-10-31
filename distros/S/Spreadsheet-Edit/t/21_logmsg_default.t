package Foo::Bar::First;

use FindBin qw($Bin);
use lib $Bin;
use t_TestCommon qw/my_capture/; # also imports Test2::V0 etc.

use strict; use warnings; use feature qw/say/;
use open ':std', ':encoding(UTF-8)';
use utf8;

use Carp;
use Data::Dumper::Interp qw/vis visq dvis dvisq u visnew/;


use Spreadsheet::Edit::Log qw/btw btwN :nocolor/;

# The default prefix should be just linenum: if imported from only one module
{ my $baseline = __LINE__;
  my ($out, $err, $exit) = my_capture {
    btw "Test1 L=",__LINE__;
    btw "Test2 L=",__LINE__;
  };
  local $_ = $out.$err; # don't care which it goes to
  { my $exp_lno = $baseline + 2;
    like($_, qr/^${exp_lno}: Test1 L=$exp_lno/m,
         "btw omits non-main pkg if imported from only one module(test1)");
  }
  { my $exp_lno = $baseline + 3;
    like($_, qr/^${exp_lno}: Test2 L=$exp_lno/m,
         "btw omits non-main pkg if imported from only one module(test2)");
  }
}

eval "package Foo::Bar::Second; use Spreadsheet::Edit::Log qw/btw/;";
die $@ if $@;

# After being imported from a different module, still only the line number
# is shown when called from package "main"
eval "package main; use Spreadsheet::Edit::Log qw/btw/;";
{ my $baseline = __LINE__;
  my ($out, $err, $exit) = my_capture {
    package main {
      main::btw("Test1 L=",__LINE__);
      main::btw("Test2 L=",__LINE__);
    }
  };
  local $_ = $out.$err; # don't care which it goes to
  { my $exp_lno = $baseline + 3;
    like($_, qr/^${exp_lno}: Test1 L=$exp_lno/m,
         "btw omits pkg 'main' when imported from two modules(test1)");
  }
  { my $exp_lno = $baseline + 4;
    like($_, qr/^${exp_lno}: Test2 L=$exp_lno/m,
         "btw omits pkg 'main' when imported from two modules(test2)");
  }
}

# But when called from another module, the package "tail" name should be shown
{ my $baseline = __LINE__;
  my ($out, $err, $exit) = my_capture {
    package Foo::Bar::Second;
      Foo::Bar::Second::btw("Test1 L=",__LINE__);
      Foo::Bar::Second::btw("Test2 L=",__LINE__);
    package main;
  };
  local $_ = $out.$err; # don't care which it goes to
  { my $exp_lno = $baseline + 3;
    like($_, qr/^Second.${exp_lno}: Test1 L=$exp_lno/m,
         "btw from Foo::Bar imported from two modules(test1)");
  }
  { my $exp_lno = $baseline + 4;
    like($_, qr/^Second.${exp_lno}: Test2 L=$exp_lno/m,
         "btw from Foo::Bar imported from two modules(test2)");
  }
}

done_testing();
