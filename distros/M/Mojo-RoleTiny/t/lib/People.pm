package People;
use Mojo::Base 'Developer';

# using roles
use Mojo::RoleTiny -with;
with 'MojoCoreMantainer';
with 'PerlCoreMantainer';


sub what_can_i_do {
  my $self = shift;
  say "I can do people things...";
  $self->make_code;
  $self->mantaining_mojo;
  $self->mantaining_perl;
}

1;

