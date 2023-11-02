use FindBin qw($Bin);
use lib $Bin;
use t_TestCommon qw/my_capture/; # also imports Test2::V0 etc.

use strict; use warnings; use feature qw/say/;
use open ':std', ':encoding(UTF-8)';
use utf8;

use Carp;
use Data::Dumper::Interp qw/vis visq dvis dvisq u visnew/;

use Spreadsheet::Edit::Log qw/btw btwN/;

# The default prefix should be just linenum: if imported from only one module
{ my $baseline = __LINE__;
  my ($out, $err, $exit) = my_capture {
    btw "Test1 L=",__LINE__;
    btw "Test2 L=",__LINE__;
  };
  local $_ = $out.$err; # don't care which it goes to
  { my $exp_lno = $baseline + 2;
    like($_, qr/^${exp_lno}: Test1 L=$exp_lno/m,
         "btw imported from only one module(test1)");
  }
  { my $exp_lno = $baseline + 3;
    like($_, qr/^${exp_lno}: Test2 L=$exp_lno/m,
         "btw imported from only one module(test2)");
  }
}

eval "package Foo::Bar; use Spreadsheet::Edit::Log qw/btw/;";
die $@ if $@;

# But after being imported from a different module, show the module name
{ my $baseline = __LINE__;
  my ($out, $err, $exit) = my_capture {
    btw "Test1 L=",__LINE__;
    btw "Test2 L=",__LINE__;
  };
  local $_ = $out.$err; # don't care which it goes to
  { my $exp_lno = $baseline + 2;
    like($_, qr/^main.${exp_lno}: Test1 L=$exp_lno/m,
         "btw imported from two modules(test1)");
  }
  { my $exp_lno = $baseline + 3;
    like($_, qr/^main.${exp_lno}: Test2 L=$exp_lno/m,
         "btw imported from two modules(test2)");
  }
}

done_testing();
