use utf8;
use Test::More;
use Parse::SQLOutput;

eval "use YAML::XS; 1" or do {
    plan skip_all => 'YAML::XS is required';
};

plan tests => 7;

my $sql_output = <<'...';
+-------+----------+
| first | last     |
+-------+----------+
| Ingy  | dot Net  |
| Clark | Evans    |
| Oren  | Ben-Kiki |
+-------+----------+
...

is Dump(Parse::SQLOutput->new->parse($sql_output)), <<'...',
---
Clark:
  first: Clark
  last: Evans
Ingy:
  first: Ingy
  last: dot Net
Oren:
  first: Oren
  last: Ben-Kiki
...
    'default (hoh) parse works';

is Dump(Parse::SQLOutput->new(as => 'lol')->parse($sql_output)), <<'...',
---
- - Ingy
  - dot Net
- - Clark
  - Evans
- - Oren
  - Ben-Kiki
...
    'lol parse works';

is Dump(Parse::SQLOutput->new(as => 'hol')->parse($sql_output)), <<'...',
---
Clark:
- Clark
- Evans
Ingy:
- Ingy
- dot Net
Oren:
- Oren
- Ben-Kiki
...
    'hol parse works';

is Dump(Parse::SQLOutput->new(as => 'loh')->parse($sql_output)), <<'...',
---
- first: Ingy
  last: dot Net
- first: Clark
  last: Evans
- first: Oren
  last: Ben-Kiki
...
    'loh parse works';

is Dump(Parse::SQLOutput->new(header => 1)->parse($sql_output)), <<'...',
---
'':
- first
- last
Clark:
  first: Clark
  last: Evans
Ingy:
  first: Ingy
  last: dot Net
Oren:
  first: Oren
  last: Ben-Kiki
...
    'header works for hash';

is Dump(Parse::SQLOutput->new(as => 'lol', header => 1)->parse($sql_output)), <<'...',
---
- - first
  - last
- - Ingy
  - dot Net
- - Clark
  - Evans
- - Oren
  - Ben-Kiki
...
    'header works for list';

is Dump(Parse::SQLOutput->new(as => 'hol', key => 'last')->parse($sql_output)), <<'...',
---
Ben-Kiki:
- Oren
- Ben-Kiki
Evans:
- Clark
- Evans
dot Net:
- Ingy
- dot Net
...
    'key works';

