package POE::Component::WWW::Pastebin::Bot::Pastebot::Create;

use warnings;
use strict;

our $VERSION = '0.003';

use Carp;
use POE;
use base 'POE::Component::NonBlockingWrapper::Base';
use WWW::Pastebin::Bot::Pastebot::Create;

sub _methods_define {
    return ( paste => '_wheel_entry' );
}

sub paste {
    $poe_kernel->post( shift->{session_id} => paste => @_ );
}

sub _check_args {
    my ( $self, $args_ref ) = @_;

    exists $args_ref->{content}
        or carp "Missing `content` argument"
        and return;

    return 1;
}

sub _prepare_wheel {
    my $self = shift;
    $self->{obj} = WWW::Pastebin::Bot::Pastebot::Create->new(
        %{ $self->{obj_args} || {} }
    );
}

sub _process_request {
    my ( $self, $in_ref ) = @_;
    my @args = ( $in_ref->{content} );
    for ( qw(channel nick summary) ) {
        exists $in_ref->{$_}
            and push @args, $_ => $in_ref->{$_};
    }
    
    my $paster = $self->{obj};

    if ( exists $in_ref->{site} ) {
        $paster->site( $in_ref->{site} );
    }

    my $response_ref = $paster->paste( @args );
    if ( $response_ref ) {
        $in_ref->{uri} = $paster->uri;
    }
    else {
        $in_ref->{error} = $paster->error;
    }
}

1;

__END__

=encoding utf8

=head1 NAME

POE::Component::WWW::Pastebin::Bot::Pastebot::Create - non-blocking POE wrapper around WWW::Pastebin::Bot::Pastebot::Create

=head1 SYNOPSIS

    use strict;
    use warnings;

    use POE qw(Component::WWW::Pastebin::Bot::Pastebot::Create);

    my $poco = POE::Component::WWW::Pastebin::Bot::Pastebot::Create->spawn;

    POE::Session->create(
        package_states => [ main => [ qw(_start pasted) ], ],
    );

    $poe_kernel->run;

    sub _start {
        $poco->paste( {
                event       => 'pasted',
                content     => 'test',
                summary     => 'just testing',
                nick        => 'foos',
            }
        );
    }

    sub pasted {
        my $in_ref = $_[ARG0];
        if ( $in_ref->{error} ) {
            print "Got error: $in_ref->{error}\n";
        }
        else {
            print "Your paste is located on $in_ref->{uri}\n";
        }
        $poco->shutdown;
    }

=head1 DESCRIPTION

The module is a L<POE> based non-blocking wrapper around
L<WWW::Pastebin::Bot::Pastebot::Create> module which provides interface
to create new pastes on pastebin sites powered by L<Bot::Pastebot>.

=head1 CONSTRUCTOR

=head2 C<spawn>

    my $poco = POE::Component::WWW::Pastebin::Bot::Pastebot::Create->spawn;

    POE::Component::WWW::Pastebin::Bot::Pastebot::Create->spawn(
        alias => 'paster',
        obj_args => { timeout => 30 },
        options => {
            debug => 1,
            trace => 1,
            # POE::Session arguments for the component
        },
        debug => 1, # output some debug info
    );

The C<spawn> method returns a
POE::Component::WWW::Pastebin::Bot::Pastebot::Create object. It takes a few arguments,
I<all of which are optional>. The possible arguments are as follows:

=head3 C<alias>

    ->spawn( alias => 'paster' );

B<Optional>. Specifies a POE Kernel alias for the component.

=head3 C<obj_args>

    ->spawn( obj_args => { timeout => 30 } );

B<Optional>. Takes a hashref as a value. This hashref will be
dereferenced directly into L<WWW::Pastebin::Bot::Pastebot::Create>'s
contructor. See documentation for L<WWW::Pastebin::Bot::Pastebot::Create>
for possible arguments.

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

=head2 C<paste>

    $poco->paste( {
            event       => 'event_for_output',
            content     => 'long chunk of text to paste',
            summary     => 'description of the paste',
            nick        => 'Zoffix',
            channel     => '#perl',
            _blah       => 'pooh!',
            session     => 'other',
        }
    );

Takes a hashref as an argument, does not return a sensible return value.
See C<paste> event's description for more information.

=head2 C<session_id>

    my $poco_id = $poco->session_id;

Takes no arguments. Returns component's session ID.

=head2 C<shutdown>

    $poco->shutdown;

Takes no arguments. Shuts down the component.

=head1 ACCEPTED EVENTS

=head2 C<paste>

    $poe_kernel->post( paster => paste => {
            event       => 'event_for_output',
            content     => 'long chunk of text to paste',
            summary     => 'description of the paste',
            nick        => 'Zoffix',
            channel     => '#perl',
            _blah       => 'pooh!',
            session     => 'other',
        }
    );

Instructs the component to create a new paste. Takes a hashref as an
argument, the possible keys/value of that hashref are as follows:

=head3 C<event>

    { event => 'results_event', }

B<Mandatory>. Specifies the name of the event to emit when results are
ready. See OUTPUT section for more information.

=head3 C<content>

    { content => 'long chunk to paste' }

B<Mandatory>. Specifies the actual content of the paste you want to create.

=head3 C<channel>

    { channel => '#perl' }

B<Optional>. Specifies the channel to which the pastebot will announce.
Valid values vary as different pastebots configured for different channels,
but the value would be the same as what you'd see in the "Channel" select
box on the site. Specifying empty string will result in "No channel".
B<Defaults to:> C<''> (no specific channel)

=head3 C<nick>

    { nick => 'Zoffix' }

B<Optional>. Specifies the name of the person creating the paste.
B<Defaults to:> C<''> (empty; no name)

=head3 C<summary>

    { summary => 'some uber codez' }

B<Optional>. Specifies a short summary of the paste contents.
B<Defaults to:> C<''> (empty; no summary)

=head3 C<site>

    { site  => 'http://erxz.com/pb' }

B<Optional>. Must contain a URI to pastebin site powered by L<Bot::Pastebot>
(note: don't end it with specific channel suffix). If specified will
make the component change the pastebin used for pasting. B<Note:> the
specified pastebin is not restored back to the original value.
B<By default> this argument is not specified.

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
        'summary' => 'just testing',
        'content' => 'test',
        'nick' => 'foos',
        'uri' => bless( do{\(my $o = 'http://erxz.com/pb/7998')}, 'URI::http' ),
        '_blah' => 'user arg',
    };

The event handler set up to handle the event which you've specified in
the C<event> argument to C<paste()> method/event will recieve input
in the C<$_[ARG0]> in a form of a hashref. The possible keys/value of
that hashref are as follows:

=head2 C<uri>

    { 'uri' => bless( do{\(my $o = 'http://erxz.com/pb/7998')}, 'URI::http' ), }

If all worked out without errors C<uri> key will contain a L<URI> object
pointing to a newly created paste.

=head2 C<error>

    { error => 'Network error: 500 read timeout' }

If an error occured during pasting the C<error> key will be present and
its value will contain an explanation of the failure.

=head2 valid arguments for C<paste()>

    {
        'summary' => 'just testing',
        'content' => 'test',
        'nick' => 'foos',
    }

Valid arguments to C<paste()> event/method (i.e. the C<summary>,
C<content>, C<channel>, C<site> and C<nick>) will be present in output
containing
same values as you gave them when calling C<paste()> event/method.

=head2 user defined

    { '_blah' => 'foos' }

Any arguments beginning with C<_> (underscore) passed into the C<paste()>
event/method will be present intact in the result.

=head1 SEE ALSO

L<POE>, L<URI>, L<WWW::Pastebin::Bot::Pastebot::Create>

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>
(L<http://zoffix.com>, L<http://haslayout.net>)

=head1 BUGS

Please report any bugs or feature requests to C<bug-poe-component-www-pastebin-bot-pastebot-create at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Component-WWW-Pastebin-Bot-Pastebot-Create>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Component::WWW::Pastebin::Bot::Pastebot::Create

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Component-WWW-Pastebin-Bot-Pastebot-Create>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Component-WWW-Pastebin-Bot-Pastebot-Create>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Component-WWW-Pastebin-Bot-Pastebot-Create>

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Component-WWW-Pastebin-Bot-Pastebot-Create>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Zoffix Znet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

