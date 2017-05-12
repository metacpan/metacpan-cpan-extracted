package Seis::Any;
use strict;
use warnings;
use utf8;
use 5.010_001;


sub _new {
    my $class = shift;
    bless [@_], $class;
}

package # hide from pause
    Any;

sub Str { '' }
sub Stringy { '' }
sub gist { '(Any)' }
sub perl { 'Any' }
sub meta { Seis::MetaClass->new(name => 'Any') }

1;

