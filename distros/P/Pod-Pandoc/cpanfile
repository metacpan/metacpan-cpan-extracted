requires 'perl', '5.014';

# core modules
requires 'Pod::Simple', '3.08';
requires 'Pod::Usage';

# additional modules
requires 'Pandoc', '0.6.0';
requires 'Pandoc::Elements', '0.29';
requires 'IPC::Run3'; # already implied by Pandoc

on test => sub {
    requires 'Test::More', '0.96';
    requires 'Test::Output';
    requires 'Test::Exception';
};
