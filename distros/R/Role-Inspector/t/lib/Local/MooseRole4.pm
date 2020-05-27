package Local::MooseRole4;

use Moose::Role;

requires qw( req );

around mod => sub { shift->(@_) };

sub mod { 42 };

after [ qw( req_list1 req_list2 req_list3 ) ] => sub { 1 };

before [ 'req_array_ref1', 'req_array_ref2' ] => sub { 1 };

sub meth3 { 666 }

1;
