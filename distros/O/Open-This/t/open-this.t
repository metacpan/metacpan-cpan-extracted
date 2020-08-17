use strict;
use warnings;

use Open::This qw( parse_text to_editor_args );
use Path::Tiny qw( path );
use Test::More;
use Test::Differences qw( eq_or_diff );
use Test::Warnings;

# This gets really noisy on Travis if $ENV{EDITOR} is not set
local $ENV{EDITOR} = 'vim';

{
    my $text        = 'lib/Foo/Bar.pm line 222.';
    my $line_number = Open::This::_maybe_extract_line_number( \$text );
    is( $line_number, 222,              'line_number' );
    is( $text,        'lib/Foo/Bar.pm', 'line number stripped' );
}

{
    my $text        = 'lib/Open/This.pm:17';
    my $line_number = Open::This::_maybe_extract_line_number( \$text );
    is( $line_number, 17,                 'git-grep line_number' );
    is( $text,        'lib/Open/This.pm', 'git-grep line number stripped' );
}

{
    my $text        = 'lib/Open/This.pm#L17';
    my $line_number = Open::This::_maybe_extract_line_number( \$text );
    is( $line_number, 17,                 'GitHub line_number' );
    is( $text,        'lib/Open/This.pm', 'GitHub line number stripped' );
}

{
    my $text        = 'lib/Open/This.pm#L17-L18';
    my $line_number = Open::This::_maybe_extract_line_number( \$text );
    is( $line_number, 17,                 'GitHub line range' );
    is( $text,        'lib/Open/This.pm', 'GitHub line range stripped' );
}

{
    my $text        = 'lib/Open/This.pm-17-';
    my $line_number = Open::This::_maybe_extract_line_number( \$text );
    is( $line_number, 17, 'git-grep context line_number' );
    is( $text, 'lib/Open/This.pm', 'git-grep context line number stripped' );
}

{
    my $text = './lib/Open/This.pm:17:3';
    my ( $line_number, $column_number )
        = Open::This::_maybe_extract_line_number( \$text );
    is( $line_number,   17, 'ripgrep line_number' );
    is( $column_number, 3,  'ripgrep column_number' );
    is(
        $text, './lib/Open/This.pm',
        'ripgrep context line number and column number stripped'
    );
}

{
    my $text = './lib/Open/This.pm:[17,3]';
    my ( $line_number, $column_number )
        = Open::This::_maybe_extract_line_number( \$text );
    is( $line_number,   17, 'mvn test line_number' );
    is( $column_number, 3,  'mvn test column_number' );
    is(
        $text, './lib/Open/This.pm',
        'mvn test context line number and column number stripped'
    );
}

{
    my $text = './lib/Open/This.pm:135:20:sub _maybe_extract_line_number {';
    my ( $line_number, $column_number )
        = Open::This::_maybe_extract_line_number( \$text );
    is( $line_number,   135, 'ripgrep line_number' );
    is( $column_number, 20,  'ripgrep column_number' );
    is(
        $text, './lib/Open/This.pm',
        'ripgrep context line number and column number stripped'
    );
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

{
    my $text = 't/lib/Foo/Bar.pm line 222.';
    eq_or_diff(
        parse_text($text),
        {
            file_name     => 't/lib/Foo/Bar.pm',
            line_number   => 222,
            original_text => $text,
        },
        'line 222'
    );
}

{
    my @text = ( 't/lib/Foo/Bar.pm', 'line', '222.' );
    eq_or_diff(
        parse_text(@text),
        {
            file_name     => 't/lib/Foo/Bar.pm',
            line_number   => 222,
            original_text => join( q{ }, @text ),
        },
        'parse_text with list'
    );
}

{
    my $text = 'Foo::Bar::do_something()';
    eq_or_diff(
        parse_text($text),
        {
            file_name      => 't/lib/Foo/Bar.pm',
            is_module_name => 1,
            line_number    => 3,
            original_text  => $text,
            sub_name       => 'do_something',
        },
        'line 3'
    );
}

{
    my $text = 't/test-data/foo/bar/baz.html.ep line 5. Blah';
    eq_or_diff(
        parse_text($text),
        {
            file_name     => 't/test-data/foo/bar/baz.html.ep',
            line_number   => 5,
            original_text => $text,
        },
        'line 3 in Mojo template'
    );
}

{
    my $text = 't/lib/Foo/Bar.pm:32';
    eq_or_diff(
        parse_text($text),
        {
            file_name     => 't/lib/Foo/Bar.pm',
            line_number   => 32,
            original_text => $text,
        },
        'results from git-grep'
    );
}

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

{
    my $text = 't/lib/Foo/Bar.pm';
    eq_or_diff(
        parse_text($text),
        {
            file_name     => 't/lib/Foo/Bar.pm',
            original_text => $text,
        },
        'file name passed in'
    );
}

{
    my $abs_path = path('t/lib/Foo/Bar.pm')->absolute;
    my $text     = "$abs_path line 41.";
    eq_or_diff(
        parse_text($text),
        {
            file_name     => $abs_path->stringify,
            line_number   => 41,
            original_text => $text,
        },
        'line 41 in absolute path: ' . $abs_path
    );
}

eq_or_diff(
    parse_text('/Users/Foo Bar/something/or/other.txt'),
    undef,
    'spaces in file name but not found'
);

{
    my $text = 'a/t/test-data/file';
    eq_or_diff(
        parse_text($text),
        {
            file_name     => 't/test-data/file',
            original_text => $text,
        },
        'a git-diff path and the file exists'
    );
}

eq_or_diff(
    parse_text('a/t/test-data/i-m-not-here'),
    undef,
    'could have been a git diff file name, but it doesn\'t exist'
);

eq_or_diff(
    parse_text('b/t/test-data/i-m-not-here'),
    undef,
    'could have been the other variant of a git diff file name, but it doesn\'t exist'
);

{
    my $text = 't/test-data/file with spaces';
    eq_or_diff(
        parse_text($text),
        {
            file_name     => 't/test-data/file with spaces',
            original_text => $text,
        },
        'spaces in file name and exists'
    );
}

{
    my $text = 'lib/Open/This.pm#L17';
    eq_or_diff(
        parse_text($text),
        {
            file_name     => 'lib/Open/This.pm',
            line_number   => 17,
            original_text => $text,
        },
        'line number parsed out of partial GitHub URL'
    );
}

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
