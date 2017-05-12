package MyData::Bar;
use strict;
use MongoDBx::Tiny::Document;

COLLECTION_NAME 'bar';
ESSENTIAL qw/foo_id code/;
FIELD 'foo_id', OID, DEFAULT(''), REQUIRED;
FIELD 'code',   STR,     DEFAULT('0'),REQUIRED;
FIELD 'name',   LENGTH(30), DEFAULT('noname'),&MY_ATTRIBUTE;

RELATION 'foo', RELATION_DEFAULT('single','id','foo_id');

TRIGGER  'before_insert', sub {
    my ($tiny,$document,$opt) = @_;
};

# before_update,after_update,before_remove,after_remove
TRIGGER  'after_insert', sub {
    my ($object,$opt) = @_;
};

sub MY_ATTRIBUTE {
    return {
	name     => 'MY_ATTRIBUTE',
	callback => sub {
	    return 1;
	}
    };
}

1;
