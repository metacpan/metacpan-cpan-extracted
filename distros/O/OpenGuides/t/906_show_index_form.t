use strict;
use Wiki::Toolkit::Setup::SQLite;
use OpenGuides;
use OpenGuides::CGI;
use OpenGuides::Test;
use Test::More;

eval { require DBD::SQLite; };
if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all => "DBD::SQLite could not be used - no database to test with ($error)";
}

eval { require Test::HTML::Content; };
if ( $@ ) {
    plan skip_all => "Test::HTML::Content not available";
}

plan tests => 40;

# Clear out the database from any previous runs.
OpenGuides::Test::refresh_db();

my $config = OpenGuides::Test->make_basic_config;
my $guide = OpenGuides->new( config => $config );

# Write some nodes with categories and things.
OpenGuides::Test->write_data( guide => $guide, node => "A Node",
                              categories => "Apples\r\nBananas\r\nCherries",
                              locales => "Anerley\r\nBrockley\r\nChiswick",
                              return_output => 1 );

# Test the form for altering the search - first with no criteria.
my @dropdowns = eval {
    OpenGuides::CGI->make_index_form_dropdowns( guide => $guide );
};
ok( !$@, "->make_index_form_dropdowns doesn't die when no criteria supplied" );
my $html = '<html>' . join( " ", ( map { $_->{html} } @dropdowns ) ) . '</html>';
Test::HTML::Content::tag_ok( $html, "select", { name => "cat" },
                             "...and we have a 'cat' select" );
like( $html, qr/apples.*bananas.*cherries/is,
      "...and the categories seem to be in the right order" );
Test::HTML::Content::tag_ok( $html, "select", { name => "loc" },
                             "...and we have a 'loc' select" );
like( $html, qr/anerley.*brockley.*chiswick/is,
      "...and the locales seem to be in the right order" );
ok( $dropdowns[0]{type} eq "category" && $dropdowns[1]{type} eq "locale",
    "...and category dropdown comes before locale dropdown" );
my @cat_dropdowns = grep { $_->{type} eq "category" } @dropdowns;
my @loc_dropdowns = grep { $_->{type} eq "locale" } @dropdowns;
Test::HTML::Content::tag_ok( $cat_dropdowns[0]{html}, "option",
    { value => "", selected => "selected" },
    "...and the empty value is selected for category" );
Test::HTML::Content::tag_ok( $loc_dropdowns[0]{html}, "option",
    { value => "", selected => "selected" },
    "...and the empty value is selected for locale" );

# Now try it with one category, no locale.
@dropdowns = eval {
    OpenGuides::CGI->make_index_form_dropdowns(
        guide => $guide,
        selected => [ { type => "category", value => "bananas" } ],
    );
};
ok( !$@, "->make_index_form_dropdowns doesn't die when category supplied" );
$html = '<html>' . join( " ", ( map { $_->{html} } @dropdowns ) ) . '</html>';
Test::HTML::Content::tag_ok( $html, "select", { name => "cat" },
                             "...and we have a 'cat' select" );
like( $html, qr/apples.*bananas.*cherries/is,
      "...and the categories seem to be in the right order" );
Test::HTML::Content::tag_ok( $html, "select", { name => "loc" },
                             "...and we have a 'loc' select" );
like( $html, qr/anerley.*brockley.*chiswick/is,
      "...and the locales seem to be in the right order" );
ok( $dropdowns[0]{type} eq "category" && $dropdowns[1]{type} eq "locale",
    "...and category dropdown comes before locale dropdown" );
@cat_dropdowns = grep { $_->{type} eq "category" } @dropdowns;
@loc_dropdowns = grep { $_->{type} eq "locale" } @dropdowns;
Test::HTML::Content::tag_ok( $cat_dropdowns[0]{html}, "option",
    { value => "bananas", selected => "selected" },
    "...and the category is selected" );
Test::HTML::Content::tag_ok( $cat_dropdowns[0]{html}, "option",
    { value => "" },
    "...and the empty value is present in the category dropdown" );
Test::HTML::Content::no_tag( $cat_dropdowns[0]{html}, "option",
    { value => "", selected => "selected" },
    "...but not selected" );
Test::HTML::Content::tag_ok( $loc_dropdowns[0]{html}, "option",
    { value => "", selected => "selected" },
    "...and the empty value is selected for locale" );

# Now with one locale, no category.
@dropdowns = eval {
    OpenGuides::CGI->make_index_form_dropdowns(
        guide => $guide,
        selected => [ { type => "locale", value => "anerley" } ],
    );
};
ok( !$@, "->make_index_form_dropdowns doesn't die when locale supplied" );
$html = '<html>' . join( " ", ( map { $_->{html} } @dropdowns ) ). '</html>';
Test::HTML::Content::tag_ok( $html, "select", { name => "cat" },
                             "...and we have a 'cat' select" );
like( $html, qr/apples.*bananas.*cherries/is,
      "...and the categories seem to be in the right order" );
Test::HTML::Content::tag_ok( $html, "select", { name => "loc" },
                             "...and we have a 'loc' select" );
like( $html, qr/anerley.*brockley.*chiswick/is,
      "...and the locales seem to be in the right order" );
ok( $dropdowns[0]{type} eq "category" && $dropdowns[1]{type} eq "locale",
    "...and category dropdown comes before locale dropdown" );
@cat_dropdowns = grep { $_->{type} eq "category" } @dropdowns;
@loc_dropdowns = grep { $_->{type} eq "locale" } @dropdowns;
Test::HTML::Content::tag_ok( $loc_dropdowns[0]{html}, "option",
    { value => "anerley", selected => "selected" },
    "...and the locale is selected" );
Test::HTML::Content::tag_ok( $loc_dropdowns[0]{html}, "option",
    { value => "" },
    "...and the empty value is present in the locale dropdown" );
Test::HTML::Content::no_tag( $loc_dropdowns[0]{html}, "option",
    { value => "", selected => "selected" },
    "...but not selected" );
Test::HTML::Content::tag_ok( $cat_dropdowns[0]{html}, "option",
    { value => "", selected => "selected" },
    "...and the empty value is selected for category" );

# Now test with a category and a locale.
@dropdowns = eval {
    OpenGuides::CGI->make_index_form_dropdowns(
        guide => $guide,
        selected => [
                      { type => "category", value => "cherries" },
                      { type => "locale",   value => "chiswick" },
                    ],
    );
};
ok( !$@,
  "->make_index_form_dropdowns doesn't die when locale and categorysupplied" );
$html = '<html>' . join( " ", ( map { $_->{html} } @dropdowns ) ). '</html>';
Test::HTML::Content::tag_ok( $html, "select", { name => "cat" },
                             "...and we have a 'cat' select" );
like( $html, qr/apples.*bananas.*cherries/is,
      "...and the categories seem to be in the right order" );
Test::HTML::Content::tag_ok( $html, "select", { name => "loc" },
                             "...and we have a 'loc' select" );
like( $html, qr/anerley.*brockley.*chiswick/is,
      "...and the locales seem to be in the right order" );
ok( $dropdowns[0]{type} eq "category" && $dropdowns[1]{type} eq "locale",
    "...and category dropdown comes before locale dropdown" );
@cat_dropdowns = grep { $_->{type} eq "category" } @dropdowns;
@loc_dropdowns = grep { $_->{type} eq "locale" } @dropdowns;
Test::HTML::Content::tag_ok( $cat_dropdowns[0]{html}, "option",
    { value => "cherries", selected => "selected" },
    "...and the category is selected" );
Test::HTML::Content::tag_ok( $cat_dropdowns[0]{html}, "option",
    { value => "" },
    "...and the empty value is present in the category dropdown" );
Test::HTML::Content::no_tag( $cat_dropdowns[0]{html}, "option",
    { value => "", selected => "selected" },
    "...but not selected" );
Test::HTML::Content::tag_ok( $loc_dropdowns[0]{html}, "option",
    { value => "chiswick", selected => "selected" },
    "...and the locale is selected" );
Test::HTML::Content::tag_ok( $loc_dropdowns[0]{html}, "option",
    { value => "" },
    "...and the empty value is present in the locale dropdown" );
Test::HTML::Content::no_tag( $loc_dropdowns[0]{html}, "option",
    { value => "", selected => "selected" },
    "...but not selected" );
