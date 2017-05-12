use strict;
use OpenGuides;
use OpenGuides::Test;
use Test::More;

eval { require DBD::SQLite; };
if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all => "DBD::SQLite could not be used - no database to test with. ($error)";
}

eval { require Test::HTML::Content; };
if ( $@ ) {
    plan skip_all => "Test::HTML::Content not installed";
}

plan tests => 3;

# Clear out the database from any previous runs.
OpenGuides::Test::refresh_db();

# Set up a guide with a custom macro module.
my $config = OpenGuides::Test->make_basic_config;
$config->custom_macro_module( "OpenGuides::Local::CustomMacros" );
my $guide = OpenGuides->new( config => $config );

# Write some data.
OpenGuides::Test->write_data( guide => $guide, node => "Home",
    content => '@INCLUDE_NODE [[Inclusion]]\n\n@GRAFFITI',
    return_output => 1 );
OpenGuides::Test->write_data( guide => $guide, node => "Inclusion",
    content => "Inclusion inclusion!", return_output => 1 );

# Render node and check macros work.
my $output = $guide->display_node( id => "Home", return_output => 1,
    noheaders => 1 );

like( $output, qr/Here is an included node./, "can override existing macros" );
like( $output, qr/Kake was here!/, "...and define new ones" );

# Make sure we fail gracefully if module doesn't load.
$config->custom_macro_module( "I::Do::Not::Exist" );
$guide = OpenGuides->new( config => $config );

$output = $guide->display_node( id => "Home", return_output => 1,
    noheaders => 1 );
like( $output, qr/Inclusion inclusion!/,
      "default macros used if custom module doesn't load" );


package OpenGuides::Local::CustomMacros;

sub custom_macros {
    my ($class, %args ) = @_;
    my %macros = %{ $args{macros} };

    $macros{qr/\@INCLUDE_NODE\s+\[\[([^\]|]+)\]\]/}
        = sub { return "Here is an included node." };

    $macros{qr/\@GRAFFITI/} = sub { return "Kake was here!" };

    return %macros;
}

1;
