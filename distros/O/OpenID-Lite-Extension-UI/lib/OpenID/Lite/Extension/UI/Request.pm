package OpenID::Lite::Extension::UI::Request;

use Any::Moose;
extends 'OpenID::Lite::Extension::Request';

use OpenID::Lite::Extension::UI qw(
    UI_NS
    UI_POPUP_NS
    UI_LANG_NS
    UI_NS_ALIAS
);

has 'lang' => (
    is      => 'rw',
    isa     => 'Str',
#    default => q{en-US}
);

has 'mode' => (
    is      => 'rw',
    isa     => 'Str',
#    default => q{popup},
);

# RP should create popup to be 450 pixels wide and 500 pixels tall.
# The popup must have the address bar displayed.
# The popup must be in a standalone browser window.
# The contents of the popup must not be framed by the RP.
override 'append_to_params' => sub {
    my ( $self, $params ) = @_;
    $params->register_extension_namespace( UI_NS_ALIAS, UI_NS );
    $params->set_extension( UI_NS_ALIAS, 'lang', $self->lang );
    $params->set_extension( UI_NS_ALIAS, 'mode', $self->mode );
};

sub from_provider_response {
    my ( $class, $res ) = @_;
    my $message = $res->req_params->copy();
    my $ns_url  = UI_NS;
    my $alias   = $message->get_ns_alias($ns_url);
    return unless $alias;
    my $data = $message->get_extension_args($alias) || {};
    my $obj = $class->new();
    my $result = $obj->parse_extension_args($data);
    return $result ? $obj : undef;
}

sub parse_extension_args {
    my ( $self, $args ) = @_;
    $self->lang( $args->{lang} ) if $args->{lang};
    $self->mode( $args->{mode} ) if $args->{mode};
    return 1;
}

no Any::Moose;
__PACKAGE__->meta->make_immutable;
1;
