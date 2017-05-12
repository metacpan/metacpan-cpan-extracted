requires 'AnyEvent';
requires 'AnyEvent::Filesys::Notify';
requires 'File::ShareDir';
requires 'File::Slurp';
requires 'JSON::Any';
requires 'Plack';
requires 'Readonly';

on configure => sub {
    requires 'Module::Build::Tiny', '0.034';
    requires 'perl',                '5.008';
};

on test => sub {
    requires 'HTTP::Request::Common';
    requires 'Test::More';
};

on develop => sub {
    requires 'Test::Kwalitee';
    requires 'Test::Perl::Critic';
};
