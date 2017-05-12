requires 'perl', '5.010001';

# core modules
requires 'Pod::Simple', '3.08';
requires 'List::Util';
requires 'Scalar::Util';
requires 'Pod::Usage';

# additional modules
requires 'JSON';
requires 'Hash::MultiValue', '0.06';
requires 'Pandoc', '0.6.0';
requires 'IPC::Run3'; # implied by Pandoc

on test => sub {
    requires 'Test::More', '0.96';
    requires 'Test::Output';
    requires 'Test::Exception';
};
