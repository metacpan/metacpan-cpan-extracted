package POE::Component::WWW::Cache::Google;

use warnings;
use strict;

our $VERSION = '2.001001'; # VERSION

use POE;
use base 'POE::Component::NonBlockingWrapper::Base';
use WWW::Cache::Google;
use LWP::UserAgent;

sub _methods_define {
    return ( cache => '_wheel_entry' );
}

sub cache {
    $poe_kernel->post( shift->{session_id} => cache => @_ );
}

sub _process_request {
    my ( $self, $in_ref ) = @_;

    my $cache = WWW::Cache::Google->new( $in_ref->{uri} );

    $in_ref->{cache} = $cache->cache;

    if ( $in_ref->{fetch} ) {
        my $ua = LWP::UserAgent->new(
            agent   => 'Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:21.0) '
             . 'Gecko/20100101 Firefox/21.0',
             # trick google into not giving us 403s
            timeout => 30,
            max_size => $in_ref->{max_size},
        );

        my $response = $ua->get( $in_ref->{cache} );
        if ( not $response->is_success ) {
            $in_ref->{error} = $response->status_line;
            if ( $in_ref->{error} eq '404 Not Found' ) {
                $in_ref->{error} = q|Doesn't look like cache exists|;
            }
            return;
        }

        $in_ref->{content} = $response->content;
        if ( $in_ref->{content} !~ /<base/ ) {
            $in_ref->{error} = q|Doesn't look like cache exists|;
            return;
        }
    }

    if ( ref $in_ref->{fetch} eq 'SCALAR' ) {

        my $filename = ${ $in_ref->{fetch} };

        if ( -e $filename and not $in_ref->{overwrite} ) {
            $in_ref->{error} = "File `$filename` already exists";
            return;
        }

        if ( open my $fh, '>', $filename ) {
            print $fh delete $in_ref->{content}, "\n";
            close $fh;
        }
        else {
            $in_ref->{error} = "Failed to open `$filename` for writing [$!]";
        }
    }

    return;
}

1;
__END__

=encoding utf8

=head1 NAME

POE::Component::WWW::Cache::Google - non-blocking wrapper around WWW::Cache::Google

=head1 SYNOPSIS

    use strict;
    use warnings;

    use POE qw(Component::WWW::Cache::Google);

    my $poco = POE::Component::WWW::Cache::Google->spawn;

    POE::Session->create(
        package_states => [ main => [qw(_start cache)] ],
    );

    $poe_kernel->run;

    sub _start {
        $poco->cache( {
                uri   => 'http://zoffix.com/',
                event => 'cache',
                fetch => 1,
            }
        );
    }

    sub cache {
        my $in_ref = $_[ARG0];

        print "Cache URI for $in_ref->{uri} is: $in_ref->{cache}\n";
        print "Content:\n$in_ref->{content}\n";

        $poco->shutdown;
    }

Using event based interface is also possible of course.

=head1 DESCRIPTION

The module is a non-blocking wrapper (for what it's worth) around
L<WWW::Cache::Google>
which provides interface to get Google's "cache" URIs as well as optionally
fetch contents of such URIs.

=head1 CONSTRUCTOR

=head2 C<spawn>

    my $poco = POE::Component::WWW::Cache::Google->spawn;

    POE::Component::WWW::Cache::Google->spawn(
        alias => 'google_cache',
        options => {
            debug => 1,
            trace => 1,
            # POE::Session arguments for the component
        },
        debug => 1, # output some debug info
    );

The C<spawn> method returns a
POE::Component::WWW::Cache::Google object. It takes a few arguments,
I<all of which are optional>. The possible arguments are as follows:

=head3 C<alias>

    ->spawn( alias => 'google_cache' );

B<Optional>. Specifies a POE Kernel alias for the component.

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

=head2 C<cache>

    $poco->cache( {
            event       => 'event_for_output',
            uri         => 'http://zoffix.com',
            max_size    => 1000,
            fetch       => 1, # or fetch => \'file_name',
            overwrite => 1,
            _blah       => 'pooh!',
            session     => 'other',
        }
    );

Takes a hashref as an argument, does not return a sensible return value.
See C<WWW::Cache::Google> event's description for more information.

=head2 C<session_id>

    my $poco_id = $poco->session_id;

Takes no arguments. Returns component's session ID.

=head2 C<shutdown>

    $poco->shutdown;

Takes no arguments. Shuts down the component.

=head1 ACCEPTED EVENTS

=head2 C<cache>

    $poe_kernel->post( google_cache => cache => {
            event       => 'event_for_output',
            uri         => 'http://zoffix.com',
            max_size    => 1000,
            fetch       => 1, # or fetch => \'file_name',
            overwrite   => 1,
            _blah       => 'pooh!',
            session     => 'other',
        }
    );

Instructs the component to construct a URI to Google's 'cached' URI
for the URI given via C<uri> argument. Optionally can fetch page's
content or automatically store it in a file. Takes a hashref as an
argument, the possible keys/value of that hashref are as follows:

=head3 C<event>

    { event => 'results_event', }

B<Mandatory>. Specifies the name of the event to emit when results are
ready. See OUTPUT section for more information.

=head3 C<uri>

    { uri => 'http://haslayout.net/' }

B<Mandatory>. Specifies the URi which to look up in Google's cache.

=head3 C<fetch>

    { fetch => 1 },

    { fetch => \'file_name' }

B<Optional>. Takes either true, false or scalarref values. When set
to a false value, the component will B<not> fetch the page. When
set to a true value, the component will try to fetch the uri (in Google's
cache that is) using L<LWP::Simple>. When set to a scalarref, it will be
dereferenced to obtain a filename into which to save the contents. The
component will error out if the file already exists (the check is performed
via C<-e>) unless C<overwrite> argument (see below) is set to a true
value. B<Defaults to:> C<0> (no fetching)

=head3 C<overwrite>

    { overwrite => 1 }

B<Optional>. Regarded only when the C<fetch> argument (see above) is set
to a scalarref which is a filename. Can take either true or false values.
When set to a true value will overwrite the filename set via C<fetch>
argument if the file already exists. B<Defaults to:> C<0> (no overwriting
- error out instead)

=head3 C<max_size>

    { max_size => 1000, }

B<Optional>. Regarded only when the C<fetch> argument is not a false value.
The value you specify (which indicates the maximum length of the content to
retrieve) will by passed to L<LWP::UserAgent>'s C<max_size>
method. Use this argument if you just want to have error checking with
regards to actual existence of that cache page. B<Note:> component
*does* actually need some content to determine if the cached page exists,
thus do not set max_size below 100. B<By default> is not set, thus no
limit on the content length is imposed.

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

    $poe_kernel->post( google_cache => 'shutdown' );

Takes no arguments. Tells the component to shut itself down.

=head1 OUTPUT

    $VAR1 = {
        'overwrite' => 1,
        'content' => '<meta http-e.... and so on',
        'fetch' => 1,
        'uri' => 'http://zoffix.com',
        'cache' => bless( do{\(my $o = 'http://www.google.com/search?q=cache:zoffix.com')}, 'URI::http' )
    };

The event handler set up to handle the event which you've specified in
the C<event> argument to C<cache()> method/event will receive input
in the C<$_[ARG0]> in a form of a hashref. The possible keys/value of
that hashref are as follows:

=head2 C<cache>

    'cache' => bless( do{\(my $o = 'http://www.google.com/search?q=cache:zoffix.com')}, 'URI::http' )

The C<cache> key will contain a L<URI> object representing the URI pointing
to the Google's cache page. Note: without actually fetching anything there
is no way to know if that URI contains anything but Google's "no found".

=head2 C<content>

    'content' => '<meta http-e.... and so on',

The C<content> key will contain the content of the Google cache page.
This key will be set only when the C<fetch> argument to the C<cache>
event/method is set to a true value, or when the C<fetch> argument
is set to a scalarref B<and> the cached page was not found on google. When
later occurs, the C<error> key will also be present.

=head2 C<error>

    'error' => 'Doesn\'t look like cache exists',

There won't ever be errors if the C<fetch> argument to C<cache> event/method
is set to a false value. Otherwise, the C<error> key will contain the
explanation of any errors that occur, including any issues with opening
the file when C<fetch> argument is set to a scalarref.

=head2 arguments passed to C<cache> event/method

    'overwrite' => 1,
    'fetch' => 1,
    'max_size' => 100,
    'uri' => 'http://zoffix.com',

The C<overwrite>, C<fetch>, C<max_size> and C<uri> arguments passed to
C<cache> event/method will be present in the output intact.

=head2 user defined

    { '_blah' => 'foos' }

Any arguments beginning with C<_> (underscore) passed into the C<cache()>
event/method will be present intact in the result.

=head1 SEE ALSO

L<POE>, L<WWW::Cache::Google>

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