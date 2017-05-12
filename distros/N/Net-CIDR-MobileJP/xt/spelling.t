use strict;
use warnings;
use Test::More;
BEGIN {
    eval q[use Test::Spelling];
    plan(skip_all => "Test::Spelling required for testing spelling") if $@;
}

add_stopwords(<DATA>);
all_pod_files_spelling_ok;

__END__
Tokuhiro
Matsuno
IP
ip
yaml
