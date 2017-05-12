package POE::Component::App::PNGCrush;

use warnings;
use strict;

our $VERSION = '2.001001'; # VERSION

use Carp;
use POE;
use base 'POE::Component::NonBlockingWrapper::Base';
use App::PNGCrush;

sub _methods_define {
    return ( run => '_wheel_entry' );
}

sub run {
    $poe_kernel->post( shift->{session_id} => run => @_ );
}

sub _check_args {
    my ( $self, $args_ref ) = @_;

    exists $args_ref->{in}
        or carp "Missing `in` argument"
        and return;

    exists $args_ref->{options}
        or carp "Missing `options` argument"
        and return;

    return 1;
}

sub _prepare_wheel {
    my $self = shift;
    $self->{crush} = App::PNGCrush->new( %{ $self->{obj_args} || {} } );
}

sub _process_request {
    my ( $self, $in_ref ) = @_;
    unless ( ref $in_ref->{in} eq 'ARRAY' ) {
        $in_ref->{in} = [ $in_ref->{in} ];
    }

    my $crush = $self->{crush};

    $crush->set_options( @{ $in_ref->{options} || [] } );

    for ( @{ $in_ref->{in} } ) {
        my $out_ref = $crush->run( $_ );
        unless ( defined $out_ref ) {
            $out_ref = $crush->error;
        }
        $in_ref->{out}{ $_ } = $out_ref;
    }
}

1;
__END__

=encoding utf8

=head1 NAME

POE::Component::App::PNGCrush - non-blocking wrapper around App::PNGCrush

=head1 SYNOPSIS

    use strict;
    use warnings;

    use POE qw(Component::App::PNGCrush);

    my $poco = POE::Component::App::PNGCrush->spawn;

    POE::Session->create(
        package_states => [ main => [qw(_start crushed)] ],
    );

    $poe_kernel->run;

    sub _start {
        $poco->run( {
                in      => [ qw(file1.png file2.png file3.png) ],
                options => [
                    qw( -d OUT_DIR -brute 1 ),
                    remove  => [ qw( gAMA cHRM sRGB iCCP ) ],
                ],
                event   => 'crushed',
            }
        );
    }

    sub crushed {
        my $in_ref = $_[ARG0];

        my $proc_ref = $in_ref->{out};
        for ( keys %$proc_ref ) {
            if ( exists $proc_ref->{$_}{error} ) {
                print "Got error on file $_ : $proc_ref->{$_}{error}\n";
            }
            else {
                printf "Stats for file %s\n\tSize reduction: %.2f%%\n\t"
                        . "IDAT reduction: %.2f%%\n",
                        $_, @{ $proc_ref->{$_} }{ qw(size idat) };
            }
        }

        $poco->shutdown;
    }

Using event based interface is also possible.

=head1 DESCRIPTION

The module is a non-blocking wrapper around L<App::PNGCrush>
which provides interface to ``pngcrush'' program. See documentation for
L<App::PNGCrush> regarding information on how to obtain ``pngcrush''
program.

You should familiarize yourself with C<new()>, C<run()> and C<set_options()>
methods of L<App::PNGCrush> module to fully understand the workings
of this POE wrapper (although, I'll point you to those in the right
place throughout this document)

=head1 CONSTRUCTOR

=head2 C<spawn>

    my $poco = POE::Component::App::PNGCrush->spawn;

    POE::Component::App::PNGCrush->spawn(
        alias => 'crush',
        obj_args => {
            max_time => 600,
        },
        options => {
            debug => 1,
            trace => 1,
            # POE::Session arguments for the component
        },
        debug => 1, # output some debug info
    );

The C<spawn> method returns a
POE::Component::App::PNGCrush object. It takes a few arguments,
I<all of which are optional>. The possible arguments are as follows:

=head3 C<alias>

    POE::Component::App::PNGCrush->spawn(
        alias => 'crush'
    );

B<Optional>. Specifies a POE Kernel alias for the component.

=head3 C<obj_args>

    POE::Component::App::PNGCrush->spawn(
        obj_args => { max_time => 600 },
    );

B<Optional>. Takes a hashref as an argument. If specified that hashref will
be directly dereferenced into L<App::PNGCrush>'s constructor (C<new()>
method). See documentation for L<App::PNGCrush> regarding valid values.

=head3 C<options>

    my $poco = POE::Component::App::PNGCrush->spawn(
        options => {
            trace => 1,
            default => 1,
        },
    );

B<Optional>.
A hashref of POE Session options to pass to the component's session.

=head3 C<debug>

    my $poco = POE::Component::App::PNGCrush->spawn(
        debug => 1
    );

When set to a true value turns on output of debug messages. B<Defaults to:>
C<0>.

=head1 METHODS

=head2 C<run>

    $poco->run( {
            event   => 'event_for_output',
            in      => [ qw(file1.png file2.png file3.png) ],
            options => [
                qw( -d OUT_DIR -brute 1 ),
                remove  => [ qw( gAMA cHRM sRGB iCCP )
            ],
            _blah   => 'pooh!',
            session => 'other',
        }
    );

Takes a hashref as an argument, does not return a sensible return value.
See C<run> event's description for more information.

=head2 C<session_id>

    my $poco_id = $poco->session_id;

Takes no arguments. Returns component's session ID.

=head2 C<shutdown>

    $poco->shutdown;

Takes no arguments. Shuts down the component.

=head1 ACCEPTED EVENTS

=head2 C<run>

    $poe_kernel->post( crush => run => {
            event   => 'event_for_output',
            in      => [ qw(file1.png file2.png file3.png) ],
            options => [
                qw( -d OUT_DIR -brute 1 ),
                remove  => [ qw( gAMA cHRM sRGB iCCP )
            ],
            _blah   => 'pooh!',
            session => 'other',
        }
    );

Instructs the component to perform "crushing" of png files.
Takes a hashref as an
argument, the possible keys/value of that hashref are as follows:

=head3 C<event>

    { event => 'results_event', }

B<Mandatory>. Specifies the name of the event to emit when results are
ready. See OUTPUT section for more information.

=head3 C<in>

    { in => 'file.png' }

    { in => [ qw(file1.png file2.png file3.png) ] }

B<Mandatory>. Takes either a scalar containing a filename of an image
you want to "crush" or an arrayref of filenames (if more than one).

=head3 C<options>

    {
        options => [
            qw( -d OUT_DIR -brute 1 ),
            remove  => [ qw( gAMA cHRM sRGB iCCP )
        ],
    }

B<Mandatory>. Takes an arrayref as a value which will be directly
dereferenced into C<set_options()> method of L<App::PNGCrush>. See
documentation for L<App::PNGCrush>'s C<set_options()> method for possible
values.

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

    $poe_kernel->post( EXAMPLE => 'shutdown' );

Takes no arguments. Tells the component to shut itself down.

=head1 OUTPUT

    $VAR1 = {
        'out' => {
            'p2.png' => {
                        'msg' => undef,
                        'total_idat_length' => '1880',
                        'stderr' => '',
                        'cpu' => {
                                    'decoding' => '0.030',
                                    'other' => '0.090',
                                    'total' => '0.200',
                                    'encoding' => '0.080'
                                },
                        'status' => '0',
                        'idat' => '0.80',
                        'stdout' => 'stdout from pngcrush will be here',
                        'size' => '1.56'
                        },
            'p.png' => {
                        'msg' => undef,
                        'total_idat_length' => '1880',
                        'stderr' => '',
                        'cpu' => {
                                    'decoding' => '0.040',
                                    'other' => '0.030',
                                    'total' => '0.200',
                                    'encoding' => '0.130'
                                },
                        'status' => '0',
                        'idat' => '0.80',
                        'stdout' => 'pngcrush 1.6.4 blah blah',
                        'size' => '1.56'
                    }
        },
        'options' => [
                        '-d',
                        'OUT_DIR',
                        '-brute',
                        '1',
                        'remove',
                        [
                        'gAMA',
                        'cHRM',
                        'sRGB',
                        'iCCP'
                        ]
                    ],
        'in' => [
                'p.png',
                'p2.png'
                ],
        '_blah' => 'pooh!',
    };


The event handler set up to handle the event which you've specified in
the C<event> argument to C<run()> method/event will receive input
in the C<$_[ARG0]> in a form of a hashref. The possible keys/value of
that hashref are as follows:

=head2 C<out>

The C<out> key will have a hashref as a value. The keys of that
hashref will be filenames of the files which you gave as C<in> argument
to C<run()> event/method. The values for each of these keys will either
be a scalar containing an error message (if an error occurred) or a hashref
containing the exact same hashref C<run()> method of L<App::PNGCrush>
module would return. For explanation of keys/values of that hashref
see C<run()> method in documentation for L<App::PNGCrush> module.

=head2 valid arguments to C<run()>

    'options' => [
                    '-d',
                    'OUT_DIR',
                    '-brute',
                    '1',
                    'remove',
                    [
                    'gAMA',
                    'cHRM',
                    'sRGB',
                    'iCCP'
                    ]
                ],
    'in' => [
            'p.png',
            'p2.png'
            ],

Valid arguments to C<run()> event/method (that is the C<options> and
C<in> arguments) will be present in the output as well.

=head2 user defined

    { '_blah' => 'foos' }

Any arguments beginning with C<_> (underscore) passed into the C<EXAMPLE()>
event/method will be present intact in the result.

=head1 SEE ALSO

L<POE>, L<App::PNGCrush>

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