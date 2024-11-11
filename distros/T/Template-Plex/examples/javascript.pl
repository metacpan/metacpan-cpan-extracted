use Template::Plex;
use Test::More;

my $template= q|function (){
{
}

|;

#$template=~s/\#/\\#/g;
my $a=q! asdf\|dfdf!;

say STDERR Template::Plex->immediate(undef, [$template],{});
ok 1;

done_testing;

