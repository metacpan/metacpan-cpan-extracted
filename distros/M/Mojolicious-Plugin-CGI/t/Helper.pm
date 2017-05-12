package t::Helper;
use Mojo::Base -strict;

use File::Basename;
use File::Spec::Functions qw(catdir catfile);
use Mojolicious;
use Mojo::Loader;
use Test::Mojo;
use Test::More;

sub cgi_script {
  my $template = shift;
  my $script = catfile 't', 'cgi-bin', $template;
  mkdir catdir qw(t cgi-bin);
  open my $CGI_BIN, '>', $script or Test::More::plan(skip_all => "write $script: $!");
  print $CGI_BIN "#!$^X\n";
  print $CGI_BIN "use strict;\nuse warnings;\n";
  print $CGI_BIN Mojo::Loader::data_section(__PACKAGE__, $template);
  close $CGI_BIN;
  eval { chmod 0755, $script };
  return $script;
}

sub import {
  my $class  = shift;
  my $caller = caller;

  Test::More::plan(skip_all => 'Skipping tests on Windows.') if $^O eq 'Win32';

  eval <<"HERE";
package $caller;
use Mojo::Base -strict;
use Test::Mojo;
use Test::More;
HERE

  Mojo::Util::monkey_patch($caller => cgi_script => \&cgi_script);
}

1;

__DATA__
@@ basic.pl
print "Content-Type: text/custom\n\r\n\rbasic stuff\n";
@@ env
print "Content-Type: text/plain\n\r";
print "\n\rENVIRON";
print "MENT\n";
print "$_=$ENV{$_}\n" for sort keys %ENV;
@@ env.cgi
print "Content-Type: text/plain\n\r";
print "\n\rENVIRON";
print "MENT\n";
print "$_=$ENV{$_}\n" for sort keys %ENV;
@@ errlog
warn "yikes!";
print "Content-Type: text/plain\n\r\n\r";
print "yayayyaya\n";
@@ file_upload
print "Content-Type: text/custom\n\r\n\r";
print "$$\n";
print "=== $ENV{$_}\n" for qw/CONTENT_TYPE CONTENT_LENGTH/;
print "--- $_" while <STDIN>;
@@ not-found.pl
print "Status: 404 Not Found\r\n";
print "Content-Type: text/html; charset=ISO-8859-1\r\n";
print "\r\n";
print "<body><p>This page is missing\n";
@@ not-modified.pl
print "Status: 304 Not Modified\r\n";
print "X-Test: if-none-match seen: $ENV{HTTP_IF_NONE_MATCH}\r\n";
print "\r\n";
@@ nph-borked.pl
# When SERVER_PROTOCOL is set to "HTTP", the CGI module will just print HTTP and
# no version!
print "HTTP 403 Payment Required\r\n";
print "Content-Type: text/html; charset=ISO-8859-1\r\n";
print "\r\n";
print "<body><p>This is the borked paywall.\n";
@@ nph.pl
print "HTTP/1.1 403 Payment Required\r\n";
print "Content-Type: text/html; charset=ISO-8859-1\r\n";
print "\r\n";
print "<body><p>This is the paywall.\n";
@@ postman
print "Content-Type: text/custom\n\r\n\r";
print "$$\n";
print "--- $_" while <STDIN>;
@@ redirect.pl
print "Location: http://somewhereelse.com\n\r\n\r";
@@ slow.pl
sleep 1;
print "Content-Type: text/custom\n\r\n\rHello Morbo!\n";
