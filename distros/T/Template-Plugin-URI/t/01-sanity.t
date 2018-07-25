#!perl

use strict;
use warnings;

use Test::More (tests => 16);
use lib 'lib';

BEGIN
{
    use_ok("Template::Plugin::URI");
}

use Template;

my $uri;
my $uri2;
my $output;

my $tt = Template->new({ PRE_CHOMP  => 1, POST_CHOMP => 1 });
my $template = <<EOL;
[% USE uri = URI('foo/bar') %]
[% uri %]
EOL

$tt->process(\$template, undef, \$output);
$uri = URI->new('foo/bar');
is($output, $uri->as_string);

$output = '';
$template = <<EOL;
[% USE uri = URI('foo/bar','https') %]
[% uri %]
EOL
$tt->process(\$template, undef, \$output);
$uri = URI->new('foo/bar','https');
is($output, $uri->as_string);

$output = '';
$template = <<EOL;
[% USE uri = URI('http://www.perl.com') %]
[% USE uri2 = URI('foo','http') %]
[% uri3 = uri2.abs(uri) %]
[% uri3 %]
EOL
$tt->process(\$template, undef, \$output);
my $u1 = URI->new("http://www.perl.com");
my $u2 = URI->new("foo", "http");
my $u3 = $u2->abs($u1);
is($output, $u3->as_string);

$output = '';
$template = <<EOL;
[% USE uri = URI('foo/bar','https://google.com', new_abs = 1) %]
[% uri %]
EOL
$tt->process(\$template, undef, \$output);
$uri = URI->new_abs('foo/bar','https://google.com'); 
is($output, $uri->as_string);

$output = '';
$template = <<EOL;
[% USE uri = URI('https://google.com') %]
[% uri.canonical %]
EOL
$tt->process(\$template, undef, \$output);
$uri = URI->new('https://google.com')->canonical;
is($output, $uri->as_string);

$output = '';
$template = <<EOL;
[% USE uri = URI('http://www.perl.com') %]
[% uri.scheme %]
EOL
$tt->process(\$template, undef, \$output);
$uri = URI->new('http://www.perl.com');
is($output, $uri->scheme);

$output = '';
$template = <<EOL;
[% USE uri = URI('http://www.perl.com') %]
[% uri.opaque %]
EOL
$tt->process(\$template, undef, \$output);
$uri = URI->new('http://www.perl.com');
is($output, $uri->opaque);

$output = '';
$template = <<EOL;
[% USE uri = URI('foo/bar','file') %]
[% uri.file('mac') %]
EOL
$tt->process(\$template, undef, \$output);
$uri = URI->new('foo/bar','file');
is($output, $uri->file('mac'));

$output = '';
$template = <<EOL;
[% USE uri = URI('foo/bar','file') %]
[% uri.file('win32') %]
EOL
$tt->process(\$template, undef, \$output);
$uri = URI->new('foo/bar','file');
is($output, $uri->file('win32'));

$output = '';
$template = <<EOL;
[% USE uri = URI('http://www.perl.com') %]
[% uri.path("cpan/") %]
[% uri %]
EOL
$tt->process(\$template, undef, \$output);
$uri = URI->new('http://www.perl.com');
$uri->path('cpan/');
is($output, $uri->as_string);

$output = '';
$template = <<EOL;
[% USE uri = URI('http://www.perl.com') %]
[% uri.fragment("test") %]
[% uri %]
EOL
$tt->process(\$template, undef, \$output);
$uri = URI->new('http://www.perl.com');
$uri->fragment('test');
is($output, $uri->as_string);

$output = '';
$template = <<EOL;
[% USE uri = URI('http://www.perl.com') %]
[% uri.path_query("test") %]
[% uri %]
EOL
$tt->process(\$template, undef, \$output);
$uri = URI->new('http://www.perl.com');
$uri->path_query('test');
is($output, $uri->as_string);

$output = '';
$template = <<EOL;
[% USE uri = URI('http://www.perl.com') %]
[% uri2 = uri.clone %]
[% uri2 %]
EOL
$tt->process(\$template, undef, \$output);
$uri = URI->new('http://www.perl.com');
$uri2 = $uri->clone();
is($output, $uri->as_string);

$output = '';
$template = <<EOL;
[% USE uri = URI('https://google.com/слава-україні') %]
[% uri.as_iri %]
EOL
$tt->process(\$template, undef, \$output);
$uri = URI->new('https://google.com/слава-україні');
is($output, $uri->as_iri);

$output = '';
$template = <<EOL;
[% USE uri = URI('https://google.com/') %]
[% uri.query_form('test' = 1, 'test2' = 10) %]
[% uri %]
EOL
$tt->process(\$template, undef, \$output);
$uri = URI->new('https://google.com/');
$uri->query_form('test' => 1, 'test2' => 10);
is($output, $uri->as_string);