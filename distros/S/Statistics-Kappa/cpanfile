requires warnings => 0;
requires strict => 0;
requires Moo => 0;
requires experimental => 0;
requires 'List::Util' => 0;
requires 'namespace::clean' => 0;

on configure => sub {
   requires 'ExtUtils::MakeMaker' => 0;
};

on build => sub {
   requires 'Test::More' => 0;
   requires 'FindBin' => 0;
};

on develop => sub {
   requires 'Test::CheckManifest' => '0.9';
};