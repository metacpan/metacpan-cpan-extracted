package Local::Config;
sub new { bless $_[1], $_[0] }
sub DESTROY { 1 }
sub AUTOLOAD {
	our $AUTOLOAD;
	( my $method = $AUTOLOAD ) =~ s/.*:://;
	exists $_[0]{$method} ? $_[0]{$method} : ()
	}
1;
