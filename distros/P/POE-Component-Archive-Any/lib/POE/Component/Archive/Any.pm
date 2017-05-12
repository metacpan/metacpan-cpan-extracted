package POE::Component::Archive::Any;

use warnings;
use strict;

our $VERSION = '0.002';

use Carp;
use POE (qw( Filter::Reference  Filter::Line  Wheel::Run ));

sub spawn {
    my $package = shift;
    croak "$package requires an even number of arguments"
        if @_ & 1;

    my %params = @_;
    
    $params{ lc $_ } = delete $params{ $_ } for keys %params;

    delete $params{options}
        unless ref $params{options} eq 'HASH';
    
    my $self = bless \%params, $package;

    $self->{session_id} = POE::Session->create(
        object_states => [
            $self => {
                extract  => '_extract',
                shutdown => '_shutdown',
            },
            $self => [
                qw(
                    _child_error
                    _child_closed
                    _child_stdout
                    _child_stderr
                    _sig_child
                    _start
                )
            ]
        ],
        ( defined $params{options} ? ( options => $params{options} ) : () ),
    )->ID();

    return $self;
}


sub _start {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
    $self->{session_id} = $_[SESSION]->ID();

    if ( $self->{alias} ) {
        $kernel->alias_set( $self->{alias} );
    }
    else {
        $kernel->refcount_increment( $self->{session_id} => __PACKAGE__ );
    }

    $self->{wheel} = POE::Wheel::Run->new(
        Program    => \&_wheel,
        ErrorEvent => '_child_error',
        CloseEvent => '_child_close',
        StdoutEvent => '_child_stdout',
        StderrEvent => '_child_stderr',
        StdioFilter => POE::Filter::Reference->new,
        StderrFilter => POE::Filter::Line->new,
        ( $^O eq 'MSWin32' ? ( CloseOnCall => 0 ) : ( CloseOnCall => 1 ) )
    );

    $kernel->yield('shutdown')
        unless $self->{wheel};

    $kernel->sig_child( $self->{wheel}->PID(), '_sig_child' );

    undef;
}

sub _sig_child {
    $poe_kernel->sig_handled;
}

sub session_id {
    return $_[0]->{session_id};
}

sub  extract {
    my $self = shift;
    $poe_kernel->post( $self->{session_id} => 'extract' => @_ );
}

sub _extract {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
    my $sender = $_[SENDER]->ID;
    
    return
        if $self->{shutdown};
        
    my $args;
    if ( ref $_[ARG0] eq 'HASH' ) {
        $args = { %{ $_[ARG0] } };
    }
    else {
        carp "First parameter must be a hashref, trying to adjust...";
        $args = { @_[ARG0 .. $#_] };
    }
    
    $args->{ lc $_ } = delete $args->{ $_ }
        for grep { !/^_/ } keys %$args;

    unless ( $args->{event} ) {
        carp "Missing 'event' parameter to extract";
        return;
    }
    unless ( $args->{file} ) {
        carp "Missing 'file' parameter to extract";
        return;
    }

    if (    defined $args->{dir}
        and not defined $args->{just_info}
        and not -e $args->{dir}
    ) {
        unless ( mkdir $args->{dir} ) {
            carp "Directory `$args->{dir}` did not exist and I failed"
                    . "to create it ($!)";
            return;
        }
    }
        
    if ( $args->{session} ) {
        if ( my $ref = $kernel->alias_resolve( $args->{session} ) ) {
            $args->{sender} = $ref->ID;
        }
        else {
            carp "Could not resolve 'session' parameter to a valid"
                    . " POE session";
            return;
        }
    }
    else {
        $args->{sender} = $sender;
    }
    
    $kernel->refcount_increment( $args->{sender} => __PACKAGE__ );
    $self->{wheel}->put( $args );
    
    undef;
}

sub shutdown {
    my $self = shift;
    $poe_kernel->call( $self->{session_id} => 'shutdown' => @_ );
}

sub _shutdown {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
    $kernel->alarm_remove_all;
    $kernel->alias_remove( $_ ) for $kernel->alias_list;
    $kernel->refcount_decrement( $self->{session_id} => __PACKAGE__ )
        unless $self->{alias};

    $self->{shutdown} = 1;
    
    $self->{wheel}->shutdown_stdin
        if $self->{wheel};
}

sub _child_closed {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
    
    carp "_child_closed called (@_[ARG0..$#_])\n"
        if $self->{debug};

    delete $self->{wheel};
    $kernel->yield('shutdown')
        unless $self->{shutdown};

    undef;
}

sub _child_error {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
    carp "_child_error called (@_[ARG0..$#_])\n"
        if $self->{debug};

    delete $self->{wheel};
    $kernel->yield('shutdown')
        unless $self->{shutdown};

    undef;
}

sub _child_stderr {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
    carp "_child_stderr: $_[ARG0]\n"
        if $self->{debug};

    undef;
}

sub _child_stdout {
    my ( $kernel, $self, $input ) = @_[ KERNEL, OBJECT, ARG0 ];
    
    my $session = delete $input->{sender};
    my $event   = delete $input->{event};

    $kernel->post( $session, $event, $input );
    $kernel->refcount_decrement( $session => __PACKAGE__ );
    
    undef;
}

sub _wheel {
    if ( $^O eq 'MSWin32' ) {
        binmode STDIN;
        binmode STDOUT;
    }
    
    my $raw;
    my $size = 4096;
    my $filter = POE::Filter::Reference->new;

    while ( sysread STDIN, $raw, $size ) {
        my $requests = $filter->get( [ $raw ] );
        foreach my $req_ref ( @$requests ) {

            _process_request( $req_ref ); # changes $req_ref

            my $response = $filter->put( [ $req_ref ] );
            print STDOUT @$response;
        }
    }
}

sub _process_request {
    my $req_ref = shift;
    require Archive::Any;
    my $ar = Archive::Any->new( $req_ref->{file} );
    unless ( defined $ar ) {
        $req_ref->{error} = 'Failed to create the '
                             . 'Archive::Any object.';

        unless ( -f $req_ref->{file} ) {
            $req_ref->{error} .= q| Specified `file` doesn't exist|;
        }
        return;
    }

    unless ( $req_ref->{just_info} ) {
        $ar->extract( $req_ref->{dir} );
    }
    
    @$req_ref{ qw(files  type  is_impolite  is_naughty) }
    = (
        [ $ar->files ],

        ## TODO when the bug in Archive::Any is fixed, change this to
        ## simple $ar->mime->type()
        ($ar->{type} || $ar->mime_type ), 
        scalar $ar->is_impolite,
        scalar $ar->is_naughty,
    );

    undef;
}


1;
__END__

=encoding utf8

=head1 NAME

POE::Component::Archive::Any - a non-blocking wrapper around
L<Archive::Any>

=head1 SYNOPSIS

    use strict;
    use warnings;
    
    use POE qw(Component::Archive::Any);

    my $poco = POE::Component::Archive::Any->spawn;

    POE::Session->create(
        package_states => [
            main => [ qw( _start  extracted ) ],
        ],
    );

    $poe_kernel->run;

    sub _start {
        $poco->extract( {
                event => 'extracted',
                file  => 'archive.tar.gz',
            }
        );
    }

    sub extracted {
        my $in = $_[ARG0];

        if ( $in->{error} ) {
            print "Error: $in->{error}\n";
        }
        else {
            print "The archive extracts itself to outside directory\n"
                if $in->{is_naughty};
            print "The archive extracts itself to the current directory\n"
                if $in->{is_impolite};

            print "Extracted $in->{file} archive which is of type "
                    . "$in->{type} and contains the following files:\n";

            print "$_\n" for @{ $in->{files} };
        }
        $poco->shutdown;
    }

Using the event-based interface is also possible, of course.

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head2 spawn

    my $poco = POE::Component::Archive::Any->spawn;

    POE::Component::Archive::Any->spawn(
        alias => 'arch',
        options => {
            debug => 1,
            trace => 1,
            # POE::Session arguments for the component
        },
        debug => 1, # output some debug info
    );

The C<spawn> method returns a
POE::Component::Archive::Any object. It takes a few arguments,
I<all of which are optional>. The possible arguments are as follows:

=head3 alias

    POE::Component::Archive::Any->spawn(
        alias => 'arch'
    );

B<Optional>. Specifies a POE Kernel alias for the component.

=head3 options

    my $poco = POE::Component::Archive::Any->spawn(
        options => {
            trace => 1,
            default => 1,
        },
    );

B<Optioanl>.
A hashref of POE Session options to pass to the component's session.

=head3 debug

    my $poco = POE::Component::Archive::Any->spawn(
        debug => 1
    );

When set to a true value turns on output of debug messages. B<Defaults to:>
C<0>.

=head1 METHODS

These are the object-oriented methods of the components.

=head2 extract

    $poco->extract( {
            event       => 'results_event',     # mandatory
            file        => 'archive.tar.gz',    # mandatory
            type        => 'tar.gz',            # optional
            just_info   => 1,                   # optional
            dir         => 'exctract_dir',      # optional
            session     => 'other_session',     # optional
            _user       => 'random',            # optional
        }
    );

Instructs the component to get archive's information as well as
extract it (the extraction step can be omited).
Takes a hashref of options. See C<extract> event
description for more information.

=head2 session_id

    my $poco_id = $poco->session_id;

Takes no arguments. Returns component's session ID.

=head2 shutdown

    $poco->shutdown;

Takes no arguments. Shuts down the component.

=head1 ACCEPTED EVENTS

=head2 extract

    $poe_kernel->post( arch => extract => {
            event       => 'results_event',     # mandatory
            file        => 'archive.tar.gz',    # mandatory
            type        => 'tar.gz',            # optional
            just_info   => 1,                   # optional
            dir         => 'exctract_dir',      # optional
            session     => 'other_session',     # optional
            _user       => 'random',            # optional
        }
    );

Instructs the component to get archive's information as well as
extract it (the extraction step can be omited).
Takes a hashref of options. The possible keys/values of that hashref
are as follows:

=head3 event

    { event => 'results_event', }

B<Mandatory>. Specifies the name of the event to emit when results are
ready. See OUTPUT section for more information.

=head3 file

    { file => 'archive.tar.gz' }

B<Mandatory>. Specifies the filename of the archive to get information
about or exctract.

=head3 type

    { type => 'tar.gz' }

B<Optional>. Specifies the type of the archive. If not specified
L<Archive::Any> will work its magic to try to figure it out on its own.

=head3 just_info

B<Optional>. When C<just_info> key's value is set to a I<true> value
component will B<NOT> extract the archive or create archive extraction
directory (see C<dir> argument below). This is useful when you just want
to get information about the archive, such as what files it contains
without actually extracting anything. B<Defaults to:> C<0> (meaning
the component will exctract the archive).

=head3 dir

    { dir => 'exctract_dir' }

B<Optional>. Specifies the directory into which the archive should
be extracted. Unless C<just_info> argument (see above) is set to a I<true>
value, the directory will be created if it doesn't exist. B<Defaults to:>
current working directory.

=head3 session

    { session => $some_other_session_ref }
    
    { session => 'some_alias' }
    
    { session => $session->ID }

B<Optional>. An alternative session alias, reference or ID that the
response should be sent to. B<Defaults to:> sending session.

=head3 user defined

    {
        _user    => 'random',
        _another => 'more',
    }

B<Optional>. Any keys starting with C<_> (underscore) will not affect the
component and will be passed back in the result intact.

=head2 shutdown

    $poe_kernel->post( arch => 'shutdown' );

Takes no arguments. Tells the component to shut itself down.

=head1 OUTPUT

    $VAR1 = {
        'is_naughty' => 0,
        'is_impolite' => 0,
        'files' => [
            'POE-Component-WWW-WebDevout-BrowserSupportInfo-0.01/',
            'POE-Component-WWW-WebDevout-BrowserSupportInfo-0.01/README',
        ],
        'dir'  => '/tmp',
        'file' => 't.tar.gz',
        'type' => 'application/x-gzip',
        _user  => 'random',
    };

The event handler set up to handle the event which you've specified in
the C<event> argument to C<extract()> method/event will recieve input
in the C<$_[ARG0]> in a form of a hashref. The possible keys/value of
that hashref are as follows:

=head2 is_naughty

    { 'is_naughty' => 0 }

Will be set to a true value if archive is going to unpack outside
the current directory (or C<dir> if specified; see C<extract()>
method/event description), otherwise will be set to a false value.

=head2 is_impolite

    { 'is_impolite' => 0 }

Will be set to a true value if archive is going to unpack into the
current directory (or C<dir> if specified; see C<extract()>
method/event description) rather than create its own; otherwise
C<is_impolite> key will be set to a false value.

=head2 files

    {
        'files' => [
            'POE-Component-WWW-WebDevout-BrowserSupportInfo-0.01/',
            'POE-Component-WWW-WebDevout-BrowserSupportInfo-0.01/README',
        ],
    }

Will contain an arrayref elements of which are files that the archive
contains.

=head2 dir

    { dir => '/tmp' }

The C<dir> key will contain the directory into which the archive was
(or could have been, depending on the C<just_info> option to C<extract()>)
extracted. This will be whatever you have provided to the C<extract()>
event/method.

=head2 file

The C<file> key will contain the filename of the archive which was
processed by C<extract()>. This will be whatever you've provided to the
C<extract()> event/method.

=head2 type

    { 'type' => 'application/x-gzip' }

The C<type> key will contain the mime-type of the archive.

=head2 user defined

    { '_user' => 'random' }

Any arguments beginning with C<_> (underscore) passed into the C<extract()>
event/method will be present intact in the result.

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>
(L<http://zoffix.com>, L<http://haslayout.net>)

=head1 BUGS

Please report any bugs or feature requests to C<bug-poe-component-archive-any at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Component-Archive-Any>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Component::Archive::Any

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Component-Archive-Any>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Component-Archive-Any>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Component-Archive-Any>

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Component-Archive-Any>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Zoffix Znet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
