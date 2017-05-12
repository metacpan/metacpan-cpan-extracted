requires 'Exporter';
requires 'File::Slurp';
requires 'Text::Table';
requires 'List::MoreUtils';
requires 'PadWalker';

on 'test' => sub {
    requires 'Test::More' => '0.98';
    requires 'Test::Requires' =>  0;
    requires 'Test::TCP';
    requires 'Capture::Tiny'   => '0.12';
    requires 'Try::Tiny';
    requires 'Test::Exception';
    requires 'File::Spec';
    requires 'Devel::Cover';
};

on 'develop' => sub {
    requires 'Minilla';
    requires 'Pod::Markdown::Github';
    requires 'Version::Next';
    requires 'CPAN::Uploader';
};
