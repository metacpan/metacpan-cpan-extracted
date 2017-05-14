#
# This file is part of Riak-Light
#
# This software is copyright (c) 2013 by Weborama.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
## no critic (RequireUseStrict, RequireUseWarnings)
package Riak::Light::Timeout::ByteCount;
{
    $Riak::Light::Timeout::ByteCount::VERSION = '0.052';
}
## use critic
use Moo;

has socket => ( is => 'ro', required => 1 );

has bytes_in  => ( is => 'rw', default => sub {0} );
has bytes_out => ( is => 'rw', default => sub {0} );

sub sysread {
    my $self = shift;

    my $bytes = $self->socket->sysread(@_);

    $self->bytes_in( $self->bytes_in + $bytes );

    $bytes;
}

sub syswrite {
    my $self = shift;

    my $bytes = $self->socket->syswrite(@_);

    $self->bytes_out( $self->bytes_out + $bytes );

    $bytes;
}

1;
__END__

=pod

=head1 NAME

Riak::Light::Timeout::ByteCount

=head1 VERSION

version 0.052

=head1 AUTHOR

Tiago Peczenyj <tiago.peczenyj@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Weborama.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
