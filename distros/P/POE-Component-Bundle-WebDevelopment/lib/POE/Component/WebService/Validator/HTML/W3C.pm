package POE::Component::WebService::Validator::HTML::W3C;

use warnings;
use strict;

our $VERSION = '2.001001'; # VERSION

use WebService::Validator::HTML::W3C;
use POE (qw( Wheel::Run  Filter::Reference  Filter::Line));
use Carp;

sub spawn {
    my $package = shift;

    croak "Even number of arguments must be passed to $package"
        if @_ & 1;

    my %params = @_;

    $params{ lc $_ } = delete $params{ $_ } for keys %params;

    delete $params{options}
        unless ref $params{options} eq 'HASH';

    my $self = bless \%params, $package;

    $self->{session_id} = POE::Session->create(
        object_states => [
            $self => {
                validate => '_validate',
                shutdown => '_shutdown',
            },
            $self => [
                qw(
                    _child_error
                    _child_close
                    _child_stderr
                    _child_stdout
                    _sig_chld
                    _start
                )
            ],
        ],
        ( exists $params{options} ? ( options => $params{options} ) : () ),
    )->ID;

    return $self;
}

sub _start {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
    $self->{session_id} = $_[SESSION]->ID();

    if  ( $self->{alias} ) {
        $kernel->alias_set( $self->{alias} );
    }
    else {
        $kernel->refcount_increment( $self->{session_id} => __PACKAGE__ );
    }

    $self->{wheel} = POE::Wheel::Run->new(
        Program => \&_validate_wheel,
        ErrorEvent => '_child_error',
        CloseEvent => '_child_close',
        StderrEvent => '_child_stderr',
        StdoutEvent => '_child_stdout',
        StdioFilter => POE::Filter::Reference->new,
        StderrFilter => POE::Filter::Line->new,
        ( $^O eq 'MSWin32' ? ( CloseOnCall => 0 ) : ( CloseOnCall => 1 ) ),
    );

    $kernel->call('shutdown')
        unless $self->{wheel};

    $kernel->sig_child( $self->{wheel}->PID, '_sig_chld' );
}

sub _sig_chld {
    $poe_kernel->sig_handled;
}

sub _child_close {
    my ( $kernel, $self, $wheel_id ) = @_[ KERNEL, OBJECT, ARG0 ];

    warn "_child_close called (@_[ARG0..$#_])\n"
        if $self->{debug};

    delete $self->{wheel};
    $kernel->yield('shutdown')
        unless $self->{shutdown};

    undef;
}

sub _child_error {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
    warn "_child_error called (@_[ARG0..$#_])\n"
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
    $kernel->post( $session, $event, $input );
    $kernel->refcount_decrement( $session => __PACKAGE__ );

    undef;
}

sub shutdown {
    my $self = shift;
    $poe_kernel->post( $self->{session_id} => 'shutdown' );
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

sub session_id {
    return $_[0]->{session_id};
}

sub validate {
    my $self = shift;
    $poe_kernel->post( $self->{session_id} => 'validate' => @_ );
}

sub _validate {
    my ( $kernel, $self ) = @_[KERNEL, OBJECT];

    my $sender = $_[SENDER]->ID;

    return
        if $self->{shutdown};

    my $args;
    if ( ref $_[ARG0] eq 'HASH' ) {
        $args = { %{ $_[ARG0] } };
    }
    else {
        warn "Argument must be a hashref, trying to adjust";
        $args = { @_[ARG0 .. $#_] };
    }

    $args->{ lc $_ } = delete $args->{ $_ }
        for grep { !/^_/ } keys %{ $args };

    unless ( $args->{event} ) {
        warn "No `event` parameter specified. Aborting...";
        return;
    }

    unless ( $args->{in} ) {
        warn "No `in` parameter specified. Aborting...";
        return;
    }

    unless ( exists $args->{options}{detailed} ) {
        $args->{options}{detailed} = 1;
    }

    if ( $args->{type} ) {
        $args->{type} = lc $args->{type};
    }
    else {
        $args->{type} = 'uri';
    }

    if ( $args->{session} ) {
        if ( my $ref = $kernel->alias_resolve( $args->{session} ) ) {
            $args->{sender} = $ref->ID;
        }
        else {
            warn "Could not resolve `session` parameter to a "
                    . "valid POE session. Aborting...";
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

sub _validate_wheel {
    if ( $^O eq 'MSWin32' ) {
        binmode STDIN;
        binmode STDOUT;
    }

    my $raw;
    my $size = 4096;
    my $filter = POE::Filter::Reference->new;

    while ( sysread STDIN, $raw, $size ) {
        my $requests = $filter->get( [ $raw ] );
        foreach my $req ( @$requests ) {

            my $val
            = WebService::Validator::HTML::W3C->new( %{ $req->{options} } );

            my $val_success = 0;
            if ( $req->{type} eq 'file' ) {
                $val_success = $val->validate_file( $req->{in} );
            }
            elsif ( $req->{type} eq 'markup' ) {
                $val_success = $val->validate_markup( $req->{in} );
            }
            else {
                $val_success = $val->validate( $req->{in} );
            }

            if ( $val_success ) {

                @{ $req }{
                    qw(
                        is_valid
                        num_errors
                    )
                }
                = (
                    $val->is_valid,
                    $val->num_errors,
                );

                $req->{errors} = undef;
                foreach my $error ( @{ $val->errors || [] } ) {
                    push @{ $req->{errors} }, {
                        line => $error->line,
                        col  => $error->col,
                        msg  => $error->msg,
                    };
                }
                if ( $req->{get_warnings} ) {
                    $req->{'warnings'} = undef;
                    foreach my $warning ( @{ $val->warnings || [] } ) {
                        push @{ $req->{'warnings'} }, {
                            line => $warning->line,
                            col  => $warning->col,
                            msg  => $warning->msg,
                        }
                    }
                }

            }
            else {
                $req->{validator_error} = $val->validator_error;
            }
            $req->{validator_uri} = $val->validator_uri;

            my $response = $filter->put( [ $req ] );
            print STDOUT @$response;
        }
    }
}

1;
__END__

=head1 NAME

POE::Component::WebService::Validator::HTML::W3C - a non-blocking L<POE>
wrapper around L<WebService::Validator::HTML::W3C>

=head1 SYNOPSIS

    use strict;
    use warnings;

    use POE qw(Component::WebService::Validator::HTML::W3C);

    my $poco = POE::Component::WebService::Validator::HTML::W3C->spawn(
        alias => 'val',
    );

    POE::Session->create(
        package_states => [
            main => [ qw( _start validated ) ],
        ],
    );

    $poe_kernel->run;

    sub _start {
        $poe_kernel->post( val => validate => {
                in => 'http://haslayout.net',
                event => 'validated',
            }
        );
    }

    sub validated {
        my ( $kernel, $input ) = @_[ KERNEL, ARG0 ];

        use Data::Dumper;
        print Dumper( $input );

        $poco->shutdown;
    }

=head1 DESCRIPTION

The module provides a non-blocking L<POE> wrapper around
L<WebService::Validator::HTML::W3C>

=head1 CONSTRUCTOR

    POE::Component::WebService::Validator::HTML::W3C->spawn( alias => 'val' );

    POE::Component::WebService::Validator::HTML::W3C->spawn(
        alias => 'val',
        debug => 1,
    );

    my $poco = POE::Component::WebService::Validator::HTML::W3C->spawn;

Returns a PoCo object. Takes three I<optional> arguments:

=head2 alias

    POE::Component::WebService::Validator::HTML::W3C->spawn( alias => 'val' );

Specifies a POE Kernel alias for the component.

=head2 options

    POE::Component::WebService::Validator::HTML::W3C->spawn(
        options => {
            trace => 1,
            default => 1,
        },
    );

A hashref of POE Session options to pass to the component's session.

=head2 debug

    POE::Component::WebService::Validator::HTML::W3C->spawn( debug => 1 );

When set to a true value turns on output of debug messages.

=head1 METHODS

These are the object-oriented methods of the component.

=head2 validate

    $poco->validate( {
            in => 'http://zoffix.com',
            event => 'validated',
            _random => 'bar',
        }
    );

Method makes a validation request. Takes a single argument which is a
hashref of options. See C<validate> event for details.

=head2 session_id

    my $tube_id = $poco->session_id;

Takes no arguments. Returns POE Session ID of the component.

=head2 shutdown

    $poco->shutdown;

Takes no arguments. Shuts the component down.

=head1 ACCEPTED EVENTS

=head2 validate

    $poe_kernel->post( val => validate => {
            in      => 'http://haslayout.net',
            event   => 'when_we_are_done', # everything below is optional
            session => 'some_other_session',
            _user   => 'something',
            _moar   => 'yet more',
            options => {
                http_timeout  => 10,
                validator_uri => 'http://local.plz/check',
                # and the rest of
                # WebService::Validator::HTML::W3C constructor options.
            },
            get_warnings => 1, # see description (below) before use
        },
    );

    $poe_kernel->post( val => validate => {
            in      => 'markup_file.html',
            type    => 'file',
            event   => 'done',
        },
    );

    $poe_kernel->post( val => validate => {
            in      => $some_markup_in_memory,
            type    => 'markup',
            event   => 'done',
        },
    );

Takes one argument which is a hashref. Instructs the component to validate
a webpage, markup from the file or markup stored in a scalar. The options
hashref keys are as follows:

=head3 in

    { in => 'http://haslayout.net' }

    { in => 'filename.html' }

    { in => $markup_stored_just_like_that }

B<Mandatory>. The value can be either the URI of the webpage, filename with markup to
validate or markup stored in a plain scalar. Unless C<in> key contains
a URI to a webpage you must also set the C<type> key to tell the component
what you want to validate. I<Note:> when C<in> key represents a URI of the
webpage it must be accessible by the validator.

=head3 event

    { event => 'we_are_done' }

B<Mandatory>. The event to send the output to. See I<RESULTS> section for
information on how it will be sent. See C<session> key (below) if you want
to send the output to another session.

=head3 type

    { type => 'file' }

    { type => 'markup' }

B<Optional>. This option specifies what exactly you gave the component
in the C<in> key. When C<type> is set to C<file>, the component will treat
C<in> key value as a filename of the file with the markup to validate.
When C<type> is set to C<markup>, the component will treat the value of
C<in> key as a scalar containing a piece of markup to validate. Any other
value will tell the component that the C<in> key represents a URI of the
webpage to validate. Defaults to C<uri> (C<in> contains a URI)

=head3 session

    { session => 'another_session' }

    { session => $another_session_ref }

    { session => $another_session_ID }

B<Optional>. The value must be either an alias, a reference or an ID of
an active session. When specified, the output will be sent to the session
specified. Defaults to the sending session (the session that sends the
C<validate> event).

=head3 user defined keys

    { _user => 'something' }

    { _other => \@another }

B<Optional>. Any keys starting with the C<_> (underscore) will be present
in the results intact. I<Note:> these will be passed through
L<POE::Wheel::Run> so values should be something that would survive the
process.

=head3 options

    {
        options => {
            http_timeout => 10,
            validator_uri => 'http://local/check',
            # and other WebService::Validator::HTML::W3C
            # constructor options.
        }
    }

B<Optional>. The value must be a hashref. This will be passed directly
to the L<WebService::Validator::HTML::W3C> constructor. See
L<WebService::Validator::HTML::W3C> C<new> method for possible options.

=head3 get_warnings

    { get_warnings => 1 }

This will request the validator to get the warning messages.
B<Note:> the documentation of L<WebService::Validator::HTML::W3C> reads:

    ONLY available with the SOAP output from the development Validator at the moment.

I didn't have a chance to test this feature out, so use at your own risk
and please report the bugs if you find any.

=head2 shutdown

    $poe_kernel->post( val => 'shutdown' );

Takes no arguments. Tells the component to shut itself down.

=head1 RESULTS

    sub validated {
        my ( $kernel, $results ) = @_[ KERNEL, ARG0 ];

        use Data::Dumper;
        print Dumper( $results );

        $poco->shutdown;
    }

    $VAR1 = {
          'errors' => [
                        {
                                 'msg' => 'no document type declaration; implying "<!DOCTYPE HTML SYSTEM>"',
                                 'col' => '0',
                                 'line' => '1'
                          },
                        # and more and more of these
          ],
          'in' => 'http://google.ca',
          'num_errors' => '46',
          'validator_uri' => 'http://validator.w3.org/check',
          'type' => 'uri',
          'is_valid' => 0
        };


    $VAR1 = {
          'options' => {
                         'http_timeout' => 2,
                         'validator_uri' => 'http://somewhereesle.com'
                       },
          '_user_defined' => 'something',
          'in' => 'http://zoffix.com',
          'validator_error' => 'Could not contact validator',
          'type' => 'uri',
          'validator_uri' => 'http://somewhereesle.com'
    };

The event handler set up to handle the event you've specified in the
C<event> key of the C<validate> event/method (and optionally the session
you've specified in C<session> key) will receive the results of the
validation. The results will be returned in a form of a hashref in the
C<ARG0>. Some keys of the hashref will not be present if we failed to contact the
validator or other reasons why we couldn't proceed with validation.
The keys of the results hashref are as follows:

=head2 validator_error

    if ( $results->{validator_error} ) {
        print "Could not validate: $results->{validator_error}\n";
    }
    else {
        # print out the results here.
    }

If for some reason we could not perform the validation (for possible reasons
see L<WebService::Validator::HTML::W3C>'s C<validator_error()> method
description), the C<validator_error> key will be present containing
the description of the error. If we successfully performed validation
(the validation itself, not whether or not the HTML was valid) then this
key will not be present in the results, thus you can use it to check
for success.

=head2 is_valid

    if ( $results->{is_valid} ) {
        print "Your document is valid! YEY!\n";
    }
    else {
        print "ZOMG! HTML WITH ERRORZ!\n";
        # print out error herer.
    }

Set to either true or false value indicated whether or not the HTML
document passed or failed validation. If it is set to true - document is
valid, otherwise document contains errors. If document is valid the
C<num_errors> key will have C<0> (zero) as a value and C<errors> key will be
set to C<undef>.
The C<is_valid> key will I<NOT> exist if C<{validator_error}> is present.

=head2 num_errors

    unless ( $results->{is_valid} ) {
        print "Your document contained: $results->{num_errors} errors\n";
    }

The number (possibly a zero) of errors that validator found in your HTML.
B<Note:> this is B<NOT> the number of elements in the C<{errors}> key's
arrayref, this is because C<{errors}>
will also have the C<entity was defined here>
type of messages which describe previous errors but not actually errors
themselves. This key will I<NOT> exist if C<{validator_error}> is present.

=head2 errors

    foreach my $error ( @{ $results->{errors} } ) {
       printf "line: %s, col: %s\n  error: %s\n\n",
                    @$error{ qw( line col msg ) };

    }

This key will I<NOT> exist if C<{validator_error}> is present, otherwise
it will contain an arrayref, elements of which are hashrefs with the
following keys:

=over 5

=item msg

The textual description of an error

=item col

The column number of the HTML code where the error was spotted

=item line

The line number of the HTML code where the error was spotted.

=back

B<Note:> each element is B<NOT> necessarily an error, but could also be
the C<entity was defined here>
type of messages which describe previous errors but not actually errors
themselves. If you think that should be different contact the author
of L<WebService::Validator::HTML::W3C> module.

=head2 type

    if ( $results->{type} eq 'file' ) {
        print "I've validated file $results->{in}\n";
    }
    elsif ( $results->{type} eq 'markup' ) {
        print "I've validated markup which was: \n$results->{in}\n";
    }
    else {
        print "I've validated a URI $results->{in}\n";
        # note that if we get here then: $results->{type} eq 'uri'
    }

This is the type of validation which was performed. Unless you've
specified a I<proper> type with C<type> option in the C<validate>
event/method this key's value will be C<'uri'>. Otherwise it will be
either 'file' or 'markup' (always lowercase).

=head2 in

    print "These are the results for $results->{in}\n";

This will have whatever you have specified in the C<in> option of the
C<validate> event/method.

=head2 validator_uri

    print "Results provided by $results->{validator_uri}\n";

This will contain the URI of the validator which performed validation.
Unless you've set
C<{ options =E<gt> { validator_uri =E<gt> 'http://something_else' } }> in the
C<validate> method/event call, C<validator_uri> key will contain
C<'http://validator.w3.org/check'>

=head2 user specified arguments

    print "User set $_ to $results->{ $_ }\n"
        for grep { /^_/ } keys %$results;

Any keys beginning with C<_> (underscore) which were specified to the
C<validate> method/event will be present intact in the result.

=head2 warnings

    foreach my $warning ( @{ $results->{warnings} } ) {
       printf "line: %s, col: %s\n  warning: %s\n\n",
                    @$warning{ qw( line col msg ) };
    }

If C<get_warnings> option is set in the C<validate> method/event (and
make sure to read its description before setting it!), the C<warnings>
key will be present in the results, value of which will be an arrayref.
Each element of that arrayref will be a hashref, each having three
keys:

=over 5

=item msg

The textual description of a warning

=item col

The column number of the HTML code where the warning was spotted

=item line

The line number of the HTML code where the warning was spotted.

=back

B<Note:> this is I<untested>. Read
the description of C<get_warnings> option of the C<validate> event/method
for the reason. Please report any bugs/discrepancies.

=head1 SEE ALSO

L<POE>, L<WebService::Validator::HTML::W3C>

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