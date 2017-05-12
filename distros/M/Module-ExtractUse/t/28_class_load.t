#!/usr/bin/perl -w
use strict;
use Test::More;
use Test::Deep;
use Test::NoWarnings;
use Module::ExtractUse;

my @tests=
  (
#1
   ['load_class("Some::Module");',[qw(Some::Module)],undef,[qw(Some::Module)]],
   ['load_class("Some::Module", { -version => 1.23 });',[qw(Some::Module)],undef,[qw(Some::Module)]],
   ['Class::Load::load_class("Some::Module");',[qw(Some::Module)],undef,[qw(Some::Module)]],
   ['Class::Load::load_class("Some::Module", { -version => 1.23 });',[qw(Some::Module)],undef,[qw(Some::Module)]],

   ['try_load_class("Some::Module");',[qw(Some::Module)],undef,[qw(Some::Module)]],
   ['try_load_class("Some::Module", { -version => 1.23, other => "string" });',[qw(Some::Module)],undef,[qw(Some::Module)]],
   ['Class::Load::try_load_class("Some::Module");',[qw(Some::Module)],undef,[qw(Some::Module)]],
   ['Class::Load::try_load_class("Some::Module", { -version => 1.23 });',[qw(Some::Module)],undef,[qw(Some::Module)]],

   ['load_optional_class("Some::Module");',[qw(Some::Module)],undef,[qw(Some::Module)]],
   ['load_optional_class("Some::Module", { -version => 1.23 });',[qw(Some::Module)],undef,[qw(Some::Module)]],
   ['Class::Load::load_optional_class("Some::Module");',[qw(Some::Module)],undef,[qw(Some::Module)]],
   ['Class::Load::load_optional_class("Some::Module", { -version => 1.23 });',[qw(Some::Module)],undef,[qw(Some::Module)]],

   ['load_first_existing_class("Some::Module");', [qw(Some::Module)],undef,[qw(Some::Module)]],
   ['load_first_existing_class("Some::Module", "Other::Module", "Third::Module::Too");', [qw(Some::Module Other::Module Third::Module::Too)],undef,[qw(Some::Module Other::Module Third::Module::Too)]],
   ['load_first_existing_class("Some::Module", { -version => 1.23 });', [qw(Some::Module)],undef,[qw(Some::Module)]],
   ['load_first_existing_class("Some::Module", { -version => 1.23 }, "Other::Module", "Third::Module::Too", { -version => 4.56 } );', [qw(Some::Module Other::Module Third::Module::Too)],undef,[qw(Some::Module Other::Module Third::Module::Too)]],

    ['$foo->load_class("Some::Module")', undef, undef, undef],
    ['Other::Namespace::load_class("Some::Module")', undef, undef, undef],
    ['$foo->try_load_class("Some::Module")', undef, undef, undef],
    ['Other::Namespace::try_load_class("Some::Module")', undef, undef, undef],
    ['$foo->load_optional_class("Some::Module")', undef, undef, undef],
    ['Other::Namespace::load_optional_class("Some::Module")', undef, undef, undef],
    ['$foo->load_first_existing_class("Some::Module")', undef, undef, undef],
    ['Other::Namespace::load_first_existing_class("Some::Module")', undef, undef, undef],
);


plan tests => (scalar @tests)*3+1;


foreach my $t (@tests) {
    my ($code, @expected)=@$t;
    my $p=Module::ExtractUse->new;

    my @used = (
        $p->extract_use(\$code)->arrayref || undef,
        $p->extract_use(\$code)->arrayref_in_eval || undef,
        $p->extract_use(\$code)->arrayref_out_of_eval || undef,
    );

    for(my $i = 0; $i < @used; ++$i) {
        if (ref($expected[$i]) eq 'ARRAY') {
            cmp_bag($used[$i]||[],$expected[$i],$i.": ".$code);
        } elsif (!defined $expected[$i]) {
            is(undef,$used[$i],$i.": ".$code);
        } else {
            is($used[$i],$expected[$i],$i.": ".$code);
        }
    }
}



