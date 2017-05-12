package POE::Component::WWW::GetPageTitle;

use warnings;
use strict;

our $VERSION = '2.001001'; # VERSION

use POE;
use WWW::GetPageTitle;
use base 'POE::Component::NonBlockingWrapper::Base';

sub _methods_define {
    return ( get_title => '_wheel_entry' );
}

sub get_title {
    $poe_kernel->post( shift->{session_id} => get_title => @_ );
}

sub _prepare_wheel {
    my $self = shift;
    $self->{obj} = WWW::GetPageTitle->new(
        $self->{ua} ? ( ua => $self->{ua} ) : (),
    );
}

sub _process_request {
    my ( $self, $in_ref ) = @_;
    my $t = $self->{obj};
    $t->get_title( $in_ref->{page} );

    if ( my $error =  $t->error ) {
        $in_ref->{error} = $error;
    }
    else {
        $in_ref->{title} = $t->title;
    }

    return;
}

1;
__END__

=head1 NAME

POE::Component::WWW::GetPageTitle - non-blocking wrapper around WWW::GetPageTitle

=head1 SYNOPSIS

    use strict;
    use warnings;

    use POE qw(Component::WWW::GetPageTitle);

    my $poco = POE::Component::WWW::GetPageTitle->spawn;

    POE::Session->create(
        package_states => [ main => [qw(_start result )] ],
    );

    $poe_kernel->run;

    sub _start {
        $poco->get_title( {
                page  => 'http://zoffix.com/',
                event => 'result',
            }
        );
    }

    sub result {
        my $in_ref = $_[ARG0];

        if ( $in_ref->{error} ) {
            print "ERROR: $in_ref->{error}\n";
        }
        else {
            print "Title of $in_ref->{page} is $in_ref->{title}\n";
        }

        $poco->shutdown;
    }

Using event based interface is also possible of course.

=head1 DESCRIPTION

The module is a non-blocking wrapper around L<WWW::GetPageTitle>
which provides interface to fetch page titles.

=head1 CONSTRUCTOR

=head2 C<spawn>

    my $poco = POE::Component::WWW::GetPageTitle->spawn;

    POE::Component::WWW::GetPageTitle->spawn(
        alias => 'page_title',
        ua => LWP::UserAgent->new,
        options => {
            debug => 1,
            trace => 1,
            # POE::Session arguments for the component
        },
        debug => 1, # output some debug info
    );

The C<spawn> method returns a
POE::Component::WWW::GetPageTitle object. It takes a few arguments,
I<all of which are optional>. The possible arguments are as follows:

=head3 C<alias>

    ->spawn( alias => 'page_title' );

B<Optional>. Specifies a POE Kernel alias for the component.

=head3 C<ua>

    ->spawn( ua => LWP::UserAgent->new );

B<Optional>. The C<ua> argument is passed directly to L<WWW::GetPageTitle>'s constructor.
See documentation for L<WWW::GetPageTitle> for more details.

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

=head2 C<get_title>

    $poco->get_title( {
            event       => 'event_for_output',
            page        => 'http://zoffix.com/',
            _blah       => 'pooh!',
            session     => 'other',
        }
    );

Takes a hashref as an argument, does not return a sensible return value.
See C<get_title> event's description for more information.

=head2 C<session_id>

    my $poco_id = $poco->session_id;

Takes no arguments. Returns component's session ID.

=head2 C<shutdown>

    $poco->shutdown;

Takes no arguments. Shuts down the component.

=head1 ACCEPTED EVENTS

=head2 C<get_title>

    $poe_kernel->post( page_title => get_title => {
            event       => 'event_for_output',
            page        => 'http://zoffix.com/',
            _blah       => 'pooh!',
            session     => 'other',
        }
    );

Instructs the component to fetch the title of the page. Takes a hashref as an
argument, the possible keys/value of that hashref are as follows:

=head3 C<event>

    { event => 'results_event', }

B<Mandatory>. Specifies the name of the event to emit when results are
ready. See OUTPUT section for more information.

=head3 C<page>

    { page => 'http://zoffix.com/' },

B<Mandatory>. Specifies the URI of the page of which to get the title.

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

    $poe_kernel->post( page_title => 'shutdown' );

Takes no arguments. Tells the component to shut itself down.

=head1 OUTPUT

    $VAR1 = {
        'page' => 'http://google.ca',
        'title' => 'Google',
        '_blah' => 'foos'
    };

    $VAR1 = {
        'page'  => 'http://google.ca',
        'error' => 'Network error: 500 timeout',
        '_blah' => 'foos'
    };

The event handler set up to handle the event which you've specified in
the C<event> argument to C<get_title()> method/event will receive input
in the C<$_[ARG0]> in a form of a hashref. The possible keys/value of
that hashref are as follows:

=head2 C<page>

    { 'page' => 'http://google.ca', }

The C<page> key will contain the URI of the page that was accessed.

=head2 C<title>

    { 'title' => 'Google', }

The C<title> key (providing no errors occurred) will contain the title of the page that was
accessed.

=head2 C<error>

    { 'error' => 'Network error: 500 timeout', }

If a network error occurred, the C<error> key will be present and will
contain the description of the error.

=head2 user defined

    { '_blah' => 'foos' }

Any arguments beginning with C<_> (underscore) passed into the C<get_title()>
event/method will be present intact in the result.

=head1 SEE ALSO

L<POE>, L<WWW::GetPageTitle>

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