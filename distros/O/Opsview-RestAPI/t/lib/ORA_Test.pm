package ORA_Test;
use strict;
use warnings;

use Test::More;
use Test::Trap qw/ :on_fail(diag_all_once) /;
use Data::Dump qw(pp);

sub new {
    my ( $class, %args ) = @_;

    my %config = (
        url      => 'http://localhost',
        username => 'admin',
        password => 'initial',

        ssl_verify_hostname => 0,

        %args,
    );

    for my $var (qw/ url username password /) {
        my $envvar = 'OPSVIEW_' . uc($var);
        if ( !$ENV{$envvar} ) {
            diag
                "Using default '$envvar' value of '$config{$var}' for testing.";
        }
        else {
            $config{$var} = $ENV{$envvar};
            note "Using provided '$envvar' for testing.";
        }
    }

    use_ok("Opsview::RestAPI")
        || BAIL_OUT("Could not use Opsview::RestAPI; giving up");
    use_ok("Opsview::RestAPI::Exception")
        || BAIL_OUT("Could not use Opsview::RestAPI::Exception; giving up");

    my $self = bless {%config}, $class;

    my $rest;
    my $output;

    $self->{rest} = trap {
        Opsview::RestAPI->new(%config);
    };
    isa_ok( $self->rest, 'Opsview::RestAPI' );
    $trap->did_return(" ... returned");
    $trap->quiet(" ... quietly");
   
    isa_ok( $self->rest->{client}, 'REST::Client' );
    is( $self->rest->url,
        $self->{url},
        "URL set on object correctly"
    );
    is( $self->rest->username,
        $self->{username},
        "Username set on object correctly"
    );
    is( $self->rest->password,
        $self->{password},
        "Password set on object correctly"
    );

    $output = trap {
        $self->rest->api_version();
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
                = "The configured URL '".$self->{url}."' does NOT appear to be an opsview server: "
                . $message;
            diag $exit_msg;
            skip $exit_msg;
        }
    }

    return $self;
}

sub rest { return shift->{rest}; }

sub login {
    my ( $self, %arg_for ) = @_;

    isa_ok( $self->rest, 'Opsview::RestAPI' );

    trap {
        $self->rest->login;
    };
    $trap->did_return("Logged in okay");
    $trap->quiet("no further errors on login");

    my $output = trap {
        $self->rest->opsview_info;
    };
    $trap->did_return("Got opsview_info when logged in");
    $trap->quiet("No extra output");

    note( "output: ", pp($output) );

    return $self->rest;
}

sub logout {
    my ($self) = @_;

    isa_ok( $self->rest, 'Opsview::RestAPI' );

    my $output = trap {
        $self->rest->logout;
    };
    $trap->did_return("Logged in okay");
    $trap->quiet("no further errors on login");

    is($self->rest->{token}, undef, "Logged out");

    return $self;
}

1;
