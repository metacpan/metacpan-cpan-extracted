#!perl
use strict;
use warnings;
use Test::More tests => 18;
use FindBin;
use lib "$FindBin::Bin/../lib";

use_ok ('Speak', qw(speak say_persona last_message is_persona resolve_persona %PERSONA_MAP));

# 1. Test is_persona
{
  ok (is_persona ('default'), 'is_persona recognizes default');
  ok (is_persona ('Default'), 'is_persona recognizes Default (case-insensitive)');
  ok (is_persona ('Smith'), 'is_persona recognizes short key Smith');
  ok (is_persona ('Agent Smith'), 'is_persona recognizes display name Agent Smith');
  ok (is_persona ('Captain Picard'), 'is_persona recognizes Captain Picard');
  ok (is_persona ('Charles Clark III'), 'is_persona recognizes Charles Clark III');
  ok (is_persona ('Charles Clarke III'), 'is_persona recognizes Charles Clarke III');
  ok (!is_persona ('announceEmail Gmail'), 'is_persona rejects application tag announceEmail Gmail');
  ok (!is_persona ('speak'), 'is_persona rejects command name speak');
  ok (!is_persona (undef), 'is_persona rejects undef');
}

# 2. Test resolve_persona
{
  my ($v, $disp, $fallback) = resolve_persona ('BogusVoiceName');
  is ($v, 'Default', 'Bogus voice resolves to Default voice file');
  is ($disp, 'default', 'Bogus voice display tag is default');
  is ($fallback, 1, 'Bogus voice flags fallback as 1');

  my ($v2, $disp2, $fb2) = resolve_persona ('Agent Smith');
  is ($v2, 'Smith', 'Agent Smith resolves to voice key Smith');
  is ($disp2, 'Agent Smith', 'Agent Smith display name preserved');
  is ($fb2, 0, 'Agent Smith is not a fallback');

  my ($v3, $disp3, $fb3) = resolve_persona ('default');
  is ($disp3, 'default', 'default resolves to default');
}
