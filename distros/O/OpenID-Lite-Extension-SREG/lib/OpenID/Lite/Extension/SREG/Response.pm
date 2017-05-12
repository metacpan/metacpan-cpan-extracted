package OpenID::Lite::Extension::SREG::Response;

use Any::Moose;
use List::MoreUtils qw(any none);

extends 'OpenID::Lite::Extension::Response';

use OpenID::Lite::Extension::SREG qw(SREG_NS_1_0 SREG_NS_1_1 SREG_NS_ALIAS);

has 'data' => (
    is       => 'rw',
    isa      => 'HashRef',
    required => 1,
);

has 'ns_url' => (
    is      => 'rw',
    isa     => 'Str',
    default => sub {SREG_NS_1_1},
);

has 'ns_alias' => (
    is      => 'rw',
    isa     => 'Str',
    default => sub {SREG_NS_ALIAS},
);

sub extract_response {
    my ( $class, $req, $data ) = @_;
    my $fields   = $req->all_requested_fields();
    my $rejected = {};
    for my $key ( keys %$data ) {
        next unless ( any { $_ eq $key } @$fields );
        $rejected->{$key} = $data->{$key};
    }
    return $class->new(
        data   => $rejected,
        ns_url => $req->ns_url
    );
}

sub from_success_response {
    my ( $class, $res ) = @_;
    my $message = $res->params->copy();
    my $ns_url  = SREG_NS_1_1;
    my $alias   = $message->get_ns_alias($ns_url);
    unless ($alias) {
        $ns_url = SREG_NS_1_0;
        $alias  = $message->get_ns_alias($ns_url);
    }
    return unless $alias;
    my $data = $message->get_extension_args($alias) || {};
    return $class->new(
        data   => $data,
        ns_url => $ns_url
    );
}

override 'append_to_params' => sub {
    my ( $self, $params ) = @_;
    $params->register_extension_namespace( $self->ns_alias, $self->ns_url );
    for my $key ( keys %{ $self->data } ) {
        $params->set_extension(
            $self->ns_alias,
            $key,
            $self->data->{$key},
        );
    }
};

no Any::Moose;
__PACKAGE__->meta->make_immutable;
1;

