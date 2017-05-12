package Net::Amazon::HadoopEC2::S3fs;
use Moose;
our $VERSION = '0.02';

use Net::Amazon::S3;
use Net::Amazon::HadoopEC2::S3fs::Inode;
use File::Basename;

has aws_access_key_id => ( is => 'ro', isa => 'Str', required => 1 );
has aws_secret_access_key => ( is => 'ro', isa => 'Str', required => 1 );
has bucket => ( is => 'ro', isa => 'Str', required => 1 );
has s3 => ( is => 'ro', isa => 'Net::Amazon::S3::Bucket', required => 1, lazy => 1,
    default => sub {
        my $self = shift;
        return Net::Amazon::S3->new(
            {
                aws_access_key_id     => $self->aws_access_key_id,
                aws_secret_access_key => $self->aws_secret_access_key,
                retry                 => 1,
            }
        )->bucket($self->bucket);
    }
);

__PACKAGE__->meta->make_immutable;

no Moose;

sub list {
    my ($self, $path) = @_;
    my $res = $self->s3->list(
        {
            prefix => $path,
        }
    )
        or die $self->s3->errstr;
    my $response;
    for my $key (@{$res->{keys}}) {
        push @{$response}, Net::Amazon::HadoopEC2::S3fs::Inode->new(
            {
                path => $key->{key},
                fs => $self,
            }
        );
    }
    return $response;
}

sub put {
    my ($self, $args) = @_;
    my $filename = basename($args->{file});
    (my $dest = $args->{destination}) =~ s{(.)/$}{$1};
    my $list = $self->list(dirname($dest)) or return;
    scalar @{$list} == 0 and return;
    my $inode = Net::Amazon::HadoopEC2::S3fs::Inode->new(
        { 
            fs => $self,
            inode_type => 'file'
        }
    );
    if ( my $existing = grep { $_->path eq $args->{destination} && $_->inode_type eq 'directory' } @{$list}) {
        $inode->path("$args->{destination}/$filename");
    } else {
        $inode->path($args->{destination});    
    }
    $inode->put($args->{file}) or return;
    return $inode;
}

sub mkdir {
    my ($self, $dir) = @_;
    $dir =~ s{(.)/$}{$1};
    $self->list($dir) and return;
    my $inode = Net::Amazon::HadoopEC2::S3fs::Inode->new(
        {
            path => $dir,
            inode_type => 'directory',
            fs => $self,
        }
    );
    $inode->put or return;
    return $inode;
}

sub get {
    my ($self, $args) = @_;
    my ($file) = @{$self->list($args->{file})} or return;
    return $file->get({destination => $args->{destination}}); 
}

sub remove {
    my ($self, $path) = @_;
    my $list = $self->list($path) or return;
    scalar @{$list} == 1 or return;
    return $list->[0]->remove;
}

1;
__END__

=head1 NAME

Net::Amazon::HadoopEC2::S3fs - Perl interface to hadoop s3fs

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

Net::Amazon::HadoopEC2::S3fs is a Perl interface to hadoop s3fs.

=head1 METHODS

=head2 new(\%args)

Constructor. The arguments are:

=over 4

=item aws_access_key_id (required)

Your aws access key.

=item aws_secret_access_key (required)

Your aws secret key.

=item bucket (required)

The bucket name to use.

=back

=head2 list($path)

Returns arrayref of Net::Amazon::HadoopEC2::S3fs::Inode instances. Pass the path to list.

=head2 put(\%args)

Puts file to s3fs. returns Net::Amazon::HadoopEC2::S3fs::Inode instance of the file on success,
undef on failure. The arguments are:

=over 4

=item file (required)

The file path to put.

=item destination (required)

The destination path to put.

=back

=head2 mkdir($dir)

Makes directory on S3fs. Returns L<Net::Amazon::HadoopEC2::S3fs::Inode> instance of the directory
on success, undef on failure. Pass the directory path to make.

=head2 get(\%args)

Gets a file from S3fs. Returns the file path on success, undef on failure. The arguments are:

=over 4

=item file (required)

The S3fs path of the file to get.

=item destination (required)

The path to save the file.

=back

=head2 remove($path)

Removes S3fs inode. Returns 1 on success, undef on failure.

=head1 AUTHOR

Nobuo Danjou E<lt>nobuo.danjou@gmail.comE<gt>

=head1 SEE ALSO

L<Net::Amazon::S3>

L<Net::Amazon::HadoopEC2>

Hadoop project - L<http://hadoop.apache.org/>

Hadoop Wiki, AmazonS3 - L<http://wiki.apache.org/hadoop/AmazonS3>

=head1 REPOSITORY

  svn co http://svn.coderepos.org/share/lang/perl/Net-Amazon-HadoopEC2-S3fs/trunk Net-Amazon-HadoopEC2-S3fs

The svn repository of this module is hosted at L<http://coderepos.org/share/>.
Patches and commits are welcome.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
