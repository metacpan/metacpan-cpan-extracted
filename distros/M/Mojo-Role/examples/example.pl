#!perl

use 5.10.0;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/t/lib";


# People class
# is Developer 
# does 'MojoCoreMantainer' and 'PerlCoreMantainer'
package People {
  use Mojo::Base 'Developer';

  # load roles
  use Mojo::Role -with;
  with 'MojoCoreMantainer';
  with 'PerlCoreMantainer';
  

  sub what_can_i_do {
    my $self = shift;
    say "I can do people things...";
    $self->make_code;
    $self->mantaining_mojo;
    $self->mantaining_perl;
  }
}

my $p = People->new;
$p->what_can_i_do;


