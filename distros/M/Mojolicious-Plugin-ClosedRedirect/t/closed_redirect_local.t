use strict;
use warnings;
use Test::More;
use Mojolicious::Plugin::ClosedRedirect;
use Mojo::URL;

my $l_url = \&Mojolicious::Plugin::ClosedRedirect::_local_path;

# Testsuite from
# http://blog.michaelhidalgo.info/2015/10/preventing-open-redirects-attacks-in.html
# http://example.com/view_topic?view=//www.qualys.com
ok(!$l_url->(''), 'Empty URL');
ok(!$l_url->('//a/..'), '//a/..');
ok(!$l_url->('//a'), '//a');
ok(!$l_url->('/\\abc'), '/\\abc');
ok(!$l_url->('https://foo/bar'), 'https://foo/bar');
ok(!$l_url->('http://foo/bar'), 'http://foo/bar');
ok(!$l_url->('foo/bar'), 'foo/bar');
ok(!$l_url->('file:///c:/path/to/the%20f.txt'), 'file:///c:/path/to/the%20f.txt');
ok(!$l_url->('////host/share/dir/file.txt'), '////host/share/dir/file.txt');
ok(!$l_url->('null'), 'null');
ok($l_url->('%2fAccount%2fChangePassword%2f'), '%2fAccount%2fChangePassword%2f');
ok($l_url->('~/foo/bar'), '~/foo/bar');
ok($l_url->('/foo/bar'), '/foo/bar');

# Reported at https://www.redmine.org/issues/19577
# Check ?back_url=/attacker.com
# Check ?back_url=@attacker.com
ok(!$l_url->('//test.foo/fake'), '//test.foo/fake');
ok(!$l_url->('http://test.host//fake'),'http://test.host//fake');
ok(!$l_url->('http://test.host/\n//fake'),'http://test.host/\n//fake');
ok(!$l_url->('//bar@test.foo'),'//bar@test.foo');
ok(!$l_url->('//test.foo'),'//test.foo');
ok(!$l_url->('////test.foo'),'////test.foo');
ok(!$l_url->('@test.foo'),'@test.foo');
ok(!$l_url->('fake@test.foo'), 'fake@test.foo');

done_testing;
__END__
