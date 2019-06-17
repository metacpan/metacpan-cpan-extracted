package Pcore::API::Facebook::User;

use Pcore -role, -const;
use Pcore::Util::Scalar qw[is_plain_coderef];

const our $API_VER => 3.3;

sub me ( $self, @args ) {
    my $cb = is_plain_coderef $args[-1] ? pop @args : undef;

    my %args = @args;

    return $self->_req( 'GET', 'me', \%args, undef, $cb );
}

sub debug_token ( $self, @args ) {
    my $cb = is_plain_coderef $args[-1] ? pop @args : undef;

    my %args = @args;

    return $self->_req( 'GET', "v$API_VER/debug_token", { input_token => $self->{token} }, undef, $cb );
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::Facebook::User

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
