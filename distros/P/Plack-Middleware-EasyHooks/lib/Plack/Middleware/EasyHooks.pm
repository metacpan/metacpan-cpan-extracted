package Plack::Middleware::EasyHooks;

use 5.006;
use strict;
use warnings;

use parent qw(Plack::Middleware);

our $VERSION = '0.02';

sub before {
    my ($self, $env) = @_;

    $self->{before}->($env) if defined $self->{before};
}

sub after {
    my ($self, $env, $res) = @_;

    $self->{after}->($env, $res) if defined $self->{after};
}

sub filter {
    my ($self, $env, $chunk) = @_;

    $chunk = $self->{filter}->($env, $chunk) if defined $self->{filter};

    return $chunk;
}

sub tail {
    my ($self, $env) = @_;

    $self->{tail}->($env) if defined $self->{tail};
}

sub finalize {
    my ($self, $env) = @_;

    $self->{finalize}->($env) if defined $self->{finalize};
}

sub call {
    my ($self, $env) = @_;

    $self->before($env);
    my $res = $self->app->($env);

    if ( $env->{"psgix.cleanup"} ) {
        push @{ $env->{"psgix.cleanup.handlers"} }, sub { $self->finalize($_[0]) };
    }

    if ( ref $res eq "ARRAY" ) {
        return $self->handle_full_response($env, $res);
    }

    if ( ref $res eq "CODE" ) {
        return $self->handle_delayed_response($env, $res);
    }

    # Unknown response type...
    return $res;
}

sub handle_full_response {
    my ($self, $env, $res) = @_;

    my $override = $self->after($env, $res);
    if (defined($override) && ref $override eq "ARRAY") {
        $res->[0] = $override->[0];
        $res->[1] = $override->[1];
        $res->[2] = $override->[2];
    }

    my ($status, $header, $body) = @$res;

    if (ref $body eq "ARRAY") {
        my $tail;
        $body  = [
            (map { $self->filter($env, $_) } @$body), 
            (defined($tail = $self->tail($env)) ? $tail : ())
        ];

        $self->finalize($env) unless $env->{'psgix.cleanup'};
        return [ $status, $header, $body ];
    }

    my $done;
    my $wrapped = Plack::Util::inline_object(
        getline => sub {
            return if $done;

            my $chunk = $body->getline();

            if (defined $chunk) {
                return $self->filter($env, $chunk);
            }

            $done = 1;
            return $self->tail($env);
        },
        close => sub {
            $body->close;

            $self->finalize($env) unless $env->{"psgix.cleanup"};
        },
    );

    return [ $status, $header, $wrapped ];
}

sub handle_delayed_response {
    my ($self, $env, $res) = @_;

    return sub {
        my $responder = shift;

        $res->(
            sub {
                my ($res) = @_;

                if (exists( $res->[2] )) {
                    return $responder->( $self->handle_full_response($env, $res) );
                }

                my $override = $self->after($env, $res);
                if (defined($override) && ref $override eq "ARRAY") {
                    $res->[0] = $override->[0];
                    $res->[1] = $override->[1];
                    $res->[2] = $override->[2] if exists $override->[2];
                }

                my $writer = $responder->( $res );

                return Plack::Util::inline_object(
                    write => sub {
                        $writer->write( $self->filter($env, @_) );
                    },
                    close => sub {
                        my $tail = $self->tail();
                        $writer->write($tail) if defined($tail);

                        $self->finalize($env) unless $env->{'psgix.cleanup'};
                        $writer->close;
                    },
                );
            }
        );
    };
}


1;

__END__

=head1 NAME

Plack::Middleware::EasyHooks - Writing PSGI Middleware using simple hooks

=head1 SYNOPSIS

  package Plack::Middleware::MyAccessLog;

  use parent qw(Plack::Middleware::EasyHooks);
 
  sub before {
      my ($self, $env) = @_;

      $env->{MyAccessLog} = {
          start_time    => time(),
          response_size => 0,
      };
  }

  sub filter {
      my ($self, $env, $chunk) = @_;

      $env->{MyAccessLog]->{response_size} += length $chunk;

      return $chunk;
  }

  sub finalize {
      my ($self, $env) = shift;

      my $time = time() - $env->{MyAccessLog}->{start_time};
      my $size = $env->{MyAccessLog}->{response_size};

      warn "Request took $time seconds and sent $size bytes";
  }

  1;

Or as an inline middleware

  use Plack::Builder;

  my $app = ...; 

  builder {
      enable 'Plack::Middleware::EasyHooks', 
          before    => sub { $_[0]->{start_time} = time(); },
          finalize  => sub {
              my $time = time() - $_[0]->{start};
              warn "Request took $time seconds";
          };

      $app;
  }

=head1 DESCRIPTION

Plack::Middleware::EasyHooks takes care of the complexities handling streaming
in PSGI middleware. Just provide hooks to be called before, during and after
the wrapped PSGI application.

The hooks are called in the following order (much simplified):

    before();
    $app->();
    after();
    
    filter($_) for @body;
    tail($env);
    
    finalize();


=head1 SUPPORTED HOOKS

The following methods are available for hooking into the request handling

=over 4

=item before( $env )

This method is called before processing the wrapped PSGI application.
It receives the PSGI C<$env> hash ref as argument.

The return value is ignored.

=item after( $env, $res )

This method is called when the app starts to respond. It receives the PSGI
C<$env> and a array ref containing the status code and headers as arguments.

The middleware can override the status code and headers either by updating
the elements of this array ref or by returning a array ref with the new status
code and headers.

=item filter ( $env, $chunk )

This method allows you to filter the content of the response. It is called
on each chunk of the response.

The return value is passed to the next level. If the return value is C<undef>
proccessing of the request is stopped.

=item tail( $env );

This methods allows you to add some additional content at the end of the body.

=item finalize( $env )

This method is called after the request has been processed.

=back

=head1 BUGS

Unless your PSGI server supports cleanup handles, the finalize() method
might be calles before the final chunk is successfully sent to the client.

=head1 AUTHOR

Peter Makholm E<lt>peter@makholm.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Peter Makholm.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=cut


