requires 'perl', '5.008005';

requires 'Cwd';
requires 'File::Temp';
requires 'HTTP::Headers';
requires 'HTTP::Request::Common';
requires 'LWP';
requires 'Pod::Usage';
requires 'Term::ReadKey';
requires 'Term::ReadLine';
requires 'Text::ParseWords';
requires 'Time::Local';

feature 'httpauth' => 'HTTP basic authentication support', sub {
    requires 'GSSAPI';
    requires 'LWP::Authen::Negotiate';
};

on test => sub {
    requires 'Test::More', '0.88';
};
