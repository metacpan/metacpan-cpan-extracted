use strict;
use Wiki::Toolkit::Setup::SQLite;
use OpenGuides;
use OpenGuides::Test;
use Test::More;

eval { require DBD::SQLite; };

if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all => "DBD::SQLite could not be used - no database to test with. ($error)";
}

plan tests => 28;

SKIP: {
    # Clear out the database from any previous runs.
    OpenGuides::Test::refresh_db();

    my $config = OpenGuides::Test->make_basic_config;
    my $guide = OpenGuides->new( config => $config );
    my $wiki = $guide->wiki;

    # Test @INDEX_LINK
    $wiki->write_node( "Category Alpha", "\@INDEX_LINK [[Category Alpha]]",
                       undef, { category => "category" } )
      or die "Can't write node";

    $wiki->write_node( "Category Beta", "\@INDEX_LINK [[Category Beta|Betas]]",
                       undef, { category => "category" } )
      or die "Can't write node";

    my $output;
    $output = $guide->display_node(
                                    return_output => 1,
                                    id            => "Category Alpha",
                                  );
    like( $output, qr/View all pages in Category Alpha/,
          "\@INDEX_LINK has right default link text" );
    like( $output, qr/action=index;cat=alpha/, "...and URL looks right" );

    $output = $guide->display_node(
                                    return_output => 1,
                                    id            => "Category Beta",
                                  );
    like( $output, qr/>Betas<\/a>/, "Default link text can be overridden" );
    like( $output, qr/action=index;cat=beta/, "...and URL looks right" );

    # Test @INDEX_LIST
    $wiki->write_node( "Category Foo", "\@INDEX_LIST [[Category Foo]]",
                       undef, { category => "category" } )
      or die "Can't write node";
    $wiki->write_node( "Locale Bar", "\@INDEX_LIST [[Locale Bar]]",
                       undef, { category => "locales" } )
      or die "Can't write node";
    $wiki->write_node( "Category Empty", "\@INDEX_LIST [[Category Empty]]",
                       undef, { category => "foo" } )
      or die "Can't write node";
    $wiki->write_node( "Locale Empty", "\@INDEX_LIST [[Locale Empty]]",
                       undef, { locale => "bar" } )
      or die "Can't write node";
    $wiki->write_node( "Wibble", "wibble", undef,
                       {
                         category => "foo",
                         locale   => "bar",
                       }
                     )
      or die "Can't write node";

    $output = $guide->display_node(
                                    return_output => 1,
                                    id            => "Category Foo",
                                  );
    like ( $output, qr|<a href=".*">Wibble</a>|,
           '@INDEX_LIST works for regular pages in categories' );
    like ( $output, qr|<a href=".*">Category Empty</a>|,
           '...and for category pages in categories' );
    $output = $guide->display_node(
                                    return_output => 1,
                                    id            => "Category Empty",
                                  );
    like ( $output, qr|No pages currently in category|,
           "...and fails nicely if no pages in category" );
    $output = $guide->display_node(
                                    return_output => 1,
                                    id            => "Locale Bar",
                                  );
    like ( $output, qr|<a href=".*">Wibble</a>|,
           '@INDEX_LIST works for regular pages in locales' );
    like ( $output, qr|<a href=".*">Locale Empty</a>|,
           '...and for locale pages in locales' );
    $output = $guide->display_node(
                                    return_output => 1,
                                    id            => "Locale Empty",
                                  );
    like ( $output, qr|No pages currently in locale|,
           "...and fails nicely if no pages in locale" );

    # Test @INDEX_LIST_NO_PREFIX
    $wiki->write_node( "Category Foo NP",
                       "\@INDEX_LIST_NO_PREFIX [[Category Foo NP]]",
                       undef, { category => "category" } )
      or die "Can't write node";
    $wiki->write_node( "Locale Bar NP",
                       "\@INDEX_LIST_NO_PREFIX [[Locale Bar NP]]",
                       undef, { category => "locales" } )
      or die "Can't write node";
    $wiki->write_node( "Category Empty NP",
                      "\@INDEX_LIST_NO_PREFIX [[Category Empty NP]]",
                       undef, { category => "foo np" } )
      or die "Can't write node";
    $wiki->write_node( "Locale Empty NP",
                       "\@INDEX_LIST_NO_PREFIX [[Locale Empty NP]]",
                       undef, { locale => "bar np" } )
      or die "Can't write node";
    $wiki->write_node( "Wibble NP", "wibble", undef,
                       {
                         category => "foo np",
                         locale   => "bar np",
                       }
                     )
      or die "Can't write node";

    $output = $guide->display_node(
                                    return_output => 1,
                                    id            => "Category Foo NP",
                                  );
    like ( $output, qr|<a href=".*">Wibble NP</a>|,
           '@INDEX_LIST_NO_PREFIX works for regular pages in categories' );
    like ( $output, qr|<a href=".*">Empty NP</a>|,
           '...and for category pages in categories' );
    $output = $guide->display_node(
                                    return_output => 1,
                                    id            => "Category Empty NP",
                                  );
    like ( $output, qr|No pages currently in category|,
           "...and fails nicely if no pages in category" );
    $output = $guide->display_node(
                                    return_output => 1,
                                    id            => "Locale Bar NP",
                                  );
    like ( $output, qr|<a href=".*">Wibble NP</a>|,
           '@INDEX_LIST_NO_PREFIX works for regular pages in locales' );
    like ( $output, qr|<a href=".*">Empty NP</a>|,
           '...and for locale pages in locales' );
    $output = $guide->display_node(
                                    return_output => 1,
                                    id            => "Locale Empty NP",
                                  );
    like ( $output, qr|No pages currently in locale|,
           "...and fails nicely if no pages in locale" );

    # Test @MAP_LINK
    OpenGuides::Test->write_data(
                                  guide   => $guide,
                                  node    => "Test 1",
                                  content => "\@MAP_LINK [[Category Foo]]",
                                  return_output => 1,
                                );
    OpenGuides::Test->write_data(
                                  guide   => $guide,
                                  node    => "Test 2",
                                  content => "\@MAP_LINK [[Category Foo|Map]]",
                                  return_output => 1,
                                );
    $output = $guide->display_node(
                                    return_output => 1,
                                    id            => "Test 1",
                                  );
    like( $output, qr/View map of pages in Category Foo/,
          "\@MAP_LINK has right default link text" );
    like( $output, qr/\bcat=foo\b/, "...and URL looks right" );

    $output = $guide->display_node(
                                    return_output => 1,
                                    id            => "Test 2",
                                  );
    like( $output, qr/>Map<\/a>/, "Default link text can be overridden" );
    like( $output, qr/\bcat=foo\b/, "...and URL looks right" );

    # Test @RANDOM_PAGE_LINK
    OpenGuides::Test->write_data(
                                  guide   => $guide,
                                  node    => "Test Random",
                                  content => "\@RANDOM_PAGE_LINK",
                                  return_output => 1,
                                );
    $output = $guide->display_node(
                                    return_output => 1,
                                    id            => "Test Random",
                                  );
    like( $output, qr/View a random page on this guide/,
          "\@RANDOM_PAGE_LINK has right default link text" );

    # Not sure yet how to let people override link text in the above.  TODO.

    OpenGuides::Test->write_data(
                                  guide   => $guide,
                                  node    => "Test Random",
                                  content => "\@RANDOM_PAGE_LINK "
                                             . "[[Category Pubs]]",
                                  return_output => 1,
                                );
    $output = $guide->display_node(
                                    return_output => 1,
                                    id            => "Test Random",
                                  );
    like( $output, qr/View a random page in Category Pubs/,
          "\@RANDOM_PAGE_LINK has right default link text for categories" );
    OpenGuides::Test->write_data(
                                  guide   => $guide,
                                  node    => "Test Random",
                                  content => "\@RANDOM_PAGE_LINK "
                                             . "[[Category Pubs|Random pub]]",
                                  return_output => 1,
                                );
    $output = $guide->display_node(
                                    return_output => 1,
                                    id            => "Test Random",
                                  );
    like( $output, qr/>Random pub<\/a>/, "...and can be overridden" );

    OpenGuides::Test->write_data(
                                  guide   => $guide,
                                  node    => "Test Random",
                                  content => "\@RANDOM_PAGE_LINK "
                                             . "[[Locale Fulham]]",
                                  return_output => 1,
                                );
    $output = $guide->display_node(
                                    return_output => 1,
                                    id            => "Test Random",
                                  );
    like( $output, qr/View a random page in Locale Fulham/,
          "\@RANDOM_PAGE_LINK has right default link text for categories" );
    OpenGuides::Test->write_data(
                                  guide   => $guide,
                                  node    => "Test Random",
                                  content => "\@RANDOM_PAGE_LINK "
                                             . "[[Locale Fulham|"
                                             . "Random thing in Fulham]]",
                                  return_output => 1,
                                );
    $output = $guide->display_node(
                                    return_output => 1,
                                    id            => "Test Random",
                                  );
    like( $output, qr/>Random thing in Fulham<\/a>/,
          "...and can be overridden" );

    # Test @INCLUDE_NODE
    OpenGuides::Test->write_data(
                                  guide   => $guide,
                                  node    => "Test 1",
                                  content => "Hello, I am Test 1!\r\n"
                                             . "\@INCLUDE_NODE [[Test 2]]",
                                  return_output => 1,
                                );
    OpenGuides::Test->write_data(
                                  guide   => $guide,
                                  node    => "Test 2",
                                  content => "Hello, I am Test 2!",
                                  return_output => 1,
                                );
    $output = $guide->display_node(
                                    return_output => 1,
                                    id            => "Test 1",
                                  );
    like( $output, qr/Hello, I am Test 1!/,
          "Node with \@INCLUDE_NODE has its own content" );
    like( $output, qr/Hello, I am Test 2!/,
          "...and the included content" );
    #Test @NODE_COUNT
    OpenGuides::Test->write_data(
                                  guide   => $guide,
                                  node    => "node count test",
                                  content => "there are \@NODE_COUNT [[Category Foo]] things in [[Category Foo]]",
                                  return_output => 1,
                                );
    $output = $guide->display_node(
                                    return_output => 1,
                                    id            => "node count test",
                                  );
    like( $output, qr/there are 2 things in/,
          "Node with \@NODE_COUNT has a value of 2" );
}
