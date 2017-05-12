package Net::OATH::Server::Lite::Model::User;
use strict;
use warnings;

use parent 'Class::Accessor::Fast';
use Params::Validate qw(SCALAR);

__PACKAGE__->mk_accessors(qw(
    id
    type
    secret
    algorithm
    digits
    counter
    period
));

sub new {
    my $class = shift;
    my @args = @_ == 1 ? %{$_[0]} : @_;
    my %params = Params::Validate::validate_with(
        params => \@args, 
        spec => {
            id => {
                type     => SCALAR,
            },
            type => {
                type     => SCALAR,
                default  => q{totp},
                optional => 1,
            },
            secret => {
                type     => SCALAR,
            },
            algorithm => {
                type     => SCALAR,
                default  => q{SHA1},
                optional => 1,
            },
            digits => {
                type     => SCALAR,
                default  => 6,
                optional => 1,
            },
            counter => {
                type     => SCALAR,
                default  => 0,
                optional => 1,
            },
            period => {
                type     => SCALAR,
                default  => 30,
                optional => 1,
            },
        },
        allow_extra => 0,
    );

    my $self = bless \%params, $class;
 
    return $self;
}

sub is_valid {
    my $self = shift;

    return unless ($self->type eq q{totp} || $self->type eq q{hotp});

    # TODO: Support SHA256, SHA512
    return unless ($self->algorithm eq q{SHA1} || $self->algorithm eq q{MD5});

    # TODO: Validation other params

    return 1;
}

1;
