requires 'Moo';
requires 'String::ShellQuote';
requires 'IPC::Open3::Simple';
requires 'Net::OpenSSH';
requires 'IO::Pty';

on 'test' => sub {
    requires 'Test::Most';
    requires 'Test::Fatal';
};

on 'build' => sub {
    requires 'Test::MinimumVersion::Fast';
    requires 'Test::Pod';
};

on 'develop' => sub {
    requires 'Minilla';
};
