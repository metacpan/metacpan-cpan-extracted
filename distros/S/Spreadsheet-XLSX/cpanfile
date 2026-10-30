requires 'perl', '5.006000';
requires 'Archive::Zip', '1.18';
requires 'Spreadsheet::ParseExcel';

on 'configure' => sub {
    requires 'ExtUtils::MakeMaker';
};

on 'test' => sub {
    requires 'Test::More';
    requires 'Test::Warnings';
    requires 'Test::NoWarnings';
    requires 'File::Temp';
};

on 'develop' => sub {
    requires 'Test::Kwalitee';
};
