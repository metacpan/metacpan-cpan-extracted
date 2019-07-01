package Tcl::pTk::Submethods;

our ($VERSION) = ('1.02');

sub import
{
 my $class = shift;
 no strict 'refs';
 my $package = caller(0);
 while (@_)
  {
   my $fn = shift;
   my $sm = shift;
   foreach my $sub (@{$sm})
    {
     my ($suffix) = $sub =~ /(\w+)$/;
     my $pfn = $package.'::'.$fn;
     *{$pfn."\u$suffix"} = sub { shift->$pfn($sub,@_) };
    }
  }
}

# Method calls that include the window path
sub Direct
{
 my $class = shift;
 no strict 'refs';
 my $package = caller(0);
 while (@_)
  {
   my $fn = shift;
   my $sm = shift;
   my $sub;
   foreach $sub (@{$sm})
    {
     # eval "sub ${package}::${sub} { shift->$fn('$sub',\@_) }";
     *{$package.'::'.$sub} = sub { 
        my $self = shift;
        $self->interp->call($fn, $sub, $self->path, @_) };
    }
  }
}

# Method calls that don't include the window path (like $widget->windowingsystem
sub Direct2
{
 my $class = shift;
 no strict 'refs';
 my $package = caller(0);
 while (@_)
  {
   my $fn = shift;
   my $sm = shift;
   my $sub;
   foreach $sub (@{$sm})
    {
     # eval "sub ${package}::${sub} { shift->$fn('$sub',\@_) }";
     *{$package.'::'.$sub} = sub { 
        my $self = shift;
        $self->interp->call($fn, $sub, @_) };
    }
  }
}

# Method calls that are camel case and don't include the window path (like $widget->optionReadfile
sub Direct3
{
 my $class = shift;
 no strict 'refs';
 my $package = caller(0);
 while (@_)
  {
   my $fn = shift;
   my $sm = shift;
   foreach my $sub (@{$sm})
    {
     my ($suffix) = $sub =~ /(\w+)$/;
     my $pfn = $package.'::'.$fn;
     *{$pfn."\u$suffix"} = sub {
        my $self = shift;
        $self->interp->call($fn, $sub, @_)
     };
    }
  }
}

1;

