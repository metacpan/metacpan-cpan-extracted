package Net::OATH::Server::Lite::Error;
use strict;
use warnings;

use parent 'Class::Accessor::Fast';
use Params::Validate qw(SCALAR);

=head1 NAME

Net::OATH::Server::Lite::Error - Error class of Lite Server

=head1 SYNOPSIS

    use Net::OATH::Server::Lite::Error;

    # default error
    # HTTP/1.1 400 Bad Request
    # Content-Type: application/json;charset=UTF-8
    # Cache-Control: no-store
    # Pragma: no-cache
    #
    # {
    #   "error":"invalid_request"
    # } 
    Net::OATH::Server::Lite::Error->throw() if ...

    # custom error
    # HTTP/1.1 404 Not Found
    # Content-Type: application/json;charset=UTF-8
    # Cache-Control: no-store
    # Pragma: no-cache
    #
    # {
    #   "error":"invalid_request",
    #   "error_description":"invalid id"
    # } 
    Net::OATH::Server::Lite::Error->throw(
        code => 404,
        description => q{invalid id},
    ) if ...

=cut

__PACKAGE__->mk_accessors(qw(
    code
    error
    description
));

sub new {
    my $class = shift;
    my @args = @_ == 1 ? %{$_[0]} : @_;
    my %params = Params::Validate::validate_with(
        params => \@args, 
        spec => {
            code => {
                type     => SCALAR,
                default  => 400,
                optional => 1,
            },
            error => {
                type     => SCALAR,
                default  => q{invalid_request},
                optional => 1,
            },
            description => {
                type     => SCALAR,
                default  => q{},
                optional => 1,
            },
        },
        allow_extra => 0,
    );

    my $self = bless \%params, $class;

    # TODO: more varidation
 
    return $self;
}

sub throw {
    my ($class, %args) = @_;
    die $class->new(%args);
}

1;
