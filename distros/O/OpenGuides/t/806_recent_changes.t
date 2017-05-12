use strict;
use OpenGuides;
use OpenGuides::Test;
use Test::More;
use Time::Piece;
use Time::Seconds;
use Wiki::Toolkit::Store::Database;

eval { require DBD::SQLite; };
if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all => "DBD::SQLite could not be used - no database to test with. ($error)";
}

plan tests => 16;

OpenGuides::Test::refresh_db();

my $config = OpenGuides::Test->make_basic_config;
my $guide = OpenGuides->new( config => $config );
my $wiki = $guide->wiki;

# Set things up so that we have the following nodes and edit types.  All
# nodes added 11 days ago.
# - Red Lion, edited 9 days ago (normal), 3 days ago (normal) and today (minor)
# - Blue Lion, edited 7 days ago (minor), 5 days ago (normal) & today (minor)
setup_pages();

# Check all went in OK.
my %red = $wiki->retrieve_node( "Red Lion" );
my %blue = $wiki->retrieve_node( "Blue Lion" );
ok( $wiki->node_exists( "Red Lion" ), "Red Lion written." );
ok( $wiki->node_exists( "Blue Lion" ), "Blue Lion written." );
is( $red{version}, 4, "Correct Red version." );
is( $blue{version}, 4, "Correct Blue version." );

# Check recent changes output when minor edits switched on.
my $cookie = OpenGuides::CGI->make_prefs_cookie( config => $config,
    show_minor_edits_in_rc => 1 );
$ENV{HTTP_COOKIE} = $cookie;

# First check default display.
my %tt_vars = $guide->display_recent_changes( return_tt_vars => 1 );
my @nodes = extract_nodes( %tt_vars );
my @names_vers = sort map { "$_->{name} (v$_->{version})" } @nodes;
is_deeply( \@names_vers, [ "Blue Lion (v4)", "Red Lion (v4)" ],
  "With minor edits: nodes returned only once however many times changed." );
diag( "Found: " . join( ", ", @names_vers ) );

# Should see the same thing for past 10 days.
my $now = localtime; # overloaded by Time::Piece
my $tendays = $now - ( ONE_DAY * 10 );
%tt_vars = $guide->display_recent_changes( return_tt_vars => 1,
    since => $tendays->epoch );
@nodes = extract_nodes( %tt_vars );
@names_vers = sort map { "$_->{name} (v$_->{version})" } @nodes;
is_deeply( \@names_vers, [ "Blue Lion (v4)", "Red Lion (v4)" ],
  "...same result when looking at past 10 days" );
diag( "Found: " . join( ", ", @names_vers ) );

# Check last day (both nodes edited minorly today, should show up).
my $yesterday = $now - ONE_DAY;
%tt_vars = $guide->display_recent_changes( return_tt_vars => 1,
    since => $yesterday->epoch );
@nodes = extract_nodes( %tt_vars );
@names_vers = sort map { "$_->{name} (v$_->{version})" } @nodes;
is_deeply( \@names_vers, [ "Blue Lion (v4)", "Red Lion (v4)" ],
  "...and both nodes included when we look at past day." );
diag( "Found: " . join( ", ", @names_vers ) );

# Check last 4 days (again, both should show up since this is minor edits,
# but they should only show up once).
my $fourdays = $now - ( ONE_DAY * 4 );
%tt_vars = $guide->display_recent_changes( return_tt_vars => 1,
    since => $fourdays->epoch );
@nodes = extract_nodes( %tt_vars );
@names_vers = sort map { "$_->{name} (v$_->{version})" } @nodes;
is_deeply( \@names_vers, [ "Blue Lion (v4)", "Red Lion (v4)" ],
  "...and past 4 days" );
diag( "Found: " . join( ", ", @names_vers ) );

# Now test with minor edits switched off.
$cookie = OpenGuides::CGI->make_prefs_cookie( config => $config,
    show_minor_edits_in_rc => 0 );
$ENV{HTTP_COOKIE} = $cookie;

# First check default display.
%tt_vars = $guide->display_recent_changes( return_tt_vars => 1 );
@nodes = extract_nodes( %tt_vars );
@names_vers = sort map { "$_->{name} (v$_->{version})" } @nodes;
is_deeply( \@names_vers, [ "Blue Lion (v3)", "Red Lion (v3)" ],
  "Without minor edits: node returned only once however many times changed." );
diag( "Found: " . join( ", ", @names_vers ) );

# Should see the same thing for past 10 days.
%tt_vars = $guide->display_recent_changes( return_tt_vars => 1,
    since => $tendays->epoch );
@nodes = extract_nodes( %tt_vars );
@names_vers = sort map { "$_->{name} (v$_->{version})" } @nodes;
is_deeply( \@names_vers, [ "Blue Lion (v3)", "Red Lion (v3)" ],
  "...same result when looking at past 10 days" );
diag( "Found: " . join( ", ", @names_vers ) );

# Check last day (last normal edit 3 days ago - nothing should show up).
%tt_vars = $guide->display_recent_changes( return_tt_vars => 1,
    since => $yesterday->epoch );
@nodes = extract_nodes( %tt_vars );
@names_vers = sort map { "$_->{name} (v$_->{version})" } @nodes;
ok( scalar @nodes == 0,
    "...and nothing returned when no recent normal edits." );
diag( "Found: " . join( ", ", @names_vers ) );

# Check last 4 days (should only see one normal edit, for Red Lion).
%tt_vars = $guide->display_recent_changes( return_tt_vars => 1,
    since => $fourdays->epoch );
@nodes = extract_nodes( %tt_vars );
@names_vers = sort map { "$_->{name} (v$_->{version})" } @nodes;
is_deeply( \@names_vers, [ "Red Lion (v3)" ],
  "...and only normally-edited nodes returned for past 4 days" );
diag( "Found: " . join( ", ", @names_vers ) );

# Now write a node that will Auto Create a locale, and check the
# Recent Changes output with minor edits and admin links switched on.
# We can't use OG::Test->write_data() for this, because it calls
# make_cgi_object(), which overwrites REMOTE_ADDR (and we want to test
# output of IP address).
my $q = OpenGuides::Test->make_cgi_object();
$q->param( -name => "username", -value => "Anonymous" );
$q->param( -name => "locales", -value => "London" );
my $test_host = "198.51.100.255";
$ENV{REMOTE_ADDR} = $test_host;
$guide->commit_node( id => "A Pub", cgi_obj => $q, return_output => 1 );
$ENV{HTTP_COOKIE} = OpenGuides::CGI->make_prefs_cookie(
    config => $config, show_minor_edits_in_rc => 1, is_admin => 1 );
my $output = $guide->display_recent_changes( return_output => 1 );
like( $output, qr|Auto\s+Create|,
      "Auto Create stuff shown on Recent Changes." );
unlike( $output, qr|host=;action=userstats|,
        "...and no spurious link to host userstats" );

# Make sure IP addresses always show up for anonymous edits.
$ENV{HTTP_COOKIE} = OpenGuides::CGI->make_prefs_cookie(
    config => $config, is_admin => 1 );
$output = $guide->display_recent_changes( return_output => 1 );
like( $output, qr|$test_host|,
      "IP addresses show for anon edits when admin links switched on" );
$ENV{HTTP_COOKIE} = OpenGuides::CGI->make_prefs_cookie(
    config => $config, is_admin => 0 );
$output = $guide->display_recent_changes( return_output => 1 );
like( $output, qr|$test_host|,
      "...also when admin links switched off" );

sub setup_pages {
    # We write directly to the database because that way we can fake the pages
    # having been written in the past.  Copied from test 062 in Wiki::Toolkit.
    my $dbh = $wiki->store->dbh;
    my $content_sth = $dbh->prepare( "INSERT INTO content
                                     (node_id,version,text,modified)
                                     VALUES (?,?,?,?)");
    my $node_sth = $dbh->prepare( "INSERT INTO node
                                  (id,name,version,text,modified)
                                  VALUES (?,?,?,?,?)");
    my $md_sth = $dbh->prepare( "INSERT INTO metadata
                                 (node_id,version,metadata_type,metadata_value)
                                 VALUES (?,?,?,?)");

    # Red Lion first.
    $node_sth->execute( 10, "Red Lion", 3, "red 2",
                        get_timestamp( days => 3 ) )
        or die $dbh->errstr;
    $content_sth->execute( 10, 3, "red 3", get_timestamp( days => 3 ) )
        or die $dbh->errstr;
    $content_sth->execute( 10, 2, "red 2", get_timestamp( days => 9 ) )
        or die $dbh->errstr;
    $content_sth->execute( 10, 1, "red 1", get_timestamp( days => 11 ) )
        or die $dbh->errstr;
    $md_sth->execute( 10, 3, "edit_type", "Normal edit" );
    $md_sth->execute( 10, 2, "edit_type", "Normal edit" );
    $md_sth->execute( 10, 1, "edit_type", "Normal edit" );
    $md_sth->execute( 10, 3, "comment", "Third red edit." );
    $md_sth->execute( 10, 2, "comment", "Second red edit." );
    $md_sth->execute( 10, 1, "comment", "First red edit." );

    # Now write it as per usual.
    OpenGuides::Test->write_data( guide => $guide, node => "Red Lion",
        content => "red 4", edit_type => "Minor tidying",
        comment => "Fourth red edit.", return_output => 1 );

    # Now Blue Lion.
    $node_sth->execute( 20, "Blue Lion", 3, "blue 3",
                        get_timestamp( days => 5 ) )
        or die $dbh->errstr;
    $content_sth->execute( 20, 3, "blue 3", get_timestamp( days => 5 ) )
        or die $dbh->errstr;
    $content_sth->execute( 20, 2, "blue 2", get_timestamp( days => 7 ) )
        or die $dbh->errstr;
    $content_sth->execute( 20, 1, "blue 1", get_timestamp( days => 11 ) )
        or die $dbh->errstr;
    $md_sth->execute( 20, 3, "edit_type", "Normal edit" );
    $md_sth->execute( 20, 2, "edit_type", "Minor tidying" );
    $md_sth->execute( 20, 1, "edit_type", "Normal edit" );
    $md_sth->execute( 20, 3, "comment", "Third blue edit." );
    $md_sth->execute( 20, 2, "comment", "Second blue edit." );
    $md_sth->execute( 20, 1, "comment", "First blue edit." );

    # Now write it as per usual.
    OpenGuides::Test->write_data( guide => $guide, node => "Blue Lion",
        content => "blue 4", edit_type => "Minor tidying",
        comment => "Fourth blue edit.", return_output => 1);
}

sub get_timestamp {
    my %args = @_;
    my $days = $args{days};
    my $now = localtime; # overloaded by Time::Piece
    my $time = $now - ( $days * ONE_DAY );
    return Wiki::Toolkit::Store::Database->_get_timestamp( $time );
}

sub extract_nodes {
    my %tt_vars = @_;
    my %rc = %{$tt_vars{recent_changes} };
    return @{ $rc{1} || [] }, @{ $rc{7} || [] }, @{ $rc{14} || [] },
           @{ $rc{since} || [] };
}
