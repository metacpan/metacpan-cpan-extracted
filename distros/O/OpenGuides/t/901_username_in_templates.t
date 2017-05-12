use strict;
use Cwd;
use OpenGuides;
use OpenGuides::CGI;
use OpenGuides::Test;
use Test::More;

eval { require DBD::SQLite; };
if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all =>
        "DBD::SQLite could not be used - no database to test with. ($error)";
}

plan tests => 2;

# Clear out the database from any previous runs.
OpenGuides::Test::refresh_db();

my $config = OpenGuides::Test->make_basic_config;
$config->custom_template_path( cwd . "/t/templates/tmp/" );
my $guide = OpenGuides->new( config => $config );

# Write a node.
OpenGuides::Test->write_data(
                              guide => $guide,
                              node  => "Ship Of Fools",
                              return_output => 1,
                            );
# Make sure the tmp directory exists
eval {
    mkdir cwd . "/t/templates/tmp";
};
# Write a custom banner template that includes the username.
eval {
    unlink cwd . "/t/templates/tmp/custom_banner.tt";
};

open( my $fh, ">", cwd . "/t/templates/tmp/custom_banner.tt" ) or die $!;
print $fh <<EOF;
<div class="banner_username">
  [% IF username %]
    You are logged in as [% username %].
  [% ELSE %]
    You are not logged in.
  [% END %]
</div>
EOF
close $fh or die $!;

# Set a username in the cookie.
my $cookie = OpenGuides::CGI->make_prefs_cookie(
    config                     => $config,
    username                   => "Kake",
);
$ENV{HTTP_COOKIE} = $cookie;

# Check that username appears if cookie is set.
my $output = $guide->display_node( id => "Ship Of Fools", return_output => 1 );
like( $output, qr/You are logged in as Kake./,
      "username sent to templates if set in prefs cookie" );

# Check that username doesn't appear if cookie not set.
delete $ENV{HTTP_COOKIE};
$output = $guide->display_node( id => "Ship Of Fools", return_output => 1 );
like( $output, qr/You are not logged in./,
      "...but not if no username is set." );
