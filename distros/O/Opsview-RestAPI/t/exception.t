use 5.12.1;
use strict;
use warnings;

use Test::More;
use Test::Trap qw/ :on_fail(diag_all_once) /;

use Carp qw(croak confess);

use_ok("Opsview::RestAPI::Exception");

my $exception;
my $line;

$line      = __LINE__;
$exception = trap {
    croak( Opsview::RestAPI::Exception->new() );
};
$trap->did_die("Death with no parameters okay");
$trap->quiet("No extra output expected");
isa_ok( $trap->die, 'Opsview::RestAPI::Exception' );
is( $trap->die->line,      $line + 2, "Line set correctly" );
is( $trap->die->message,   undef,     "No message set" );
is( $trap->die->http_code, undef,     "No http_code set" );

$line      = __LINE__;
$exception = trap {
    croak(
        Opsview::RestAPI::Exception->new( message => "This is a message" ) );
};
$trap->did_die("Death with message param okay");
$trap->quiet("No extra output");
isa_ok( $trap->die, 'Opsview::RestAPI::Exception' );
is( $trap->die->line,      $line + 2,           "Line set correctly" );
is( $trap->die->message,   "This is a message", "Message set" );
is( $trap->die,   "This is a message", "Exception stringified correctly" );
is( $trap->die->http_code, undef,               "No http_code set" );

$line      = __LINE__;
$exception = trap {
    croak(
        Opsview::RestAPI::Exception->new(
            message   => "This is a message",
            http_code => 404
        )
    );
};
$trap->did_die("Death with message param okay");
$trap->quiet("No extra output");
isa_ok( $trap->die, 'Opsview::RestAPI::Exception' );
is( $trap->die->line,      $line + 2,           "Line set correctly" );
is( $trap->die->message,   "This is a message", "Message set" );
is( $trap->die,   "This is a message", "Exception stringified correctly" );
is( $trap->die->http_code, 404,                 "404 http_code set" );

done_testing();
