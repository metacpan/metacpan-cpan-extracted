use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'Fn';
use SPVM::File::Spec;

use File::Spec;

use SPVM 'File::Spec::Instance';
use SPVM 'File::Spec';
use SPVM 'Cwd';

use SPVM 'TestCase::File::Spec::Instance';
use SPVM 'TestCase::File::Spec::Instance::Unix';

ok(SPVM::TestCase::File::Spec::Instance->test);

ok(SPVM::File::Spec->devnull, File::Spec->devnull);

ok(SPVM::File::Spec->rootdir, File::Spec->rootdir);

ok(SPVM::File::Spec->updir, File::Spec->updir);

# no_upwards
{
  {
    my $dir_parts = ["foo", "", "..", ".", "..."];
    is_deeply(SPVM::File::Spec->no_upwards($dir_parts)->to_strings, [File::Spec->no_upwards(@$dir_parts)]);
  }
}

ok(SPVM::File::Spec->curdir, File::Spec->curdir);

# canonpath
{
  {
    my $path = "";
    is_deeply(SPVM::File::Spec->canonpath($path), File::Spec->canonpath($path));
  }
  {
    my $path = "foo/";
    is_deeply(SPVM::File::Spec->canonpath($path), File::Spec->canonpath($path));
  }
  {
    my $path = "foo/../bar";
    is_deeply(SPVM::File::Spec->canonpath($path), File::Spec->canonpath($path));
  }
  {
    my $path = "foo/../bar/../baz";
    is_deeply(SPVM::File::Spec->canonpath($path), File::Spec->canonpath($path));
  }
  {
    my $path = "foo/./bar";
    is_deeply(SPVM::File::Spec->canonpath($path), File::Spec->canonpath($path));
  }
  {
    my $path = "foo/./a/./bar";
    is_deeply(SPVM::File::Spec->canonpath($path), File::Spec->canonpath($path));
  }
  {
    my $path = "C:/foo/bar";
    is_deeply(SPVM::File::Spec->canonpath($path), File::Spec->canonpath($path));
  }
  {
    my $path = "//192.168.102.155/foo/bar";
    is_deeply(SPVM::File::Spec->canonpath($path), File::Spec->canonpath($path));
  }
  {
    my $path = "/foo";
    is_deeply(SPVM::File::Spec->canonpath($path), File::Spec->canonpath($path));
  }

  {
    my $path = "";
    is_deeply(SPVM::File::Spec->canonpath($path), File::Spec->canonpath($path));
  }
  {
    my $path = "c:";
    is_deeply(SPVM::File::Spec->canonpath($path), File::Spec->canonpath($path));
  }
  {
    my $path = "foo\\";
    is_deeply(SPVM::File::Spec->canonpath($path), File::Spec->canonpath($path));
  }
  {
    my $path = "foo\\..\\bar";
    is_deeply(SPVM::File::Spec->canonpath($path), File::Spec->canonpath($path));
  }
  {
    my $path = "foo\\..\\bar\\..\\baz";
    is_deeply(SPVM::File::Spec->canonpath($path), File::Spec->canonpath($path));
  }
  {
    my $path = "foo\\.\\bar";
    is_deeply(SPVM::File::Spec->canonpath($path), File::Spec->canonpath($path));
  }
  {
    my $path = "foo\\.\\a\\.\\bar";
    is_deeply(SPVM::File::Spec->canonpath($path), File::Spec->canonpath($path));
  }
  {
    my $path = "C:\\foo\\bar";
    is_deeply(SPVM::File::Spec->canonpath($path), File::Spec->canonpath($path));
  }
  {
    my $path = "\\\\192.168.102.155\\foo\\bar";
    is_deeply(SPVM::File::Spec->canonpath($path), File::Spec->canonpath($path));
  }
  {
    my $path = "\\foo";
    is_deeply(SPVM::File::Spec->canonpath($path), File::Spec->canonpath($path));
  }

  {
    my $path = "\\\\HOST\\SHARE\\";
    is_deeply(SPVM::File::Spec->canonpath($path), File::Spec->canonpath($path));
  }
  {
    my $path = "C:\\..\\..";
    is_deeply(SPVM::File::Spec->canonpath($path), File::Spec->canonpath($path));
  }
}

# file_name_is_absolute
{
  ok(SPVM::TestCase::File::Spec::Instance::Unix->file_name_is_absolute);
  
  # Unix
  {
    {
      my $path = '/foo';
      is(!!SPVM::File::Spec->file_name_is_absolute($path), !!File::Spec->file_name_is_absolute($path));
    }
    {
      my $path = 'foo';
      is(!!SPVM::File::Spec->file_name_is_absolute($path), !!File::Spec->file_name_is_absolute($path));
    }
  }
  
  # Windows
  {
    {
      my $path = "\\foo";
      is(!!SPVM::File::Spec->file_name_is_absolute($path), !!File::Spec->file_name_is_absolute($path));
    }
    {
      my $path = "C:";
      is(!!SPVM::File::Spec->file_name_is_absolute($path), !!File::Spec->file_name_is_absolute($path));
    }
    {
      my $path = "C:\\";
      is(!!SPVM::File::Spec->file_name_is_absolute($path), !!File::Spec->file_name_is_absolute($path));
    }
    {
      my $path = "C:\\foo";
      is(!!SPVM::File::Spec->file_name_is_absolute($path), !!File::Spec->file_name_is_absolute($path));
    }
    {
      my $path = "a:\\foo";
      is(!!SPVM::File::Spec->file_name_is_absolute($path), !!File::Spec->file_name_is_absolute($path));
    }
    {
      my $path = "z:\\foo";
      is(!!SPVM::File::Spec->file_name_is_absolute($path), !!File::Spec->file_name_is_absolute($path));
    }
    {
      my $path = "A:\\foo";
      is(!!SPVM::File::Spec->file_name_is_absolute($path), !!File::Spec->file_name_is_absolute($path));
    }
    {
      my $path = "Z:\\foo";
      is(!!SPVM::File::Spec->file_name_is_absolute($path), !!File::Spec->file_name_is_absolute($path));
    }
    {
      my $path = "\\\\192.168.201.205";
      is(!!SPVM::File::Spec->file_name_is_absolute($path), !!File::Spec->file_name_is_absolute($path));
    }
    {
      my $path = "\\\\192.168.201.205\\";
      is(!!SPVM::File::Spec->file_name_is_absolute($path), !!File::Spec->file_name_is_absolute($path));
    }
    {
      my $path = "\\\\192.168.201.205\\foo";
      is(!!SPVM::File::Spec->file_name_is_absolute($path), !!File::Spec->file_name_is_absolute($path));
    }
    {
      my $path = "/foo";
      is(!!SPVM::File::Spec->file_name_is_absolute($path), !!File::Spec->file_name_is_absolute($path));
    }
    {
      my $path = "C:";
      is(!!SPVM::File::Spec->file_name_is_absolute($path), !!File::Spec->file_name_is_absolute($path));
    }
    {
      my $path = "C:/";
      is(!!SPVM::File::Spec->file_name_is_absolute($path), !!File::Spec->file_name_is_absolute($path));
    }
    {
      my $path = "C:/foo";
      is(!!SPVM::File::Spec->file_name_is_absolute($path), !!File::Spec->file_name_is_absolute($path));
    }
    {
      my $path = "a:/foo";
      is(!!SPVM::File::Spec->file_name_is_absolute($path), !!File::Spec->file_name_is_absolute($path));
    }
    {
      my $path = "z:/foo";
      is(!!SPVM::File::Spec->file_name_is_absolute($path), !!File::Spec->file_name_is_absolute($path));
    }
    {
      my $path = "A:/foo";
      is(!!SPVM::File::Spec->file_name_is_absolute($path), !!File::Spec->file_name_is_absolute($path));
    }
    {
      my $path = "Z:/foo";
      is(!!SPVM::File::Spec->file_name_is_absolute($path), !!File::Spec->file_name_is_absolute($path));
    }
    {
      my $path = "//192.168.201.205";
      is(!!SPVM::File::Spec->file_name_is_absolute($path), !!File::Spec->file_name_is_absolute($path));
    }
    {
      my $path = "//192.168.201.205/";
      is(!!SPVM::File::Spec->file_name_is_absolute($path), !!File::Spec->file_name_is_absolute($path));
    }
    {
      my $path = "//192.168.201.205/foo";
      is(!!SPVM::File::Spec->file_name_is_absolute($path), !!File::Spec->file_name_is_absolute($path));
    }
  }
}

# file_name_is_root
{
  
  # Unix/Windows
  {
    {
      my $path = '/foo';
      ok(!SPVM::File::Spec->file_name_is_root($path));
    }
    {
      my $path = 'foo';
      ok(!SPVM::File::Spec->file_name_is_root($path));
    }
    {
      my $path = '/';
      ok(SPVM::File::Spec->file_name_is_root($path));
    }
  }
  
  # Windows
  if ($^O eq 'MSWin32'){
    {
      my $path = "\\foo";
      ok(!SPVM::File::Spec->file_name_is_root($path));
    }
    {
      my $path = "C:";
      ok(!SPVM::File::Spec->file_name_is_root($path));
    }
    {
      my $path = "C:\\";
      ok(SPVM::File::Spec->file_name_is_root($path));
    }
    {
      my $path = "C:\\foo";
      ok(!SPVM::File::Spec->file_name_is_root($path));
    }
    {
      my $path = "a:\\foo";
      ok(!SPVM::File::Spec->file_name_is_root($path));
    }
    {
      my $path = "z:\\foo";
      ok(!SPVM::File::Spec->file_name_is_root($path));
    }
    {
      my $path = "A:\\foo";
      ok(!SPVM::File::Spec->file_name_is_root($path));
    }
    {
      my $path = "Z:\\foo";
      ok(!SPVM::File::Spec->file_name_is_root($path));
    }
    {
      my $path = "\\\\192.168.201.205";
      ok(!SPVM::File::Spec->file_name_is_root($path));
    }
    {
      my $path = "\\\\192.168.201.205\\";
      ok(!SPVM::File::Spec->file_name_is_root($path));
    }
    {
      my $path = "\\\\192.168.201.205\\foo";
      ok(SPVM::File::Spec->file_name_is_root($path));
    }
    {
      my $path = "\\\\192.168.201.205\\foo/";
      ok(SPVM::File::Spec->file_name_is_root($path));
    }
    {
      my $path = "\\\\192.168.201.205\\foo\\";
      ok(SPVM::File::Spec->file_name_is_root($path));
    }
    {
      my $path = "/foo";
      ok(!SPVM::File::Spec->file_name_is_root($path));
    }
    {
      my $path = "C:";
      ok(!SPVM::File::Spec->file_name_is_root($path));
    }
    {
      my $path = "C:/";
      ok(SPVM::File::Spec->file_name_is_root($path));
    }
    {
      my $path = "C:/foo";
      ok(!SPVM::File::Spec->file_name_is_root($path));
    }
    {
      my $path = "a:/foo";
      ok(!SPVM::File::Spec->file_name_is_root($path));
    }
    {
      my $path = "z:/foo";
      ok(!SPVM::File::Spec->file_name_is_root($path));
    }
    {
      my $path = "A:/foo";
      ok(!SPVM::File::Spec->file_name_is_root($path));
    }
    {
      my $path = "Z:/foo";
      ok(!SPVM::File::Spec->file_name_is_root($path));
    }
    {
      my $path = "//192.168.201.205";
      ok(!SPVM::File::Spec->file_name_is_root($path));
    }
    {
      my $path = "//192.168.201.205/";
      ok(!SPVM::File::Spec->file_name_is_root($path));
    }
    {
      my $path = "//192.168.201.205/foo";
      ok(SPVM::File::Spec->file_name_is_root($path));
    }
    {
      my $path = "//192.168.201.205/foo/";
      ok(SPVM::File::Spec->file_name_is_root($path));
    }
  }
}

# splitdir
{
  {
    my $path = "foo/bar";
    is_deeply(SPVM::File::Spec->splitdir($path)->to_strings, [File::Spec->splitdir($path)]);
  }
  {
    my $path = "/a/b/c//d/";
    is_deeply(SPVM::File::Spec->splitdir($path)->to_strings, [File::Spec->splitdir($path)]);
  }
  {
    my $path = "foo\\bar";
    is_deeply(SPVM::File::Spec->splitdir($path)->to_strings, [File::Spec->splitdir($path)]);
  }
  {
    my $path = "\\a\\b\\c\\\\d\\";
    is_deeply(SPVM::File::Spec->splitdir($path)->to_strings, [File::Spec->splitdir($path)]);
  }
}

# splitpath
{
  {
    my $path = "foo/bar";
    my $no_file = 0;
    is_deeply(SPVM::File::Spec->splitpath($path, $no_file)->to_strings, [File::Spec->splitpath($path, $no_file)]);
  }
  {
    my $path = "/foo/bar/";
    my $no_file = 0;
    is_deeply(SPVM::File::Spec->splitpath($path, $no_file)->to_strings, [File::Spec->splitpath($path, $no_file)]);
  }
  {
    my $path = "c:/foo/bar";
    my $no_file = 0;
    is_deeply(SPVM::File::Spec->splitpath($path, $no_file)->to_strings, [File::Spec->splitpath($path, $no_file)]);
  }
  {
    my $path = "//1.2.3.4/SHARE/foo/bar";
    my $no_file = 0;
    is_deeply(SPVM::File::Spec->splitpath($path, $no_file)->to_strings, [File::Spec->splitpath($path, $no_file)]);
  }
  {
    my $path = "foo/bar";
    my $no_file = 1;
    is_deeply(SPVM::File::Spec->splitpath($path, $no_file)->to_strings, [File::Spec->splitpath($path, $no_file)]);
  }
  {
    my $path = "c:/foo/bar";
    my $no_file = 1;
    is_deeply(SPVM::File::Spec->splitpath($path, $no_file)->to_strings, [File::Spec->splitpath($path, $no_file)]);
  }
  {
    my $path = "/foo/bar/";
    my $no_file = 1;
    is_deeply(SPVM::File::Spec->splitpath($path, $no_file)->to_strings, [File::Spec->splitpath($path, $no_file)]);
  }
  {
    my $path = "//1.2.3.4/SHARE/foo/bar";
    my $no_file = 1;
    is_deeply(SPVM::File::Spec->splitpath($path, $no_file)->to_strings, [File::Spec->splitpath($path, $no_file)]);
  }
  {
    my $path = "foo\\bar";
    my $no_file = 0;
    is_deeply(SPVM::File::Spec->splitpath($path, $no_file)->to_strings, [File::Spec->splitpath($path, $no_file)]);
  }
  {
    my $path = "\\foo\\bar\\";
    my $no_file = 0;
    is_deeply(SPVM::File::Spec->splitpath($path, $no_file)->to_strings, [File::Spec->splitpath($path, $no_file)]);
  }
  {
    my $path = "c:\\foo\\bar";
    my $no_file = 0;
    is_deeply(SPVM::File::Spec->splitpath($path, $no_file)->to_strings, [File::Spec->splitpath($path, $no_file)]);
  }
  {
    my $path = "\\\\1.2.3.4\\SHARE\\foo\\bar";
    my $no_file = 0;
    is_deeply(SPVM::File::Spec->splitpath($path, $no_file)->to_strings, [File::Spec->splitpath($path, $no_file)]);
  }
  {
    my $path = "foo\\bar";
    my $no_file = 1;
    is_deeply(SPVM::File::Spec->splitpath($path, $no_file)->to_strings, [File::Spec->splitpath($path, $no_file)]);
  }
  {
    my $path = "c:\\foo\\bar";
    my $no_file = 1;
    is_deeply(SPVM::File::Spec->splitpath($path, $no_file)->to_strings, [File::Spec->splitpath($path, $no_file)]);
  }
  {
    my $path = "\\foo\\bar\\";
    my $no_file = 1;
    is_deeply(SPVM::File::Spec->splitpath($path, $no_file)->to_strings, [File::Spec->splitpath($path, $no_file)]);
  }
  {
    my $path = "\\\\1.2.3.4\\SHARE\\foo\\bar";
    my $no_file = 1;
    is_deeply(SPVM::File::Spec->splitpath($path, $no_file)->to_strings, [File::Spec->splitpath($path, $no_file)]);
  }
}

# catdir
{
  {
    my $dir_parts = ["foo", "bar"];
    is(SPVM::File::Spec->catdir($dir_parts), File::Spec->catdir(@$dir_parts));
  }
  {
    my $dir_parts = [];
    is(SPVM::File::Spec->catdir($dir_parts), File::Spec->catdir(@$dir_parts));
  }
  {
    my $dir_parts = ["", "foo", "bar"];
    is(SPVM::File::Spec->catdir($dir_parts), File::Spec->catdir(@$dir_parts));
  }

  {
    my $dir_parts = ["c:", "bar"];
    is(SPVM::File::Spec->catdir($dir_parts), File::Spec->catdir(@$dir_parts));
  }
  {
    my $dir_parts = ["//1.2.3.4/SHARE", "bar"];
    is(SPVM::File::Spec->catdir($dir_parts), File::Spec->catdir(@$dir_parts));
  }
  {
    my $dir_parts = ["foo", "bar"];
    is(SPVM::File::Spec->catdir($dir_parts), File::Spec->catdir(@$dir_parts));
  }
  {
    my $dir_parts = [];
    is(SPVM::File::Spec->catdir($dir_parts), File::Spec->catdir(@$dir_parts));
  }
  {
    my $dir_parts = ["", "foo", "bar"];
    is(SPVM::File::Spec->catdir($dir_parts), File::Spec->catdir(@$dir_parts));
  }

  {
    my $dir_parts = ["c:", "bar"];
    is(SPVM::File::Spec->catdir($dir_parts), File::Spec->catdir(@$dir_parts));
  }
  {
    my $dir_parts = ["\\\\\\\\1.2.3.4\\\\SHARE", "bar"];
    is(SPVM::File::Spec->catdir($dir_parts), File::Spec->catdir(@$dir_parts));
  }
  {
    my $dir_parts = ["..", "..", "foo", "bar"];
    is(SPVM::File::Spec->catdir($dir_parts), File::Spec->catdir(@$dir_parts));
  }
}

# catfile
{
  {
    my $dir_parts = ["foo", "bar"];
    my $file_base_name = "a.txt";
    is(SPVM::File::Spec->catfile($dir_parts, $file_base_name), File::Spec->catfile(@$dir_parts, $file_base_name));
  }
  {
    my $dir_parts = [];
    my $file_base_name = "a.txt";
    is(SPVM::File::Spec->catfile($dir_parts, $file_base_name), File::Spec->catfile(@$dir_parts, $file_base_name));
  }
  {
    my $dir_parts = ["foo"];
    my $file_base_name = "a.txt";
    is(SPVM::File::Spec->catfile($dir_parts, $file_base_name), File::Spec->catfile(@$dir_parts, $file_base_name));
  }
  {
    my $dir_parts = ["foo"];
    my $file_base_name = "p/../a.txt";
    is(SPVM::File::Spec->catfile($dir_parts, $file_base_name), File::Spec->catfile(@$dir_parts, $file_base_name));
  }
  {
    my $dir_parts = ["foo"];
    my $file_base_name = "p\\..\\a.txt";
    is(SPVM::File::Spec->catfile($dir_parts, $file_base_name), File::Spec->catfile(@$dir_parts, $file_base_name));
  }
}


# join
{
  {
    my $dir_parts = ["foo", "bar"];
    my $file_base_name = "a.txt";
    is(SPVM::File::Spec->join($dir_parts, $file_base_name), File::Spec->join(@$dir_parts, $file_base_name));
  }
  {
    my $dir_parts = [];
    my $file_base_name = "a.txt";
    is(SPVM::File::Spec->join($dir_parts, $file_base_name), File::Spec->join(@$dir_parts, $file_base_name));
  }
  {
    my $dir_parts = ["foo"];
    my $file_base_name = "a.txt";
    is(SPVM::File::Spec->join($dir_parts, $file_base_name), File::Spec->join(@$dir_parts, $file_base_name));
  }
  {
    my $dir_parts = ["foo"];
    my $file_base_name = "p/../a.txt";
    is(SPVM::File::Spec->join($dir_parts, $file_base_name), File::Spec->join(@$dir_parts, $file_base_name));
  }
  {
    my $dir_parts = ["foo"];
    my $file_base_name = "p\\..\\a.txt";
    is(SPVM::File::Spec->join($dir_parts, $file_base_name), File::Spec->join(@$dir_parts, $file_base_name));
  }
}


# catpath
{
  {
    my $volume = "A:";
    my $dir = "foo";
    my $file_base_name = "a.txt";
    
    is(SPVM::File::Spec->catpath($volume, $dir, $file_base_name), File::Spec->catpath($volume, $dir, $file_base_name));
  }
  {
    my $volume = "a:";
    my $dir = "foo";
    my $file_base_name = "a.txt";
    
    is(SPVM::File::Spec->catpath($volume, $dir, $file_base_name), File::Spec->catpath($volume, $dir, $file_base_name));
  }
  {
    my $volume = "A:";
    my $dir = "foo";
    my $file_base_name = "a.txt";
    
    is(SPVM::File::Spec->catpath($volume, $dir, $file_base_name), File::Spec->catpath($volume, $dir, $file_base_name));
  }
  {
    my $volume = "Z:";
    my $dir = "foo";
    my $file_base_name = "a.txt";
    
    is(SPVM::File::Spec->catpath($volume, $dir, $file_base_name), File::Spec->catpath($volume, $dir, $file_base_name));
  }
  {
    my $volume = "A:/";
    my $dir = "foo/";
    my $file_base_name = "a.txt";
    
    is(SPVM::File::Spec->catpath($volume, $dir, $file_base_name), File::Spec->catpath($volume, $dir, $file_base_name));
  }
  {
    my $volume = "//1.2.3.4/SHARE";
    my $dir = "foo/";
    my $file_base_name = "a.txt";
    
    is(SPVM::File::Spec->catpath($volume, $dir, $file_base_name), File::Spec->catpath($volume, $dir, $file_base_name));
  }
  {
    my $volume = "A:";
    my $dir = "foo";
    my $file_base_name = "a.txt";
    
    is(SPVM::File::Spec->catpath($volume, $dir, $file_base_name), File::Spec->catpath($volume, $dir, $file_base_name));
  }
  {
    my $volume = "a:";
    my $dir = "foo";
    my $file_base_name = "a.txt";
    
    is(SPVM::File::Spec->catpath($volume, $dir, $file_base_name), File::Spec->catpath($volume, $dir, $file_base_name));
  }
  {
    my $volume = "A:";
    my $dir = "foo";
    my $file_base_name = "a.txt";
    
    is(SPVM::File::Spec->catpath($volume, $dir, $file_base_name), File::Spec->catpath($volume, $dir, $file_base_name));
  }
  {
    my $volume = "Z:";
    my $dir = "foo";
    my $file_base_name = "a.txt";
    
    is(SPVM::File::Spec->catpath($volume, $dir, $file_base_name), File::Spec->catpath($volume, $dir, $file_base_name));
  }
  {
    my $volume = "A:\\";
    my $dir = "foo\\";
    my $file_base_name = "a.txt";
    
    is(SPVM::File::Spec->catpath($volume, $dir, $file_base_name), File::Spec->catpath($volume, $dir, $file_base_name));
  }
  {
    my $volume = "\\\\1.2.3.4\\SHARE";
    my $dir = "foo\\";
    my $file_base_name = "a.txt";
    
    is(SPVM::File::Spec->catpath($volume, $dir, $file_base_name), File::Spec->catpath($volume, $dir, $file_base_name));
  }
}

# rel2abs
{
  {
    my $rel_file = "a:/foo/../bar/a.txt";
    is(SPVM::File::Spec->rel2abs($rel_file), File::Spec->rel2abs($rel_file));
  }
  {
    my $rel_file = "c:/foo/../bar/a.txt";
    is(SPVM::File::Spec->rel2abs($rel_file), File::Spec->rel2abs($rel_file));
  }
  {
    my $rel_file = "//1.2.3.4/SHARE/foo/../bar/a.txt";
    is(SPVM::File::Spec->rel2abs($rel_file), File::Spec->rel2abs($rel_file));
  }
  {
    my $rel_file = "/foo/../bar/a.txt";
    is(SPVM::File::Spec->rel2abs($rel_file), File::Spec->rel2abs($rel_file));
  }
  {
    my $rel_file = "/";
    is(SPVM::File::Spec->rel2abs($rel_file), File::Spec->rel2abs($rel_file));
  }
  {
    my $rel_file = "/foo";
    is(SPVM::File::Spec->rel2abs($rel_file), File::Spec->rel2abs($rel_file));
  }
  {
    my $rel_file = "foo/../bar/../a.txt";
    my $base = "c:/foo/../bar";
    is(SPVM::File::Spec->rel2abs($rel_file, $base), File::Spec->rel2abs($rel_file, $base));
  }
  {
    my $rel_file = "foo/../bar/../a.txt";
    my $base = "foo/../bar";
    is(SPVM::File::Spec->rel2abs($rel_file, $base), File::Spec->rel2abs($rel_file, $base));
  }
  {
    my $rel_file = "foo/../bar/../a.txt";
    is(SPVM::File::Spec->rel2abs($rel_file), File::Spec->rel2abs($rel_file));
  }
  {
    my $rel_file = "a:\\foo\\..\\bar\\a.txt";
    is(SPVM::File::Spec->rel2abs($rel_file), File::Spec->rel2abs($rel_file));
  }
  {
    my $rel_file = "c:\\foo\\..\\bar\\a.txt";
    is(SPVM::File::Spec->rel2abs($rel_file), File::Spec->rel2abs($rel_file));
  }
  {
    my $rel_file = "\\\\1.2.3.4\\SHARE\\foo\\..\\bar\\a.txt";
    is(SPVM::File::Spec->rel2abs($rel_file), File::Spec->rel2abs($rel_file));
  }
  {
    my $rel_file = "\\foo\\..\\bar\\a.txt";
    is(SPVM::File::Spec->rel2abs($rel_file), File::Spec->rel2abs($rel_file));
  }
  {
    my $rel_file = "\\";
    is(SPVM::File::Spec->rel2abs($rel_file), File::Spec->rel2abs($rel_file));
  }
  {
    my $rel_file = "\\foo";
    is(SPVM::File::Spec->rel2abs($rel_file), File::Spec->rel2abs($rel_file));
  }
  {
    my $rel_file = "foo";
    my $base = "\\base\\a\\..\\b";
    is(SPVM::File::Spec->rel2abs($rel_file, $base), File::Spec->rel2abs($rel_file, $base));
  }
  {
    my $rel_file = "foo\\..\\bar\\..\\a.txt";
    my $base = "c:\\foo\\..\\bar";
    is(SPVM::File::Spec->rel2abs($rel_file, $base), File::Spec->rel2abs($rel_file, $base));
  }
  {
    my $rel_file = "foo\\..\\bar\\..\\a.txt";
    my $base = "foo\\..\\bar";
    is(SPVM::File::Spec->rel2abs($rel_file, $base), File::Spec->rel2abs($rel_file, $base));
  }
  {
    my $rel_file = "foo\\..\\bar\\..\\a.txt";
    is(SPVM::File::Spec->rel2abs($rel_file), File::Spec->rel2abs($rel_file));
  }
}

# abs2rel
{
  {
    my $abs_file = "a:/foo/../bar/a.txt";
    is(SPVM::File::Spec->abs2rel($abs_file), File::Spec->abs2rel($abs_file));
  }
  {
    my $abs_file = "c:/foo/../bar/a.txt";
    is(SPVM::File::Spec->abs2rel($abs_file), File::Spec->abs2rel($abs_file));
  }
  {
    my $abs_file = "//1.2.3.4/SHARE/foo/../bar/a.txt";
    is(SPVM::File::Spec->abs2rel($abs_file), File::Spec->abs2rel($abs_file));
  }
  {
    my $abs_file = "/foo/../bar/a.txt";
    is(SPVM::File::Spec->abs2rel($abs_file), File::Spec->abs2rel($abs_file));
  }
  {
    my $abs_file = "";
    is(SPVM::File::Spec->abs2rel($abs_file), File::Spec->abs2rel($abs_file));
  }
  {
    my $abs_file = "/";
    is(SPVM::File::Spec->abs2rel($abs_file), File::Spec->abs2rel($abs_file));
  }
  {
    my $abs_file = "c:";
    is(SPVM::File::Spec->abs2rel($abs_file), File::Spec->abs2rel($abs_file));
  }
  {
    my $abs_file = "c:/foo/../bar/a.txt";
    my $base = "c:/foo";
    is(SPVM::File::Spec->abs2rel($abs_file), File::Spec->abs2rel($abs_file));
  }
  {
    my $abs_file = "c:/foo/../bar/a.txt";
    my $base = "c:/foo/../bar";
    is(SPVM::File::Spec->abs2rel($abs_file), File::Spec->abs2rel($abs_file));
  }
  {
    my $abs_file = "c:/foo/../bar/a.txt";
    my $base = "foo";
    is(SPVM::File::Spec->abs2rel($abs_file), File::Spec->abs2rel($abs_file));
  }
  for my $drive ('a' .. 'z') {
    my $abs_file = "$drive:/bar";
    my $base = "$drive:";
    is(SPVM::File::Spec->abs2rel($abs_file, $base), File::Spec->abs2rel($abs_file, $base));
  }
  for my $drive ('a' .. 'z') {
    my $abs_file = "$drive:/bar";
    my $base = "$drive";
    is(SPVM::File::Spec->abs2rel($abs_file, $base), File::Spec->abs2rel($abs_file, $base));
  }
  {
    my $cur_dir = SPVM::Cwd->getcwd;
    my $abs_file = "$cur_dir/bar";
    my $base = "$cur_dir";
    is(SPVM::File::Spec->abs2rel($abs_file, $base), File::Spec->abs2rel($abs_file, $base));
    is(SPVM::File::Spec->abs2rel($abs_file, $base), "bar");
  }
  {
    my $rel_file = "foo";
    my $base = "/base/a/../b";
    is(SPVM::File::Spec->rel2abs($rel_file, $base), File::Spec->rel2abs($rel_file, $base));
  }
  {
    my $abs_file = "a:\\foo\\..\\bar\\a.txt";
    is(SPVM::File::Spec->abs2rel($abs_file), File::Spec->abs2rel($abs_file));
  }
  {
    my $abs_file = "c:\\foo\\..\\bar\\a.txt";
    is(SPVM::File::Spec->abs2rel($abs_file), File::Spec->abs2rel($abs_file));
  }
  {
    my $abs_file = "\\\\1.2.3.4\\SHARE\\foo\\..\\bar\\a.txt";
    is(SPVM::File::Spec->abs2rel($abs_file), File::Spec->abs2rel($abs_file));
  }
  {
    my $abs_file = "\\foo\\..\\bar\\a.txt";
    is(SPVM::File::Spec->abs2rel($abs_file), File::Spec->abs2rel($abs_file));
  }
  {
    my $abs_file = "";
    is(SPVM::File::Spec->abs2rel($abs_file), File::Spec->abs2rel($abs_file));
  }
  {
    my $abs_file = "\\";
    is(SPVM::File::Spec->abs2rel($abs_file), File::Spec->abs2rel($abs_file));
  }
  {
    my $abs_file = "c:";
    is(SPVM::File::Spec->abs2rel($abs_file), File::Spec->abs2rel($abs_file));
  }
  {
    my $abs_file = "c:\\foo\\..\\bar\\a.txt";
    my $base = "c:\\foo";
    is(SPVM::File::Spec->abs2rel($abs_file), File::Spec->abs2rel($abs_file));
  }
  {
    my $abs_file = "c:\\foo\\..\\bar\\a.txt";
    my $base = "c:\\foo\\..\\bar";
    is(SPVM::File::Spec->abs2rel($abs_file), File::Spec->abs2rel($abs_file));
  }
  {
    my $abs_file = "c:\\foo\\..\\bar\\a.txt";
    my $base = "foo";
    is(SPVM::File::Spec->abs2rel($abs_file), File::Spec->abs2rel($abs_file));
  }
}

{
  is_deeply(SPVM::File::Spec->path->to_strings, [File::Spec->path]);
}

# tmpdir
{
  {
    is(SPVM::File::Spec->tmpdir, File::Spec->tmpdir);
  }
}

# Instance
{
  ok(SPVM::TestCase::File::Spec::Instance::Unix->canonpath);

  ok(SPVM::TestCase::File::Spec::Instance::Unix->catdir);

  ok(SPVM::TestCase::File::Spec::Instance::Unix->catfile);

  ok(SPVM::TestCase::File::Spec::Instance::Unix->no_upwards);

  ok(SPVM::TestCase::File::Spec::Instance::Unix->join);

  ok(SPVM::TestCase::File::Spec::Instance::Unix->catpath);

  ok(SPVM::TestCase::File::Spec::Instance::Unix->splitpath);

  ok(SPVM::TestCase::File::Spec::Instance::Unix->rel2abs);

  ok(SPVM::TestCase::File::Spec::Instance::Unix->splitdir);

  ok(SPVM::TestCase::File::Spec::Instance::Unix->abs2rel);
}

# Version
is($SPVM::File::Spec::VERSION, SPVM::Fn->get_version_string('File::Spec'));
done_testing;
