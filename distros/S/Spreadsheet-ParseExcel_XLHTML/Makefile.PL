use inc::Module::Install 0.91;

name     'Spreadsheet-ParseExcel_XLHTML';
all_from 'lib/Spreadsheet/ParseExcel_XLHTML.pm';

test_requires 'Test::More';
test_requires 'Spreadsheet::WriteExcel';

requires 'Spreadsheet::ParseExcel';
requires 'HTML::Entities';

requires_external_bin 'xlhtml';

resources repository =>
    'git://github.com/rkitover/spreadsheet-parseexcel-xlhtml.git';

if ($Module::Install::AUTHOR) {
    system('pod2text lib/Spreadsheet/ParseExcel_XLHTML.pm > README');
}

realclean_files 'README';

auto_provides;
auto_install;
WriteAll;
