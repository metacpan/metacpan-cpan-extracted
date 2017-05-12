#!/usr/bin/perl
package Storable::Ref;
use strict;
use Storable;

our $VERSION="1.1";

=head1 NAME

Storable::Ref - Persistent automatic variables vi Storable

=head1 SYNOPSYS

  $ cat >tesy.pl
  use Storable::Ref;
  my $v=new Storable::Ref({a=>1, b=>1},"filename");
  print "a=".($v->{a}++)." b=".($v->{b}*=2)."\n";
  ^D
  $ perl test.pl
  a=1 b=2
  $ for v in 1 2 3; do perl test.pl; done
  a=2 b=4
  a=3 b=8
  a=4 b=16
  rm filename
  $ perl test.pl
  a=1 b=2

L<Storable::Ref> gets your reference to variable and remembers
filename associated with this variable. When you construct
this variable you provide to constructor default value 
and fully qualified filename for storing this it.
If L<Storable::Ref> finds this file and it contains valid
L<Storable> object, it uses this data to initialize variable
with this data instead of default value.

this functionality my be used for storing state of
interuptable scripts, or for saving important information
when script throws die or uncatched exceptions.

=head1 CAUTION

L<Storable::Ref> stores data in method  DESTROY(), and if
thismethod isn't called, saving is not processed.
if yor perl was killed by sig9 or sig11 data will be lost.

=cut


our $storage={};

=head1 METHODS

=head2 new($defaultvalue, $filepath)

constructor rebless variable to L<Storable::Ref>.
So you can't use persistence on blessed variables, yet.

=cut

sub new {
    my ($class, $var, $fname)=@_;
    die "Variable must be a reference" unless ref $var;
    die "File name must be presented" unless $fname and !ref $fname;
    my $tmp;
    $tmp=Storable::retrieve($fname) if -f $fname;
    $var=$tmp if $tmp;
    "$var"=~/\(0x([0-9a-f]+)\)/;
    $storage->{$1}=$fname;
    return bless $var;
}

=head2 savenow()

$variable->savenow() Implicitly stores data,
use it if you convinient to death without of
testating your stuff.

=cut

sub savenow {
    my $self=shift;
    "$self"=~/\(0x([0-9a-f]+)\)/;
    Storable::nstore($self, $storage->{$1});
}

=head2 DESTROY()

This method called automaticaly, when perl intended to
delete variable and clear it memory.
Method recall in memory filename associated with this
variable and stores it to this file.
Works automatically when: 
  $variable=undef;
or variable leaves it scope, or when programm terminates,
but perl data structures is not destroyed.


=cut


sub DESTROY {
    my $self=shift;
    "$self"=~/\(0x([0-9a-f]+)\)/;
    Storable::nstore($self, $storage->{$1});
}

=head1 AUTHOR

Vany Serezhkin <ivan@serezhkin.com> 2009 Yandex.

=cut

1;
