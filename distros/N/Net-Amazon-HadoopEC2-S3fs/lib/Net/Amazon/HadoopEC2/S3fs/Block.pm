package Net::Amazon::HadoopEC2::S3fs::Block;
use Moose;
use Moose::Util::TypeConstraints;
use bigint;

subtype 'Net::Amazon::HadoopEC2::S3fs::Block::Id'
    => as 'Str';

coerce 'Net::Amazon::HadoopEC2::S3fs::Block::Id'
    => from 'ArrayRef'
    => via {
        my $arg = shift;
        return __PACKAGE__->from_unsigned_long_long(@{$arg})->bstr;
    };

subtype 'Net::Amazon::HadoopEC2::S3fs::Block::Size'
    => as 'Int';

coerce 'Net::Amazon::HadoopEC2::S3fs::Block::Size'
    => from 'ArrayRef'
    => via {
        my $arg = shift;
        return __PACKAGE__->from_unsigned_long_long(@{$arg})->bstr;
   };

has fs => ( is => 'ro', isa => 'Net::Amazon::HadoopEC2::S3fs', required => 1 );
has id => ( 
    is => 'ro', 
    isa => 'Net::Amazon::HadoopEC2::S3fs::Block::Id', 
    coerce => 1,
    lazy => 1,
    default => sub {
        my $self = shift;
        while (1) {
            my $id = $self->from_unsigned_long_long(int(rand(2**32)),int(rand(2**32)))->bstr;
            $self->fs->s3->head_key($id) or return $id;
        }
    }
);

has filename => ( is => 'ro', isa => 'Str', lazy => 1,
    default => sub {
        my $self = shift;
        return 'block_'.$self->id
    }
);

has size => ( is => 'ro', isa => 'Net::Amazon::HadoopEC2::S3fs::Block::Size', required => 1, coerce => 1);

sub put {
    my ($self, $content) = @_;
    return $self->fs->s3->add_key($self->filename, $content);
}

sub get {
    my ($self) = @_;
    my $key = $self->fs->s3->get_key($self->filename) or return;
    return $key->{value};
}

sub remove {
    my ($self) = @_;
    return $self->fs->s3->delete_key($self->filename);
}

sub inode_content {
    my $self = shift;
    my ($id_u, $id_l) = $self->to_unsigned_long_long($self->id);
    my ($size_u, $size_l) = $self->to_unsigned_long_long($self->size);
    return pack("N4", $id_u, $id_l, $size_u, $size_l);
}

sub from_unsigned_long_long {
    my ($self, $u, $l) = @_;
    return ($u >= 2 ** 31 ? $u - 2 ** 32 : $u) * 2 ** 32 + $l;
}

sub to_unsigned_long_long {
    my ($self, $arg) = @_;
    my $l = $arg % (2 ** 32);
    my $u = ($arg - $l) / (2 ** 32);
    return ($u, $l);
}

1;
__END__

=head1 NAME

Net::Amazon::HadoopEC2::S3fs::Block - A representation of Hadoop-ec2 s3fs block.

=head1 DESCRIPTION

Net::Amazon::HadoopEC2::S3fs::Block is a representation of Hadoop-ec2 s3fs block.

=head1 AUTHOR

Nobuo Danjou E<lt>nobuo.danjou@gmail.comE<gt>

=head1 SEE ALSO

L<Net::Amazon::S3>

L<Net::Amazon::HadoopEC2::S3fs>

=cut
