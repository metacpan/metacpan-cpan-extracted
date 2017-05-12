use Test::More tests => 22;

BEGIN {
use_ok( 'Perl::ImportReport' );
}

diag( "Testing Perl::ImportReport $Perl::ImportReport::VERSION" );

my $test = <<'END_PM';
use Carp;

package PM_test;

use This::Shall::Pass "yo","howdy",'!$skip', '@foo';
use CGI;
use CGI 'header';
use CGI 1.0;
use CGI 1.0, qw(url);
use CGI 1.0 ();
use CGI ("param",1.0);

use CGI 1.0 'url';

use CGI "";

use CGI qw(:netscape);

use CGI qw(:netscape !center);

use CGI qw(header !header);

use File::Slurp qw(/slurp/);

use File::Slurp qw(slurp !/slurp/);

use File::Slurp qw(/slurp/);

package XYZ;

use CGI "encodeHTML", 1.0;
package ABC;use File::Slurp 1.0;package Foo;
use CGI ();

package PM_test;

use Path::Iter;

use CGI qw();
END_PM

ok(!Perl::ImportReport->new(), "bad args returns false");

my $iro = Perl::ImportReport->new(\$test);
ok(ref($iro) eq 'Perl::ImportReport','new() from scalar');

my $data = $iro->get_import_report();
diag($data->{'number_of_includes'});
ok($data->{'number_of_includes'} == 18, 'number_of_includes');

# TODO: do these specifically and better (e.g. find EXPORTS and keep that key, test error for value when we know it will fail, etc) instead of machine generated

for (0 .. 17) {
    delete $data->{'imports'}[$_]->{'arguments'}; # object's, not really used TODO: test ref() and count is N
    delete $data->{'imports'}[$_]->{'exporter'};  # what if a module being used changes, this test would fail
    delete $data->{'imports'}[$_]->{'symbol_list'}; # what if a module being used changes, this test would fail
}


is_deeply({
          'line_number' => 1,
          'module_version' => undef,
          'raw_perl' => 'use Carp;',
          'in_package' => 'main',
          'module' => 'Carp'
}, $data->{'imports'}[0], 'TODO NAME');



is_deeply({
          'line_number' => 5,

          'module_version' => undef,
          'raw_perl' => 'use This::Shall::Pass "yo","howdy",\'!$skip\', \'@foo\';',
          'in_package' => 'PM_test',
          'module' => 'This::Shall::Pass'
}, $data->{'imports'}[1], 'TODO NAME');



is_deeply({
          'line_number' => 6,

          'module_version' => undef,
          'raw_perl' => 'use CGI;',
          'in_package' => 'PM_test',
          'module' => 'CGI'
}, $data->{'imports'}[2], 'TODO NAME');



is_deeply({
          'line_number' => 7,

          'module_version' => undef,
          'raw_perl' => 'use CGI \'header\';',
          'in_package' => 'PM_test',
          'module' => 'CGI'
}, $data->{'imports'}[3], 'TODO NAME');



is_deeply({
          'line_number' => 8,

          'module_version' => '1.0',
          'raw_perl' => 'use CGI 1.0;',
          'in_package' => 'PM_test',
          'module' => 'CGI'
}, $data->{'imports'}[4], 'TODO NAME');



is_deeply({
          'line_number' => 9,

          'module_version' => undef,
          'raw_perl' => 'use CGI 1.0, qw(url);',
          'in_package' => 'PM_test',
          'module' => 'CGI'
}, $data->{'imports'}[5], 'TODO NAME');



is_deeply({
          'line_number' => 11,

          'module_version' => undef,
          'raw_perl' => 'use CGI ("param",1.0);',
          'in_package' => 'PM_test',
          'module' => 'CGI'
}, $data->{'imports'}[6], 'TODO NAME');



is_deeply({
          'line_number' => 13,

          'module_version' => '1.0',
          'raw_perl' => 'use CGI 1.0 \'url\';',
          'in_package' => 'PM_test',
          'module' => 'CGI'
}, $data->{'imports'}[7], 'TODO NAME');



is_deeply({
          'line_number' => 15,

          'module_version' => undef,
          'raw_perl' => 'use CGI "";',
          'in_package' => 'PM_test',
          'module' => 'CGI'
}, $data->{'imports'}[8], 'TODO NAME');



is_deeply({
          'line_number' => 17,

          'module_version' => undef,
          'raw_perl' => 'use CGI qw(:netscape);',
          'in_package' => 'PM_test',
          'module' => 'CGI'
}, $data->{'imports'}[9], 'TODO NAME');



is_deeply({
          'line_number' => 19,

          'module_version' => undef,
          'raw_perl' => 'use CGI qw(:netscape !center);',
          'in_package' => 'PM_test',
          'module' => 'CGI'
}, $data->{'imports'}[10], 'TODO NAME');



is_deeply({
          'line_number' => 21,

          'module_version' => undef,
          'raw_perl' => 'use CGI qw(header !header);',
          'in_package' => 'PM_test',
          'module' => 'CGI'
}, $data->{'imports'}[11], 'TODO NAME');



is_deeply({
          'line_number' => 23,

          'module_version' => undef,
          'raw_perl' => 'use File::Slurp qw(/slurp/);',
          'in_package' => 'PM_test',
          'module' => 'File::Slurp'
}, $data->{'imports'}[12], 'TODO NAME');



is_deeply({
          'line_number' => 25,

          'module_version' => undef,
          'raw_perl' => 'use File::Slurp qw(slurp !/slurp/);',
          'in_package' => 'PM_test',
          'module' => 'File::Slurp'
}, $data->{'imports'}[13], 'TODO NAME');



is_deeply({
          'line_number' => 27,

          'module_version' => undef,
          'raw_perl' => 'use File::Slurp qw(/slurp/);',
          'in_package' => 'PM_test',
          'module' => 'File::Slurp'
}, $data->{'imports'}[14], 'TODO NAME');



is_deeply({
          'line_number' => 31,

          'module_version' => undef,
          'raw_perl' => 'use CGI "encodeHTML", 1.0;',
          'in_package' => 'XYZ',
          'module' => 'CGI'
}, $data->{'imports'}[15], 'TODO NAME');



is_deeply({
          'line_number' => 32,

          'module_version' => '1.0',
          'raw_perl' => 'use File::Slurp 1.0;',
          'in_package' => 'ABC',
          'module' => 'File::Slurp'
}, $data->{'imports'}[16], 'TODO NAME');



is_deeply({
          'line_number' => 37,

          'module_version' => undef,
          'raw_perl' => 'use Path::Iter;',
          'in_package' => 'PM_test',
          'module' => 'Path::Iter'
}, $data->{'imports'}[17], 'TODO NAME');
