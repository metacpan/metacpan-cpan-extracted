package POE::Component::WWW::DoctypeGrabber;

use warnings;
use strict;

our $VERSION = '2.001001'; # VERSION

use POE;
use base 'POE::Component::NonBlockingWrapper::Base';
use WWW::DoctypeGrabber;

sub _methods_define {
    return ( grab => '_wheel_entry' );
}

sub grab {
    $poe_kernel->post( shift->{session_id} => grab => @_ );
}

sub _prepare_wheel {
    my $self = shift;
    $self->{obj} = WWW::DoctypeGrabber->new(
        %{ $self->{obj_args} || {} },
    );
}

sub _process_request {
    my ( $self, $in_ref ) = @_;

    my $grabber = $self->{obj};
    if ( exists $in_ref->{raw} ) {
        $grabber->raw( $in_ref->{raw} );
    }
    my $grab = $grabber->grab( $in_ref->{page} );
    if ( $grab ) {
        $in_ref->{result} = $grab;
    }
    else {
        $in_ref->{error} = $grabber->error;
    }
}

1;
__END__

=encoding utf8

=head1 NAME

POE::Component::WWW::DoctypeGrabber - non-blocking wrapper around WWW::DoctypeGrabber

=head1 SYNOPSIS

    use strict;
    use warnings;

    use POE qw(Component::WWW::DoctypeGrabber);

    my $poco = POE::Component::WWW::DoctypeGrabber->spawn;

    POE::Session->create(
        package_states => [ main => [qw(_start results)] ],
    );

    $poe_kernel->run;

    sub _start {
        $poco->grab( {
                page  => 'http://zoffix.com',
                event => 'results',
            }
        );
    }

    sub results {
        my $in_ref = $_[ARG0];

        if ( $in_ref->{error} ) {
            print "ERROR: $in_ref->{error}\n";
        }
        else {
            my $result = $in_ref->{result};

            print $result->{has_doctype}
                ? "$in_ref->{page} has $result->{doctype} doctype\n"
                : "$in_ref->{page} does not contain a doctype\n";

            print $result->{xml_prolog}
                ? "Contains XML prolog\n" : "Does not contain XML prolog\n";

            print "Doctype is preceeded by $result->{non_white_space} non-whitespace characters\n";
            print "\n\n\n";
        };

        $poco->shutdown;
    }

=head1 DESCRIPTION

The module is a non-blocking wrapper around L<WWW::DoctypeGrabber> which provides means to
grab the doctype from a given webpage along with some other related information.

=head1 CONSTRUCTOR

=head2 C<spawn>

    my $poco = POE::Component::WWW::DoctypeGrabber->spawn;

    POE::Component::WWW::DoctypeGrabber->spawn(
        alias => 'grabber',
        obj_args => {
            raw => 1,
        },
        options => {
            debug => 1,
            trace => 1,
            # POE::Session arguments for the component
        },
        debug => 1, # output some debug info
    );

The C<spawn> method returns a
POE::Component::WWW::DoctypeGrabber object. It takes a few arguments,
I<all of which are optional>. The possible arguments are as follows:

=head3 C<alias>

    ->spawn( alias => 'grabber' );

B<Optional>. Specifies a POE Kernel alias for the component.

=head3 C<obj_args>

    obj_args => {
        raw => 1,
    },

B<Optional>. Takes a hashref as a value. This hashref will be directly dereferenced into
L<WWW::DoctypeGrabber>'s constructor (C<new()> method). See documentation for
L<WWW::DoctypeGrabber> for more information.

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

=head2 C<grab>

    $poco->grab( {
            event       => 'event_for_output',
            page        => 'http://zoffix.com/',
            raw         => 1,
            _blah       => 'pooh!',
            session     => 'other',
        }
    );

Takes a hashref as an argument, does not return a sensible return value.
See C<grab> event's description for more information.

=head2 C<session_id>

    my $poco_id = $poco->session_id;

Takes no arguments. Returns component's session ID.

=head2 C<shutdown>

    $poco->shutdown;

Takes no arguments. Shuts down the component.

=head1 ACCEPTED EVENTS

=head2 C<grab>

    $poe_kernel->post( grabber => grab => {
            event       => 'event_for_output',
            page        => 'http://zoffix.com',
            raw         => 1,
            _blah       => 'pooh!',
            session     => 'other',
        }
    );

Instructs the component to grab a doctype from a specified page. Takes a hashref as an
argument, the possible keys/value of that hashref are as follows:

=head3 C<event>

    { event => 'results_event', }

B<Mandatory>. Specifies the name of the event to emit when results are
ready. See OUTPUT section for more information.

=head3 C<page>

    { page => 'http://zoffix.com/' }

B<Mandatory>. Specifies the page of which to grab the doctype.

=head3 C<raw>

    { raw => 1 },

B<Optional>. If specified then L<WWW::DoctypeGrabber>'s C<raw()> method will be called and
the value you specified to the C<raw> argument will be passed along as an argument to
C<raw()> method. Note that this will affect any future "grabs".

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

    $poe_kernel->post( grabber => 'shutdown' );

Takes no arguments. Tells the component to shut itself down.

=head1 OUTPUT

    $VAR1 = {
        'page' => 'google.ca',
        'result' => {
            'xml_prolog' => 0,
            'doctype' => '',
            'non_white_space' => 0,
            'has_doctype' => 0,
            'mime' => 'text/html; charset=UTF-8'
        },
        '_blah' => 'foos'
    };

    $VAR1 = {
        'page' => 'zoffix.com',
        'raw' => 1,
        'result' => '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">',
        '_blah' => 'foos'
    };

The event handler set up to handle the event which you've specified in
the C<event> argument to C<grab()> method/event will receive input
in the C<$_[ARG0]> in a form of a hashref. The possible keys/value of
that hashref are as follows:

=head2 C<page>

    { page => 'google.ca' }

The C<page> key will contain the same thing you specified for C<page> argument in
C<grab()> event/method.

=head2 C<raw>

    { raw => 1 }

The C<raw> key will contain the same thing you specified for C<raw> argument in
C<grab()> event/method. If you didn't specify anything - it won't be present in the output.

=head2 C<error>

    { error => 'Network error: timeout' }

If an error occurred then the C<error> key will be present describing the reason for failure.

=head2 C<result>

    'result' => {
        'xml_prolog' => 0,
        'doctype' => '',
        'non_white_space' => 0,
        'has_doctype' => 0,
        'mime' => 'text/html'
    },


    'result' => '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">',

Depending on the setting of C<raw> argument the C<result> key will either contain a hashref
filled with info or the actual doctype. See description of C<grab()> method in
L<WWW::DoctypeGrabber>'s documentation for explanation of all the keys/values in the
hashref.

=head2 user defined

    { '_blah' => 'foos' }

Any arguments beginning with C<_> (underscore) passed into the C<grab()>
event/method will be present intact in the result.

=head1 SEE ALSO

L<POE>, L<WWW::DoctypeGrabber>

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