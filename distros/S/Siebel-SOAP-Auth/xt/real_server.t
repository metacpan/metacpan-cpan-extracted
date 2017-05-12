use warnings;
use strict;
use XML::Compile::WSDL11;
use XML::Compile::SOAP11;
use XML::Compile::Transport::SOAPHTTP;
use Log::Report mode => 'NORMAL';
use Siebel::SOAP::Auth;
use Config::Tiny 2.23;
use Test::More;

my ( $call, $auth );
my %request = (
    ListOfSwicontactio => {
        Contact => {
            Id        => '0-1',
            FirstName => 'Siebel',
            LastName  => 'Administrator'
        }
    }
);

SKIP: {

    skip 'No configuration available for testing with a real server', 1
      unless ( ( exists( $ENV{SIEBEL_SOAP_AUTH} ) )
        and ( defined( $ENV{SIEBEL_SOAP_AUTH} ) ) );

    my $config = Config::Tiny->read( $ENV{SIEBEL_SOAP_AUTH} );
    my $wsdl   = XML::Compile::WSDL11->new( $config->{General}->{wsdl} );

    # forcing server side timeout
    my $forced_timeout = $config->{General}->{timeout} + 100;

    $auth = Siebel::SOAP::Auth->new(
        {
            user            => $config->{General}->{user},
            password        => $config->{General}->{password},
            token_timeout   => $forced_timeout,
            session_timeout => $forced_timeout,
        }
    );
    my $call = $wsdl->compileClient(
        operation      => 'SWIContactServicesQueryByExample',
        transport_hook => \&run
    );

    note( 'Connecting to the first time to the Siebel server defined on '
          . $config->{General}->{wsdl} );
    my $start = time();
    note("start = $start");
    my ( $answer, $trace ) = $call->(%request);
    my $answer_ok = 0;
    if ( my $e = $@->wasFatal ) {

        BAIL_OUT($e);

    }
    else {

        $answer_ok = 1;

    }
    ok( $answer_ok, 'Siebel Servers answer is OK' );
    is( ref($answer), 'HASH',
        'the answer returned from the Siebel Server is valid' );
    $auth->find_token($answer);
    isnt( $auth->get_token, 'unset',
        'the Siebel Server returned a valid token' )
      or diag( explain($answer) );
    note( 'auth instance has token_timeout = ' . $auth->get_token_timeout );
    my $fixed_sleep = 100;
    note(
"Repeating the request, ignoring token renew and hoping that the Siebel Server do not return a SOAP Fault"
    );
    my $time_left = $config->{General}->{timeout};

    while (1) {

        my ( $t1, $t2 );

        $t1 = time();
        sleep($fixed_sleep);

        try sub {

            ( $answer, $trace ) = $call->(%request);
            $auth->check_fault($answer);

        };

        if ( my $e = $@->wasFatal ) {

            my $e = $@->wasFatal;
            ok( $e, 'the Siebel Server returned an exception' )
              or diag( explain($answer) );
            like( $e, qr/token\sexpired/,
                'the expected SOAP fault was returned' );
            last;

        }
        else {

            ok(
                not( exists( $answer->{Fault} ) ),
                'no fault detected in the answer'
            ) or diag( explain($answer) );
            ok( $answer_ok, 'Siebel Servers answer is OK' );
            is( ref($answer), 'HASH',
                'the answer returned from the Siebel Server is valid' );

            # won't feed $auth with the renewed token to force failure
            #$auth->find_token($answer);
            isnt( $auth->get_token, 'unset',
                'the Siebel Server returned a valid token' );

        }

        $t2 = time();
        $time_left -= ( $t2 - $t1 );
        note("Time left: $time_left");

    }

}

done_testing;

sub run {

    my ( $request, $trace, $transporter ) = @_;
    my $answer =
      $trace->{user_agent}->request( $auth->add_auth_header($request) );
    return $answer;

}
