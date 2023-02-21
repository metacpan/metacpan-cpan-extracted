requires 'perl', '5.020';
requires 'Imager', '>= 1.019';
requires 'Mojolicious', '>= 9.31';

requires 'Alien::Font::Vera', '>= 0.013';

on 'develop' => sub {
    recommends 'Devel::Camelcadedb';
};

on 'test' => sub {
    requires 'Test::More';
    requires 'Test::Directory';
    requires 'File::Find::Rule';
}