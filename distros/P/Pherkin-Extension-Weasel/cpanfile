#!perl


requires 'perl', '5.10.1';

requires 'File::Find::Rule';
requires 'File::Share';
requires 'Module::Runtime';
requires 'Moose';
requires 'Template';
requires 'Test::BDD::Cucumber';
requires 'Weasel', '0.30';
requires 'Weasel::Session', '0.30';
# depend on the same YAML library as Test::BDD::Cucumber
requires 'YAML', '0.15';


on test => sub {
    requires 'Test::More';
    requires 'Carp::Always';
    requires 'Weasel::Driver::Mock', '0.02';
};
