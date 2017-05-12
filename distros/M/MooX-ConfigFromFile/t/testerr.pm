use strict;
use warnings FATAL => "all";

require Role::Tiny;

eval sprintf( <<'EOCDECL', ($main::OO) x 1 );
{
    package #
      Must::Fail;

    use MooX::ConfigFromFile;

    sub new { bless {}, shift }
}

{
    package #
      Already::There;

    use %s;

    sub _initialize_from_config {}

    use MooX::ConfigFromFile;
}
EOCDECL

note $main::OO;

my $mf = Must::Fail->new;
ok( !$mf->can("_initialize_from_config"), "Failed to apply MooX::ConfigFromFile::Role" );

my $ar = Already::There->new;
ok( !Role::Tiny::does_role( $ar, "MooX::ConfigFromFile::Role" ), "Skipped applying MooX::ConfigFromFile::Role" );
