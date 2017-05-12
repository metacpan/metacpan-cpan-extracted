requires 'Plack';
requires 'Plack::Middleware::Debug';
requires 'Text::Markdown';
requires 'Text::MicroTemplate';

on build => sub {
    requires 'ExtUtils::MakeMaker', '6.36';
};

on test => sub {
    requires 'Test::MockObject::Extends';
    requires 'Test::Most';
    requires 'File::Tempdir';
    requires 'Test::MockModule';
};
