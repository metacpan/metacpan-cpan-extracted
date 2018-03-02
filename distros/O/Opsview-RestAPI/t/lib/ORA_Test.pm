package ORA_Test;
use strict;
use warnings;

use Test::More;
use Test::Trap qw/ :on_fail(diag_all_once) /;
use Data::Dump qw(pp);

my %opsview = (
    url      => 'http://localhost',
    username => 'admin',
    password => 'initial',
);

sub new {
    my ( $class, %args ) = @_;
    my $self = bless {%args}, $class;

    for my $var (qw/ url username password /) {
        my $envvar = 'OPSVIEW_' . uc($var);
        if ( !$ENV{$envvar} ) {
            diag
                "Using default '$envvar' value of '$opsview{$var}' for testing.";
        }
        else {
            $opsview{$var} = $ENV{$envvar};
            note "Using provided '$envvar' for testing.";
        }
    }

    use_ok("Opsview::RestAPI")
        || BAIL_OUT("Could not use Opsview::RestAPI; giving up");
    use_ok("Opsview::RestAPI::Exception")
        || BAIL_OUT("Could not use Opsview::RestAPI::Exception; giving up");

    my $rest;
    my $output;

    $rest = trap {
        Opsview::RestAPI->new(%opsview);
    };
    isa_ok( $rest, 'Opsview::RestAPI' );
    $trap->did_return(" ... returned");
    $trap->quiet(" ... quietly");
    isa_ok( $rest->{client}, 'REST::Client' );
    is( $rest->url, $opsview{url}, "URL set on object correctly" );
    is( $rest->username, $opsview{username},
        "Username set on object correctly" );
    is( $rest->password, $opsview{password},
        "Password set on object correctly" );

    $output = trap {
        $rest->api_version();
    };

    if ( $trap->die && ref( $trap->die ) eq 'Opsview::RestAPI::Exception' ) {
        if (   $trap->die->message =~ m/was not found on this server/
            || $trap->die->http_code != 200 )
        {
            my $message
                = "HTTP STATUS CODE: "
                . $trap->die->http_code
                . " MESSAGE: "
                . $trap->die->message;
            $message =~ s/\n/ /g;

            my $exit_msg
                = "The configured URL '$opsview{url}' does NOT appear to be an opsview server: "
                . $message;
            diag $exit_msg;
            skip $exit_msg;
        }
    }

    return $self;
}

sub login {
    my ( $self, %arg_for ) = @_;

    my %settings = ( %opsview, %arg_for );
    my $rest = Opsview::RestAPI->new(%settings);

    isa_ok( $rest, 'Opsview::RestAPI' );
    $trap->did_return(" ... returned");
    $trap->quiet(" ... quietly");
    is( $rest->url, $settings{url}, "URL set on object correctly" );
    is( $rest->username, $settings{username},
        "Username set on object correctly" );
    is( $rest->password, $settings{password},
        "Password set on object correctly" );

    trap {
        $rest->login;
    };
    $trap->did_return("Logged in okay");
    $trap->quiet("no further errors on login");

    my $output = trap {
        $rest->opsview_info;
    };
    $trap->did_return("Got opsview_info when logged in");
    $trap->quiet("No extra output");

    note("output: ", pp($output));

    return $rest;
}
