package POE::Component::WWW::Pastebin::Many::Retrieve;

use warnings;
use strict;

our $VERSION = '0.001';

use Carp;
use WWW::Pastebin::Many::Retrieve;
use POE;
use base 'POE::Component::NonBlockingWrapper::Base';

sub _methods_define {
    return ( retrieve => '_wheel_entry' );
}

sub retrieve {
    $poe_kernel->post( shift->{session_id} => retrieve => @_ );
}

sub _prepare_wheel {
    my $self = shift;
    $self->{obj} = WWW::Pastebin::Many::Retrieve->new(
        timeout => $self->{timeout} || 30
    );
}

sub _check_args {
    my ( $self, $args_ref ) = @_;
    exists $args_ref->{uri}
        or carp "Missing `uri` argument"
        and return;

    return 1;
}

sub _process_request {
    my ( $self, $in_ref ) = @_;
    my $paster = $self->{obj};
    my $response = $paster->retrieve( $in_ref->{uri} );
    if ( $response ) {
        @$in_ref{ qw(response content) } = ( $response, $paster->content );
    }
    else {
        $in_ref->{error} = $paster->error;
    }
}

1;
__END__

=head1 NAME

POE::Component::WWW::Pastebin::Many::Retrieve - non-blocking wrapper around WWW::Pastebin::Many::Retrieve

=head1 SYNOPSIS

    use strict;
    use warnings;

    use POE qw(Component::WWW::Pastebin::Many::Retrieve);

    my $poco = POE::Component::WWW::Pastebin::Many::Retrieve->spawn;

    POE::Session->create(
        package_states => [ main => [qw(_start retrieved)] ],
    );

    $poe_kernel->run;

    sub _start {
        $poco->retrieve( {
                uri     => 'http://phpfi.com/302683',
                event   => 'retrieved',
                _random => scalar localtime,
            }
        );
    }

    sub retrieved {
        my $in_ref = $_[ARG0];

        print "This is request from $in_ref->{_random}\n";

        if ( $in_ref->{error} ) {
            print "Got error: $in_ref->{error}\n";
        }
        else {
            print "Paste $in_ref->{uri} contains:\n$in_ref->{content}\n";
        }

        $poco->shutdown;
    }

Using event based interface is also possible.

=head1 DESCRIPTION

The module is a non-blocking wrapper around L<WWW::Pastebin::Many::Retrieve>
which provides interface to retrieve pastes from many different pastebin
sites.

=head1 CONSTRUCTOR

=head2 C<spawn>

    my $poco = POE::Component::WWW::Pastebin::Many::Retrieve->spawn;

    POE::Component::WWW::Pastebin::Many::Retrieve->spawn(
        alias => 'paster',
        timeout => 30,
        options => {
            debug => 1,
            trace => 1,
            # POE::Session arguments for the component
        },
        debug => 1, # output some debug info
    );

The C<spawn> method returns a
POE::Component::WWW::Pastebin::Many::Retrieve object. It takes a few
arguments,
I<all of which are optional>. The possible arguments are as follows:

=head3 C<alias>

    ->spawn( alias => 'paster' );

B<Optional>. Specifies a POE Kernel alias for the component.

=head3 C<timeout>

    ->spawn( timeout => 30 );

B<Optional>. Specifies the network timeout to relate to when retrieving
pastes. B<Defaults to:> C<30> seconds

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

=head2 C<retrieve>

    $poco->retrieve( {
            event       => 'event_for_output',
            uri         => 'http://uri_to_paste_you_want_to_retrieve.com',
            _blah       => 'pooh!',
            session     => 'other',
        }
    );

Takes a hashref as an argument, does not return a sensible return value.
See C<retrieve> event's description for more information.

=head2 C<session_id>

    my $poco_id = $poco->session_id;

Takes no arguments. Returns component's session ID.

=head2 C<shutdown>

    $poco->shutdown;

Takes no arguments. Shuts down the component.

=head1 ACCEPTED EVENTS

=head2 C<retrieve>

    $poe_kernel->post( paster => retrieve => {
            event       => 'event_for_output',
            uri         => 'http://uri_to_paste_you_want_to_retrieve.com',
            _blah       => 'pooh!',
            session     => 'other',
        }
    );

Instructs the component to retrieve a paste. Takes a hashref as an
argument, the possible keys/value of that hashref are as follows:

=head3 event

    { event => 'results_event', }

B<Mandatory>. Specifies the name of the event to emit when results are
ready. See OUTPUT section for more information.

=head3 uri

    { uri => 'http://uri_to_paste_you_want_to_retrieve.com' }

B<Mandatory>. Takes a scalar containing a URI poiting to the paste you
would like to retrieve. See "SUPPORTED PASTEBINS" section in documentation
for L<WWW::Pastebin::Many::Retrieve> module regarding accepted pastebins.

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

    $poe_kernel->post( paster => 'shutdown' );

Takes no arguments. Tells the component to shut itself down.

=head1 OUTPUT

    $VAR1 = {
        'response' => {
            'hits' => '0',
            'lang' => 'plaintext',
            'name' => 'N/A',
            'content' => 'paste content here',
            'age' => '14.03.08 21:59'
        },
        'content' => 'paste content here',
        'uri' => 'http://phpfi.com/302683',
        '_random' => 'Sun Mar 30 07:33:00 2008'
    };

The event handler set up to handle the event which you've specified in
the C<event> argument to C<retrieve()> method/event will recieve input
in the C<$_[ARG0]> in a form of a hashref. The possible keys/value of
that hashref are as follows:

=head2 content

    { 'content' => 'paste content here', }

Unless an error occured the C<content> key will be present and its value
will be the actual content of the paste you retrieved.

=head2 response

    {
        'response' => {
            'hits' => '0',
            'lang' => 'plaintext',
            'name' => 'N/A',
            'content' => 'paste content here',
            'age' => '14.03.08 21:59'
        },
    }

Unless an error occured the C<response> key will contain the return
value of C<response()> method of the specific object which was used
to retrieve your paste. See L<WWW::Pastebin::Many::Retrieve> for more
information.

=head2 error

    { 'error' => 'Nework error: 500 read timeout' }

If an error occured during retrieval of your paste the C<error> key will
be present and its value will be a human parsable error message explaining
why we failed.

=head2 uri

    { 'uri' => 'http://phpfi.com/302683', }

The C<uri> key will contain whatever you've specified in the C<uri> argument
to C<retrieve()> event/method.

=head2 user defined

    { '_blah' => 'foos' }

Any arguments beginning with C<_> (underscore) passed into the C<retrieve()>
event/method will be present intact in the result.

=head1 SEE ALSO

L<POE>, L<WWW::Pastebin::Many::Retrieve>

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>
(L<http://zoffix.com>, L<http://haslayout.net>)

=head1 BUGS

Please report any bugs or feature requests to C<bug-poe-component-www-pastebin-many-retrieve at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Component-WWW-Pastebin-Many-Retrieve>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Component::WWW::Pastebin::Many::Retrieve

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Component-WWW-Pastebin-Many-Retrieve>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Component-WWW-Pastebin-Many-Retrieve>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Component-WWW-Pastebin-Many-Retrieve>

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Component-WWW-Pastebin-Many-Retrieve>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Zoffix Znet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

