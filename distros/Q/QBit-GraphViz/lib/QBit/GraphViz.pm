package QBit::GraphViz;
$QBit::GraphViz::VERSION = '0.003';
use qbit;

use base qw(GraphViz);

sub _as_generic {
    my ($self, $type, $dot, $output) = @_;

    utf8::encode($dot);

    local $ENV{'PATH'} = 'usr/bin/' unless defined($ENV{'PATH'});

    return $self->SUPER::_as_generic($type, $dot, $output);
}

sub as_svg {
    my ($self, $type, $dot, $output) = @_;

    my $data = $self->SUPER::as_svg($type, $dot, $output);

    utf8::decode($data);

    return $data;
}

TRUE;

__END__

=encoding utf8

=head1 Name

QBit::GraphViz - QBit wrapper on Graphviz.

=head1 GitHub

https://github.com/QBitFramework/QBit-GraphViz

=head1 Install

=over

=item *

cpanm QBit::GraphViz

=item *

apt-get install libqbit-graphviz-perl (http://perlhub.ru/)

=back

For more information. please, see code.

=cut