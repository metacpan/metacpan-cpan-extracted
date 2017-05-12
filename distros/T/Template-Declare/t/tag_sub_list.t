#use Smart::Comments;
use strict;
use warnings;
use Test::More tests => 8;

{
    package Foo;
    use List::Util 'first';
    use Template::Declare::Tags 'HTML';

    my @list = @Template::Declare::Tags::TAG_SUB_LIST;
    ### @list
    my $tag = first { $_ eq 'table' } @list;
    ::is $tag, 'table', 'table {...} found';

    $tag = first { $_ eq 'li' } @list;
    ::is $tag, 'li', 'li {...} found';

    # Backward compatibility:
    @list = @Template::Declare::Tags::TagSubs;
    ### @list
    $tag = first { $_ eq 'table' } @list;
    ::is $tag, 'table', 'table {...} found';

    $tag = first { $_ eq 'li' } @list;
    ::is $tag, 'li', 'li {...} found';

}

{
    package Bar;
    use List::Util 'first';
    use Template::Declare::Tags 'XUL';
    my @list = @Template::Declare::Tags::TAG_SUB_LIST;

    my $tag = first { $_ eq 'div' } @list;
    ::is $tag, 'div', 'HTML tag div {...} also found';
    $tag = first { $_ eq 'tabbox' } @list;
    ::is $tag, 'tabbox', 'tabbox {...} found';

    # Backward compatibility:
    @list = @Template::Declare::Tags::TagSubs;

    $tag = first { $_ eq 'div' } @list;
    ::is $tag, 'div', 'HTML tag div {...} also found';
    $tag = first { $_ eq 'tabbox' } @list;
    ::is $tag, 'tabbox', 'tabbox {...} found';

}

