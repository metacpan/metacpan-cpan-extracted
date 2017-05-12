package POE::Component::WWW::HTMLTagAttributeCounter;

use warnings;
use strict;

our $VERSION = '2.001001'; # VERSION

use POE;
use base 'POE::Component::NonBlockingWrapper::Base';
use WWW::HTMLTagAttributeCounter;

sub _methods_define {
    return ( count => '_wheel_entry' );
}

sub count {
    $poe_kernel->post( shift->{session_id} => count => @_ );
}

sub _prepare_wheel {
    my $self = shift;
    $self->{obj} = WWW::HTMLTagAttributeCounter->new(
        $self->{ua} ? $self->{ua} : ()
    );
}

sub _process_request {
    my ( $self, $in_ref ) = @_;

    $in_ref->{type} ||= 'tag';
    my $c = $self->{obj};
    if ( my $result = $c->count( @$in_ref{qw/where what type/} ) ) {
        @$in_ref{ qw/result result_readable/ } = ( $result, "$c" );
    }
    else {
        $in_ref->{error} = $c->error;
    }

}

1;
__END__

=encoding utf8

=head1 NAME

POE::Component::WWW::HTMLTagAttributeCounter - non-blocking wrapper around WWW::HTMLTagAttributeCounter

=head1 SYNOPSIS

    use strict;
    use warnings;

    use POE qw/Component::WWW::HTMLTagAttributeCounter/;
    my $poco = POE::Component::WWW::HTMLTagAttributeCounter->spawn;

    POE::Session->create( package_states => [ main => [qw(_start results)] ], );

    $poe_kernel->run;

    sub _start {
        $poco->count( {
                event => 'results',
                where  => 'http://zoffix.com/',
                what   => [ qw/div a span/ ],
            }
        );
    }

    sub results {
        my $in_ref = $_[ARG0];
        if ( $in_ref->{error} ) {
            print "Error: $in_ref->{error}\n";
        }
        else {
            print "I counted $in_ref->{result_readable} tags on $in_ref->{where}\n";
        }

        $poco->shutdown;
    }

Using event based interface is also possible of course.

=head1 DESCRIPTION

The module is a non-blocking wrapper around L<WWW::HTMLTagAttributeCounter>
that provides interface to count HTML tags and attributes in given web page or HTML code

=head1 CONSTRUCTOR

=head2 C<spawn>

    my $poco = POE::Component::WWW::HTMLTagAttributeCounter->spawn;

    POE::Component::WWW::HTMLTagAttributeCounter->spawn(
        alias => 'counter',
        ua => LWP::UserAgent->new( timeout => 10 ),
        options => {
            debug => 1,
            trace => 1,
            # POE::Session arguments for the component
        },
        debug => 1, # output some debug info
    );

The C<spawn> method returns a
POE::Component::WWW::HTMLTagAttributeCounter object. It takes a few arguments,
I<all of which are optional>. The possible arguments are as follows:

=head3 C<alias>

    ->spawn( alias => 'counter' );

B<Optional>. Specifies a POE Kernel alias for the component. B<By default> no aliases are set.

=head3 C<ua>

    ->spawn( ua => LWP::UserAgent->new( timeout => 10 ) );

B<Optional>. When specified, will be given to L<WWW::HTMLTagAttributeCounter> constructor's
C<ua> argument. B<Defaults to:> default L<WWW::HTMLTagAttributeCounter> C<ua> argument.

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

=head2 C<count>

    $poco->count( {
            event       => 'event_for_output',
            where       => 'http://zoffix.com/',
            what        => [ qw/div span a/ ],
            type        => 'tag',
            _blah       => 'pooh!',
            session     => 'other',
        }
    );

Takes a hashref as an argument, does not return a sensible return value.
See C<count> event's description for more information.

=head2 C<session_id>

    my $poco_id = $poco->session_id;

Takes no arguments. Returns component's session ID.

=head2 C<shutdown>

    $poco->shutdown;

Takes no arguments. Shuts down the component.

=head1 ACCEPTED EVENTS

=head2 C<count>

    $poe_kernel->post( counter => count => {
            event       => 'event_for_output',
            where       => 'http://zoffix.com/',
            what        => [ qw/div span a/ ],
            type        => 'tag',
            _blah       => 'pooh!',
            session     => 'other',
        }
    );

Instructs the component to count tags or attributes on the given page (referenced by a URI)
or direct HTML code given as a scalarref. Takes a hashref as an
argument, the possible keys/value of that hashref are as follows:

=head3 C<event>

    { event => 'results_event', }

B<Mandatory>. Specifies the name of the event to emit when results are
ready. See OUTPUT section for more information.

=head3 C<where>

    { where => 'http://zoffix.com/', }

    { where => \ $html_code, }

B<Mandatory>. Takes either a string that must be a URI to the page with HTML code or a
scalarref that references actual HTML code. This code will be used for counting.

=head3 C<what>

    { what => [ qw/div span a/ ], }

    { what => 'div', }

B<Mandatory>. Takes either an arrayref or a scalar. Specifying a scalar is the same as
specifying an arrayref with just that scalar in it. The C<what> argument specifies the
names of HTML tags or attributes that you want to count.

=head3 C<tag>.

    { type => 'tag', }

    { type => 'attr', }

B<Optional>. Takes two valid strings: C<tag> or C<attr>. Specifies what you wish to count:
tags or attributes. B<Defaults to:> C<tag>

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

    $poe_kernel->post( counter => 'shutdown' );

Takes no arguments. Tells the component to shut itself down.

=head1 OUTPUT

    $VAR1 = {
        'result' => {
            'div' => '6',
            'a' => '15',
            'span' => '8'
        },
        'result_readable' => '15 a, 6 div and 8 span',
        'what' => [
            'div',
            'a',
            'span'
        ],
        'type' => 'tag',
        'where' => 'http://zoffix.com/',
    };

The event handler set up to handle the event which you've specified in
the C<event> argument to C<count()> method/event will receive input
in the C<$_[ARG0]> in a form of a hashref. The possible keys/value of
that hashref are as follows:

=head2 C<result>

    {
        'result' => {
            'div' => '6',
            'a' => '15',
            'span' => '8'
        },
    }

Unless an error occurred the C<result> key will be present and its value will be a hashref
that is the same as the return value of C<count()> method in L<WWW::HTMLTagAttributeCounter>.
See L<WWW::HTMLTagAttributeCounter> C<count()> method documentation for explanation of
keys and values.

=head3 C<result_readable>

    { 'result_readable' => '15 a, 6 div and 8 span', }

Unless an error occurred the C<result_readable> will be present. The value will be the
return of L<WWW::HTMLTagAttributeCounter>'s C<result_readable()> method.
See L<WWW::HTMLTagAttributeCounter> C<result_readable()> method documentation for explanation.

=head3 C<what>, C<type> and C<where>

    {
        'what' => [
            'div',
            'a',
            'span'
        ],
        'type' => 'tag',
        'where' => 'http://zoffix.com/',
    }

The C<what>, C<type> and C<where> keys will contain whatever you passed to the C<count()>
event/method as their values. If you didn't specify the C<type> argument, its value in the
response will be its default value.

=head2 user defined

    { '_blah' => 'foos' }

Any arguments beginning with C<_> (underscore) passed into the C<count()>
event/method will be present intact in the result.

=head1 SEE ALSO

L<POE>, L<WWW::HTMLTagAttributeCounter>

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