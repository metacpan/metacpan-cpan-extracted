#!perl -T

use Test::More tests => 16;

BEGIN {
  use_ok(Orze);
  use_ok(Orze::Modules);
  use_ok(Orze::Drivers::Template);
  use_ok(Orze::Drivers::Llgal);
  use_ok(Orze::Drivers::Thumb);
  use_ok(Orze::Drivers::Copy);
  use_ok(Orze::Drivers::Section);
  use_ok(Orze::Drivers::RSS);
  use_ok(Orze::Sources::Pandoc);
  use_ok(Orze::Sources::Pod);
  use_ok(Orze::Sources::Menu);
  use_ok(Orze::Sources::Markdown);
  use_ok(Orze::Sources::Include);
  use_ok(Orze::Sources::YAML);
  use_ok(Orze::Sources);
  use_ok(Orze::Drivers);
}

