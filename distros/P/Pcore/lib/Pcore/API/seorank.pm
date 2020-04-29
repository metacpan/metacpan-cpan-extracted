package Pcore::API::seorank;

use Pcore -class, -res;

has api_key => ( required => 1 );

has max_threads => 10;

has _semaphore => sub ($self) { Coro::Semaphore->new( $self->{max_threads} ) }, is => 'lazy';

sub get_moz ( $self, $domain ) {
    my $guard = $self->{max_threads} && $self->_semaphore->guard;

    my $res = P->http->get(qq[https://seo-rank.my-addr.com/api2/moz/$self->{api_key}/$domain]);

    return $res if !$res;

    my $data = P->data->from_json( $res->{data} );

    return res 200, $data;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::seorank

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
