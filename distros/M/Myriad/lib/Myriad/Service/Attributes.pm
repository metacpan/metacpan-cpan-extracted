package Myriad::Service::Attributes;

use strict;
use warnings;

our $VERSION = '0.004'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

use utf8;

=encoding utf8

=head1 NAME

Myriad::Service::Attributes - microservice coördination

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

=head1 Attributes

Each of these is an attribute that can be applied to a method.

Note that this class is just a simple passthrough to L<Myriad::Registry>,
which does all the real work.

=cut

use Myriad::Registry;

use Log::Any qw($log);
use Exporter qw(import export_to_level);

use Sub::Util ();

our %KNOWN_ATTRIBUTES = (
    RPC      => 'rpc',
    Batch    => 'batch',
    Emitter  => 'emitter',
    Receiver => 'receiver',
);

=head2 MODIFY_CODE_ATTRIBUTES

Due to L<Attribute::Handlers> limitations at runtime, we need to pick
up attributes ourselves.

=cut

sub apply_attributes {
    my ($class, %args) = @_;
    my $pkg = $args{class};
    my ($method) = Sub::Util::subname($args{code}) =~ /::([^:]+)$/;
    for my $attr ($args{attributes}->@*) {
        my ($type, $args) = $attr =~ m{^([a-z]+)(.*$)}si;
        # Nasty, but functional for now - this will likely be replaced by
        # an m//gc parser later with a restricted set of options.
        $args = eval "+{ $args }" // die 'invalid attribute parameters: ' . $@ if length $args;

        $log->tracef('Attribute %s (%s) applying to %s', $type, $args, $pkg);
        my $handler = $KNOWN_ATTRIBUTES{$type}
            or die 'unknown attribute ' . $type;
        $class->$handler(
            $pkg,
            $method,
            $args{code},
            $args
        );
    }
    return;
}

=head2 RPC

Mark this async method as a callable RPC method.

 async method example_rpc : RPC (%args) {
  return \%args;
 }

This will cause the method to be registered in L<Myriad::Registry/add_rpc>.

=cut

sub rpc {
    my ($class, $pkg, $method, $code, $args) = @_;
    $Myriad::REGISTRY->add_rpc(
        $pkg,
        $method,
        $code,
        $args
    );
}

=head2 Batch

Mark this as an async method which should be called repeatedly to generate
arrayref batches of data.

 has $id = 0;
 async method example_batch : Batch {
  return [ ++$id ];
 }

=cut

sub batch {
    my ($class, $pkg, $method, $code, $args) = @_;
    $Myriad::REGISTRY->add_batch(
        $pkg,
        $method,
        $code,
        $args,
    );
}

=head2 Emitter

Indicates a method which should be called on startup, which given a
L<Ryu::Sink> will emit events to that sink until it's done.

=cut

sub emitter {
    my ($class, $pkg, $method, $code, $args) = @_;
    $Myriad::REGISTRY->add_emitter(
        $pkg,
        $method,
        $code,
        $args,
    );
}

=head2 Receiver

Indicates a method which should be called on startup and passed a
L<Ryu::Source>. Events will be emitted to that source until termination.

=cut

sub receiver {
    my ($class, $pkg, $method, $code, $args) = @_;
    $Myriad::REGISTRY->add_receiver(
        $pkg,
        $method,
        $code,
        $args,
    );
}

1;

=head1 AUTHOR

Deriv Group Services Ltd. C<< DERIV@cpan.org >>.

See L<Myriad/CONTRIBUTORS> for full details.

=head1 LICENSE

Copyright Deriv Group Services Ltd 2020-2021. Licensed under the same terms as Perl itself.

