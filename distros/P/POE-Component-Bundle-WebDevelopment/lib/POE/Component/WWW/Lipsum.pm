package POE::Component::WWW::Lipsum;

use warnings;
use strict;

our $VERSION = '2.001001'; # VERSION

use POE;
use base 'POE::Component::NonBlockingWrapper::Base';
use WWW::Lipsum;

sub _methods_define {
    return ( generate => '_wheel_entry' );
}

sub generate {
    $poe_kernel->post( shift->{session_id} => generate => @_ );
}

sub _prepare_wheel {
    my $self = shift;
    $self->{obj} = WWW::Lipsum->new;
}

sub _process_request {
    my ( $self, $req_ref ) = @_;

    eval {
        $req_ref->{lipsum} = [
            $self->{obj}->generate( %{ $req_ref->{args} } )
        ];
    };
    if ( $@ ) {
        $req_ref->{lipsum} = [ "Error: $@" ];
    }

    if ( substr($req_ref->{lipsum}[0], 0, 5) eq 'Error' ) {
        $req_ref->{error} = $req_ref->{lipsum}[0];
        delete $req_ref->{lipsum};
    }
}

1;
__END__

=encoding utf8

=for stopwords Ipsum Lorem lipsum

=head1 NAME

POE::Component::WWW::Lipsum - non-blocking wrapper around WWW::Lipsum

=head1 SYNOPSIS

    use strict;
    use warnings;

    use POE qw/Component::WWW::Lipsum/;

    my $poco = POE::Component::WWW::Lipsum->spawn;

    POE::Session->create( package_states => [ main => [qw/_start lipsum/] ], );

    $poe_kernel->run;

    sub _start {
        $poco->generate({
                event => 'lipsum',
                args  => {
                    amount => 5,
                    what   => 'paras',
                    start  => 0,
                    html   => 1
                },
            }
        );
    }

    sub lipsum {
        my $in_ref = $_[ARG0];

        print "$_\n" for @{ $in_ref->{lipsum} };

        $poco->shutdown;
    }

    # Using event based interface is also possible of course.

=head1 DESCRIPTION

The module is a non-blocking wrapper around L<WWW::Lipsum>
which provides interface to retrieve lipsum text from L<http://lipsum.com/>

=head1 CONSTRUCTOR

=head2 C<spawn>

    my $poco = POE::Component::WWW::Lipsum->spawn;

    POE::Component::WWW::Lipsum->spawn(
        alias => 'lipsum',
        options => {
            debug => 1,
            trace => 1,
            # POE::Session arguments for the component
        },
        debug => 1, # output some debug info
    );

The C<spawn> method returns a
POE::Component::WWW::Lipsum object. It takes a few arguments,
I<all of which are optional>. The possible arguments are as follows:

=head3 C<alias>

    ->spawn( alias => 'lipsum' );

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

=head2 C<generate>

    $poco->generate( {
            event       => 'event_for_output',
            args        => {
                amount => 5,
                what   => 'paras',
                start  => 0,
                html   => 1,
            },
            _blah       => 'pooh!',
            session     => 'other',
        }
    );

Takes a hashref as an argument, does not return a sensible return value.
See C<generate> event's description for more information.

=head2 C<session_id>

    my $poco_id = $poco->session_id;

Takes no arguments. Returns component's session ID.

=head2 C<shutdown>

    $poco->shutdown;

Takes no arguments. Shuts down the component.

=head1 ACCEPTED EVENTS

=head2 C<generate>

    $poe_kernel->post( lipsum => generate => {
            event       => 'event_for_output',
            args        => {
                amount => 5,
                what   => 'paras',
                start  => 0,
                html   => 1,
            },
            _blah       => 'pooh!',
            session     => 'other',
        }
    );

Instructs the component to fetch some Lorem Ipsum text
from L<http://lipsum.com/>. Takes a hashref as an
argument, the possible keys/value of that hashref are as follows:

=head3 C<event>

    { event => 'results_event', }

B<Mandatory>. Specifies the name of the event to emit when results are
ready. See OUTPUT section for more information.

=head3 C<args>

    {
        args => {
            amount => 5,
            what   => 'paras',
            start  => 0,
            html   => 1,
        },
    }

B<Mandatory>. The C<args> key takes a hashref as its value. This hashref
will be directly dereferenced into L<WWW::Lipsum> C<generate()> method.
See documentation for L<WWW::Lipsum> for possible arguments.

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

    $poe_kernel->post( lipsum => 'shutdown' );

Takes no arguments. Tells the component to shut itself down.

=head1 OUTPUT

    $VAR1 = {
        'args' => {
            'amount' => 2,
            'html' => 1,
            'what' => 'paras',
            'start' => 'no'
        },
        'lipsum' => [
            '<p>Lipsum text here</p>',
            '<p>Lipsum text here (cut for brevity)</p>',
        ],
        _user => 'defined args',
    };

The event handler set up to handle the event which you've specified in
the C<event> argument to C<generate()> method/event will receive input
in the C<$_[ARG0]> in a form of a hashref. The possible keys/value of
that hashref are as follows:

=head2 C<lipsum>

    {
        'lipsum' => [
            '<p>Lipsum text here</p>',
            '<p>Lipsum text here (cut for brevity)</p>',
        ],
    }

The C<lipsum> key will contain an I<arrayref> elements of which will be
the generated Lorem Ipsum text. Note: if an error occurred the C<lipsum>
key will B<not> be present. See C<error> below.

=head2 C<error>

    {
        'error' => 'Error: message',
    },

In case of an error the L<lipsum> key will not be present and an
C<error> key will be present instead which will contain an error
message describing the problem. B<Note:> at the time of this
writing there is a minor
bug in L<WWW::Lipsum> due to which any errors related to
L<LWP::UserAgent> will not return an appropriate error message, just
the text "Error: ". The bug report has been posted and may be fixed already.

=head2 C<args>

        'args' => {
            'amount' => 2,
            'html' => 1,
            'what' => 'paras',
            'start' => 0,
        },

The C<args> key will contain the same hashref that you passed to
C<generate()> event/method C<args> argument.

=head2 user defined

    { '_blah' => 'foos' }

Any arguments beginning with C<_> (underscore) passed into the C<generate()>
event/method will be present intact in the result.

=head1 SEE ALSO

L<POE>, L<WWW::Lipsum>

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