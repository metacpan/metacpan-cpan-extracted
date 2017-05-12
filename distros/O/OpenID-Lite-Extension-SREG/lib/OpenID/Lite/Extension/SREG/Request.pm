package OpenID::Lite::Extension::SREG::Request;

use Any::Moose;
use List::MoreUtils qw(any none);
use Carp ();

extends 'OpenID::Lite::Extension::Request';
with 'OpenID::Lite::Role::ErrorHandler';

use OpenID::Lite::Extension::SREG qw(SREG_NS_1_0 SREG_NS_1_1 SREG_NS_ALIAS);

has '_required' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [] },
);

has '_optional' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [] },
);

has 'policy_url' => (
    is  => 'rw',
    isa => 'Str',
);

has 'ns_url' => (
    is      => 'rw',
    isa     => 'Str',
    default => sub {SREG_NS_1_1},
);

my @SREG_FIELDS = qw(
    fullname
    nickname
    dob
    email
    gender
    postcode
    country
    language
    timezone
);

override 'append_to_params' => sub {
    my ( $self, $params ) = @_;
    $params->register_extension_namespace( SREG_NS_ALIAS, $self->ns_url );

    my $required = $self->_required;
    $params->set_extension( SREG_NS_ALIAS, 'required',
        join( ',', @$required ) )
        if @$required > 0;
    my $optional = $self->_optional;
    $params->set_extension( SREG_NS_ALIAS, 'optional',
        join( ',', @$optional ) )
        if @$optional > 0;
    $params->set_extension( SREG_NS_ALIAS, 'policy_url', $self->policy_url )
        if $self->policy_url;
};

sub check_field_name {
    my ( $self, $field_name ) = @_;
    return ( $field_name && ( any { $_ eq $field_name } @SREG_FIELDS ) );
}

sub request_field {
    my ( $self, $field_name, $required ) = @_;
    $self->check_field_name($field_name)
        or return $self->ERROR( sprintf q{Invalid field-name for SREG, "%s"},
        $field_name );
    my $required_fields = $self->_required;
    my $optional_fields = $self->_optional;
    return if ( any { $_ eq $field_name } @$required_fields );
    if ( any { $_ eq $field_name } @$optional_fields ) {
        return unless $required;
        my @new_optional = grep { $_ ne $field_name } @$optional_fields;
        $optional_fields = \@new_optional;
        $self->_optional($optional_fields);
    }
    if ($required) {
        push( @$required_fields, $field_name );
    }
    else {
        push( @$optional_fields, $field_name );
    }
}

sub from_provider_response {
    my ( $class, $res ) = @_;
    my $message = $res->req_params->copy();
    my $ns_url  = SREG_NS_1_1;
    my $alias   = $message->get_ns_alias($ns_url);
    unless ($alias) {
        $ns_url = SREG_NS_1_0;
        $alias  = $message->get_ns_alias($ns_url);
    }
    return unless $alias;
    my $data = $message->get_extension_args($alias) || {};
    my $obj = $class->new( ns_url => $ns_url );
    my $result = $obj->parse_extension_args($data);
    return $result ? $obj : undef;
}

sub parse_extension_args {
    my ( $self, $args, $strict ) = @_;
    if ( $args->{required} ) {
        my @f = split( /,/, $args->{required} );
        for my $f (@f) {
            my $result = $self->request_field( $f, 1 );
            return if ( $strict && !$result );
        }
    }
    if ( $args->{optional} ) {
        my @f = split( /,/, $args->{optional} );
        for my $f (@f) {
            my $result = $self->request_field( $f, 0 );
            return if ( $strict && !$result );
        }
    }
    $self->policy_url( $args->{policy_url} ) if $args->{polici_url};
    return 1;
}

sub all_requested_fields {
    my $self = shift;
    my @fields = ( @{ $self->_required }, @{ $self->_optional } );
    return \@fields;
}

no Any::Moose;
__PACKAGE__->meta->make_immutable;
1;

