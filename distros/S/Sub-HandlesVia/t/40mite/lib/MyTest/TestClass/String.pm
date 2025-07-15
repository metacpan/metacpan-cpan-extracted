package MyTest::TestClass::String;

use MyTest::Mite;
use Sub::HandlesVia;

has attr => (
  is => 'rwp',
  isa => 'Str',
  handles_via => 'String',
  handles => {
    'my_append' => 'append',
    'my_chomp' => 'chomp',
    'my_chop' => 'chop',
    'my_clear' => 'clear',
    'my_cmp' => 'cmp',
    'my_cmpi' => 'cmpi',
    'my_contains' => 'contains',
    'my_contains_i' => 'contains_i',
    'my_ends_with' => 'ends_with',
    'my_ends_with_i' => 'ends_with_i',
    'my_eq' => 'eq',
    'my_eqi' => 'eqi',
    'my_fc' => 'fc',
    'my_ge' => 'ge',
    'my_gei' => 'gei',
    'my_get' => 'get',
    'my_gt' => 'gt',
    'my_gti' => 'gti',
    'my_inc' => 'inc',
    'my_lc' => 'lc',
    'my_le' => 'le',
    'my_lei' => 'lei',
    'my_length' => 'length',
    'my_lt' => 'lt',
    'my_lti' => 'lti',
    'my_match' => 'match',
    'my_match_i' => 'match_i',
    'my_ne' => 'ne',
    'my_nei' => 'nei',
    'my_prepend' => 'prepend',
    'my_replace' => 'replace',
    'my_replace_globally' => 'replace_globally',
    'my_reset' => 'reset',
    'my_set' => 'set',
    'my_starts_with' => 'starts_with',
    'my_starts_with_i' => 'starts_with_i',
    'my_substr' => 'substr',
    'my_trim' => 'trim',
    'my_uc' => 'uc',
  },
  default => sub { q[] },
);

1;

