use strict;
use warnings;

use Open::This qw( parse_text to_editor_args );
use Path::Tiny qw( path );
use Test::More;
use Test::Differences;

{
    my $text        = 'lib/Foo/Bar.pm line 222.';
    my $line_number = Open::This::_maybe_extract_line_number( \$text );
    is( $line_number, 222, 'line_number' );
    is( $text, 'lib/Foo/Bar.pm', 'line number stripped' );
}

{
    my $text        = 'lib/Open/This.pm:17';
    my $line_number = Open::This::_maybe_extract_line_number( \$text );
    is( $line_number, 17, 'git-grep line_number' );
    is( $text, 'lib/Open/This.pm', 'git-grep line number stripped' );
}

{
    my $text        = 'lib/Open/This.pm-17-';
    my $line_number = Open::This::_maybe_extract_line_number( \$text );
    is( $line_number, 17, 'git-grep context line_number' );
    is( $text, 'lib/Open/This.pm', 'git-grep context line number stripped' );
}

{
    my $text        = 'lib/Open/This.pm-17';
    my $line_number = Open::This::_maybe_extract_line_number( \$text );
    is(
        $line_number, 17,
        'git-grep context line_number without trailing dash'
    );
    is( $text, 'lib/Open/This.pm', 'git-grep context line number stripped' );
}

{
    my $text = 'lib/Open/This.pm::do_something()';
    my $name = Open::This::_maybe_extract_subroutine_name( \$text );
    is( $name, 'do_something',     'subroutine name' );
    is( $text, 'lib/Open/This.pm', 'sub name stripped from path' );
}

{
    my $text = 'Open::This::do_something()';
    my $name = Open::This::_maybe_extract_subroutine_name( \$text );
    is( $name, 'do_something', 'subroutine name' );
    is( $text, 'Open::This',   'sub name stripped' );
}

{
    my $text = q{Open::This::do_something('HASH(0x25521248)')};
    my $name = Open::This::_maybe_extract_subroutine_name( \$text );
    is( $name, 'do_something', 'subroutine name with args' );
    is( $text, 'Open::This',   'sub name stripped' );
}

{
    my $text = q{Foo::Bar::_render('This::Module=HASH(0x257631c0)')};
    my $name = Open::This::_maybe_extract_subroutine_name( \$text );
    is( $name, '_render',  'subroutine name with args' );
    is( $text, 'Foo::Bar', 'stringified object' );
}

{
    my $text = 'Foo::Bar';
    my $name = Open::This::_maybe_find_local_file($text);
    is( $name, 't/lib/Foo/Bar.pm', 'found local file' );
}

{
    local $ENV{OPEN_THIS_LIBS} = 'lib,t/lib,t/other-lib';

    my $text = 'Foo::Baz';
    my $name = Open::This::_maybe_find_local_file($text);
    is(
        $name, 't/other-lib/Foo/Baz.pm',
        'found local file in non-standard location'
    );
}

eq_or_diff(
    parse_text('t/lib/Foo/Bar.pm line 222.'),
    { file_name => 't/lib/Foo/Bar.pm', line_number => 222, },
    'line 222'
);

eq_or_diff(
    parse_text( 't/lib/Foo/Bar.pm', 'line', '222.' ),
    { file_name => 't/lib/Foo/Bar.pm', line_number => 222, },
    'parse_text with list'
);

eq_or_diff(
    parse_text('Foo::Bar::do_something()'),
    {
        file_name   => 't/lib/Foo/Bar.pm',
        line_number => 3,
        sub_name    => 'do_something',
    },
    'line 3'
);

eq_or_diff(
    parse_text('t/test-data/foo/bar/baz.html.ep line 5. Blah'),
    {
        file_name   => 't/test-data/foo/bar/baz.html.ep',
        line_number => 5,
    },
    'line 3 in Mojo template'
);

eq_or_diff(
    parse_text('t/lib/Foo/Bar.pm:32'),
    {
        file_name   => 't/lib/Foo/Bar.pm',
        line_number => 32,
    },
    'results from git-grep'
);

eq_or_diff(
    parse_text('t/Does/Not/Exist'),
    undef,
    'undef on not found file'
);

eq_or_diff(
    parse_text('X::Y'),
    undef,
    'undef on not found module'
);

eq_or_diff(
    parse_text('t/lib/Foo/Bar.pm'),
    { file_name => 't/lib/Foo/Bar.pm' },
    'file name passed in'
);

my $abs_path = path('t/lib/Foo/Bar.pm')->absolute;
eq_or_diff(
    parse_text("$abs_path line 41."),
    {
        file_name   => $abs_path->stringify,
        line_number => 41,
    },
    'line 41 in absolute path: ' . $abs_path
);

eq_or_diff(
    parse_text('/Users/Foo Bar/something/or/other.txt'),
    undef,
    'spaces in file name but not found'
);

eq_or_diff(
    parse_text('t/test-data/file with spaces'),
    { file_name => 't/test-data/file with spaces' },
    'spaces in file name and exists'
);

eq_or_diff(
    [ to_editor_args('t/test-data/file with spaces') ],
    ['t/test-data/file with spaces'],
    'spaces in file name'
);
eq_or_diff(
    [ to_editor_args('Foo::Bar::do_something()') ],
    [ '+3', 't/lib/Foo/Bar.pm', ],
    'open in vim on line 3'
);

eq_or_diff(
    [ to_editor_args('t/lib/Foo/Bar.pm line 2') ],
    [ '+2', 't/lib/Foo/Bar.pm', ],
    'open in vim on line 2'
);

eq_or_diff(
    [ to_editor_args('t/lib/Foo/Bar.pm::do_something()') ],
    [ '+3', 't/lib/Foo/Bar.pm', ],
    'path/to/file::sub_name()'
);

eq_or_diff(
    [ to_editor_args('t/lib/Foo/Bar.pm::do_something_else()') ],
    [ '+5', 't/lib/Foo/Bar.pm', ],
    'path/to/file::do_something_else()'
);

eq_or_diff(
    [ to_editor_args('t/lib/Foo/Bar.pm::do_something_else_again()') ],
    [ '+7', 't/lib/Foo/Bar.pm', ],
    'path/to/file::do_something_else_again()'
);

my $more = parse_text('Test::More');
ok( $more->{file_name}, 'found Test::More on disk' );

done_testing();
