package Net::Riak::Role::PBC::Meta;
{
  $Net::Riak::Role::PBC::Meta::VERSION = '0.1702';
}

use Moose::Role;

sub _populate_metas {
    my ($self, $object, $metas) = @_;

    for my $meta (@$metas) {
        $object->set_meta( $meta->key, $meta->value );
    }
}

sub _metas_for_message {
    my ($self, $object) = @_;

    my @out;
    while ( my ( $k, $v ) = each %{ $object->metadata } ) {
        push @out, { key => $k, value => $v };
    }
    return \@out;

}

1;

__END__

=pod

=head1 NAME

Net::Riak::Role::PBC::Meta

=head1 VERSION

version 0.1702

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>, robin edwards <robin.ge@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
