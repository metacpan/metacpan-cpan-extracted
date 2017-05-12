use strict;
use warnings;
use Test::More tests => 2;
use Net::Route::Table;
use Net::Route::Parser;
use NetAddr::IP;
use IPC::Run3;
use English qw( -no_match_vars );

sub diag_system_command
{
    local $EVAL_ERROR;
    require "Net/Route/Parser/$OSNAME.pm";
    my $parser_ref = "Net::Route::Parser::$OSNAME"->new();
    my $routes_as_text;
    eval { IPC::Run3::run3( $parser_ref->command_line(), undef, \$routes_as_text ) };
    my $command = join q{ }, @{ $parser_ref->command_line() };
    $routes_as_text =~ s/[1-9]/1/g; # CPAN testers may wish to remain anonymous
    diag( qq{'$command' output:\n}, $routes_as_text );
    return;
}

my $table_ref;
if ( !eval { $table_ref = Net::Route::Table->from_system(); 1 } )
{
    diag_system_command();
    die $EVAL_ERROR;
}

my $default_network = NetAddr::IP->new( '0.0.0.0', '0.0.0.0' );

is( $table_ref->default_route()->destination(), $default_network, 'The default gateway is 0.0.0.0' );

my $size = @{ $table_ref->all_routes() };
cmp_ok( $size, '>' , 1, 'There are at least two routes' );
