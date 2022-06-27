#!perl
use v5.16;
use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok( 'Pod::Query' ) || print "Bail out!\n";
}

diag( "Testing Pod::Query $Pod::Query::VERSION, Perl $], $^X" );

my $class_dir = "dir";
my $class     = "MyClass1";

my @cases = (
    {
        name                => "Empty",
        pod_class           => $class++,
        lol                 => [],
        expected_tree       => [],
        expected_find_title => "",
    },
    {
        name      => "Head1-Para",
        pod_class => $class++,
        lol       => [
            [ "head1", "NAME" ],
            [
                "Para",
                "Example - Just an example"
            ],

        ],
        expected_tree => [
            {
                "kids" => [
                    {
                        "tag"  => "Para",
                        "text" => "Example - Just an example"
                    }
                ],
                "tag"  => "head1",
                "text" => "NAME"
            }
        ],
        expected_find_title => "Example - Just an example"
    },
    {
        name      => "Head1-Para (no cut)",
        pod_class => $class++,
        lol       => [
            [ "head1", "NAME" ],
            [
                "Para",
                "Example - Just an example"
            ],

        ],
        expected_tree => [
            {
                "kids" => [
                    {
                        "tag"  => "Para",
                        "text" => "Example - Just an example"
                    }
                ],
                "tag"  => "head1",
                "text" => "NAME"
            }
        ],
        expected_find_title => "Example - Just an example"
    },
    {
        name          => "Head2",
        pod_class     => $class++,
        lol           => [ [ "head2", "Function1" ], ],
        expected_tree => [
            {
                "tag"  => "head2",
                "text" => "Function1"
            }
        ],
        expected_find_title => "",
    },
    {
        name          => "Head2-Para",
        pod_class     => $class++,
        lol           => [ [ "head2", "Function1" ], [ "Para", "Summary" ], ],
        expected_tree => [
            {
                "kids" => [
                    {
                        "tag"  => "Para",
                        "text" => "Summary"
                    }
                ],
                "tag"  => "head2",
                "text" => "Function1"
            }
        ],
        expected_find_title => "",
    },
    {
        name      => "Head2-Para-Verbatim",
        pod_class => $class++,
        lol       => [
            [ "head2",    "Function1" ],
            [ "Para",     "Summary" ],
            [ "Verbatim", " Desc" ],
        ],
        expected_tree => [
            {
                "kids" => [
                    {
                        "tag"  => "Para",
                        "text" => "Summary"
                    },
                    {
                        "tag"  => "Verbatim",
                        "text" => " Desc"
                    }
                ],
                "tag"  => "head2",
                "text" => "Function1"
            }
        ],
        expected_find_title => "",
    },
);

$Pod::Query::MOCK_ROOT = 1;
{
    no warnings 'redefine';
    *Pod::Query::_class_to_path =
      sub { shift; "$class_dir/" . shift() . ".pm" };
}

for my $case ( @cases ) {
    pass "=== Starting $case->{pod_class} - $case->{name} ===";

    {
        no warnings 'redefine';
        *Pod::Query::_mock_root = sub { $case->{lol} };
    }

    my $query = Pod::Query->new( $case->{pod_class} );

    # Parse and compare
    is_deeply( $query->{path}, "$class_dir/$case->{pod_class}.pm", "path", );
    is_deeply( $query->{tree}, $case->{expected_tree},             "tree", );
    is( $query->find_title(), $case->{expected_find_title}, "find_title" );
}

done_testing( 25 );

