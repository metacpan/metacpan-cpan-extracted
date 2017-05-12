use Test::More tests => 4;

BEGIN {
    use_ok 'MojoX::Session::Store::File';
    use_ok 'MojoX::Session::Store::File::Driver';
    use_ok 'MojoX::Session::Store::File::Driver::Storable';
    use_ok 'MojoX::Session::Store::File::Driver::FreezeThaw';
}
