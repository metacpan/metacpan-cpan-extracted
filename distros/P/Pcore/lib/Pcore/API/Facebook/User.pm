package Pcore::API::Facebook::User;

use Pcore -role, -const;

const our $API_VER => 3.3;

sub me ( $self, %args ) {
    return $self->_req( 'GET', 'me', \%args );
}

sub debug_token ( $self ) {
    return $self->_req( 'GET', "v$API_VER/debug_token", { input_token => $self->{token} } );
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
