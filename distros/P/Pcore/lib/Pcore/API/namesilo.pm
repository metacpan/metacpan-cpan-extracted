package Pcore::API::namesilo;

use Pcore -class, -res, -const;
use Pcore::Util::Scalar qw[is_plain_arrayref];

has api_key     => ( required => 1 );
has proxy       => ();
has max_threads => 10;

has _semaphore => sub ($self) { Coro::Semaphore->new( $self->{max_threads} ) }, is => 'lazy';

# up to 200 domains
sub check_domains ( $self, $domains ) {
    my $guard = $self->{max_threads} && $self->_semaphore->guard;

    say 'run';

    my $idx = { map { $_ => 0 } is_plain_arrayref $domains ? $domains->@* : $domains };

    my $url = "https://www.namesilo.com/api/checkRegisterAvailability?version=1&type=xml&key=$self->{api_key}&domains=" . join ',', keys $idx->%*;

    my $res = P->http->get( $url, proxy => $self->{proxy} );

    retun $res if !$res;

    my $data = P->data->from_xml( $res->{data} );

    my $code = $data->{namesilo}->{reply}->[0]->{code}->[0]->{content};

    return res 400 if $code != 300;

    for my $item ( $data->{namesilo}->{reply}->[0]->{available}->[0]->{domain}->@* ) {
        $idx->{ $item->{content} } = 1;
    }

    return res 200, $idx;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::namesilo

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
