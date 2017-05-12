package POE::Component::Syntax::Highlight::CSS;

use warnings;
use strict;

our $VERSION = '2.001001'; # VERSION

use POE;
use base 'POE::Component::NonBlockingWrapper::Base';
use Syntax::Highlight::CSS;
use LWP::UserAgent;

sub _methods_define {
    return ( parse => '_wheel_entry' );
}

sub parse {
    $poe_kernel->post( shift->{session_id} => parse => @_ );
}

sub _process_request {
    my ( $self, $in_ref ) = @_;
    my $obj = Syntax::Highlight::CSS->new(
        ( defined $in_ref->{nnn} ? ( nnn => $in_ref->{nnn} ) : () ),
        ( defined $in_ref->{pre} ? ( pre => $in_ref->{pre} ) : () ),
    );

    if ( $in_ref->{uri} ) {
        $in_ref->{uri} =~ m{^(?:ht|f)tps?://}
            or $in_ref->{uri} = "http://$in_ref->{uri}";

        my $ua = $self->{ua} || LWP::UserAgent->new( timeout => 30, agent => 'Opera 9.5' );
        my $response = $ua->get( $in_ref->{uri} );

        if ( $response->is_success ) {
            $in_ref->{out} = $obj->parse( $response->content );
        }
        else {
            $in_ref->{error} = $response->status_line;
        }
    }
    else {
        $in_ref->{out} = $obj->parse( $in_ref->{in} );
    }
}

1;
__END__

=head1 NAME

POE::Component::Syntax::Highlight::CSS - non-blocking wrapper around Syntax::Highlight::CSS

=head1 SYNOPSIS

    use strict;
    use warnings;
    use POE qw/Component::Syntax::Highlight::CSS/;

    my $poco = POE::Component::Syntax::Highlight::CSS->spawn;

    POE::Session->create( package_states => [ main => [qw(_start results)] ], );

    $poe_kernel->run;

    sub _start {
        $poco->parse({
                event => 'results',
                in    => 'a:hover { font-weight: bold; }',
            }
        );
    }

    sub results {
        print "$_[ARG0]->{out}\n";
        $poco->shutdown;
    }

Using event based interface is also possible of course.

=head1 DESCRIPTION

The module is a non-blocking wrapper around L<Syntax::Highlight::CSS> with added functionality
of fetching the CSS code to highlight from a given URI. The L<Syntax::Highlight::CSS>
provides interface to
highlight CSS code by wrapping syntax elements into HTML C<< <span> >> elements with
different class names.

=head1 CONSTRUCTOR

=head2 C<spawn>

    my $poco = POE::Component::Syntax::Highlight::CSS->spawn;

    POE::Component::Syntax::Highlight::CSS->spawn(
        alias => 'highlighter',
        ua  => LWP::UserAgent->new( timeout => 30, agent => 'Opera 9.5' ),
        options => {
            debug => 1,
            trace => 1,
            # POE::Session arguments for the component
        },
        debug => 1, # output some debug info
    );

The C<spawn> method returns a
POE::Component::Syntax::Highlight::CSS object. It takes a few arguments,
I<all of which are optional>. The possible arguments are as follows:

=head3 C<alias>

    ->spawn( alias => 'highlighter' );

B<Optional>. Specifies a POE Kernel alias for the component.

=head3 C<ua>

    ->spawn( ua  => LWP::UserAgent->new( timeout => 30, agent => 'Opera 9.5' ) );

B<Optional>. The C<ua> argument takes an L<LWP::UserAgent>-like object as a value, the object
must have a C<get()> method that returns L<HTTP::Response> object and takes a URI to fetch
as the first argument. B<Default to:>

    LWP::UserAgent->new(
        timeout => 30,
        agent   => 'Opera 9.5',
    );

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

=head2 C<parse>

    $poco->parse( {
            event       => 'event_for_output',
            uri         => 'http://zoffix.com/main.css',
                # or
            in          => 'a:hover { font-weight: bold; }',
            nnn         => 1,
            pre         => 1,
            _blah       => 'pooh!',
            session     => 'other',
        }
    );

Takes a hashref as an argument, does not return a sensible return value.
See C<parse> event's description for more information.

=head2 C<session_id>

    my $poco_id = $poco->session_id;

Takes no arguments. Returns component's session ID.

=head2 C<shutdown>

    $poco->shutdown;

Takes no arguments. Shuts down the component.

=head1 ACCEPTED EVENTS

=head2 C<parse>

    $poe_kernel->post( highlighter => parse => {
            event       => 'event_for_output',
            uri         => 'http://zoffix.com/main.css',
                # or
            in          => 'a:hover { font-weight: bold; }',
            nnn         => 1,
            pre         => 1,
            _blah       => 'pooh!',
            session     => 'other',
        }
    );

Instructs the component to parse given CSS code. Takes a hashref as an
argument, the possible keys/value of that hashref are as follows:

=head3 C<event>

    { event => 'results_event', }

B<Mandatory>. Specifies the name of the event to emit when results are
ready. See OUTPUT section for more information.

=head3 C<uri>

    { uri => 'http://zoffix.com/' }

B<Optional> if C<in> argument is set. Takes a URI as a value, that uri must point to CSS
code you wish to highlight.

=head3 C<in>

    { in => 'a:hover { font-weight: bold; }', }

B<Optional> if C<uri> argument is set.
Takes a string as a value which represents CSS code to syntax-highlight. If C<uri> argument
is specified then the C<in> argument is ignored.

=head3 C<nnn>

    { nnn => 1, }

B<Optional>. Takes either true or false values. When set to a true value will insert line
numbers into the highlighted CSS code. B<Defaults to:> C<0>

=head3 C<pre>

    { pre => 1, }

B<Optional>. Takes either true or false values. When set to a true value will wrap
highlighted CSS code into a C<< <pre> >> element. B<Defaults to:> C<1>

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

    $poe_kernel->post( highlighter => 'shutdown' );

Takes no arguments. Tells the component to shut itself down.

=head1 OUTPUT

    $VAR1 = {
        'out' => '<pre class="css-code"><span class="ch-l">  0</span> <span
                class="ch-sel">a<span class="ch-ps">:hover</span></span> { <span
                class="ch-p">font-weight</span>: <span class="ch-v">bold</span>; }</pre>',
        'in' => 'a:hover { font-weight: bold; }',
        'nnn' => 1,
        'pre' => 1,
        '_blah' => 'foos'
    };

The event handler set up to handle the event which you've specified in
the C<event> argument to C<parse()> method/event will receive input
in the C<$_[ARG0]> in a form of a hashref. The possible keys/value of
that hashref are as follows:

=head2 C<out>

    {
        'out' => '<pre class="css-code"><span class="ch-l">  0</span> <span
                class="ch-sel">a<span class="ch-ps">:hover</span></span> { <span
                class="ch-p">font-weight</span>: <span class="ch-v">bold</span>; }</pre>',
    }

The C<out> key will contain a string representing highlighted CSS code. See
documentation for L<Syntax::Highlight::CSS> for explanation of each of the possible
C<class=""> names on the generated C<< <span> >>s.

=head2 C<in> and C<uri>

    { 'in' => 'a:hover { font-weight: bold; }', }

    { 'uri' => 'http://zoffix.com' }

If C<in> argument was specified to C<parse> event/method the C<in> key
will contain the original CSS code.
If C<uri> argument was specified the C<uri> key will contain the original URI.

=head2 C<error>

    { 'error' => '404 Not Found' }

If you are using the C<uri> argument to C<parse> event/method then there is a chance for
a network error to occur while the module is fetching the CSS code. If that's the case then
the C<error> key will be present and its value will be a human parsable error message.

=head2 C<nnn> and C<pre>

    {
        'nnn' => 1,
        'pre' => 1,
    }

If you specified either C<nnn> or C<pre> arguments to the C<parse()> event/method they will
be present in the output with the values that you set to them.

=head2 user defined

    { '_blah' => 'foos' }

Any arguments beginning with C<_> (underscore) passed into the C<parse()>
event/method will be present intact in the result.

=head1 SEE ALSO

L<POE>, L<Syntax::Highlight::CSS>

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