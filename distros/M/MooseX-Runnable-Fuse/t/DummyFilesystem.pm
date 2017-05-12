use MooseX::Declare;

class DummyFilesystem
  with MooseX::Runnable::Fuse
  with MooseX::Runnable
  with Filesystem::Fuse::Readable
{
    use MooseX::Types::Moose qw(Int);
    use MooseX::Types::Path::Class qw(File Dir);

    method getattr(File $file does coerce){
        warn "Getattr on $file";
        my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
            $atime,$mtime,$ctime,$blksize,$blocks) =
           (   1,   0, 0644,     1,   0,   0,    0,   10,
                1,     1,     1,     1024, 1     );

        if($file->stringify eq '/'){
            $size = 0;
            $mode += 0040 << 9;
            $mode += 0111;
        }
        else {
            $mode += 0100 << 9;
        }
        return ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
                $atime,$mtime,$ctime,$blksize,$blocks);
    }

    method file_exists(File $file){
        warn "exists? $file";
        return 1;
    }

    method getdir(Dir $dir does coerce){
        warn "Getdir $dir";
        return qw/. some files are here 0/;
    }

    method read(File $file does coerce, Int $size, Int $offset){
        warn "Read $file $size from $offset";
        return "X"x$size;
    }

    method readlink(File $file){}

    method statfs {}
}

1;
