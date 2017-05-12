package FooMeth;
our $var = 42;
our @var = ( 42, [43] );
our %var = ( foo => {bar => 42});
sub inc { my $self = shift; [ $self, $var++ ] }
sub var_ar { my $self = shift; [ $self, \@var ] }
sub var_h { my $self = shift; [ $self, \%var ] }

sub new { return bless {}, shift }

1;