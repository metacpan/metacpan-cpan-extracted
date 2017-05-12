package POE::Component::WebService::Validator::CSS::W3C;

use warnings;
use strict;

our $VERSION = '2.001001'; # VERSION

use Carp;
use URI;
use LWP::UserAgent;
use WebService::Validator::CSS::W3C;
use POE qw( Wheel::Run  Filter::Reference  Filter::Line );

sub spawn {
    my $package = shift;
    croak "$package requires an even number of arguments"
        if @_ & 1;

    my %params = @_;

    $params{ lc $_ } = delete $params{ $_ } for keys %params;

    delete $params{options}
        unless ref $params{options} eq 'HASH';

    # fill in defaults
    %params = (
        ua      => LWP::UserAgent->new( timeout => 30 ),
        val_uri => 'http://jigsaw.w3.org/css-validator/validator',

        %params,
    );

    my $self = bless \%params, $package;

    $self->{session_id} = POE::Session->create(
        object_states => [
            $self => {
                validate     => '_validate',
                shutdown => '_shutdown',
            },
            $self => [
                qw(
                    _child_error
                    _child_closed
                    _child_stdout
                    _child_stderr
                    _sig_child
                    _start
                )
            ]
        ],
        ( defined $params{options} ? ( options => $params{options} ) : () ),
    )->ID();

    return $self;
}

sub _start {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
    $self->{session_id} = $_[SESSION]->ID();

    if ( $self->{alias} ) {
        $kernel->alias_set( $self->{alias} );
    }
    else {
        $kernel->refcount_increment( $self->{session_id} => __PACKAGE__ );
    }

    $self->{wheel} = POE::Wheel::Run->new(
        Program    => sub { _val_wheel( @$self{ qw(ua val_uri) } ); },
        ErrorEvent => '_child_error',
        CloseEvent => '_child_close',
        StdoutEvent => '_child_stdout',
        StderrEvent => '_child_stderr',
        StdioFilter => POE::Filter::Reference->new,
        StderrFilter => POE::Filter::Line->new,
        ( $^O eq 'MSWin32' ? ( CloseOnCall => 0 ) : ( CloseOnCall => 1 ) )
    );

    $kernel->yield('shutdown')
        unless $self->{wheel};

    $kernel->sig_child( $self->{wheel}->PID(), '_sig_child' );

    undef;
}

sub _sig_child {
    $poe_kernel->sig_handled;
}

sub session_id {
    return $_[0]->{session_id};
}

sub validate {
    my $self = shift;
    $poe_kernel->post( $self->{session_id} => 'validate' => @_ );
}

sub _validate {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
    my $sender = $_[SENDER]->ID;

    return
        if $self->{shutdown};

    my $args;
    if ( ref $_[ARG0] eq 'HASH' ) {
        $args = { %{ $_[ARG0] } };
    }
    else {
        warn "First parameter must be a hashref, trying to adjust...";
        $args = { @_[ARG0 .. $#_] };
    }

    $args->{ lc $_ } = delete $args->{ $_ }
        for grep { !/^_/ } keys %{ $args };

    unless ( $args->{event} ) {
        carp "Missing 'event' parameter to validate()";
        return;
    }

    if ( !exists $args->{uri} and !exists $args->{string} ) {
        carp "Must specify either `uri` or `string` validate()";
        return;
    }

    $args->{params}{ $_ } = $args->{ $_ }
        for ( qw( string uri medium profile warnings language ) );

    if ( $args->{session} ) {
        if ( my $ref = $kernel->alias_resolve( $args->{session} ) ) {
            $args->{sender} = $ref->ID;
        }
        else {
            carp "Could not resolve 'session' parameter to a valid"
                    . " POE session";
            return;
        }
    }
    else {
        $args->{sender} = $sender;
    }

    $kernel->refcount_increment( $args->{sender} => __PACKAGE__ );
    $self->{wheel}->put( $args );

    undef;
}

sub shutdown {
    my $self = shift;
    $poe_kernel->call( $self->{session_id} => 'shutdown' => @_ );
}

sub _shutdown {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
    $kernel->alarm_remove_all;
    $kernel->alias_remove( $_ ) for $kernel->alias_list;
    $kernel->refcount_decrement( $self->{session_id} => __PACKAGE__ )
        unless $self->{alias};

    $self->{shutdown} = 1;

    $self->{wheel}->shutdown_stdin
        if $self->{wheel};
}

sub _child_closed {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];

    warn "_child_closed called (@_[ARG0..$#_])\n"
        if $self->{debug};

    delete $self->{wheel};
    $kernel->yield('shutdown')
        unless $self->{shutdown};

    undef;
}

sub _child_error {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
    warn "_child_error called: (@_[ARG0..$#_])\n"
        if $self->{debug};

    delete $self->{wheel};
    $kernel->yield('shutdown')
        unless $self->{shutdown};

    undef;
}

sub _child_stderr {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
    warn "_child_stderr: $_[ARG0]\n"
        if $self->{debug};

    undef;
}

sub _child_stdout {
    my ( $kernel, $self, $input ) = @_[ KERNEL, OBJECT, ARG0 ];

    my $session = delete $input->{sender};
    my $event   = delete $input->{event};
    delete $input->{params};

    $kernel->post( $session, $event, $input );
    $kernel->refcount_decrement( $session => __PACKAGE__ );

    undef;
}

sub _val_wheel {
    my ( $val_ua, $val_uri ) = @_;

    if ( $^O eq 'MSWin32' ) {
        binmode STDIN;
        binmode STDOUT;
    }

    my $raw;
    my $size = 4096;
    my $filter = POE::Filter::Reference->new;

    while ( sysread STDIN, $raw, $size ) {
        my $requests = $filter->get( [ $raw ] );
        foreach my $req_ref ( @$requests ) {

            # changes $req_ref
            _prepare_results( $req_ref, $val_ua, $val_uri );

            my $response = $filter->put( [ $req_ref ] );
            print STDOUT @$response;
        }
    }
}

sub _prepare_results {
    my ( $req_ref, $val_ua, $val_uri ) = @_;

    my $val = WebService::Validator::CSS::W3C->new( $val_ua, $val_uri );

    @$req_ref{
        qw(
            result
            is_valid
            num_errors
            errors
            num_warnings
            warnings
            val_uri
            http_response
            request_uri
            som
        )
    }
    = (
        $val->validate( %{ $req_ref->{params} || {} } ),
        $val->is_valid,
        scalar $val->errorcount,
        [ $val->errors ],
        scalar $val->warningcount,
        [ $val->warnings ],
        $val->validator_uri,
        $val->response,
        $val->request_uri,
        $val->som,
    );
    unless ( $req_ref->{result} ) {
        delete $req_ref->{result};
        $req_ref->{request_error} = $req_ref->{http_response}->status_line;
    }

    my $refer_to_uri = URI->new( $req_ref->{request_uri} );

    my %refer_to_params = $refer_to_uri->query_form;
    delete $refer_to_params{output};
    $refer_to_uri->query_form( %refer_to_params );

    $req_ref->{refer_to_uri} = $refer_to_uri;

    undef;
}

1;

__END__

=encoding utf8

=head1 NAME

POE::Component::WebService::Validator::CSS::W3C - non-blocking wrapper around L<WebService::Validator::HTML::W3C>

=head1 SYNOPSIS

    use strict;
    use warnings;

    use POE qw(Component::WebService::Validator::CSS::W3C);

    my $poco = POE::Component::WebService::Validator::CSS::W3C->spawn;

    POE::Session->create(
        package_states => [
            main => [ qw( _start validated ) ],
        ],
    );
    $poe_kernel->run;

    sub _start {
        $poco->validate( {
                event => 'validated',
                uri => 'http://zoffix.com',
            }
        );
    }

    sub validated {
        my $input = $_[ARG0];

        if ( $input->{request_error} ) {
            print "Failed to access validator: $input->{request_error}\n";
        }
        else {
            if ( $input->{is_valid} ) {
                printf "%s is valid! See %s for proof\n",
                            @$input{ qw(uri request_uri) };
            }
            else {
                printf "%s contains %d error(s), see %s\nErrors are:\n",
                            @$input{ qw(uri num_errors request_uri) };

                printf "    %s on line %d\n",
                            @$_{ qw(message line) }
                    for @{ $input->{errors} };
            }
        }

        $poco->shutdown;
    }

Using the event based interface is also possible.

=head1 DESCRIPTION

The module is a non-blocking L<POE> wrapper around
L<WebService::Validator::CSS::W3C> which provides access to W3C
CSS validator ( L<http://jigsaw.w3.org/css-validator/> )

=head1 CONSTRUCTOR

=head2 spawn

    my $poco = POE::Component::WebService::Validator::CSS::W3C->spawn;

    POE::Component::WebService::Validator::CSS::W3C->spawn(
        alias => 'val'
    );

The constructor returns a L<POE::Component::WebService::Validator::CSS::W3C>
object, though you don't need to store it anywhere if you set the C<alias>
argument (see below). Takes a few I<optional> arguments which are as
follows:

=head3 alias

    POE::Component::WebService::Validator::CSS::W3C->spawn(
        alias => 'val'
    );

B<Optional>. Specifies a POE Session alias for the component.

=head3 ua

    my $poco = POE::Component::WebService::Validator::CSS::W3C->spawn(
        ua => LWP::UserAgent->new( timeout => 10 ),
    );

B<Optional>. Takes an L<LWP::UserAgent> object which will be used to
access W3C validator. If not specified the L<LWP::UserAgent> with
its defaults will be used, I<with the exception> of C<timeout> which
will be set to C<30> seconds.

=head3 val_uri

    my $poco = POE::Component::WebService::Validator::CSS::W3C->spawn(
        val_uri => 'http://jigsaw.w3.org/css-validator/validator',
    );

Specifies the URI of the CSS validator to access. B<Defaults to:>
C<http://jigsaw.w3.org/css-validator/validator>, however you are strongly
encouraged install local validator, see
L<http://jigsaw.w3.org/css-validator/DOWNLOAD.html> for details.

=head3 options

    my $poco = POE::Component::WebService::Validator::CSS::W3C->spawn(
        options => {
            trace => 1,
            default => 1,
        },
    );

B<Optional>. A hashref of POE Session options to pass to the component's
session. No options are set by B<default>.

=head2 debug

    my $poco = POE::Component::WebService::Validator::CSS::W3C->spawn(
        debug => 1
    );

When set to a true value turns on output of debug messages. B<Defaults to:>
C<0>.

=head1 METHODS

These are the object-oriented methods of the components.

=head2 validate

    $poco->validate( {
            event => 'validated', # mandatory
            uri   => 'http://zoffix.com', # this or 'string' must be here
        }
    );

    $poco->validate( {
            event    => 'event_to_send_results_to', # mandatory
            string   => '#foo { display: none; }', # this or 'uri' must be
            medium   => 'print', # this one and all below is optional
            profile  => 'css3',
            warnings => 2,
            language => 'de',
            session  => 'other_session_to_get_results',
            _user    => rand(), # user defined args
            _any     => 'other',
        }
    );

Takes hashref of options. See C<validate> event below for description.

=head2 session_id

    my $val_session_id = $poco->session_id;

Takes no arguments. Returns component's session ID.

=head2 shutdown

    $poco->shutdown;

Takes no arguments. Shuts down the component.

=head1 ACCEPTED EVENTS

=head2 validate

    $poe_kernel->post( val => validate => {
            event => 'validated', # mandatory
            uri   => 'http://zoffix.com', # this or 'string' must be here
        }
    );

    $poe_kernel->post( val => validate => {
            event    => 'event_to_send_results_to', # mandatory
            string   => '#foo { display: none; }', # this or 'uri' must be
            medium   => 'print', # this one and all below is optional
            profile  => 'css3',
            warnings => 2,
            language => 'de',
            session  => 'other_session_to_get_results',
            _user    => rand(), # user defined args
            _any     => 'other',
        }
    );

Instructs the component to validate some CSS code, which can be passed
either in a form of a scalar or in a form of a URI to the page.
Options are passed in a hashref with keys as follows:

=head3 event

    { event => 'validation_result' }

B<Mandatory>. An event to send the result to.

=head3 uri

    { uri => 'http://zoffix.com' }

B<Semi-mandatory>. Either C<uri> or C<string> (see below) must be
specified. The C<uri> key instructs the validator to validate the
page specified in the value.

=head3 string

    { string => '#foo { display: block; }' }

B<Semi-mandatory>. Either C<string> or C<uri> (see above) must be specified.
The C<string> key instructs the validator to validate CSS code specified
as the value.

=head3 medium

    { medium => 'print' }

B<Optional>. Specifies the media type of CSS to check against.
Should be one of C<aural>, C<braille>, C<embossed>, C<handheld>, C<print>,
C<screen>, C<tty>, C<tv>, and C<presentation>. A special value C<all> can
also be specified which means all media types.
B<Defaults to:> C<undef> which means validator will use its default,
which currently is C<all>.

=head3 profile

    { profile => 'css3' }

Specifies the CSS version to check against. Legal values are C<css1>,
C<css2>, C<css21>, C<css3>, C<svg>, C<svgbasic>, C<svgtiny>, C<mobile>,
C<atsc-tv>, and C<tv>. A special value C<none> can also be used.
B<Defaults to:> C<undef> which tells the W3C validator to use its default,
which currently defaults to C<css21>.

=head3 warnings

    { warnings => 2 }

An integer 0 - 10 that determines how many warning messages you want to get
back from the CSS Validator, 0 means no warnings, 10 would give most
warnings, but is currently effectively the same as 1. The defaut is undef
in which case the CSS Validator determines a default value; this is
expected to be as if 2 had been specified. B<NOTE:> there seems to be
a discrepancy in L<WebService::Validator::CSS::W3C> documentation and
'0' defaults to "Most Important", '1' => 'Normal', '2' => 'All' and
value C<no>, or default is "No warnings". The bug report has been
submitted and hopefully this will be resolved soon. Use C<warnings>
option with caution until this note is removed.

=head3 language

    { language => 'de' }

The desired language of the supposedly human-readable messages. The string
will passed as an Accept-Language header in the HTTP request. The CSS
Validator currently supports C<en>, C<de>, C<fr>, C<ja>, C<nl>,
C<zh>, and C<zh-cn>.

=head3 session

    { session => $some_other_session_ref }

    { session => 'some_alias' }

    { session => $session->ID }

B<Optional>. An alternative session alias, reference or ID that the
response should be sent to, defaults to sending session.

=head3 user defined

B<Optional>. Any keys starting with C<_> (underscore) will not affect the
component and will be passed back in the result intact.

=head2 shutdown

    $poe_kernel->post( 'calc' => 'shutdown' );

Takes no arguments. Tells the component to shut itself down.

=head1 OUTPUT

 $VAR1 = {
    'result' => 1,
    'is_valid' => 0,
    'num_errors' => '1',
    'errors' => [
                $VAR1->{'som'}{'_content'}[2][0][2][0][2][5][2][0][2][1][2][1][4]
                ],
    'uri' => 'google.ca',
    'request_uri' => bless( do{\(my $o = 'http://jigsaw.w3.org/css-validator/validator?uri=google.ca&output=soap12')}, 'URI::http' ),
    'refer_to_uri' => bless( do{\(my $o = 'http://jigsaw.w3.org/css-validator/validator?uri=google.ca')}, 'URI::http' ),
    'http_response' => bless( { blah }, 'HTTP::Response' ),
    'som' => bless( { blah }, 'SOAP::SOM' ),
    'val_uri' => 'http://jigsaw.w3.org/css-validator/validator',
    'num_warnings' => '0',
    'warnings' => [],
 };

The result will be posted to the event and (optional) session specified in
the arguments to the C<validate> (event or method). The result, in the form
of a hashref, will be passed in C<ARG0>. The keys of that hashref are as
follows:

=head3 result

    { 'result' => 1 }

Whill contain either a true or false value. The false value will indicate
that we failed to access the validator, use C<request_error> key (see
below) to determine the reason. If the value is true - we successfully
accessed the validator (note that it doesn't mean that the code was
valid)

=head3 request_error

    { request_error => '500: Request timed out' }

If we could not access the validator (i.e. C<result> contains a false value)
then the C<request_error> key will contain the description of the error.

=head3 is_valid

    { is_valid => 0 }

Will contain either a true or false value. If contains a true value
the CSS code which was validate does not contain errors. If C<is_valid>
key contains a false value - the CSS code is invalid.

=head3 num_errors

    { 'num_errors' => '1' }

Will contain the number of errors found in CSS code which was validated.

=head3 errors

    printf "%s on line %d\n", @$_{ qw(message line) }
                for @{ $_[ARG0]->{errors} };

This will contain an arrayref of hashrefs which represent errors. The
possible error hashref might be:

    ( {
        context    => 'p',
        property   => 'color',
        expression => { start => '', end => 'not-a-color' }
        errortype  => 'parse-error',
        message    => 'not-a-color is not a color value',
        line       => 0,
    } )

However, not all the keys will be present at all times.

=head3 uri

    { 'uri' => 'google.ca' }

If the C<uri> argument was used to the C<validate> event/method
(as opposed to C<string>) the C<uri> key in the output will contain
whatever you've passed to C<validate>

=head3 string

    { 'string' => '#foo { display: block; }' }

If the C<string> argument was used to the C<validate> event/method
(as opposed to C<uri>) the C<string> key in the output will contain
whatever you've passed to C<validate>

=head3 request_uri

    { 'request_uri' => bless( do{\(my $o = 'http://jigsaw.w3.org/css-validator/validator?uri=google.ca&output=soap12')}, 'URI::http' ) }

Will contain a L<URI> object which was used to access the validator.

=head3 refer_to_uri

    { 'refer_to_uri' => bless( do{\(my $o = 'http://jigsaw.w3.org/css-validator/validator?uri=google.ca')}, 'URI::http' ), }

Will contain a L<URI> object which you can use to direct people to the
HTML version of the validator output.

=head3 http_response

    { 'http_response' => bless( { blah }, 'HTTP::Response' ) }

The C<http_response> key will contain an L<HTTP::Response> object
obtained during the access to validator. You could perhaps examine it
to find out why you failed to access the validator.

=head3 val_uri

    { 'val_uri' => 'http://jigsaw.w3.org/css-validator/validator' }

The C<val_uri> key will contain a URI of the CSS validator which
was used for validaton.

=head3 som

    { 'som' => bless( { blah }, 'SOAP::SOM' ), }

The L<SOAP::SOM> object for the successful deserialization, check the
C<result> key (see above) for a true value before using this object.

=head3 warnings

    { 'warnings' => [], }

The C<warnings> key will contain an arrayref of warnings found in CSS
file (providing the warning level was set appropriately). B<Note:>
the docs for L<WebService::Validator::CSS::W3C> read:

    Returns a list with information about the warnings found for the style
    sheet. This is currently of limited use as it is broken, see
    http://www.w3.org/Bugs/Public/show_bug.cgi?id=771 for details.

The validator bug shows as "RESOLVED", however I could not get any
warnings from L<WebService::Validator::CSS::W3C>. If you can figure it
out drop me a line ;)

=head3 user defined

    { '_some' => 'other' }

Any arguments beginning with C<_> (underscore) passed into the C<validate>
event/method will be present intact in the result.

=head1 SEE ALSO

L<WebService::Validator::CSS::W3C>, L<POE>, L<LWP::UserAgent>

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/POE-Component-Bundle-WebDevelopment>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/POE-Component-Bundle-WebDevelopment/issues>

If you can't access GitHub, you can email your request
to C<bug-POE-Component-Bundle-WebDevelopment at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet <zoffix at cpan.org>
(L<http://zoffix.com/>, L<http://haslayout.net/>)

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut