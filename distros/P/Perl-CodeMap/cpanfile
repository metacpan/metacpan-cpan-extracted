requires 'perl', '5.020';
requires 'JSON::PP';
requires 'Pod::Usage';
recommends 'PPI', '1.291';
on 'test' => sub {
    requires 'Test::More';
    requires 'File::Temp';
    requires 'Pod::Simple';
};
on 'develop' => sub {
    requires 'Test::Pod';
    requires 'Test::Pod::Coverage';
};
