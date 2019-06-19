# Implemenation of Tk::Font in Tcl::pTk
#  Source mostly copied from the perl/tk distribution

package Tcl::pTk::Font;

our ($VERSION) = ('1.00');

require Tcl::pTk::Widget;
use strict;
use Carp;
use overload '""' => 'as_string';
sub as_string { return $_[0]->{name} }

*MainWindow = \&Tcl::pTk::MainWindow;

foreach my $key (qw( metrics measure configure))
 {
  no strict 'refs';
  *{$key} = sub { 
        my $me = shift;
        $me->interp->call('font', $key, $me, @_);
    }
 }

Construct Tcl::pTk::Widget 'Font';


################################################################
###  Wrapper for $font->actual #################################
#    This corrects a problems seen with font size attribute reporting
#    seen using Tcl 8.5.1 - 8.5.5 on linux. See the test case t/fontAttr.t in the source distribution
#    for details.
sub actual{
        my $self = shift;
        my @args = @_;
        
        # If no args, or size option present, then check to see if the font size returned makes
        # sense
        my $interp = $self->interp;
        my $sizeDefined = grep(/-size/, @args);
        if( $^O ne 'MSWin32' && (!scalar(@_) || $sizeDefined) ){
                
                # Get attributes and create our own font with it
                my %attributes = $interp->call('font', 'actual', $self);
                my $testFontName = $interp->call('font', 'create', %attributes);
               
                # See if the width of the font we just made matches the current font
                #   (if not, there is a problem with the attributes
                my $widthTest1 = $interp->call('font', 'measure', $testFontName, 'This is a test of font size');
                my $widthTest2 = $self->measure(    'This is a test of font size');
                
                $interp->call('font', 'delete', $testFontName); # Delete the font in tcl since we are done
                
                if( $widthTest1 != $widthTest2 ){ # Size needs to be corrected if widths aren't the same
                       # We fix the reported size by negating the ascent (don't know why this works, found empirically)
                       my $ascent = $self->metrics(-ascent);
                       $attributes{-size} = -$ascent
                }
                
                # Return the proper info
                return $attributes{-size} if( $sizeDefined );
                
                return %attributes;
        }
        
        # Attributes other than size requested, call actual normally
        return $interp->call('font', 'actual', $self, @_);
}
                


my @xfield  = qw(foundry family weight slant swidth adstyle pixel
               point xres yres space avgwidth registry encoding);
my @tkfield = qw(family size weight slant underline overstrike);
my %tkfield = map { $_ => "-$_" } @tkfield;

sub _xonly { my $old = '*'; return $old }

sub Pixel
{
 my $me  = shift;
 my $old = $me->configure('-size');
 $old = '*' if ($old > 0);
 if (@_)
  {
   $me->configure(-size => -$_[0]);
  }
 return $old;
}

sub Point
{
 my $me  = shift;
 my $old = 10*$me->configure('-size');
 $old = '*' if ($old < 0);
 if (@_)
  {
   $me->configure(-size => int($_[0]/10));
  }
 return $old;
}

foreach my $f (@tkfield,@xfield)
 {
  no strict 'refs';
  my $sub = "\u$f";
  unless (defined &{$sub})
   {
    my $key = $tkfield{$f};
    if (defined $key)
     {
      *{$sub} = sub { shift->configure($key,@_) };
     }
    else
     {
      *{$sub} = \&_xonly;
     }
   }
 }

sub new
{
 my $pkg  = shift;
 my $w    = shift;
 my $me;
 if (scalar(@_) == 1)
  {
   $me = $w->interp->call('font','create',@_);
  }
 else
  {
   my $fontName;
   if (@_ & 1){  # odd number of args supplied, first name must be fontname
           $fontName = shift;
   }
   
   my %attr;
   while (@_)
    {
     my $k = shift;
     my $v = shift;
     my $t = (substr($k,0,1) eq '-') ? $k : $tkfield{$k};
     if (defined $t)
      {
       $attr{$t} = $v;
      }
     elsif ($k eq 'point')
      {
       $attr{'-size'} = -int($v/10+0.5);
      }
     elsif ($k eq 'pixel')
      {
       $attr{'-size'} = -$v;
      }
     else
      {
       carp "$k ignored" if $^W;
      }
    }
   
   # Translate the any medium weight to normal, for compability with perl/tk
   $attr{-weight} = 'normal'  if( defined($attr{-weight}) and $attr{-weight} =~ /medium/i );
   $attr{-slant}  = 'roman'   if( defined($attr{-slant})  and $attr{-slant} =~ /^r/i );
   $attr{-slant}  = 'italic'  if( defined($attr{-slant})  and $attr{-slant} =~ /^i/i );
   
   my @args = (%attr);
   unshift @args, $fontName if defined($fontName); # Include font name, if defined
   $me = $w->interp->call('font', 'create',@args);
  }
  return bless {name => $me, interp => $w->interp},$pkg;
}

# accessor method to get the interpreter
sub interp{
  my $me = shift;
  return $me->{interp};
}

sub Pattern
{
 my $me  = shift;
 my @str;
 foreach my $f (@xfield)
  {
   my $meth = "\u$f";
   my $str  = $me->$meth();
   if ($f eq 'family')
    {
     $str =~ s/(?:Times\s+New\s+Roman|New York)/Times/i;
     $str =~ s/(?:Courier\s+New|Monaco)/Courier/i;
     $str =~ s/(?:Arial|Geneva)/Helvetica/i;
    }
   elsif ($f eq 'slant')
    {
     $str = substr($str,0,1);
    }
   elsif ($f eq 'weight')
    {
     $str = 'medium' if ($str eq 'normal');
    }
   push(@str,$str);
  }
 return join('-', '', @str);
}

sub Name
{
 my $me  = shift;
 return $me->{name} if (!wantarray || ($^O eq 'MSWin32'));
 my $max = shift || 128;
 my $w = $me->MainWindow;
 my $d = $w->Display;
 return $d->XListFonts($me->Pattern,$max);
}

sub Clone
{
 my $me = shift;
 return ref($me)->new($me,$me->actual,@_);
}

sub ascent
{
 return shift->metrics('-ascent');
}

sub descent
{
 return shift->metrics('-descent');
}

1;

