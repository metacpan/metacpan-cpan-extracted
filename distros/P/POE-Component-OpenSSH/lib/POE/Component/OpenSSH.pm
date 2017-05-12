package POE::Component::OpenSSH;
# ABSTRACT: Non-blocking SSH Component for POE using Net::OpenSSH
$POE::Component::OpenSSH::VERSION = '0.11';
use strict;
use warnings;
use Carp 'croak';
use Net::OpenSSH;
use POE::Component::Generic;

sub _build_object {
    my ( $class, $opts ) = @_;

    return POE::Component::Generic->spawn(
        package        => 'Net::OpenSSH',
        object_options => $opts->{'args'},

        map +( $_ => $opts->{$_} ), qw<alias debug verbose error>,
    );
}

sub object   { shift->{'_object'} }
sub capture  { shift->{'_object'}->capture(@_)  }
sub capture2 { shift->{'_object'}->capture2(@_) }
sub system   { shift->{'_object'}->system(@_)   }
sub scp_get  { shift->{'_object'}->scp_get(@_)  }
sub scp_put  { shift->{'_object'}->scp_put(@_)  }
sub sftp     { shift->{'_object'}->sftp(@_)     }

sub new {
    my $class = shift;

    if ( @_ % 2 != 0 ) {
        croak 'Arguments must be in the form of key/value';
    }

    my %opts = (
        args    => [],
        options => {},
        error   => {},
        alias   => '',
        debug   => 0,
        verbose => 0,
        @_,
    );

    ref $opts{'args'}    eq 'ARRAY'
        or croak '"args" must be an arryref';

    ref $opts{'options'} eq 'HASH'
        or croak '"options" must be a hashref';

    ref $opts{'error'}   eq 'HASH'
        or croak '"error" must be a hashref';

    return bless { _object => $class->_build_object(\%opts) }, $class;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::OpenSSH - Non-blocking SSH Component for POE using Net::OpenSSH

=head1 VERSION

version 0.11

=head1 SYNOPSIS

Need non-blocking SSH? You like Net::OpenSSH? Try out this stuff right here.

    use POE::Component::OpenSSH;

    my $ssh = POE::Component::OpenSSH->new( args => [ $host, user => $user ] );
    $ssh->system( { event => 'read_system_output' }, 'w' );

Perhaps you want it with debugging and verbose of POE::Component::Generic

    my $ssh = POE::Component::OpenSSH->new(
        args    => [ 'root@host', passwd => $pass ],
        verbose => 1, # turns on POE::Component::Generic verbose
        debug   => 1, # turns on POE::Component::Generic debug
    );

What about setting timeout for Net::OpenSSH?

    my $ssh = POE::Component::OpenSSH->new(
        args => [ 'root@host', passwd => $pass, timeout => 10 ],
    );

=head1 DESCRIPTION

This module allows you to use SSH (via L<Net::OpenSSH>) in a non-blocking manner.

The only differences is that in the I<new()> method, you need to indicate
OpenSSH args in I<args>, and the first arg to a method should be a hashref that
includes an I<event> to reach with the result.

I kept having to write this small thing each time I needed non-blocking SSH in a
project. I got tired of it so I wrote this instead.

You might ask 'why put the args in an "args" attribute instead of straight away
attributes?' Because Net::OpenSSH has a lot of options and they may collide
with POE::Component::Generic's options and I don't feel like maintaining the
mess. It's on Github so you can patch it up if you want (I accept patches...
and foodstamps).

Here is a more elaborate example using L<MooseX::POE>:

(If you know L<POE::Session>, you can use that too)

    package Runner;
    use MooseX::POE;

    has 'host' => ( is => 'ro', isa => 'Str', default => 'localhost' );
    has 'user' => ( is => 'ro', isa => 'Str', default => 'root'      );
    has 'pass' => ( is => 'ro', isa => 'Str', default => 'pass'      );
    has 'cmd'  => ( is => 'ro', isa => 'Str', default => 'w'         );

    sub START {
        my $self = $_[OBJECT];
        my $ssh  = POE::Component::OpenSSH->new(
            args => [
                $self->host,
                user   => $self->user,
                passwd => $self->passwd,
            ],
        );

        $ssh->capture( { event => 'parse_cmd' }, $cmd );
    }

    event 'parse_cmd' => sub {
        my ( $self, $output ) @_[ OBJECT, ARG1 ];
        my $host = $self->host;
        print "[$host]: $output";
    };

    package main;

    use POE::Kernel;

    my @machines = ( qw( server1 server2 server3 ) );

    foreach my $machine (@machines) {
        Runner->new(
            host => $machine,
            pass => 'my_super_pass',
            cmd  => 'uname -a',
        );
    }

    POE::Kernel->run();

=head1 METHODS

=head2 new

Creates a new POE::Component::OpenSSH object. If you want to access the
Net::OpenSSH check I<object> below.

This module (still?) doesn't have a I<spawn> method, so you're still required
to put it in a L<POE::Session>. The examples use L<MooseX::POE> which does the
same thing.

=over 4

=item args

The arguments that will go to L<Net::OpenSSH>.

=item options

The options that will go to L<POE::Component::Generic>'s I<options> argument,
stuff like C< { trace => 1 } >.

=item error

Event when L<POE::Component::Generic> has an error. Either a hashref with
I<session> and I<event> or a string with the event in the current session.

=item alias

A session alias to register with the kernel. Default is none.

=item debug

Shows component debugging information.

=item verbose

Some stuff about what is happening to L<Net::OpenSSH>. Very useful for
debugging the L<Net::OpenSSH> object.

=back

=head2 object

This method access the actual Net::OpenSSH object. It is wrapped with
L<POE::Component::Generic>, so the first argument is actually a hashref that
POE::Component::Generic requires. Specifically, noting which event will handle
the return of the Net::OpenSSH method.

You can reach B<every> method is L<Net::OpenSSH> this way. However, some
methods are already delegated to make your life easier. If what you need isn't
delegated, you can reach it directing using the object.

For example, these two methods are equivalent:

    $ssh->object->capture( { event => 'handle_capture' }, 'echo yo yo' );

    $ssh->capture( { event => 'handle_capture' }, 'echo yo yo' );

    # shell_quote isn't delegated
    $ssh->object->shell_quote(@args);

=head2 args

These are the arguments that will go to L<Net::OpenSSH> creation. This is an
arrayref.

For example:

    # using user@host
    my $ssh = POE::Component::OpenSSH->new( args => [ 'root@remote_host' ] );

    # using separate arguments
    my $ssh = POE::Component::OpenSSH->new( args => [ 'remote_host, user => 'root' ] );

    # same thing, just with pass, and writing it nicer
    my $ssh = POE::Component::OpenSSH->new(
        args => [
            'remote_host',
            user   => 'root',
            passwd => $pass,
        ],
    );

=head2 capture

This is a delegated method to L<Net::OpenSSH>'s capture.

=head2 capture2

This is a delegated method to L<Net::OpenSSH>'s I<capture2>.

=head2 system

This is a delegated method to L<Net::OpenSSH>'s I<system>.

=head2 scp_get

This is a delegated method to L<Net::OpenSSH>'s I<scp_get>.

=head2 scp_put

This is a delegated method to L<Net::OpenSSH>'s I<scp_put>.

=head2 sftp

This is a delegated method to L<Net::OpenSSH>'s I<sftp>.

=head1 AUTHOR

Sawyer X, C<< <xsawyerx at cpan.org> >>

=head1 BUGS

There is one known issue I've personally stumbled across which I've yet to
figure out and resolve. Using L<MooseX::POE>, running C<capture>s from the
C<START> event works, but running from another event doesn't. The connection
fails and hangs. In order to fix it, I use a clearance on the attribute before
running the second C<capture>, so now it works, but I've yet to understand why
that happens.

The Github's issue tracker is available at
L<http://github.com/xsawyerx/poe-component-openssh/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Component::OpenSSH

You can also look for information at:

=over 4

=item * Github issue tracker

L<http://github.com/xsawyerx/poe-component-openssh/issues>

=item * Github page

L<http://github.com/xsawyerx/poe-component-openssh/tree/master>

=back

=head1 SEE ALSO

If you have no idea what I'm doing (but you generally know what POE is), check
these stuff:

L<POE::Component::Generic>

L<Net::OpenSSH>

If you don't know POE at all, check L<POE>.

=head1 DEPENDENCIES

L<Net::OpenSSH>

L<POE>

L<POE::Component::Generic>

=head1 ACKNOWLEDGEMENTS

All the people involved in the aforementioned projects and the Perl community.

=head1 AUTHOR

Sawyer X <xsawyerx@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Sawyer X.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
