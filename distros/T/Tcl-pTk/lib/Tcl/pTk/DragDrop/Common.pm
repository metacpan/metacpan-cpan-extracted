package Tcl::pTk::DragDrop::Common;

our ($VERSION) = ('1.02');

use strict;
use Carp;

no warnings 'once'; # cease warning about Tk::DragDrop::type



sub Type
{
 my ($base,$name,$class) = @_;
 no strict 'refs';
 my $hash  = \%{"${base}::type"};
 my $array = \@{"${base}::types"};
 unless (exists $hash->{$name})
  {
   push(@$array,$name);
   $class = (caller(0))[0] unless (@_ > 2);
   $hash->{$name} = $class;
   # confess "Strange class $class for $base/$name" unless ($class =~ /^Tk/);
   # print "$base $name is ",$class,"\n";
  }
}

sub import
{
 my $class = shift;
 #print "### In Import $class\n";
 no strict 'refs';
 my $types = \%{"${class}::type"};
 while (@_)
  {
   my $type = shift;
   unless (exists $types->{$type})
    {
      
       my ($kind) = $class =~ /([A-Z][a-z]+)$/;
       my $file = Tcl::pTk->findINC("DragDrop/${type}${kind}.pm");
       if (defined $file)
        {
         #print "DragDrop Loading $file\n";
         require $file;
        }
       else
        {
         croak "Cannot find ${type}${kind}";
        }
      
    }
  }
}

1;
__END__

