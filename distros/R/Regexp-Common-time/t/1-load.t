
use Test::More tests => 1;
BEGIN { use_ok('Regexp::Common::time') };


# code taken from the module itself:
my $can_posix  = 0;
my $can_locale = 0;
eval
{
    $can_posix = 0;
    require POSIX;
    $can_posix = 1;
};
eval
{
    $can_locale = 0;
    require I18N::Langinfo;
    I18N::Langinfo->import(qw(langinfo));
    $can_locale = 1;
};
diag "POSIX: $can_posix";
diag "I18N:  $can_locale";

