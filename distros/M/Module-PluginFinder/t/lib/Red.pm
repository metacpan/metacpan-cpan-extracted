package t::lib::Red;

our $TYPE = 'colour';
our $SHAPE = 'circle';

sub size { return 'medium'; }
sub kind { return 'colour'; }

sub new { my $class = shift; bless [ @_ ], $class }

1;
