package Net::Amazon::HadoopEC2::S3fs::Inode;
use Moose;
use Moose::Util::TypeConstraints;
use Net::Amazon::HadoopEC2::S3fs::Block;

my $BLOCKSIZE = 2 ** 25;

enum inode_types => qw( file directory );

has path => ( is => 'rw', isa => 'Str' );
has fs => ( is => 'ro', isa => 'Net::Amazon::HadoopEC2::S3fs', required => 1);

has inode_content => ( is => 'rw', isa => 'Str', required => 1, lazy => 1,
    default => sub {
        my $self = shift;
        my $response = $self->fs->s3->get_key($self->path) or die $self->fs->s3->errstr;
        return $response->{value};
    }
);

has inode_type => ( is => 'ro', isa => 'inode_types', required => 1, lazy => 1,
    default => sub {
        my $self = shift;
        return unpack('b', $self->inode_content) ? 'file' : 'directory';
    }
);

has blocks => (
    is => 'rw',
    isa => 'ArrayRef[Net::Amazon::HadoopEC2::S3fs::Block]',
    required => 0,
    lazy => 1,
    default => sub {
        my $self = shift;
        my $blocks = [];
        $self->inode_type eq 'directory' and return $blocks;
        my $length = unpack('x N', $self->inode_content) or return $blocks;
        for (1 .. $length) {
            my $skip = 5 + ($_ - 1) * 16;
            my $block = Net::Amazon::HadoopEC2::S3fs::Block->new(
                {
                    fs => $self->fs,
                    id => [ unpack("x$skip NN", $self->inode_content) ], 
                    size => [ unpack("x$skip x8 NN", $self->inode_content) ],
                }
            );
            push @{$blocks}, $block;
        }
        return $blocks;
    }
);

sub put {
    my ($self, $file) = @_;
    
    my $inode_content;
    if ($file) {
        $self->inode_type eq 'file' or return;
        open my $fh, '<', $file or die;
        binmode $fh;
        my @blocks;
        while (my $size = read($fh, my $content, $BLOCKSIZE)) {
            my $block = Net::Amazon::HadoopEC2::S3fs::Block->new(
                fs => $self->fs,
                size => $size,
            );
            $block->put($content) or return;
            push @blocks, $block;
        }
        close $fh;
        $self->blocks(\@blocks);
        $inode_content = pack("b N", 1, scalar @{$self->blocks}) 
        . join '', map {$_->inode_content} @{$self->blocks};
    } else {
        $self->inode_type eq 'directory' or return;
        $inode_content = pack("b", 0);
    }
    $self->inode_content($inode_content);
    $self->fs->s3->add_key($self->path, $inode_content, 
        {
            'x-amz-meta-fs' => 'Hadoop',
            'x-amz-meta-fs-type' => 'block',
            'x-amz-meta-fs-version' => 1,
        }
    ) or return;
    return $self;
}

sub get {
    my ($self, $args) = @_;

    open my $fh, '>', $args->{destination} or die;
    binmode $fh;
    for my $block ( @{$self->blocks} ) {
        my $content = $block->get or return;
        print $fh $content;
    }
    close $fh;
    return $args->{destination};
}

sub remove {
    my ($self) = @_;
    for my $block ( @{$self->blocks} ) {
        $block->remove or return;
    }
    $self->fs->s3->delete_key($self->path) or return;
    return 1;
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

Net::Amazon::HadoopEC2::S3fs::Inode - A representation of Hadoop-ec2 s3fs inode.

=head1 SYNOPSIS

  use Net::Amazon::HadoopEC2::S3fs;

  my $fs = Net::Amazon::HadoopEC2::S3fs->new(
    {
        aws_access_key_id => $EVN{AWS_ACCESS_KEY_ID},
        aws_secret_access_key => $ENV{AWS_SECRET_ACCESS_KEY},
        bucket => 'your_bucket',
    }
  );
  my $file = $fs->put(
    {
        file => 'filename',
        destination => '/user/root',
    }
  );
  my $files_listed = $fs->ls(
    {
        path => '/user/root',
    }
  );

  for my $file (@{$files_listed}) {
      $file->remove;
  }

=head1 DESCRIPTION

Net::Amazon::HadoopEC2::S3fs::Inode is a representation of Hadoop-ec2 s3fs inode.

=head1 METHODS

=head2 put([$file])

Puts the inode to the s3fs. If the inode is file, $file argument is required.
Otherwise ( if the inode is directory, ) $file argument should not be passed.

=head2 get(\%args)

Gets the file to the specified destination. Returns the file path saved on success, undef on failure.
The Arguments are:

=over 4

=item destination (required)

The local file path to save the s3fs file.

=back

=head2 remove

Removes the s3fs file/direcotry. Returns 1 on success, undef on failure.

=head1 AUTHOR

Nobuo Danjou E<lt>nobuo.danjou@gmail.comE<gt>

=head1 SEE ALSO

L<Net::Amazon::HadoopEC2::S3fs>

=cut
