package MooXTestBla;
use MooX::HasEnv;

has_env bla => MOOX_HAS_ENV_TEST_BLA => 'blub';
has_env blaover => MOOX_HAS_ENV_TEST_BLAOVER => 'blubover';
has_env blabla => undef, 'blubblub';
has_env over => MOOX_HAS_ENV_TEST_OVER => 'never be';
has_env nodefault => 'MOOX_HAS_ENV_TEST_NODEFAULT';
has_env zerotest => MOOX_HAS_ENV_ZEROTEST => "1";
has_env zerodef => undef, "0";

1;