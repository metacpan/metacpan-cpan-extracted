package FakeModule;

use Carp;

sub new {
   my ($class) = @_;
   my $self = {};
   bless ($self, $class);
   return $self;
}

sub mydie {
   die "died and Nagios can detect me";

}

sub mycroak {
   croak "croaked and Nagios can detect me";
}

sub myconfess {
   confess "confessed and Nagios can detect me";
}


sub eval_dontdie {
   eval {
      die "died. and I hope that Nagios can't detect me";
   };
}


sub eval_dontcroak {
   eval {
       croak "croaked. and I hope that Nagios can't detect me";
   };
}

sub eval_dontconfess {
   eval {
       confess "confessed. and I hope that Nagios can't detect me";
   }
}

1;
