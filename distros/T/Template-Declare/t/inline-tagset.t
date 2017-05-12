# Test for RT48642 by Olivier Mengué

use Test::More tests => 1;

{
    package Template::Declare::TagSet::FooBarBaz;
    use base 'Template::Declare::TagSet';
    sub get_tag_list {
        [qw/foo bar baz/]
    }
}

eval "use Template::Declare::Tags 'FooBarBaz'";
my $res = $@;
SKIP: {
    skip "T::D::TS::FooBarBaz.pm exists, can't test!" if exists $INC{'Template/Declare/TagSet/FooBarBaz.pm'};
    ok(!$res, "use inline TagSet");
    diag $res if $res;
}
