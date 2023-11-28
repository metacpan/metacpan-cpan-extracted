use PGObject::Util::LogRep::TestDecoding 'parse_msg';
use Test2::V0;

plan 15;
# procedural interface test

is(PGObject::Util::LogRep::TestDecoding::parse_msg('BEGIN 123'), 
   {type => 'txn', txnid => '123', txn_cmd => 'BEGIN'},
   'Begin transaction message parsed');

is(parse_msg("table public.data: INSERT: id[integer]:3 data[text]:'5'"),
   {type => 'dml', operation => 'INSERT', schema => 'public', tablename => 'data', row_data => { id => 3, data => 5}},
   'dml record parsed');

is(parse_msg("table public.data: INSERT: id[integer]:3 data[test.text[]]:'5'"),
   {type => 'dml', operation => 'INSERT', schema => 'public', tablename => 'data', row_data => { id => 3, data => 5}},
   'dml record parsed');

is(parse_msg("table public.data: INSERT: id[integer]:3 data[test.text[]]:null"),
   {type => 'dml', operation => 'INSERT', schema => 'public', tablename => 'data', row_data => { id => 3, data => undef}},
   'dml record parsed');

is(parse_msg("table public.data: INSERT: id[integer]:3 data[test.text[]]:'null'"),
   {type => 'dml', operation => 'INSERT', schema => 'public', tablename => 'data', row_data => { id => 3, data => 'null'}},
   'dml record parsed');

is(parse_msg("table public.test_data: INSERT: id[integer]:6 host[character varying]:'host1' port[integer]:5432 username[character varying]:'bagger' status[smallint]:0"),
   {type => 'dml', operation => 'INSERT', schema => 'public', tablename => 'test_data', 
       row_data => { id =>6, host => 'host1', port => 5432, username => 'bagger', status => 0 }},
   'dml record parsed');

is(parse_msg('COMMIT 123'),
   {type => 'txn', txnid => '123', txn_cmd => 'COMMIT'}, 
   'Begin transaction message parsed');

ok(my $parser = PGObject::Util::LogRep::TestDecoding->new(), 'Got new parser');
is($parser->parse('BEGIN 123'),
   {type => 'txn', txnid => '123', txn_cmd => 'BEGIN'},
   'Begin transaction message parsed OOP');
is($parser->parse("table public.data: INSERT: id[integer]:3 data[character varying]:'5'"),
   {type => 'dml', operation => 'INSERT', schema => 'public', tablename => 'data', row_data => { id => 3, data => 5}},
   'dml record parsed oop');
is(PGObject::Util::LogRep::TestDecoding::_unescape('"da""ta"', '"'), 'da"ta', 'Unescape "');
is(PGObject::Util::LogRep::TestDecoding::_unescape("'da''ta'", "'"), "da'ta", "Unescape '");
is($parser->parse("table public.data: INSERT: id[integer]:3 \"da\"\"ta\"[character varying]:'5'"),
   {type => 'dml', operation => 'INSERT', schema => 'public', tablename => 'data', row_data => { id => 3, 'da"ta' => 5}},
   'dml record parsed oop');
is($parser->current_txn, 123, 'Correct transaction id');

is($parser->parse('COMMIT 123'),
   {type => 'txn', txnid => '123', txn_cmd => 'COMMIT'},
   'Begin transaction message parsed OOP');
