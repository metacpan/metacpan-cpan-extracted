#!perl

package Role::Test::Module;

use Test::More;
use Role::Tiny;
use feature qw(say);

sub _dumper {
    require Data::Dumper;
    say Data::Dumper
      ->new( [@_] )
      ->Terse( 1 )
      ->Indent( 1 )
      ->Sortkeys( 1 )
      ->Purity( 1 )
      ->Dump;
}

requires qw(
  lol
  expected_tree
  expected_find_title
  expected_find_events
  define_cases
  define_find_cases
);

sub new {
    my ( $class ) = @_;
    say "$class";
    bless {}, $class;
}

sub run {
    my ( $test_class, %parms ) = @_;
    my $obj = new( $test_class );

    use_ok( "Pod::Query" ) || print "Bail out!\n";
    diag( "Testing Pod::Query $Pod::Query::VERSION, Perl $], $^X" );
    pass "=== Using saved pod from $parms{module} ===";

    my $class_dir = "dir";
    my $class     = "MyClass";

    # TODO: Tidy up after restructuring Pod::Query.
    {
        no warnings qw( redefine once );
        $Pod::Query::MOCK_ROOT = 1;
        *Pod::Query::_class_to_path =
          sub { shift; "$class_dir/" . shift() . ".pm" };
        *Pod::Query::_mock_root     = sub { $obj->lol };
        *Pod::Query::get_term_width = sub { 56 };          # Match android.
    }

    my $query = Pod::Query->new( $class );

    # path.
    is_deeply( $query->{path}, "$class_dir/$class.pm", "path" );

    # tree.
    is_deeply( $query->{tree}, $obj->expected_tree, "tree" );

    # find_title.
    is( $query->find_title(), $obj->expected_find_title, "find_title" );

    # find_events.
    my $expected_find_events = $obj->expected_find_events;
    is(
        scalar $query->find_events,
        join( "\n", @$expected_find_events ),
        "find_events - scalar context"
    );
    is_deeply(
        [ $query->find_events ],
        $expected_find_events,
        "find_events - list context"
    );

    # Methods.
    my $cases = $obj->define_cases;
    for my $case ( @$cases ) {
        pass "=== Starting $parms{module} - method: $case->{method} ===";

        # find_method.
        is(
            scalar $query->find_method( $case->{method} ),
            join( "\n", @{ $case->{expected_find_method} } ),
            "find_method($case->{method}) - scalar context"
        );
        is_deeply(
            [ $query->find_method( $case->{method} ) ],
            [ @{ $case->{expected_find_method} } ],
            "find_method($case->{method}) - list context"
        );

        # find_method_summary.
        is(
            scalar $query->find_method_summary( $case->{method} ),
            $case->{expected_find_method_summary},
            "find_method_summary($case->{method}) - scalar context"
        );
        is_deeply(
            [ $query->find_method_summary( $case->{method} ) ],
            [ $case->{expected_find_method_summary} ],
            "find_method_summary($case->{method}) - list context"
        );
    }

    # find.
    my $find_cases = $obj->define_find_cases;
    for my $case ( @$find_cases ) {
        my $debug = $case->{debug} // '';
        my $skip  = $case->{skip}  // '';

        if ( $skip ) {
          SKIP: {
                skip $skip;
            }
            next;
        }

        my $name = "find - $case->{name}";

        if ( ref $case->{find} ) {
            fail( "Update for find string and exptected_struct: $name" );
            next;
        }

        my $find = $case->{find};

        my $struct = Pod::Query->_query_string_to_struct( $find );

        say _dumper $struct
          unless is_deeply(
            $struct,
            $case->{expected_struct},
            "String to struct - $name",
          );

        my $expected    = $case->{expected_find};
        my $scalar_find = eval { $query->find( $find ) };

        if ( $@ ) {
            $case->{error} ? pass( $name ) : fail( $name );
            next;
        }

        is( $scalar_find, join( "\n", @$expected ), "$name - scalar context", );

        {
            local $Pod::Query::DEBUG_FIND = 1 if $debug eq "find";
            my @list_find = $query->find( $find );
            say _dumper \@list_find
              unless is_deeply( \@list_find, $expected, "$name - list context",
              );
        };
    }

    my $tests_count = $parms{tests} // 1;
    done_testing( $tests_count );
}

1;
