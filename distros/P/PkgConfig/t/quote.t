use strict;
use warnings;
use PkgConfig;
use FindBin ();
use File::Spec;
use Test::More tests => 6;

my $path = File::Spec->catdir($FindBin::Bin, 'data', 'quote');

foreach my $type (qw( doublequote singlequote backslash quotevar ))
{
  subtest $type => sub {

    my $pkg = PkgConfig->find($type,
      search_path => [File::Spec->catdir($FindBin::Bin, 'data', 'quote')],
    );

    isa_ok $pkg, 'PkgConfig';
    is $pkg->errmsg, undef, 'no error';

    is_deeply [$pkg->get_cflags], ['-I/foo/include', '-DFOO=bar baz'], "$type list context";
    is scalar $pkg->get_cflags, '-I/foo/include "-DFOO=bar baz"', "$type scalar context";
    #note $_ for $pkg->get_cflags;
    done_testing;
  };
}

subtest 'noquote' => sub {
  my $pkg = PkgConfig->find('noquote',
    search_path => [File::Spec->catdir($FindBin::Bin, 'data', 'quote')],
  );

  isa_ok $pkg, 'PkgConfig';
  is $pkg->errmsg, undef, 'no error';

  is_deeply [$pkg->get_cflags], ['-I/foo/include', '-DFOO=bar'], 'list context';
  is scalar $pkg->get_cflags, '-I/foo/include -DFOO=bar', 'scalar context';
  done_testing;
};

subtest 'escape' => sub {
  my $pkg = PkgConfig->find('escape',
    search_path => [File::Spec->catdir($FindBin::Bin, 'data', 'quote')],
  );

  isa_ok $pkg, 'PkgConfig';
  is $pkg->errmsg, undef, 'no error';

  is_deeply [$pkg->get_cflags], ['-I/foo/include', '-DFOO="bar_baz"'], 'list context';
  is scalar $pkg->get_cflags, '-I/foo/include -DFOO=\\"bar_baz\\"', 'scalar context';
  done_testing;
};
