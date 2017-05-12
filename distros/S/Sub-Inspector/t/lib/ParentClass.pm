package ParentClass;
use strict;
use warnings;

sub parent_method {};

sub try (&;@) {}

sub has_attr        :lvalue         {}
sub has_multi_attrs :lvalue :method {}

sub plain {}

1;
