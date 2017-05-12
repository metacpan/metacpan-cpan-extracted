use strict;
use warnings;
use charnames qw( :full );

use Test::More;

use lib 't/lib';

use Silki::Test::FakeSchema;
use Silki::Schema::Page;

{
    my $tb = Test::Builder->new();

    binmode $_, ':utf8'
        for $tb->output(),
        $tb->failure_output(),
        $tb->todo_output();
}

{
    my @pairs = (
        [ 'Regular Title',                 'Regular_Title' ],
        [ 'Has_Underscore',                'Has%5FUnderscore' ],
        [ 'Some (Parens)',                 'Some_(Parens)' ],
        [ 'Foo & Bar 95%',                 'Foo_%26_Bar_95%25' ],
        [ "Smiley \N{WHITE SMILING FACE}", 'Smiley_%E2%98%BA' ],
    );

    for my $pair (@pairs) {
        is(
            Silki::Schema::Page->TitleToURIPath( $pair->[0] ), $pair->[1],
            "URI path for $pair->[0]"
        );

        is(
            Silki::Schema::Page->URIPathToTitle( $pair->[1] ), $pair->[0],
            "Title for $pair->[1]"
        );
    }
}

done_testing();
