package Fascisto;

sub new
{
   my $pkg = shift;
   my $foo = bless { $pkg->defaults, @_ }, $pkg;
   return $foo;
}

sub defaults
{
   return ();
}

1;
__END__;
