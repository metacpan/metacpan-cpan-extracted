package POE::Component::WebService::HtmlKitCom::FavIconFromImage;

use warnings;
use strict;

our $VERSION = '2.001001'; # VERSION

use Carp;
use POE;
use WebService::HtmlKitCom::FavIconFromImage;
use base 'POE::Component::NonBlockingWrapper::Base';

sub _methods_define {
    return ( favicon => '_wheel_entry' );
}

sub favicon {
    $poe_kernel->post( shift->{session_id} => favicon => @_ );
}

sub _prepare_wheel {
    my $self = shift;
    $self->{_obj} = WebService::HtmlKitCom::FavIconFromImage->new(
        %{ $self->{obj_args} || {} }
    );
}

sub _check_args {
    my ( $self, $args_ref ) = @_;

    unless ( defined $args_ref->{image} ) {
        carp 'Missing `image` argument';
        return;
    }

    return 1;
}

sub _process_request {
    my ( $self, $in_ref ) = @_;
    my @fav_args;

    for ( qw(image text animate file) ) {
        push @fav_args, $_, $in_ref->{$_}
            if exists $in_ref->{$_};
    }

    my $response = $self->{_obj}->favicon('', @fav_args );

    if ( $response ) {
        $in_ref->{response} = $response;
    } else {
        $in_ref->{error} = $self->{_obj}->error;
    }
}

1;
__END__

=head1 NAME

POE::Component::WebService::HtmlKitCom::FavIconFromImage - non-blocking wrapper around WebService::HtmlKitCom::FavIconFromImage

=head1 SYNOPSIS

    use strict;
    use warnings;

    use POE qw(Component::WebService::HtmlKitCom::FavIconFromImage);

    my $poco = POE::Component::WebService::HtmlKitCom::FavIconFromImage->spawn;

    POE::Session->create(
        package_states => [ main => [qw(_start result)] ],
    );

    $poe_kernel->run;

    sub _start {
        $poco->favicon( {
                image => 'some_image.jpg',
                file  => 'out.zip',
                event => 'result',
            }
        );
    }

    sub result {
        my $in_ref = $_[ARG0];

        if ( exists $in_ref->{error} ) {
            print "Got error: $in_ref->{error}\n";
        }
        else {
            print "Done! I saved your favicon in out.zip file\n";
        }

        $poco->shutdown;
    }

Using event based interface is also possible of course.

=head1 DESCRIPTION

The module is a non-blocking wrapper around
L<WebService::HtmlKitCom::FavIconFromImage>
which provides interface to generate favicons from regular images.
What's a "favicon"? See L<http://en.wikipedia.org/wiki/Favicon>

=head1 CONSTRUCTOR

=head2 C<spawn>

    my $poco = POE::Component::WebService::HtmlKitCom::FavIconFromImage->spawn;

    POE::Component::WebService::HtmlKitCom::FavIconFromImage->spawn(
        alias => 'fav',
        obj_args => { timeout => 30 },
        options => {
            debug => 1,
            trace => 1,
            # POE::Session arguments for the component
        },
        debug => 1, # output some debug info
    );

The C<spawn> method returns a
POE::Component::WebService::HtmlKitCom::FavIconFromImage object. It takes a
few arguments,
I<all of which are optional>. The possible arguments are as follows:

=head3 C<alias>

    POE::Component::WebService::HtmlKitCom::FavIconFromImage->spawn(
        alias => 'fav'
    );

B<Optional>. Specifies a POE Kernel alias for the component.

=head3 C<obj_args>

    POE::Component::WebService::HtmlKitCom::FavIconFromImage->spawn(
        obj_args => { timeout => 10 },
    );

B<Optional>. Takes a hashref as a value which will be be dereferenced
directly into L<WebService::HtmlKitCom::FavIconFromImage> constructor.
See documentation for L<WebService::HtmlKitCom::FavIconFromImage>'s
constructor for possible arguments. B<Defaults to:> C<{}>
(default constructor)

=head3 C<options>

    my $poco = POE::Component::WebService::HtmlKitCom::FavIconFromImage->spawn(
        options => {
            trace => 1,
            default => 1,
        },
    );

B<Optional>.
A hashref of POE Session options to pass to the component's session.

=head3 C<debug>

    my $poco = POE::Component::WebService::HtmlKitCom::FavIconFromImage->spawn(
        debug => 1
    );

When set to a true value turns on output of debug messages. B<Defaults to:>
C<0>.

=head1 METHODS

=head2 C<favicon>

    $poco->favicon( {
            event   => 'event_for_output',
            image   => 'some_pic.jpg',
            file    => 'out.zip',
            animate => 1,
            text    => 'ugly scrolling text',
            _blah   => 'pooh!',
            session => 'other',
        }
    );

Takes a hashref as an argument, does not return a sensible return value.
See C<favicon> event's description for more information.

=head2 C<session_id>

    my $poco_id = $poco->session_id;

Takes no arguments. Returns component's session ID.

=head2 C<shutdown>

    $poco->shutdown;

Takes no arguments. Shuts down the component.

=head1 ACCEPTED EVENTS

=head2 C<favicon>

    $poe_kernel->post( fav => favicon => {
            event   => 'event_for_output',
            image   => 'some_pic.jpg',
            file    => 'out.zip',
            animate => 1,
            text    => 'ugly scrolling text',
            _blah   => 'pooh!',
            session => 'other',
        }
    );

Instructs the component to create a favicon. Takes a hashref as an
argument, the possible keys/value of that hashref are as follows:

=head3 C<event>

    { event => 'results_event', }

B<Mandatory>. Specifies the name of the event to emit when results are
ready. See OUTPUT section for more information.

=head3 C<image>

    { image => 'some_pic.jpg' }

B<Mandatory>. Takes a scalar as a value which must be a filename of the
image file you from which you want to make your favicon.

=head3 C<file>

    {'some_pic.jpg', file => 'out.zip' }

B<Optional>.
If C<file> argument is specified the archive containing the favicon will
be saved into the file name of which is the value of C<file> argument.
B<By default> not specified and you'll have to fish out the archive
from the return value (see "OUTPUT" section)

=head3 C<animate>

    { animate => 1 }

B<Optional>. Takes either true or false values. When set to a true value
will ask the site to make an "animated" icon. B<Defaults to:> C<0>

=head3 C<text>

    { text => 'Zoffix ROXORZ!' }

B<Optional>. If animation did not make your favicon icon ugly enough then
specify the C<text> argument which ask the site to add it as
"Scrolling text" into your favicon. B<Defaults to:> C<''> (no text)

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

    $poe_kernel->post( fav => 'shutdown' );

Takes no arguments. Tells the component to shut itself down.

=head1 OUTPUT

    $VAR1 = {
        response => bless( { blah blah}, 'HTTP::Response' ),
        image   => 'foos.jpg',
        file    => 'out.zip',
        '_blah' => 'foos'
    };

The event handler set up to handle the event which you've specified in
the C<event> argument to C<Efavicon()> method/event will receive input
in the C<$_[ARG0]> in a form of a hashref. The possible keys/value of
that hashref are as follows:

=head2 C<response>

    { response => bless( { blah blah}, 'HTTP::Response' ), }

The C<response> key will contain an L<HTTP::Response> object which
was obtained while retrieving your favicon. Unless you specified the
C<file> argument to C<favicon> event/method you'll have to fish your
favicon from this L<HTTP::Response> object (it will be a 'zip' archive).

=head2 C<error>

    { error => 'Network error: 500 read timeout' }

If C<error> key is present it means your request failed for whatever
reason. The value will be the error message describing the failure.

=head2 valid arguments from C<favicon>

    { file => 'out.zip', ...etc }

Any valid arguments which can be given to C<favicon> method/event
(e.g. C<file>, C<text>, etc) will be present in output with the same
values you've set to them.

=head2 user defined

    { '_blah' => 'foos' }

Any arguments beginning with C<_> (underscore) passed into the C<favicon()>
event/method will be present intact in the result.

=head1 SEE ALSO

L<POE>, L<WebService::HtmlKitCom::FavIconFromImage>

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