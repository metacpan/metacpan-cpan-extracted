#!/usr/local/bin/perl -w

use Resources;

package Foo;

%Resources = ( zero=> [0], one => [1],  two => [2], lack=>[888] );

sub new { 
   my $class=shift;
   my $res=shift;
   my $self = bless({}, $class);
   $res = new Resources unless $res;
   warn "Mergin in Foo class $class";
   $res->merge($class);
   my ($n, $v, $d) = $res->byclass($self, "zero");

   $self->{Color}=$res->valbyclass($self, "zero");
   $self;
}

package Gop;
@ISA = qw ( Foo );
%Resources = ( two => [22], four=>[4], one=>[111]); 

package Bar;
@ISA = qw ( Foo );
%Resources = ( zero=>[1010], two => [222], five=>[5], 'gop.zero'=>[99]); 

sub new {
   my ($type, $res) = @_;
   warn "Mergin in Bar class $type";
   $res->merge($type, qw(Gop));
   my $self = bless new Foo($res);
   $self->{Gop} = new Gop($res);
   $self;
}
      
package main;
$res=new Resources;

$bar = new Bar($res);
$res=$res->edit();
$res->view();

