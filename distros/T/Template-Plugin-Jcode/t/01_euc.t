use strict;
use Template::Test;

test_expect(\*DATA);

__END__
--test--
[% USE Jcode -%]
[% foo = '£Ô£è£é£ó¡¡£é£ó¡¡£ô£ò¡¥' -%]
[% foo.jcode.tr('¡¥£Á-£Ú£á-£ú£°-£¹¡¡','.A-Za-z0-9 ') -%]
--expect--
This is tr.

--test--
[% USE Jcode -%]
[% bar = 'This is tr.' -%]
[% bar.jcode.tr('.A-Za-z0-9 ','¡¥£Á-£Ú£á-£ú£°-£¹¡¡') -%]
--expect--
£Ô£è£é£ó¡¡£é£ó¡¡£ô£ò¡¥

--test--
[% USE Jcode -%]
[% baz = 'ŽÊŽÝŽ¶Ž¸Ž¦Ž¾ŽÞŽÝŽ¶Ž¸ŽÆŽ½ŽÙ' -%]
[% baz.jcode.h2z.euc -%]
--expect--
¥Ï¥ó¥«¥¯¥ò¥¼¥ó¥«¥¯¥Ë¥¹¥ë
