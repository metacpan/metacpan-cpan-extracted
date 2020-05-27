package Local::MouseRole3;

use Mouse::Role;

requires qw( req );

around mod => sub { shift->(@_) };

after [ qw( req_list1 req_list2 req_list3 ) ] => sub { 1 };

before [ 'req_array_ref1', 'req_array_ref2' ] => sub { 1 };

sub meth3 { 666 }

1;
