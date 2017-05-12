package POE::Component::Net::FTP;

use warnings;
use strict;

our $VERSION = '0.001';

use Carp;
use POE;
use Net::FTP;
use base 'POE::Component::NonBlockingWrapper::Base';

my %True_False_Commands = map { $_ => 1 }
    qw( new  login  authorize  ascii  binary  rename  delete
        cwd  cdup  restart  rmdir  mkdir  alloc
        nlst  list  retr  stor  stou  appe  port
        pasv_xfer  pasv_xfer_unique  pasv_wait  abort  quit
    );

my %Undef_On_Fail_Commands = map { $_ => 1 }
    qw( site  pwd  get  put  put_unique  append  unique_name
        mdtm  size  pasv  quot
    );

my %In_List_Context_Commands = map { $_ => 1 }
    qw( ls  dir  feature);
    # feature will return empty list if feature is not supported

my %In_Scalar_Context_No_Fail_Commands = map { $_ => 1 }
    qw(supported  hash);

sub _methods_define {
    return ( process => '_wheel_entry', );
}

sub process {
    $poe_kernel->post( shift->{session_id} => process => @_ );
}

sub _check_args {
    my ( $self, $in_ref ) = @_;
    exists $in_ref->{commands}
        or carp "Missing `commands` argument"
        and return;

    return 1;
}

sub _prepare_wheel {
    my $self = shift;
    $self->{stop_on_error} = 1
        unless exists $self->{stop_on_error};
}

sub _process_request {
    my ( $self, $in_ref ) = @_;

    my @responses;
    my ( $is_error, $last_error );
    for ( @{ $in_ref->{commands} } ) {
        last
            if $self->{stop_on_error} and $is_error;

        my ( $command, $options_ref ) = %$_;
        $command = lc $command;
        eval {
            if ( $command eq 'new' ) {
                $self->{obj} = Net::FTP->new( @$options_ref )
                    or push @responses, [ $@ ]
                    and $is_error = $command
                    and $last_error = $@
                    and next;
                push @responses, [ 1 ];
            }
            elsif ( exists $True_False_Commands{ $command } ) {
                if ( my $res = $self->{obj}->$command( @$options_ref ) ) {
                    push @responses, [ $res ];
                }
                else {
                    my $error = $self->{obj}->message;
                    push @responses, [ $error ];
                    $is_error = $command;
                    $last_error = $error;
                }
            }
            elsif ( exists $Undef_On_Fail_Commands{ $command } ) {
                if ( defined(
                        my $res = $self->{obj}->$command( @$options_ref )
                ) ) {
                    push @responses, [ $res ];
                }
                else {
                    my $error = $self->{obj}->message;
                    push @responses, [ $error ];
                    $is_error = $command;
                }
            }
            elsif ( exists $In_List_Context_Commands{ $command } ) {
                push @responses,
                    [ $self->{obj}->$command( @$options_ref ) ];
            }
            elsif ( exists $In_Scalar_Context_No_Fail_Commands{ $command } ) {
                push @responses,
                    [ scalar $self->{obj}->$command( @$options_ref ) ];
            }
            else {
                croak "Invalid command `$command` was specified";
            }
        };
        if ( $@ ) { carp "Fatal error occured during execution: $@\n"; }
    }

    $in_ref->{is_error} = $is_error
        if $is_error;

    $in_ref->{last_error} = $last_error
        if $last_error;

    $in_ref->{responses} = \@responses;
}

1;
__END__

=head1 NAME

POE::Component::Net::FTP - non-blocking wrapper around Net::FTP

=head1 SYNOPSIS

    use strict;
    use warnings;

    use POE qw(Component::Net::FTP);

    die "Usage: perl ftp.pl <host> <login> <password> <file_to_upload>\n"
        unless @ARGV == 4;

    my ( $Host, $Login, $Pass, $File ) = @ARGV;

    my $poco = POE::Component::Net::FTP->spawn;

    POE::Session->create(
        package_states => [ main => [ qw(_start response) ], ],
    );

    $poe_kernel->run;

    sub _start {
        $poco->process( {
                event       => 'response',
                commands    => [
                    { new   => [ $Host         ] },
                    { login => [ $Login, $Pass ] },
                    { put   => [ $File         ] },
                ],
            }
        );
    }

    sub response {
        my $in_ref = $_[ARG0];
        if ( $in_ref->{is_error} ) {
            print "Failed on $in_ref->{is_error} command: "
                     . "$in_ref->{last_error}\n";
        }
        else {
            print "Success!\n";
        }
        $poco->shutdown;
    }

Using event based interface is also possible.

=head1 DESCRIPTION

The module is a non-blocking wrapper around L<Net::FTP> module with an
accent on "wrapper". In other words, to use this module you'd need
to read up the docs for L<Net::FTP> module as this wrapper is literally
a wrapper.

The is also a module L<POE::Component::Client::FTP>, you might want to
check it out although it was not fitting my requirements hence the creation
of this module.

=head1 CONSTRUCTOR

=head2 C<spawn>

    my $poco = POE::Component::Net::FTP>spawn;

    POE::Component::Net::FTP->spawn(
        alias           => 'ftp',
        stop_on_error   => 0,
        options         => {
            debug => 1,
            trace => 1,
            # POE::Session arguments for the component
        },
        debug           => 1, # output some debug info
    );

The C<spawn> method returns a
POE::Component::Net::FTP object. It takes a few arguments,
I<all of which are optional>. The possible arguments are as follows:

=head3 C<alias>

    ->spawn( alias => 'ftp' );

B<Optional>. Specifies a POE Kernel alias for the component.

=head3 C<stop_on_error>

    ->spawn( stop_on_error => 1 );

B<Optional>. Takes either true or false values. If set to a true value
will stop and return if any of the series of commands failed. Otherwise
will try to execute all the commands (this probably won't make sense
until you read up on C<process()> method/event). B<Defaults to:> C<1>

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

=head2 C<process>

    $poco->process( {
            event       => 'event_for_output',
            commands    => [
                { new   => [ $Host         ] },
                { login => [ $Login, $Pass ] },
                { put   => [ $File         ] },
            ],
            _blah       => 'pooh!',
            session     => 'other',
        }
    );

Takes a hashref as an argument, does not return a sensible return value.
See C<process> event's description for more information.

=head2 C<session_id>

    my $poco_id = $poco->session_id;

Takes no arguments. Returns component's session ID.

=head2 C<shutdown>

    $poco->shutdown;

Takes no arguments. Shuts down the component.

=head1 ACCEPTED EVENTS

=head2 C<process>

    $poe_kernel->post( ftp => process => {
            event       => 'event_for_output',
            commands    => [
                { new   => [ $Host         ] },
                { login => [ $Login, $Pass ] },
                { put   => [ $File         ] },
            ],
            _blah       => 'pooh!',
            session     => 'other',
        }
    );

Instructs the component to call a series (or just one) methods of
L<Net::FTP> object. Takes a hashref as an
argument, the possible keys/value of that hashref are as follows:

=head3 event

    { event => 'results_event', }

B<Mandatory>. Specifies the name of the event to emit when results are
ready. See OUTPUT section for more information.

=head3 commands

    commands    => [
        { new   => [ $Host         ] },
        { login => [ $Login, $Pass ] },
        { put   => [ $File         ] },
    ],

B<Mandatory>. This is the "wrapper" part. The C<commands> argument
takes an arrayref of hashrefs. The I<first call to this event/method must
contain C<new> as the first command> afterwards the L<Net::FTP> object
will be the same one until you pass in a new C<new> command. The hashrefs
are all single key/value pairs. The key is the method of L<Net::FTP> object
you wish to call and the value is an I<arrayref> of arguments to pass into
that method. Error checking will be done by the component, see "OUTPUT"
section for details.

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

    $poe_kernel->post( ftp => 'shutdown' );

Takes no arguments. Tells the component to shut itself down.

=head1 OUTPUT

    $VAR1 = {
        'commands' => [ { 'new'   => [ 'ftp.host.com'  ] },
                        { 'login' => [ 'login', 'pass' ] },
                        { 'put'   => [ 'test.txt'      ] },
        ],
        'responses' => [ [ 1   ],
                         [ '1' ],
                         [ 'test.txt' ]
        ]
    };

The event handler set up to handle the event which you've specified in
the C<event> argument to C<process()> method/event will recieve input
in the C<$_[ARG0]> in a form of a hashref. The possible keys/value of
that hashref are as follows:

=head2 C<responses>

    'responses' => [ [ 1   ],
                        [ '1' ],
                        [ 'test.txt' ]
    ]

The C<responses> key will contain an arrayref as a value. Each element
of that arrayref will also be an arrayref which will be the return value
of the "command" which was passed into C<commands> arrayref to
C<process()> event/method (i.e. the return value of the "command" passed
as a third element in C<commands> arrayref will be the the third element
in C<responses> arrayref). If a particular command (read "method call")
failed the return value will be the return value of L<Net::FTP>'s
C<message()> method (where applicable), for C<new()> method (on falure)
the element will contain the value of C<$@>.

=head2 C<is_error>

    { 'is_error'    => 'login' }

If any of the methods listed in C<commands> arrayref of C<process>
event/method failed then C<is_error> key will be present and it's value
will be the name of the method that failed.

=head2 C<last_error>

    { 'last_error' => 'Login authentication failed' }

If any of the methods listed in C<commands> arrayref of C<process>
event/method failed then C<last_error> key will be present and it's value
will be the error message explaining the falure.

=head2 user defined

    { '_blah' => 'foos' }

Any arguments beginning with C<_> (underscore) passed into the C<EXAMPLE()>
event/method will be present intact in the result.

=head1 SEE ALSO

L<POE>, L<Net::FTP>

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>
(L<http://zoffix.com>, L<http://haslayout.net>)

=head1 BUGS

Please report any bugs or feature requests to C<bug-poe-component-net-ftp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Component-Net-FTP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Component::Net::FTP

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Component-Net-FTP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Component-Net-FTP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Component-Net-FTP>

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Component-Net-FTP>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Zoffix Znet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

