package QxExample::JsonRpcService;
use strict;

use Mojo::Base 'Mojolicious::Plugin::Qooxdoo::JsonRpcController';
use Mojo::Promise;

=head1 NAME

JsonRpcService - RPC services for Qooxdoo

=head1 SYNOPSIS

This module gets instanciated by L<ep::MojoApp> and provides backend functionality for your qooxdoo app

=head1 DESCRIPTION

All methods on this class can get called remotely as long as their name does not start with an underscore.


=head2 allow_rpc_access

the dispatcher will call the allow_rpc_access method to determine if it may execute
the given method.

=cut

has service => sub { 'rpc' };

our %allow_access =  (
    echo => 1,
    async => 1,
    asyncException => 1,
    async_p => 1,
    asyncException_p => 1,
);

sub allow_rpc_access {
    my $self = shift;
    my $method = shift;
    return $allow_access{$method};
}

=head2 echo(var)

return the string we input

=cut  

sub echo {
    my $self = shift;
    my $arg = shift or die QxExample::Exception->new(code=>123,message=>"Argument Required!");
    return $arg;
}

=head2 async(var)

return the answer with a 1 second delay

=cut

sub async {
    my $self = shift;
    my $text = shift;
    $self->render_later;
    Mojo::IOLoop->timer('1.5' => sub {
        $self->renderJsonRpcResult("Delayed $text for 1.5 seconds!");
    });
}

sub asyncException {
    my $self = shift;
    $self->render_later;
    Mojo::IOLoop->timer('1' => sub {
         $self->renderJsonRpcError(QxExample::Exception->new(code=>334, message=>"a simple error"));
    });
}

sub async_p {
    my $self = shift;
    my $text = shift;
    my $p = Mojo::Promise->new;
    Mojo::IOLoop->timer('1.5' => sub {
        $p->resolve("Delayed $text for 1.5 seconds!");
    });
    return $p;
}

sub asyncException_p {
    my $self = shift;
    my $p = Mojo::Promise->new;
    Mojo::IOLoop->timer('1' => sub {
         $p->reject(QxExample::Exception->new(code=>334, message=>"a simple error"));
    });
    return $p;
}

package QxExample::Exception;

use Mojo::Base -base;
has 'code';
has 'message';
use overload ('""' => 'stringify');
sub stringify {
    my $self = shift;
    return "ERROR ".$self->code.": ".$self->message;
}

1;
__END__

=head1 COPYRIGHT

Public Domain

=head1 AUTHOR

S<Tobias Oetiker E<lt>tobi@oetiker.chE<gt>>

=head1 HISTORY 

 2011-01-25 to Initial

=cut
  
1;

# Emacs Configuration
#
# Local Variables:
# mode: cperl
# eval: (cperl-set-style "PerlStyle")
# mode: flyspell
# mode: flyspell-prog
# End:
#
# vi: sw=4 et
