package Net::OpenID::Extension::SimpleRegistration;
$Net::OpenID::Extension::SimpleRegistration::VERSION = '1.20';
use base qw(Net::OpenID::Extension);
use strict;
use Carp;

use constant namespace_uris => {
    'http://openid.net/extensions/sreg/1.1' => 'sreg',
};

sub new_request {
    my ($class, %opts) = @_;

    return Net::OpenID::Extension::SimpleRegistration::Request->new(%opts);
}

sub received_request {
    my ($class, $args) = @_;

    return Net::OpenID::Extension::SimpleRegistration::Request->received($args);
}

sub new_response {
    my ($class, %opts) = @_;

    return Net::OpenID::Extension::SimpleRegistration::Request->new(%opts);
}

sub received_response {
    my ($class, $args) = @_;

    return Net::OpenID::Extension::SimpleRegistration::Request->received($args);
}

package Net::OpenID::Extension::SimpleRegistration::Request;
$Net::OpenID::Extension::SimpleRegistration::Request::VERSION = '1.20';
use base qw(Net::OpenID::ExtensionMessage);
use strict;

sub new {
    my ($class, %opts) = @_;

    my $self = bless {}, $class;

    $self->required_fields(delete $opts{required_fields});
    $self->optional_fields(delete $opts{optional_fields});
    $self->policy_url(delete $opts{policy_url});

    $self->{required_fields} = [ split(',', $self->{required_fields}) ] unless ref $self->{required_fields};
    $self->{optional_fields} = [ split(',', $self->{optional_fields}) ] unless ref $self->{optional_fields};

    Carp::croak("Unsupported options: ".join(',', keys %opts)) if %opts;

    return $self;
}

sub received {
    my ($class, $args) = @_;

    my $self = $class->new();
    $args = $args->{sreg} || {};

    $self->required_fields($args->{required});
    $self->optional_fields($args->{optional});

    return $self;
}

sub extension_arguments {
    my ($self) = @_;

    my $ret = {};

    $ret->{required} = join(',', @{$self->required_fields}) if @{$self->required_fields};
    $ret->{optional} = join(',', @{$self->optional_fields}) if @{$self->optional_fields};
    $ret->{policy_url} = $self->policy_url if $self->policy_url;

    return {
        sreg => $ret,
    };
}

sub required_fields {
    my ($self, $value) = @_;

    if (defined $value) {
        $value = [] unless $value;
        $value = [ split(',', $value) ] unless ref $value;
        $self->{required_fields} = $value;
    }
    else {
        return $self->{required_fields};
    }
}

sub optional_fields {
    my ($self, $value) = @_;

    if (defined $value) {
        $value = [] unless $value;
        $value = [ split(',', $value) ] unless ref $value;
        $self->{optional_fields} = $value;
    }
    else {
        return $self->{optional_fields};
    }
}

sub add_required_field {
    my ($self, $value) = @_;

    push @{$self->{required_fields}}, $value;
}

sub add_optional_field {
    my ($self, $value) = @_;

    push @{$self->{optional_fields}}, $value;
}

sub policy_url {
    my ($self, $value) = @_;

    if (defined $value) {
        $self->{policy_url} = $value;
    }
    else {
        return $self->{optional_fields};
    }
}

package Net::OpenID::Extension::SimpleRegistration::Response;
$Net::OpenID::Extension::SimpleRegistration::Response::VERSION = '1.20';
use base qw(Net::OpenID::ExtensionMessage);
use strict;

use constant FIELDS => [qw(nickname email fullname dob gender postcode country language timezone)];
use fields FIELDS();

BEGIN {
    # Create an accessor for each of the fields
    foreach my $field_name (@{FIELDS()}) {
        no strict qw(refs);
        *{'Net::OpenID::Extension::SimpleRegistration::Response::'.$field_name} = sub {
            my ($self, $value) = @_;

            if (defined $value) {
                $self->{$field_name} = $value;
            }
            else {
                return $self->{$field_name};
            }
        };
    }
}

sub new {
    my ($class, %opts) = @_;

    my $self = fields::new($class);

    foreach my $field_name (@{FIELDS()}) {
        $self->{$field_name} = delete $opts{$field_name};
    }

    Carp::croak("Unrecognised options: ".join(',', %opts)) if %opts;

    return $self;
}

sub received {
    my ($class, $args) = @_;

    $args = $args->{sreg} || {};
    my %opts = ();

    foreach my $field_name (@{FIELDS()}) {
        $opts{$field_name} = $args->{$field_name} if $args->{$field_name};
    }

    return $class->new(%opts);
}

sub extension_arguments {
    my ($self) = @_;

    # De-reference and then re-reference the hash to shake off the blessedness
    my $ret = { %$self };

    return {
        sreg => $ret,
    };
}

=pod

=head1 NAME

Net::OpenID::Extension::SimpleRegistration - Support for the Simple Registration extension (SREG)

=head1 VERSION

version 1.20

=head1 SYNOPSIS

In Consumer...

    my $sreg_req = $claimed_identity->add_extension_request('Net::OpenID::Extension::SimpleRegistration', (
        required_fields => [qw(nickname email)],
        optional_fields => [qw(country language timezone)],
        policy_url => "http://example.com/policy.html",
    ));

Then, in Server, when handling the authentication request...

    # FIXME: What object do we have in ::Server that can hold this method?
    my $sreg_req = $something->get_extension_request('Net::OpenID::Extension::SimpleRegistration');
    my $required_fields = $sreg_req->required_fields;
    my $optional_fields = $sreg_req->optional_fields;
    my $policy_url = $sreg_req->policy_url;

When Server sends back its response...

    # FIXME: Again, what object do we have to hold this method?
    my $sreg_res = $something->add_extension_response('Net::OpenID::Extension::SimpleRegistration', (
        nickname => $nickname,
        email => $email,
    ));

And finally, when back in Consumer receiving the response:

    my $sreg_res = $verified_identity->get_extension_response('Net::OpenID::Extension::SimpleRegistration');
    my $nickname = $sreg_res->nickname;
    my $email = $sreg_res->email;
    my $country = $sreg_res->country;
    my $language = $sreg_res->language;
    my $timezone = $sreg_res->timezone;

=cut

1;
