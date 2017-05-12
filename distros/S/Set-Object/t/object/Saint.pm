package Saint;

#  `empty subclass' test

use vars qw(@ISA);

@ISA = qw(Person);

sub stringify {

   my $self = shift;

   return "Saint $self->{firstname} $self->{name}";

}

1;
