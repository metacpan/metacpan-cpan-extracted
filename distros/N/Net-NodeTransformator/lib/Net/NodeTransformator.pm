use strict;
use warnings;

package Net::NodeTransformator;

# ABSTRACT: interface to node transformator

use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Socket;
use AnyEvent::Proc 0.101;
use Try::Tiny;
use Env::Path;
use File::Temp qw(tempdir);
use POSIX qw(getcwd);
use CBOR::XS ();
use Carp;

our $VERSION = '0.105';    # VERSION

sub new {
    my ( $class, $hostport ) = @_;
    if ( $hostport !~ m{:} ) {
        if ( $hostport =~ m{^\d+$} ) {
            $hostport = "localhost:$hostport";
        }
        else {
            $hostport = "unix/:$hostport";
        }
    }
    my ( $host, $port ) = parse_hostport($hostport);
    if ( $host eq 'unix/' and $port !~ m{^/} ) {
        $port = getcwd . '/' . $port;
    }
    bless {
        host => $host,
        port => $port,
      } => ref $class
      || $class;
}

sub standalone {
    my $class = shift;

    my %options;
    if ( @_ > 1 and !( @_ % 2 ) ) {
        %options = @_;
    }
    elsif ( @_ == 1 ) {
        $options{connect} = shift;
    }
    elsif (@_) {
        croak "wrong paramater given for $class->standalone";
    }

    $options{bin} ||= 'transformator';
    my $path =
        $options{bin} =~ m{/}
      ? $options{bin}
      : ( Env::Path->PATH->Whence( $options{bin} ) )[0];

    unless ($path) {
        croak "binary " . $options{bin} . " not found";
    }

    unless ( $options{connect} ) {
        my $tmpdir = tempdir( CLEANUP => 1 );
        $options{connect} = "$tmpdir/~sock";
    }

    my $errstr = '';

    my $cv = $options{cv} // AE::cv;

    my $server = AnyEvent::Proc->new(
        bin         => $path,
        args        => [ $options{connect} ],
        rtimeout    => 10,
        errstr      => \$errstr,
        on_rtimeout => sub {
            shift->fire_and_kill(
                10,
                sub {
                    $cv->croak( 'timeout (' . $errstr . ')' );
                }
            );
        },
    );

    $server->readlines_cb(
        sub {
            if ( shift =~ m{server bound} ) {
                $server->stop_rtimeout;
                my $client = $class->new( $options{connect} );
                $client->{_server} = $server;
                $cv->send($client);
            }
        }
    );

    if ( $options{cb} or $options{cv} ) {
        $cv->cb( $options{cb} ) if $options{cb};
        return $cv;
    }
    else {
        return $cv->recv;
    }
}

sub cleanup {
    my ($self) = @_;
    if ( exists $self->{_server} ) {
        my $server = delete $self->{_server};
        $server->fire_and_kill(10);
    }
    else {
        AE::log note =>
          "$self->cleanup called when no standalone server active";
    }

}

sub transform_cv {
    my ( $self, %options ) = @_;

    if ( $options{on_error} ) {
        confess
"on_error option is deprecated. the returned condvar will now croak on receive if there is an error.";
    }

    my $cv = $options{cv} || AE::cv;

    my $host = $self->{host};
    my $port = $self->{port};

    tcp_connect(
        $host, $port,
        sub {
            return $cv->croak("Connect to $host:$port failed: $!") unless @_;
            my ($fh) = @_;
            my $AEH;
            $AEH = AnyEvent::Handle->new(
                fh       => $fh,
                on_error => sub {
                    my ( $handle, $fatal, $message ) = @_;
                    $handle->destroy;
                    $cv->croak("Socket error: $message");
                },
                on_eof => sub {
                    $AEH->destroy;
                },
            );
            $AEH->push_read(
                cbor => sub {
                    my $answer = $_[1];
                    if ( defined $answer and ref $answer eq 'HASH' ) {
                        if ( exists $answer->{error} ) {
                            $cv->croak( "Service error: " . $answer->{error} );
                        }
                        elsif ( exists $answer->{result} ) {
                            $cv->send( $answer->{result} );
                        }
                        else {
                            $cv->croak(
                                "Something is wrong: no result and no error");
                        }
                    }
                    else {
                        $cv->croak("No answer");
                    }
                }
            );
            $AEH->push_write( cbor =>
                  [ $options{engine}, $options{input}, $options{data} || {} ] );
            $AEH->push_shutdown;
        }
    );

    $cv->cb( $options{cb} ) if $options{cb};

    $cv;
}

sub transform {
    my ( $self, $engine, $input, $data ) = @_;
    $self->transform_cv(
        engine => $engine,
        input  => $input,
        data   => $data,
    )->recv;
}

sub jade { shift->transform( jade => @_ ) }

sub coffeescript { shift->transform( coffeescript => @_ ) }

sub minify_html { shift->transform( minify_html => @_ ) }

sub minify_css { shift->transform( minify_css => @_ ) }

sub minify_js { shift->transform( minify_js => @_ ) }

1;

__END__

=pod

=head1 NAME

Net::NodeTransformator - interface to node transformator

=head1 VERSION

version 0.105

=head1 SYNOPSIS

	use Net::NodeTransformator;
	
	my $nnt = Net::NodeTransformator->new;
	
	my $jade_in = <<'EOT';
	span
	  | Hi #{name}!
	EOT
	
	my $jade_vars = {
		name => 'Peter'
	};
	
	my $jade_out = $nnt->jade($jade_in, $jade_vars);

=head1 DESCRIPTION

This module is an interface to the transformator package of nodejs. See L<https://www.npmjs.org/package/transformator> for more information about the server.

When it's difficult for perl to interact with various nodejs packages, the transformator protocol allows everyone to interact with an nodejs service. transformator supports a vast range of libraries like jade-lang, sass-lang or coffeescript.

The other way is to invoke each command-line tool as a child process, but this may be very inefficient if such tool need to be called frequently.

=head1 METHODS

=head2 new($hostport)

Set the hostname/port or unix domain socket for connecting to transformator.

	Net::NodeTransformator->new('12345');
	Net::NodeTransformator->new('localhost:12345');
	Net::NodeTransformator->new('path/to/unix/domain/socket');	

=head2 standalone([$connect|%options])

Starts a I<transformator> standalone server. If C<$connect> or C<$options{connect}> is omitted, a temporary directory will be created and a unix domain socket will be placed in it.

Returns a ready-to-use L<Net::NodeTransformator> instance.

	my $nnt = Net::NodeTransformator->standalone; # croaks on error

Use C<$options{bin}> to either name the binary that could be found in I<$PATH> or name a direct path to the binary. Defaults to I<transformator>.

Use C<$options{cb}> to set a callback handler, to avoid blocking.

	Net::NodeTransformator->standalone(cb => sub {
		my $nnt = shift->recv; # croaks on error
	});

Alternativly, use C<$options{cv}> to use the condvar directly

	my $cv = Net::NodeTransformator->standalone(cv => 1);
	my $nnt = $cv->recv; # croaks on error

In both cases, a condvar is returned. An own condvar can also be used:

	my $cv = AE::cv;
	Net::NodeTransformator->standalone(cv => $cv);
	$cv->recv; # croaks on error

=head2 cleanup

Stopps a previously started standalone server.

=head2 transform_cv(%options)

Connects to transformator and waits for the result asynchronously by using a condition variable.

%options requires for keyworks:

=over 4

=item C<engine> The engine to be used

=item C<input> The input string

=item C<data> (optional) Additional data to be send with. Currently only meaningful for I<jade> engine.

=item C<cv> (optional) An own AnyEvent::CondVar

=item C<cb> (optional) A callback handler

	$nnt->transform_cv(..., cb => sub {
		my $result = shift->recv; # croaks on error
	});

=back

This method returns a condition variable (L<AnyEvent>::CondVar)

	my $cv = $nnt->transform_cv(...);

The result will be pushed to the condvar, so C<< $cv->recv >> will return the result or croaks on error.

=head2 transform($engine, $input, $data)

This is the synchronous variant of C<transform_cv>. It croaks on error and can be catched by L<Try::Tiny> for example.

=head1 SHORTCUT METHODS

This list is incomplete. I will add more methods on request. All methods are hopefully self-describing.

=head2 jade($input, $data)

=head2 coffeescript($input)

=head2 minify_html($input)

=head2 minify_css($input)

=head2 minify_js($input)

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/zurborg/libnet-nodetransformator-perl/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

David Zurborg <zurborg@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by David Zurborg.

This is free software, licensed under:

  The ISC License

=cut
