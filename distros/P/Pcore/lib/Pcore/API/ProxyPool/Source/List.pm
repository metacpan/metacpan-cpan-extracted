package Pcore::API::ProxyPool::Source::List;

use Pcore -class;

with qw[Pcore::API::ProxyPool::Source];

has proxy => ( is => 'ro', isa => ArrayRef [Str], required => 1 );

has '+load_timeout' => ( default => 0, init_arg => undef );

sub load ( $self, $cb ) {
    $cb->( $self->proxy );

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::ProxyPool::Source::List

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
