package MyData::Foo;
use strict;
use MyDataDocument;
COLLECTION_NAME 'foo';

# FIELD NAME, sub{}, sub{}..
ESSENTIAL qw/code/; # like CDBI's Essential.
FIELD 'code',     STR,         LENGTH(50), DEFAULT('0'), REQUIRED;
FIELD 'name',     STR,         LENGTH(30), DEFAULT('noname');
FIELD 'del_flag', STR,         LENGTH(30),  DEFAULT('off');

# RELATION ACCESSOR, sub{}
RELATION 'bar', RELATION_DEFAULT('single','foo_id','id');

QUERY_ATTRIBUTES {
    single => { del_flag => "off" },
    search => { del_flag => "off" },
};

INDEX 'code', { unique => 1 }, { check => 0 };
INDEX 'name';
INDEX [code => 1, name => -1];

sub process_some {
    my ($class,$tiny,$validator) = @_;
    $tiny->insert($class->collection_name,$validator->document);
}

is_my_data_document_exported();
1;
