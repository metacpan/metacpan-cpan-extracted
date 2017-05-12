package MojoX::Plugin::AnyCache::Backend;

use strict;
use warnings;
use Mojo::Base '-base';

has 'config';
has 'support_sync' => sub { 0 };
has 'support_async' => sub { 0 };
has 'serialiser';

sub get_serialiser {
    my ($self) = @_;
    if(!$self->serialiser && (my $s = $self->config->{serialiser})) {
        eval {
            eval "require $s;";
            warn("Require failed: $@") if $self->config->{debug} && $@;
            my $serialiser = $self->config->{serialiser}->new;
            $serialiser->config($self->config);
            $self->serialiser($serialiser);
        };
        die("Failed to load serialiser $s: $@") if $@;
    }
    return $self->serialiser;
}

sub get { die("Must be overridden in backend module") };
sub set { die("Must be overridden in backend module") };
sub incr { die("Must be overridden in backend module") };
sub decr { die("Must be overridden in backend module") };
sub del { die("Must be overridden in backend module") };

1;
