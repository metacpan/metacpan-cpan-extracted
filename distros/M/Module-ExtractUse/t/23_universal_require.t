#!/usr/bin/perl -w
use strict;
use Test::More;
use Test::Deep;
use Module::ExtractUse;

eval "use UNIVERSAL::require";
plan skip_all => 'UNIVERSAL::require required for this tests' if $@;


my @tests=
  (
#1
   ['useSome::Module1;',undef,undef,undef],
   ['use Some::Module2;',[qw(Some::Module2)],undef,[qw(Some::Module2)]],
   ["yadda yadda useless stuff;".'use Some::Module3 qw/$VERSION @EXPORT @EXPORT_OK/;',[qw(Some::Module3)],undef,[qw(Some::Module3)]],
   ['use base qw(Class::DBI4 Foo::Bar5);',[qw(Class::DBI4 Foo::Bar5)],undef,[qw(Class::DBI4 Foo::Bar5)]],
   ['if ($foo) { use Foo::Bar6; }',[qw(Foo::Bar6)],undef,[qw(Foo::Bar6)]],
#6
   ['use constant dl_ext => ".$Config{dlext}";',[qw(constant)],undef,[qw(constant)]],
   ['use strict;',[qw(strict)],undef,[qw(strict)]],

   ['use Foo8 qw/asdfsdf/;',[qw(Foo8)],undef,[qw(Foo8)]],
   ['$use=stuff;',undef,undef,undef],
   ['abuse Stuff;',undef,undef,undef],
#11
   ['package Module::ScanDeps;',undef,undef,undef],
   ['if ($foo) { require "Bar7"; }',[qw(Bar7)],undef,[qw(Bar7)]],
   ['require "some/stuff.pl";',undef,undef,undef],
   ['require "Foo/Bar.pm9";',[qw(Foo::Bar9)],undef,[qw(Foo::Bar9)]],
   ['require Foo10;',['Foo10'],undef,['Foo10']],
#16
   ["use Some::Module11;use Some::Other::Module12;",[qw(Some::Module11 Some::Other::Module12)],undef,[qw(Some::Module11 Some::Other::Module12)]],
   ["use Some::Module;\nuse Some::Other::Module;",[qw(Some::Module Some::Other::Module)],undef,[qw(Some::Module Some::Other::Module)]],
   ['use vars qw/$VERSION @EXPORT @EXPORT_OK/;',[qw(vars)],undef,[qw(vars)]],
   ['unless ref $obj;  # use ref as $obj',undef,undef,undef],
   ['$self->_carp("$name trigger deprecated: use before_$name or after_$name instead");',undef,undef,undef],
#21
   ["use base 'Exporter1';",['Exporter1'],undef,['Exporter1']],
   ['use base ("Class::DBI2");',['Class::DBI2'],undef,['Class::DBI2']],
   ['use base "Class::DBI3";',['Class::DBI3'],undef,['Class::DBI3']],
   ['use base qw/Class::DBI4 Foo::Bar5/;',[qw(Class::DBI4 Foo::Bar5)],undef,[qw(Class::DBI4 Foo::Bar5)]],
   ['use base ("Class::DBI6","Foo::Bar7");',[qw(Class::DBI6 Foo::Bar7)],undef,[qw(Class::DBI6 Foo::Bar7)]],
#26
   ['use base "Class::DBI8","Foo::Bar9";',[qw(Class::DBI8 Foo::Bar9)],undef,[qw(Class::DBI8 Foo::Bar9)]],
   ['use base qw(   Class::DBI10   Foo::Bar11   );',[qw(Class::DBI10 Foo::Bar11)],undef,[qw(Class::DBI10 Foo::Bar11)]],
   ["use parent 'Exporter1';",[qw(parent Exporter1)],undef,[qw(parent Exporter1)]],
   ['use parent ("Class::DBI2");',[qw(parent Class::DBI2)],undef,[qw(parent Class::DBI2)]],
   ['use parent "Class::DBI3";',[qw(parent Class::DBI3)],undef,[qw(parent Class::DBI3)]],
#31
   ['use parent qw/Class::DBI4 Foo::Bar5/;',[qw(parent Class::DBI4 Foo::Bar5)],undef,[qw(parent Class::DBI4 Foo::Bar5)]],
   ['use parent ("Class::DBI6","Foo::Bar7");',[qw(parent Class::DBI6 Foo::Bar7)],undef,[qw(parent Class::DBI6 Foo::Bar7)]],
   ['use parent "Class::DBI8","Foo::Bar9";',[qw(parent Class::DBI8 Foo::Bar9)],undef,[qw(parent Class::DBI8 Foo::Bar9)]],
   ['use parent qw(   Class::DBI10   Foo::Bar11   );',[qw(parent Class::DBI10 Foo::Bar11)],undef,[qw(parent Class::DBI10 Foo::Bar11)]],
   ["use parent -norequire,'Exporter1';",[qw(parent)],undef,[qw(parent)]],
#36
   ['use parent ("-norequire","Class::DBI2");',[qw(parent)],undef,[qw(parent)]],
   ['use parent "-norequire","Class::DBI3";',[qw(parent)],undef,[qw(parent)]],
   ['use parent qw/-norequire Class::DBI4 Foo::Bar5/;',[qw(parent)],undef,[qw(parent)]],
   ['use parent ("-norequire","Class::DBI6","Foo::Bar7");',[qw(parent)],undef,[qw(parent)]],
   ['use parent "-norequire","Class::DBI8","Foo::Bar9";',[qw(parent)],undef,[qw(parent)]],
#41
   ['use parent qw(   -norequire   Class::DBI10   Foo::Bar11   );',[qw(parent)],undef,[qw(parent)]],
   ['eval "use Test::Pod 1.06";',['Test::Pod'],['Test::Pod'],undef],
   [q{#!/usr/bin/perl -w
use strict;
use Test::More;
eval "use Test::Pod 1.06";
eval 'use Test::Pod::Coverage 1.06;';
plan skip_all => "Test::Pod 1.06 required for testing POD" if $@;
all_pod_files_ok();},[qw(strict Test::More Test::Pod Test::Pod::Coverage)],[qw(Test::Pod Test::Pod::Coverage)],[qw(strict Test::More)]],
   
   );


plan tests => (scalar @tests)*3;

foreach my $t (@tests) {
    my ($code,@expected)=@$t;
    my $p=Module::ExtractUse->new;
    my @used = (
        $p->extract_use(\$code)->arrayref || undef,
        $p->extract_use(\$code)->arrayref_in_eval || undef,
        $p->extract_use(\$code)->arrayref_out_of_eval || undef,
    );

    for(my $i = 0; $i < @used; ++$i) {
        if (ref($expected[$i]) eq 'ARRAY') {
            cmp_bag($used[$i],$expected[$i]);
        } elsif (!defined $expected[$i]) {
            is(undef,$used[$i],'');
        } else {
            is($used[$i],$expected[$i]);
        }
    }
}


__DATA__


