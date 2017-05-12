package POE::Component::WWW::Alexa::TrafficRank;

use warnings;
use strict;

our $VERSION = '2.001001'; # VERSION

use POE;
use base 'POE::Component::NonBlockingWrapper::Base';
use WWW::Alexa::TrafficRank;

sub _methods_define {
    return ( rank => '_wheel_entry' );
}

sub rank {
    $poe_kernel->post( shift->{session_id} => rank => @_ );
}

sub _prepare_wheel {
    my $self = shift;
    $self->{timeout} ||= 30;
    $self->{obj} = WWW::Alexa::TrafficRank->new(
        map { defined $self->{$_} ? ( $_ => $self->{$_} ) : () }
            qw/agent  proxy  timeout/
    );
}

sub _process_request {
    my ( $self, $in_ref ) = @_;
    $in_ref->{uri} =~ s{^(?:ht|f)tps?://|/$}{}gi;
    $in_ref->{rank} = $self->{obj}->get( $in_ref->{uri} );
    if ( not length $in_ref->{rank} ) {
        $in_ref->{error} = 'No result';
        delete $in_ref->{rank};
    }
    elsif ( $in_ref->{rank} !~ /^[\d,]+$/ ) {
        $in_ref->{error} = delete $in_ref->{rank};
    }
}

1;
__END__

=head1 NAME

POE::Component::WWW::Alexa::TrafficRank - non-blocking wrapper around WWW::Alexa::TrafficRank

=head1 SYNOPSIS

    use strict;
    use warnings;

    use POE qw(Component::WWW::Alexa::TrafficRank);

    my $poco = POE::Component::WWW::Alexa::TrafficRank->spawn;

    POE::Session->create(
        package_states => [ main => [qw(_start rank )] ],
    );

    $poe_kernel->run;

    sub _start {
        $poco->rank( {
                uri   => 'zoffix.com',
                event => 'rank',
            }
        );
    }

    sub rank {
        my $in_ref = $_[ARG0];

        if ( $in_ref->{error} ) {
            print "Error: $in_ref->{error}\n";
        }
        else {
            print "$in_ref->{uri}\'s rank is $in_ref->{rank}\n";
        }
        $poco->shutdown;
    }

Using event based interface is also possible of course.

=head1 DESCRIPTION

The module is a non-blocking wrapper around L<WWW::Alexa::TrafficRank>
which provides interface to traffic rank on L<http://alexa.com/>

=head1 CONSTRUCTOR

=head2 C<spawn>

    my $poco = POE::Component::WWW::Alexa::TrafficRank->spawn;

    POE::Component::WWW::Alexa::TrafficRank->spawn(
        alias   => 'alexa_rank',
        agent   => 'Your User-Agent HTTP header',
        proxy   => 'http://someproxy.com',
        timeout => 30,
        options => {
            debug => 1,
            trace => 1,
            # POE::Session arguments for the component
        },
        debug => 1, # output some debug info
    );

The C<spawn> method returns a
POE::Component::WWW::Alexa::TrafficRank object. It takes a few arguments,
I<all of which are optional>. The possible arguments are as follows:

=head3 C<alias>

    ->spawn( alias => 'alexa_rank' );

B<Optional>. Specifies a POE Kernel alias for the component.

=head3 C<agent>

    ->new( agent => 'Your User-Agent HTTP header', );

B<Optional>. Specifies which User-Agent string to use when accessing
L<http://alexa.com/>. B<Defaults to:> C<'Opera 9.5'>

=head3 C<proxy>

    ->new( proxy => 'http://someproxy.com' );

B<Optional>. Specifies which HTTP proxy to use when accessing
L<http://alexa.com/>. B<By default> no proxies are used.

=head3 C<timeout>

    ->new( timeout => 30 );

B<Optional>. Specifies the request timeout in seconds.. this will be
passed to L<LWP::UserAgent> object used by L<WWW::Alexa::TrafficRank>.
B<Defaults to:> C<30> seconds.

=head3 C<options>

    ->spawn(
        options => {
            trace => 1,
            default => 1,
        },
    );

B<Optional>.
A hashref of POE Session options to pass to the component's session.

=head3 C<debug>

    ->spawn(
        debug => 1
    );

When set to a true value turns on output of debug messages. B<Defaults to:>
C<0>.

=head1 METHODS

=head2 C<rank>

    $poco->rank( {
            event       => 'event_for_output',
            uri         => 'uri.for.which.to.get.rank.com',
            _blah       => 'pooh!',
            session     => 'other',
        }
    );

Takes a hashref as an argument, does not return a sensible return value.
See C<rank> event's description for more information.

=head2 C<session_id>

    my $poco_id = $poco->session_id;

Takes no arguments. Returns component's session ID.

=head2 C<shutdown>

    $poco->shutdown;

Takes no arguments. Shuts down the component.

=head1 ACCEPTED EVENTS

=head2 C<rank>

    $poe_kernel->post( alexa_rank => rank => {
            event       => 'event_for_output',
            uri         => 'uri.for.which.to.get.rank.com',
            _blah       => 'pooh!',
            session     => 'other',
        }
    );

Instructs the component to get the rank for the URI specified by
the C<uri> argument. Takes a hashref as an
argument, the possible keys/value of that hashref are as follows:

=head3 C<event>

    { event => 'results_event', }

B<Mandatory>. Specifies the name of the event to emit when results are
ready. See OUTPUT section for more information.

=head3 C<uri>

    { uri => 'uri.for.which.to.get.rank.com', }

B<Mandatory>. Specifies the URI for which to get the traffic rank.

=head3 C<session>

    { session => 'other' }

    { session => $other_session_reference }

    { session => $other_session_ID }

B<Optional>. Takes either an alias, reference or an ID of an alternative
session to send output to.

=head3 user defined

    {
        _user    => 'random',
        _another => 'more',
    }

B<Optional>. Any keys starting with C<_> (underscore) will not affect the
component and will be passed back in the result intact.

=head2 C<shutdown>

    $poe_kernel->post( alexa_rank => 'shutdown' );

Takes no arguments. Tells the component to shut itself down.

=head1 OUTPUT

    $VAR1 = {
        '_user' => 'defined argument',
        'rank' => '903,220',
        'uri' => 'zoffix.com'
    };

    $VAR1 = {
        'error' => 'No Data',
        '_user' => 'defined argument',
        'uri' => 'fsdofsdofsofsdfsdf.com'
    };

The event handler set up to handle the event which you've specified in
the C<event> argument to C<rank()> method/event will receive input
in the C<$_[ARG0]> in a form of a hashref. The possible keys/value of
that hashref are as follows:

=head2 C<rank>

    { 'rank' => '903,220', }

The rank for the URI which you passed in C<uri> argument to C<rank()>
event/method. Will not be present if an error occurred (see below).

=head2 C<error>

    { 'error' => 'No Data', }

If an error occurred during the request, it will be present in the
C<error> key. The C<rank> will be missing in this case.

=head2 C<uri>

    { 'uri' => 'zoffix.com' }

The C<uri> key's value will be whatever you've specified in the
C<uri> argument to C<rank()> event/method.

=head2 user defined

    { '_blah' => 'foos' }

Any arguments beginning with C<_> (underscore) passed into the C<rank()>
event/method will be present intact in the result.

=head1 EXAMPLES

The C<examples/> directory of this distribution contains a workable
script which fetched ranks for URI passed on the command line:

    perl examples/rank.pl zoffix.com

=head1 SEE ALSO

L<POE>, L<WWW::Alexa::TrafficRank>

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