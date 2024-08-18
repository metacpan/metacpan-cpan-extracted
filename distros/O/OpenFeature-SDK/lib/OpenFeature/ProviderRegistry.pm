use v5.36;

package OpenFeature::ProviderRegistry;

=head1 NAME

OpenFeature::ProviderRegistry - Provider registry for OpenFeature

=cut

my $providers = {};

sub new($class) {
    my $self = {};
    $self->{'providers'} = {};
    bless $self, $class
}

sub get_provider($self, $domain) {
    $self->{'providers'}{$domain}
}

sub get_default_provider($self) {
    $self->{'providers'}{'default'}
}

sub set_default_provider($self, $provider) {
    $self->{'providers'}{'default'} = $provider
}

sub set_provider($self, $domain, $provider) {
    $self->{'providers'}{$domain} = $provider
}

sub clear_providers($self) {
    $self->{'providers'} = {}
}

sub shutdown_all_providers($self) {
    foreach my $domain ( keys %{ $self->{'providers'} }) {
            $self->{'providers'}{$domain}->shutdown();
    }
}

1;
__END__

=head2 Things left to implement

=over

=item *

_get_evaluation_context (really... is used in _initialise_provider, maybe we can just make that more explicit)

=item *

_initialise_provider

=item *

get_provider_status

=item *

dispatch_event

=item *

_update_provider_status

=item *

event support in general it seems

=back
