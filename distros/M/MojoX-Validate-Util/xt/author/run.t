use Test::More tests => 1;

# ------------------------

my($url)      = 'http://127.0.0.1/Novels-etc.html';
my(@result)   = `$^X bin/validate.head.links.pl -d /run/shm/html -max debug -u $url`;
my($result)   = join('', @result);
my($expected) = <<EOS;
URL: $url
 Import: /run/shm/html/assets/js/DataTables-1.9.4/media/css/demo_page.css
 Import: /run/shm/html/assets/js/DataTables-1.9.4/media/css/demo_table.css
 Script: /run/shm/html/assets/js/DataTables-1.9.4/media/js/jquery.js
 Script: /run/shm/html/assets/js/DataTables-1.9.4/media/js/jquery.dataTables.min.js
Imports: 2. Errors: 0
  Links: 0. Errors: 0
Scripts: 2. Errors: 0
EOS

diag @result;

is_deeply($result, $expected, "Checked $url has no errors");
