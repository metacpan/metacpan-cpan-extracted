use Template::Plex;
use Test::More;

# From  v0.6.4 immediate renders now pass the var argument to the internal
# render call.  It means the %fields variable is now usable in immediate
# templates on repeated calls.
#
my $template1='$a $fields{a}';
my $res1=Template::Plex->immediate("", [$template1], {a=>12});
my $res2=Template::Plex->immediate("", [$template1], {a=>22});

ok $res1 eq "12 12";
ok $res2 eq "12 22";
done_testing;

