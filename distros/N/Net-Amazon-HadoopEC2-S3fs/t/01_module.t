use strict;
use warnings;
use Test::More;
use File::Temp;
use File::Spec;
use File::Basename;

BEGIN {
    for (qw( AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY S3FS_TEST_BUCKET)) {
        unless ($ENV{$_}) {
            plan skip_all => "set $_ to run this test.";
            exit 0;
        }
    }
    plan tests => 18;
    use_ok 'Net::Amazon::HadoopEC2::S3fs';
}

my $fs = Net::Amazon::HadoopEC2::S3fs->new(
    {
        aws_access_key_id => $ENV{AWS_ACCESS_KEY_ID},
        aws_secret_access_key => $ENV{AWS_SECRET_ACCESS_KEY},
        bucket => $ENV{S3FS_TEST_BUCKET},
    }
);
isa_ok $fs, 'Net::Amazon::HadoopEC2::S3fs';
{
    my $res = $fs->s3->list_all;
    for my $key (@{$res->{keys}}) {
        $fs->s3->delete_key($key->{key});
    }
}

{
    my $dir = $fs->mkdir('/');
    isa_ok $dir, 'Net::Amazon::HadoopEC2::S3fs::Inode';
    my $list = $fs->list('/');
    is scalar @{$list}, 1;
    isa_ok $list->[0], 'Net::Amazon::HadoopEC2::S3fs::Inode';
    is $list->[0]->inode_type, 'directory';
    is $list->[0]->path, '/';
}
{
    for (qw( /user /user/root /user/root/input )) {
        my $dir = $fs->mkdir($_);
    }
    my $list = $fs->list('/');
}
{
    my $tmp = File::Temp->new;
    print $tmp 'hogehoge';
    close $tmp;
    my $destination = '/user/root/input';
    my $path = File::Spec->catfile($destination, basename($tmp->filename));
    {
        my $file = $fs->put(
            {
                file => $tmp->filename,
                destination => $destination,
            }
        );
        isa_ok $file, 'Net::Amazon::HadoopEC2::S3fs::Inode';
    }
    {
        my $list = $fs->list($destination);
        is scalar @{$list}, 2;
        my ($file) = grep {$_->path eq $path} @{$list};
        isa_ok $file, 'Net::Amazon::HadoopEC2::S3fs::Inode';
        is $file->path, $path;
        is $file->inode_type, 'file';
        my $blocks = $file->blocks;
        is scalar @{$blocks}, 1;
        my $block = $blocks->[0];
        is $block->size, 8;
    }
    {
        my $got = File::Temp->new;
        close $got;
        ok $fs->get(
            {
                file => $path,
                destination => $got->filename,
            }
        );
        open my $fh, $got->filename;
        my $content = do {local $/; <$fh>};
        is $content, 'hogehoge';
    }
    {
        ok $fs->remove($path);
        my $list = $fs->list($destination);
        is scalar @{$list}, 1;
    }
}
{
    my $res = $fs->s3->list_all;
    for my $key (@{$res->{keys}}) {
        $fs->s3->delete_key($key->{key});
    }
}
