use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../";
use Test::More;
use t::Util;

plan skip_all => "requires \$ENV{PERL_PRNQL_TEST_NETWORK} to test" unless $ENV{PERL_PRNQL_TEST_NETWORK};

plan skip_all => "requires CPAN::Common::Index" unless eval "require CPAN::Common::Index";

test_app('exclude submodules', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/MyTest.pm", <<'END');
use strict;
use warnings;
use Acme::CPANAuthors;
use Acme::CPANAuthors::Utils;
END
}, {use_index => "Mirror"}, { runtime => { requires => { strict => 0, warnings => 0, 'Acme::CPANAuthors' => 0 }}});

test_app('modules under different namespaces that belong to the same distribution', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/MyTest.pm", <<'END');
use Mojo::Base;
END

  test_file("$tmpdir/MyTest2.pm", <<'END');
use Mojolicious;
END
}, {use_index => "Mirror"}, { runtime => { requires => { 'Mojolicious' => 0 }}});

test_app('modules under different namespaces (same depth) that belong to the same distribution', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/MyTest.pm", <<'END');
use Mojo::Base;
END

  test_file("$tmpdir/MyTest2.pm", <<'END');
use Mojolicious::Lite;
END
}, {use_index => "Mirror"}, { runtime => { requires => { 'Mojo::Base' => 0 }}});

test_app('versioned modules', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/MyTest.pm", <<'END');
use Mojo::Base 7.00;
END

  test_file("$tmpdir/MyTest2.pm", <<'END');
use Mojolicious::Lite 8.00;
END
}, {use_index => "Mirror"}, { runtime => { requires => { 'Mojo::Base' => '7.00', 'Mojolicious::Lite' => '8.00' }}});

test_app('versioned module plus unversioned', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/MyTest.pm", <<'END');
use Mojo::Base;
END

  test_file("$tmpdir/MyTest2.pm", <<'END');
use Mojolicious::Lite 8.00;
END
}, {use_index => "Mirror"}, { runtime => { requires => { 'Mojolicious::Lite' => '8.00' }}});

done_testing;
