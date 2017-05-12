use inc::Module::Install;

name           'Parse-CSV-Colnames';
all_from       'lib/Parse/CSV/Colnames.pm';
requires       'Carp'         => 0;
requires       'IO::File'     => 0;
requires       'Text::CSV_XS' => '0.23';
requires       'Params::Util' => '0.17';
requires       'Parse::CSV'   => '1.00';
build_requires 'File::Spec'   => '0.80';
build_requires 'Test::More'   => '0.47';
keywords "columns","field name","fieldnames","columnname","columnnames";

WriteAll;
