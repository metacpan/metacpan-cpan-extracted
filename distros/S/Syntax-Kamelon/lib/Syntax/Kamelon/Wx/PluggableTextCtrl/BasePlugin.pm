package Syntax::Kamelon::Wx::PluggableTextCtrl::BasePlugin;

use strict;
use warnings;
use Carp;

use vars qw($VERSION);
$VERSION="0.01";

my $debug = 0;

if ($debug) {
   use Data::Dumper;
}

sub new {
   my $proto = shift;
   my $class = ref($proto) || $proto;
   my $txtctrl = shift;
   my $self = {};
   $self->{TXTCTRL} = $txtctrl;
   $self->{COMMANDS} = {};

   bless ($self, $class);

   return $self;
}

sub Broadcast {
   my $self = shift;
   return $self->TxtCtrl->Broadcast(@_);
}

sub Command {
   my $self = shift;
   my $name = shift;
   if (@_) { $self->{COMMANDS}->{$name} = shift }
   return $self->{COMMANDS}->{$name}
}

sub Commands {
   my $self = shift;
   $self->{COMMANDS} = {};
   while (@_) {
      my $name = shift; my $call = shift;
      if ($debug) { print "setting command $name\n"; }
      $self->{COMMANDS}->{$name} = $call;
   }
}

sub Name {
   my $self = shift;
   my $name = ref $self;
   $name =~s/.*:://;
   if ($debug) { print "plugin name is $name\n" }
   return $name
}

sub Receive {
   my $self = shift;
   my $name = shift;
   if ($debug) { print "received $name\n"; print Dumper $self->{COMMANDS} }
   if (exists $self->{COMMANDS}->{$name}) {
      if ($debug) { print "executing $name\n" }
      my $cmd = $self->Command($name);
      return &$cmd($self, @_);
   }
   return 0
}

sub Require {
   my $self = shift;
   my $tc = $self->TxtCtrl;
   while (@_) {
      my $m = shift;
      if ($debug) { print "Requiring $m\n" }
      unless (defined($tc->FindPluginId($m))) {
         $tc->LoadPlugin($m);
      }
   }
}

sub TxtCtrl {
   my $self = shift;
   if (@_) { $self->{TXTCTRL} = shift; }
   return $self->{TXTCTRL};
}

1;
__END__