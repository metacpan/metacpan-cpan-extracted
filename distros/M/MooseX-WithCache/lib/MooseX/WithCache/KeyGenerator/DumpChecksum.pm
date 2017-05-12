# $Id: DumpChecksum.pm 21415 2008-10-16 07:50:55Z daisuke $

package MooseX::WithCache::KeyGenerator::DumpChecksum;
use Moose;
use Data::Dumper ();
use Digest::MD5 ();

with 'MooseX::WithCache::KeyGenerator';

__PACKAGE__->meta->make_immutable;

no Moose;

sub generate {
    my ($self, $key) = @_;

    local $Digest::MD5::Indent   = 0;
    local $Digest::MD5::Terse    = 1;
    local $Digest::MD5::Sortkeys = 1;
    return Digest::MD5::md5_hex( Data::Dumper::Dumper($key) );
}

1;

__END__

=head1 NAME

MooseX::WithCache::KeyGenerator::DumpChecksum - Generate MD5 Checksum Key From Complex Structure

=head1 METHODS

=head2 generate

=cut