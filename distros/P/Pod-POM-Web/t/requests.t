#!perl

use strict;
use warnings;
use Plack::Test;
use HTTP::Request::Common; # for building GET requests to the Plack handler
use Test::More;
use Pod::POM::Web;

diag( "Testing Pod::POM::Web $Pod::POM::Web::VERSION, Perl $], $^X" );

# instantiate the app
my $app = Pod::POM::Web->app;

# start testing
test_psgi $app, sub {
  my $cb = shift;

  # utility function
  my $response_like = sub {my ($req, $expected_content, $tst_name) = @_;
                           my $res = $cb->(GET $req);
                           like $res->content, $expected_content, $tst_name};

  # main entry point (frameset)
  $response_like->("",       qr/frameset/, "frameset 1");
  $response_like->("/",      qr/frameset/, "frameset 2");
  $response_like->("/index", qr/frameset/, "frameset 3");

  # module source
  $response_like->("/source/Pod/POM/Web", qr/Source of Pod::POM::Web/, "source 1");
  $response_like->("/source/Pod/POM/Web", qr/\bserve_source/,          "source 2");

  # lib files
  $response_like->("/Pod/POM/Web/lib/PodPomWeb.css",    qr/BODY, TD/,      "lib 1");
  $response_like->("/Alien/GvaScript/lib/GvaScript.js", qr/var GvaScript/, "lib 2");

  # module documentation
  $response_like->("/Plack", qr/Perl Superglue for Web frameworks/, "module 1");
  $response_like->("/Plack", qr/\(v\. \d\.\d+, installed \d\d/,     "module version and date");

  # script
  $response_like->("/script/plackup", qr/plackup is a command line utility/, "script");

  # wrong module
  $response_like->("/Foo/Bar/Bar", qr/could not be found/, "no such module");

  # main pod entry ("perl") - hyperlinks to man pages
  $response_like->("/perl",   qr[<a href="/perlfunc">], "link to perlfunc from perl main page");

  # perlfunc, special handling for the whole page, and excerpts through /search
  SKIP: {
    my ($funcpod) = find_source("perlfunc")
      or skip "no perlfunc on this system";

    $response_like->("/perlfunc",   qr/<li id="fcntl">/,                "fcntl in perlfunc");
    $response_like->("/search?source=perlfunc&search=shift", qr/array/, "shift in search perlfunc");
  }

  # table of contents -- list of modules under a given prefix
  $response_like->("/toc/Plack", qr/Builder.*?Component.*Handler/s, "toc/Plack");

  # table of contents - perldocs
  $response_like->("/toc/perldocs", qr/Reference.*?perldata.*?perldebug/s, "toc/perldocs");

  # table of contents - pragmas
  $response_like->("/toc/pragmas", qr/\bstrict.*?warnings/s, "toc/pragmas");

  # table of contents - scripts
  $response_like->("/toc/scripts", qr/\bplackup/s, "toc/scripts");

  # search in perlvar
  SKIP: {
    my ($varpod) = find_source("perlvar")
      or skip "no perlvar on this system";

    $response_like->("/search?source=perlvar&search=\@ARGV",  qr/\@ARGV/, "search in perlvar");
  }

  # search in perlfaq
  SKIP: {
    my ($faqpod) = find_source("perlfaq")
      or skip "no perlfaq on this system";
    $response_like->("/search?source=perlfaq&search=array",  qr/array/, "search in perlfaq");
  }

};

# signal end of tests
done_testing;



sub find_source {
  my ($path) = @_;

  my $obj = Pod::POM::Web->new;
  return $obj->find_module($path);
}
