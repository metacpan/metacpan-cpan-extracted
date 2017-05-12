#
# $Id: 02-kingdom.t,v 0.1 2006/10/25 09:56:04 dankogai Exp $
#
# See http://www.perl.com/pub/a/2006/09/21/onion.html
use strict;
use warnings;
use Object::Prototype;
#use Test::More tests => 1;
use Test::More qw(no_plan);

# Prototype Chain
my $kingdom = Object::Prototype->new( {}, {
    kingdom => sub { "Animalia" }
});
my $phylum = Object::Prototype->new($kingdom, {
    phylum => sub { "Chordata" }
});
my $class = Object::Prototype->new($phylum, {
   class => sub { "Mammalia" }
});
my $order = Object::Prototype->new($class, {
    order => sub { "Primata" } 
});
my $family = Object::Prototype->new($order, {
    family => sub { "Homonidae" } 
});
my $genus = Object::Prototype->new($family, {
    genus => sub { "Homo" } 
});
my $species = Object::Prototype->new($genus, {
     species => sub { "Sapiens" } 
});

is $species->species, "Sapiens";
is $species->genus,   "Homo";
is $species->family,  "Homonidae";
is $species->order,   "Primata";
is $species->class,   "Mammalia";
is $species->phylum,  "Chordata";
is $species->kingdom, "Animalia";

my $php = Object::Prototype->new($species);
$php->prototype( species => sub {  my $o = shift;
    $o->kingdom . $o->phylum . $o->class
   . $o->order  . $o->family . $o->genus
   . $o->constructor->species; # how to access super proto
});
is $php->species, "AnimaliaChordataMammaliaPrimataHomonidaeHomoSapiens";

my $ruby  = Object::Prototype->new($species, {
  class => sub { "Matzalia" }
});			      
is   $ruby->class,    "Matzalia";
isnt $species->class, "Matzalia";
my $python  = Object::Prototype->new($species, {
  order => sub { "Squamata" }
});			      
is   $ruby->genus, $python->genus;
isnt $ruby->order, $python->order;

my $haskell = Object::Prototype->new($species);
$haskell->prototype( genus => sub{ 'MacArthur Genus' } );
is   $haskell->family, $python->family;
isnt $haskell->genus,  $python->genus;

my $javascript = Object::Prototype->new($species);
$javascript->prototype( class => sub{} );
is $javascript->class, undef;
is $javascript->family, $ruby->family;

my $java =  Object::Prototype->new($species, {
    kingdom => sub { 1 },
    phylum  => sub { 0 },
    class   => sub { 0 },
    order   => sub { 0 },
    family  => sub { 0 },
    genus   => sub { 0 },
    species => sub { 1 }
});
ok  $java->kingdom;
ok !$java->phylum;
ok !$java->class;
ok !$java->order;
ok !$java->family;
ok !$java->genus;
ok $java->species;

my $csharp = Object::Prototype->new($java, {
    kingdom => sub { 'K#' },
    phylum  => sub { 'P#' },
    class   => sub { 'C#' },
    order   => sub { 'O#' },
    family  => sub { 'F#' },
    genus   => sub { 'G#' },
    species => sub { 'S#' },
});
like $csharp->kingdom, qr/#/;
like $csharp->phylum,  qr/#/;
like $csharp->class,   qr/#/;
like $csharp->order,   qr/#/;
like $csharp->family,  qr/#/;
like $csharp->genus,   qr/#/;
like $csharp->species, qr/#/;

my $perl = Object::Prototype->new($species);
$perl->prototype( orientation => sub { "whatever" });
is $perl->orientation, 'whatever';
