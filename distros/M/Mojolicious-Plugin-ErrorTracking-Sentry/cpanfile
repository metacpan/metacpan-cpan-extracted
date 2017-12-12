requires 'perl', '5.008001';
requires 'Mojolicious', '== 4.86';
requires 'Sentry::Raven', '== 1.10';
requires 'Data::Dump', '1.22';

on 'develop' => sub {
    requires "Minilla";
    requires "Version::Next";
    requires "CPAN::Uploader";
    requires 'Software::License';
};

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Mock::Guard' => '0.10';
};
