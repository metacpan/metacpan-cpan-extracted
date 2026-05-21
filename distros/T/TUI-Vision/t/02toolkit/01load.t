use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::toolkit::boolean';
  use_ok 'TUI::toolkit::Params';
  use_ok 'TUI::toolkit::Types';
  if ( eval { require UNIVERSAL::Object } ) {
    use_ok 'TUI::toolkit::UO::Base';
    use_ok 'TUI::toolkit::UO::Antlers';
  }
  use_ok 'TUI::toolkit';
}

note $TUI::toolkit::name;

done_testing();
