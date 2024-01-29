use strict;
use warnings;
use Template::Plex;
use Test::More;
#use Data::Dumper;
#use feature ":all";


{
  my $template="hello";
  my $t=Template::Plex->load([$template],{});
  ok(defined($t), "Load relative literal");
  #say STDERR Dumper $t->meta;
}

{
  my $t=Template::Plex->load(\"sub1.plex",{});
  ok(defined($t), "Load relative file path");
  #say STDERR Dumper $t->meta;
}
done_testing;

