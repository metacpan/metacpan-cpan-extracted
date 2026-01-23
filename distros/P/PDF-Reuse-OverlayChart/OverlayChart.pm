package PDF::Reuse::OverlayChart;
use PDF::Reuse;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.05';

our %possible = (x           => 1,
                 y           => 1,
                 width       => 1,
                 height      => 1,
                 size        => 1,
                 xsize       => 1,
                 ysize       => 1,
                 initialmaxy => 1,
                 initialminy => 1,
                 type        => 1,
                 background  => 1,
                 yunit       => 1,
                 nounits     => 1,
                 title       => 1,
                 groupstitle => 1,
                 groupstext  => 1,
                 iparam      => 1,
                 nogroups    => 1,
                 merge       => 1,
                 xdensity    => 1,
                 ydensity    => 1,
                 rightscale  => 1,
                 topscale    => 1,
                 nomarker    => 1);

my @gray = ( '0.97 0.97 0.97', '0.8 0.8 0.8', '0.6 0.6 0.6', '0.72 0.72 0.72', '0.9 0.9 0.9',
             '0.93 0.93 0.93', '0.7 0.7 0.7', '0.5 0.5 0.5', '0.1 0.1 0.1', '0.98 0.98 0.98');

my @light = ('1 0.9 0.9', '0.9 0.9 1', '0.9 1 1', '1 1 0.9', '1 0.9 1', '0.9 1 0.9',
             '0.6 0.8 0.95', '0.95 0.8 0.6', '0.6 0.95 0.9', '0.9 0.95 0.6' );

my @dark  = ('0.1 0.5 0.8', '0.8 0.5 0.1', '0.1 0.8 0.8', '0.8 0.8 0.1', '0.8 0.1 0.8', '0.5 0.8 0.5',
             '0.1 0.1 0.5', '0.5 0.1 0.1', '0.1 0.5 0.5', '0.5 0.5 0.1' );

my @bright  = ('1 0 1', '1 0 0', '0 1 1', '1 1 0', '0 0 1', '0 1 0',
             '0.3 0.3 0.97', '0.57 0.97 0.97', '0.97 0.5 0.5', '0.5 0.5 0.97' );

sub new
{  my $name  = shift;
   my ($class, $self);
   if (ref($name))
   {  $class = ref($name);
      $self  = $name;
   }
   else
   {  $class = $name;
      $self  = {};
   }
   bless $self, $class;
   return $self;
}

sub outlines
{  no warnings;
   my $self = shift;
   my %param = @_;
   for (keys %param)
   {   my $key = lc($_);
       if ($possible{$key})
       {  $self->{$key} = $param{$_};
       }
       else
       {  warn "Unrecognized parameter: $_, ignored\n";
       }  
   }
   $self->{xsize}    = 1 unless ($self->{xsize} != 0);
   $self->{ysize}    = 1 unless ($self->{ysize} != 0);
   $self->{size}     = 1 unless ($self->{size}  != 0);
   $self->{width}    = 450 unless ($self->{width} != 0);
   $self->{height}   = 450 unless ($self->{height} != 0);
   
   if (($self->{type} ne 'bars') 
   &&  ($self->{type} ne 'totalbars')
   &&  ($self->{type} ne 'percentbars')
   &&  ($self->{type} ne 'lines')
   &&  ($self->{type} ne 'area'))
   {  if (substr($self->{type}, 0, 1) eq 't')
      {  $self->{type} = 'totalbars'; 
      }
      elsif (substr($self->{type}, 0, 1) eq 'p')
      {  $self->{type} = 'percentbars'; 
      }
      elsif (substr($self->{type}, 0, 1) eq 'l')
      {  $self->{type} = 'lines'; 
      }
      elsif (substr($self->{type}, 0, 1) eq 'a')
      {  $self->{type} = 'area'; 
      }
      else
      {  $self->{type} = 'bars'; 
      }
   }
   
   if (! defined $self->{color})
   {   $self->{color} = ['0 0 0.8', '0.8 0 0.3', '0.9 0.9 0', '0 1 0', '0.6 0.6 0.6',
                 '1 0.8 0.9', '0 1 1', '0.9 0 0.55', '0.2 0.2 0.2','0.55 0.9 0.9'];
   }
   return $self;
}

sub overlay
{  my $self = shift;
   my %param = @_;
   for (keys %param)
   {   my $key = lc($_);
       if ($possible{$key})
       {  $self->{$key} = $param{$_};
       }
       else
       {  warn "Unrecognized parameter: $_, ignored\n";
       }  
   }
   if (($self->{type} ne 'bars') 
   &&  ($self->{type} ne 'totalbars')
   &&  ($self->{type} ne 'lines')
   &&  ($self->{type} ne 'area'))
   {  if (substr($self->{type}, 0, 1) eq 't')
      {  $self->{type} = 'totalbars'; 
      }
      elsif (substr($self->{type}, 0, 1) eq 'l')
      {  $self->{type} = 'lines'; 
      }
      elsif (substr($self->{type}, 0, 1) eq 'a')
      {  $self->{type} = 'area'; 
      }
      else
      {  $self->{type} = 'bars'; 
      }
   }

   $self->{xdensity} = 1 if (! exists $self->{xdensity});
   $self->{ydensity} = 1 if (! exists $self->{ydensity});
   $self->{level}    = 'overlay';
   return $self;
}

sub add
{  my $self  = shift;
   my @values = @_;
   my $name = shift @values || ' ';
   my $num = 0;
   my $ready;
   if (! defined $self->{col})
   {  for (@values)
      {  if (ref($_) eq 'ARRAY')
         {   last;
         }
         if ((defined $_) 
         && ($_ =~ m'[A-Za-z]+'o) 
         && ($_ !~ m'undef'oi))
         {  $ready = 1;
            $self->{col} = \@values;
            $self->{xunit} = $name;
            last;
         }
      }
   }
   if (! defined $ready)          
   {   if (! exists $self->{series}->{$name})
       {  push @{$self->{sequence}}, $name;
          $self->{series}->{$name} = [];
       }
       my @array = @{$self->{series}->{$name}}; 
       
       for (@values)
       {  if (ref($_) eq 'ARRAY')
          {  my @newArray;
             for my $element (@{$_})
             {  if ((defined $element) && (length($element)))
                {  push @newArray, $element;
                }
                else 
                {  push @newArray, undef;
                }
             }
             $array[$num] = [ @newArray ];            
          }
          elsif ((defined $_) && ($_ =~ m'([\d\.\-]*)'o))
          {  if (length($1))
             {   $array[$num] += $1;
             }
          }
          $num++;
       } 
       $self->{series}->{$name} = \@array;
   }
   return $self;
}
   
sub columns
{  my $self   = shift;
   my $xunit = shift;
   $self->{col} = \@_;
   $self->{xunit} = $xunit;
   return $self;
}

sub color
{  my $self = shift;
   my @vector = @_;
   if ($vector[0] =~ m'gray'oi)
   {  $self->{color} = [ (@gray) ];
   }
   elsif ($vector[0] =~ m'light'oi)
   {  $self->{color} = [ (@light) ];
   }
   elsif ($vector[0] =~ m'dark'oi)
   {  $self->{color} = [ (@dark) ];
   }
   elsif ($vector[0] =~ m'bright'oi)
   {  $self->{color} = [ (@bright) ];
   }
   else 
   {  $self->{color} = [ (@_) ];
   }
   return $self;
}

sub analysera
{  my $self   = shift;
   my ($min, $max, $maxSum, $minSum, $i);
 
   my @tot    = ();
   my @pos    = ();
   my @neg    = ();
   my $num    = 0;
   for my $namn (@{$self->{sequence}})
   {   $i = -1;
       for my $unit (@{$self->{series}->{$namn}})
       {   $i++;
           next if (! defined $unit);
           if (ref($unit) eq 'ARRAY')
           {   my $k   = 0;
               for (@{$unit})
               {  if ((! defined $_) || ($_ eq ''))
                  {  $k++;
                     next;
                  }
                  $max = $_ if ((! defined $max) || ($_ > $max));
                  $min = $_ if ((! defined $min) || ($_ < $min));
                  $tot[$i][$k] += abs($_);
                  $pos[$i][$k] += $_      if $_ > 0;
                  $neg[$i][$k] += abs($_) if $_ < 0;
                  $k++;
               }
           }
           else
           {   $max = $unit if ((! defined $max) || ($unit > $max));
               $min = $unit if ((! defined $min) || ($unit < $min));
               $tot[$i] += abs($unit);
               $pos[$i] += $unit      if $unit > 0;
               $neg[$i] += abs($unit) if $unit < 0;
           }
       }
       $num = $i  if ((! defined $num) || ($i > $num));
   }
  
   $num = (defined $num) ? ($num + 1) : 0;
   
   my $posPercent = 0;
   my $negPercent = 0;

   for ($i = 0; $i < $num; $i++)
   {   if (! defined $tot[$i])
       {  next;
       }
       if (ref($tot[$i]) eq 'ARRAY')
       {  my $k = 0;
          for my $element (@{$tot[$i]})
          {   if (! defined $element)
              {  $k++;
                 next;
              }
              $maxSum = $element if ((! defined $maxSum) || ($element > $maxSum));
              $minSum = $element if ((! defined $minSum) || ($element < $minSum));
              if ((defined $neg[$i][$k]) && (($neg[$i][$k] * -1) < $minSum))
              {   $minSum = $neg[$i][$k] * -1;
              }
              if (($posPercent < 100) && (defined $pos[$i][$k]))
              {   my $percent = sprintf("%.3f", (($pos[$i][$k] / $element) * 100));
                  $posPercent = $percent if ($percent > $posPercent);
              }
              if (($negPercent < 100) && (defined $neg[$i][$k]))
              {   my $percent = sprintf("%.3f", (($neg[$i][$k] / $element) * 100));
                  $negPercent = $percent if ($percent > $posPercent);
              }
              $k++;
          }
       }
       else
       {  $maxSum = $tot[$i] if ((! defined $maxSum) || ($tot[$i] > $maxSum));
          $minSum = $tot[$i] if ((! defined $minSum) || ($tot[$i] < $minSum));
          if ((defined $neg[$i]) && (($neg[$i] * -1) < $minSum))
          {   $minSum = $neg[$i] * -1;
          }
          if (($posPercent < 100) && (defined $pos[$i]))
          {   my $percent = sprintf("%.3f", (($pos[$i] / $tot[$i]) * 100));
              $posPercent = $percent if ($percent > $posPercent);
          }
          if (($negPercent < 100) && (defined $neg[$i]))
          {   my $percent = sprintf("%.3f", (($neg[$i] / $tot[$i]) * 100));
              $negPercent = $percent if ($percent > $negPercent);
          }
       }
   }

   $self->{max} = (defined $max) ? $max : 0;
   $self->{min} = (defined $min) ? $min : 0;
   $self->{maxSum} = (defined $maxSum) ? $maxSum : 0;
   $self->{minSum} = (defined $minSum) ? $minSum : 0;
   $self->{tot} = \@tot;
   $self->{pos} = \@pos;
   $self->{neg} = \@neg;
   $self->{posPercent} = $posPercent;
   $self->{negPercent} = $negPercent;
   $self->{num} = $num;
   
   return ($self->{max}, $self->{min}, $self->{maxSum}, $self->{minSum}, 
           $self->{num}, $self->{posPercent}, $self->{negPercent});
}

sub marginAction
{  my $self = shift;
   my $code = shift;
   $self->{marginAction} = $self->prepare($code);
   return $self;
}

sub marginToolTip
{  my $self = shift;
   my $text = shift;
   $self->{marginToolTip} = $self->prepare($text);
   return $self;
}


sub barsActions
{  my $self = shift;
   my $namn = shift;
   my (@codeArray, $str);
   for (@_)
   {   if (ref($_) eq 'ARRAY')
       {   my @vector;
           my @array = @{$_};
           for my $element (@array)
           {   push @vector, $self->prepare($element);
           }
           push @codeArray, [@vector];
       }
       else
       {   push @codeArray, $self->prepare($_);
       }
   }

   if ($namn)
   {  $self->{barAction}->{$namn} = \@codeArray;
   }
   return $self;
}

sub prepare
{  my $self = shift;
   my $str  = shift;
   if ($str !~ m'\"'os)
   {  $str = '"' . $str . '"';
   }
   elsif ($str !~ m/\'/os)
   {  $str = '\'' . $str . '\'';
   }
   else
   {  $str =~ s/\'/\\\'/og;
      $str =~ s/\\\\\'/\\\'/og;
      $str = "'" . $str . "'";
   }
   return $str;
}


sub barsToolTips
{  my $self = shift;
   my $namn = shift;
   my (@toolTips, $str);
   for (@_)
   {   if (ref($_) eq 'ARRAY')
       {   my @vector;
           my @array = @{$_};
           for my $element (@array)
           {   push @vector, $self->prepare($element);
           }
           push @toolTips, [@vector];
       }
       else
       {   push @toolTips, $self->prepare($_);
       }
   }
   if ($namn)
   {  $self->{barToolTip}->{$namn} = \@toolTips;
   }
   return $self;
}

sub columnsActions
{  my $self = shift;
   my (@codeArray, $str);

   for (@_)
   {   if (ref($_) eq 'ARRAY')
       {   my @vector;
           my @array = @{$_};
           for my $element (@array)
           {   push @vector, $self->prepare($element);
           }
           push @codeArray, [@vector];
       }
       else
       {   push @codeArray, $self->prepare($_);
       }
   }
   $self->{columnsActions} = \@codeArray;
   
   return $self;
}

sub columnsToolTips
{  my $self = shift;
   my (@toolTips, $str);
   for (@_)
   {   if (ref($_) eq 'ARRAY')
       {   my @vector;
           my @array = @{$_};
           for my $element (@array)
           {   push @vector, $self->prepare($element);
           }
           push @toolTips, [@vector];
       }
       else
       {   push @toolTips, $self->prepare($_);
       }
   }
   $self->{columnsToolTips} = \@toolTips;
   return $self;
}


sub boxAction
{  my $self = shift;
   my $namn = shift;
   my $code = shift;
   $self->{boxAction}->{$namn} = $self->prepare($code);
   return $self;
}

sub boxToolTip
{  my $self = shift;
   my $namn = shift;
   my $text = shift;
   $self->{boxToolTip}->{$namn} = $self->prepare($text);
   return $self;
}


sub defineIArea
{  my $self = shift;
   my $code =<<"EOF";
function iArea()
{  var vec = iArea.arguments;
   var page = vec[0];
   var x  = vec[1];
   var y2 = vec[2];
   var x2 = vec[3] + x;     
   var y  = y2 + vec[4];
   var name = 'p' + page + 'x' + x + 'y' + y + 'x2' + x2 + 'y2' + y2;
   var b = this.addField(name, "button", page, [x, y, x2, y2]);
   b.setAction("MouseUp", vec[5]);
   if (vec[6])
     b.userName = vec[6]; 
}
EOF

  prJs($code);
  return $self;
}


sub draw
{  my $self = shift;
   my %param = @_;
   for (keys %param)
   {  my $key = lc($_); 
      if ($possible{$key})
       {  $self->{$key} = $param{$_};
       }
       else
       {  warn "Unrecognized parameter: $_, ignored\n";
       }  
   }
   $self->outlines();
   $self->{level}    = 'top';
   my ($str, $xsize, $ysize, $font, $x, $y, $y0, $ySteps, $xT, @array, $chartMax,
       $chartMin, $rightScale, $topScale);
   
   my ($max, $min, $maxSum, $minSum, $num, 
       $posPercent, $negPercent ) = $self->analysera();
   if (($self->{type} eq 'totalbars') || ($self->{type} eq 'area'))
   {  $chartMax = $maxSum;
      $chartMin = $minSum;
   }
   else
   {  $chartMax = $max;
      $chartMin = $min;
   }
   
   if ((defined $self->{initialmaxy})
   &&  ($self->{initialmaxy} > $chartMax))
   {  $chartMax = $self->{initialmaxy}
   }
   
   if ((defined $self->{initialminy})
   &&  ($self->{initialminy} < $chartMin))
   {  $chartMin = $self->{initialminy}
   }
   
   
   if ((exists $param{'merge'}) && ($self->{type} ne 'percentbars'))
   {  for (@{$param{'merge'}})
      {   if ($_->{type} ne 'percentbars')
          {   push @array, $_;
          }
      }
      for my $overlay (@array)
      {   my ($tmax, $tmin, $tmaxSum, $tminSum, $tnum) = $overlay->analysera();
          if (($overlay->{type} eq 'totalbars') || ($overlay->{type} eq 'area'))
          {  $tmaxSum = sprintf ("%.0f", ($tmaxSum / $overlay->{ydensity}));
             $tminSum = sprintf ("%.0f", ($tminSum / $overlay->{ydensity}));

             $chartMax = $tmaxSum if ($tmaxSum > $chartMax);
             $chartMin = $tminSum if ($tminSum < $chartMin);
          }
          else
          {  $tmax = sprintf ("%.0f", ($tmax / $overlay->{ydensity}));
             $tmin = sprintf ("%.0f", ($tmin / $overlay->{ydensity}));

             $chartMax = $tmax if ($tmax > $chartMax);
             $chartMin = $tmin if ($tmin < $chartMin);
          }
          $tnum = sprintf ("%.0f", ($tnum / $overlay->{xdensity})); 
          $num  = $tnum if ($tnum > $num);
          $tnum = sprintf ("%.0f", ($self->{num} / $overlay->{xdensity})); 
          $num  = $tnum if ($tnum > $num);
          if ((defined $overlay->{rightscale})
          &&  (! defined $rightScale))
          {  $rightScale = $overlay;
          }
          if ((defined $overlay->{topscale})
          &&  (! defined $topScale))
          {  $topScale = $overlay;
          }
          $overlay->{x}     = $self->{x};
          $overlay->{xsize} = $self->{xsize};
          $overlay->{size}  = $self->{size};
          $overlay->{y}     = $self->{y};
          $overlay->{ysize} = $self->{ysize};
       }
   }
   my $xSteps = $#{$self->{col}} + 1;
   $xSteps = $num if ($num > $xSteps);
   my $groups = $#{$self->{sequence}} + 1;

   if ($self->{type} ne 'percentbars')
   {  if ($chartMin > 0)
      { $ySteps = $chartMax || 1;
      }
      elsif ($chartMax < 0)
      { $ySteps = ($chartMin * -1) || 1;
      }
      else
      { $ySteps = ($chartMax - $chartMin) || 1;
      }
   }
   else
   {  $max    = $posPercent;      
      $min    = $negPercent * -1;
      $ySteps = sprintf("%.0f", ($max - $min));
      $chartMax = $max;
      $chartMin = $min;
   }         
   
   ####################
   # N�gra kontroller
   ####################

   if ($num < 1)
   {  prText ($self->{x}, $self->{y}, 
              'Values are missing - no graph can be shown');
      return;
   }
   
   if ((! defined $max) || (! defined $min))
   {  prText ($self->{x}, $self->{y}, 
              'Values are missing - no graph can be shown');
      return;
   }
   my $tal1 = sprintf("%.0f", $chartMax);
   my $tal2 = sprintf("%.0f", $chartMin);
   my $tal = (length($tal1) > length($tal2)) ? $tal1 : $tal2;
   my $langd = length($tal);
   
   my $xCor  = ($langd * 7.5) || 25;         # margin to the left
   my $yCor  = 20;                          # margin from the bottom
   my $xEnd  = $self->{width};
   my $yEnd  = $self->{height};
   my $xArrow = $xEnd * 0.9;
   my $yArrow = $yEnd * 0.97;
   my $xAreaEnd = $xEnd * 0.85;
   my $yAreaEnd = $yEnd * 0.92;
   my $xAxis =  $xAreaEnd - $xCor;
   my $yAxis =  $yAreaEnd - $yCor;

   $xsize = $self->{xsize} * $self->{size};
   $ysize = $self->{ysize} * $self->{size};
   $str  = "q\n";                            # save graphic state
   $str .= "3 M\n";                          # miter limit
   $str .= "1 w\n";                          # line width
   $str .= "0.5 0.5 0.5 RG\n";               # Gray as stroke color
   $str .= "$xsize 0 0 $ysize $self->{x} $self->{y} cm\n";
   $font = prFont('H');
   
   my $labelStep = sprintf("%.5f", ($xAxis / $xSteps));
   my $prop   = sprintf("%.5f", ($yAxis / $ySteps));
   my $xStart = $xArrow + 10;
   my $yStart = $yAreaEnd;
   
   my $iStep  = sprintf("%.3f", ($yAxis / $groups));
   if ($chartMax < 0)
   {  $y0 = $yAreaEnd;
   }
   elsif ($chartMin < 0)
   {  $y0 = $yCor - ($chartMin * $prop);
   } 
   else 
   {  $y0 = $yCor;
   }

   ################
   # Rita y-axeln
   ################

   if (defined $self->{background})
   {  $str .= "$self->{background} rg\n";
      $str .= "$xCor $yCor $xAxis $yAxis re\n";
      $str .= "b*\n";
      $str .= "0 0 0 rg\n";
   }
   $str .= "$xCor $yCor m\n";
   $str .= "$xCor $yArrow l\n";
   # $str .= "b*\n";

   ###############
   # Rita X-axeln
   ###############
   
   $str .= "$xCor $y0 m\n";
   $str .= "$xArrow $y0 l\n";
   $str .= "b*\n";

   #####################   
   # Draw the arrowhead
   #####################

   $str .= "$xCor $yArrow m\n";                  
   $x = $xCor + 2;
   $y = $yArrow - 5;
   $str .= "$x $y l\n";
   $x = $xCor;
   $y = $yArrow - 2;
   $str .= "$x $y l\n";
   $x = $xCor - 2;
   $y = $yArrow - 5;
   $str .= "$x $y l\n";
   $str .= "s\n";

   my $xT2 = 0;

   if ((! defined $self->{nounits}) && (defined $self->{yunit}))
   {  $xT = $xCor - (length($self->{yunit}) * 3);
      $xT = 1 if $xT < 1;
      $xT2 = $xT + (length($self->{yunit}) * 6);
      $y = $yArrow + 7;
      $x = $xCor - 15;
      $str .= "BT\n";
      $str .= "/$font 12 Tf\n";
      $str .= "$xT $y Td\n";
      $str .= '(' . $self->{yunit} . ') Tj' . "\n";
      $str .= "ET\n"; 
   }

   if ($self->{title})
   {  $xT =  ($self->{width} - (length($self->{title}) * 7)) / 2;
      if ($xT < ($xT2 + 10))
      {  $xT = $xT2 + 10;
      }
      $y = $yArrow + 12;
      $str .= "BT\n";
      $str .= "/$font 14 Tf\n";
      $str .= "$xT $y Td\n";
      $str .= '(' . $self->{title} . ') Tj' . "\n";
      $str .= "ET\n";
   }
       
   #####################
   # draw the arrowhead
   #####################
 
   $str .= "$xArrow $y0 m\n";
   $x = $xArrow - 5;                           
   $y = $y0 - 2;
   $str .= "$x $y l\n";
   $x = $xArrow - 2;
   $y = $y0;
   $str .= "$x $y l\n";
   $x = $xArrow - 5;
   $y = $y0 + 2;
   $str .= "$x $y l\n";
   $str .= "s\n";

   if ((! defined $self->{nounits}) && (defined $self->{xunit}))
   {  $y = $y0 - 5;
      $x = $xArrow + 10;
      $str .= "BT\n";
      $str .= "/$font 12 Tf\n";
      $str .= "$x $y Td\n";
      $str .= '(' . $self->{xunit} . ') Tj' . "\n";
      $str .= "ET\n"; 
   } 

   ##################################
   # draw the lines cross the x-axis
   ##################################
   my $yCor2 = $yCor - 5;
   my $yFrom = $yAreaEnd;
   if (($self->{type} eq 'area') || ($self->{type} eq 'lines'))
   {  $xT = sprintf("%.4f", ($labelStep / 2));
      $xT += $xCor;
   }
   
   $str .= "0.9 w\n";
   
   $x = $xCor;
   for (my $i = 0; $i < $xSteps; $i++)
   {  if (($self->{type} eq 'area') || ($self->{type} eq 'lines'))
      {   $str .= "0.9 0.9 0.9 RG\n";
          $str .= "$xT $yAreaEnd m\n";
          $str .= "$xT $yCor l\n";
          $str .= "S\n";
          $str .= "0 0 0 RG\n";
          $xT += $labelStep;
      }

      if ((defined $self->{iparam})
      &&  (defined $self->{columnsActions}->[$i]))
      {   $self->insert($x,
                        0,
                        $labelStep,
                        $yCor,
                        $self->{iparam},
                        $self->{columnsActions}->[$i],
                        $self->{columnsToolTips}->[$i]);
      }
      $x += $labelStep;
      $str .= "$x $yCor m\n";
      $str .= "$x $yCor2 l\n";
      $str .= "s\n";
   }

   ####################################
   # Write the labels under the x-axis
   ####################################

   $str .= "1 w\n";
   $str .= "0 0 0 RG\n";
   $x = $xCor + sprintf("%.3f", ($labelStep / 2.5));
   if ((scalar @{$self->{col}}) && ($labelStep > 5) && (! $self->{nounits}))
   {   my $radian = 5.3;     
       my $Cos    = sprintf("%.4f", (cos($radian)));
       my $Sin    = sprintf("%.4f", (sin($radian)));
       my $negSin = $Sin * -1;
       my $negCos = $Cos * -1;
       for (my $i = 0; $i <= $xSteps; $i++)
       {  if (exists $self->{col}->[$i])
          {    $str .= "BT\n";
               $str .= "/$font 8 Tf\n";
               $str .= "$Cos $Sin $negSin $Cos $x $yCor2 Tm\n";
               $str .= '(' . $self->{col}->[$i] . ') Tj' . "\n";
               $str .= "ET\n"; 
          }
          $x += $labelStep;
       }       
       
   }
   if (defined $topScale)
   {  
      my $numSteps = $topScale->{num};
      my $factor = 1 / $topScale->{xdensity}; 
      my $tLabelStep = sprintf("%.5f", ($labelStep * $factor)); 
      ##################################
      # draw the lines cross the x-axis
      ##################################
      my $ty1 = $yAreaEnd - 2;
      my $ty2 = $yAreaEnd;
      my $ty3 = $ty2 + 3;
      my $ty4 = $ty2 + 1;
      
      $str .= "0.9 w\n";
   
      $x = $xCor;
      for (my $i = 0; $i < $numSteps; $i++)
      {  if ((defined $self->{iparam})
         &&  (defined $topScale->{columnsActions}->[$i]))
         {   $topScale->insert($x,
                               $ty2,
                               $tLabelStep,
                               10,
                               $self->{iparam},
                               $topScale->{columnsActions}->[$i],
                               $topScale->{columnsToolTips}->[$i]);
         }
         $x += $tLabelStep;
         $str .= "$x $ty1 m\n";
         $str .= "$x $ty3 l\n";
         $str .= "s\n";
      }

      ######################################
      # Write the labels over the top scale
      ######################################

      $str .= "1 w\n";
      $str .= "0 0 0 RG\n";
      $x = $xCor + sprintf("%.3f", ($tLabelStep / 2.5));
      if ((exists $topScale->{col})
      && (scalar @{$topScale->{col}}) 
      && ($tLabelStep > 5) 
      && (! $self->{nounits}))
      {   my $radian = 0.45;     
          my $Cos    = sprintf("%.4f", (cos($radian)));
          my $Sin    = sprintf("%.4f", (sin($radian)));
          my $negSin = $Sin * -1;
          my $negCos = $Cos * -1;
          for (my $i = 0; $i <= $numSteps; $i++)
          {  if (exists $topScale->{col}->[$i])
             {    $str .= "BT\n";
                  $str .= "/$font 8 Tf\n";
                  $str .= "$Cos $Sin $negSin $Cos $x $ty4 Tm\n";
                  $str .= '(' . $topScale->{col}->[$i] . ') Tj' . "\n";
                  $str .= "ET\n"; 
             }
             $x += $tLabelStep;
          }       
       
       }
   }

   if ($iStep > 20)
   {  $iStep   = 20;
   }

   if ($tal < 0)
   {  $tal *= -1;
      $langd = length($tal);
   }
   
   if ($langd > 1)
   {  $langd--;
      if (($langd > 1)
      || (($langd == 1) &&  (substr($tal, 0, 1) le '5')))
      {  $langd--;
      }
      $langd = '0' x $langd;
      $langd = '1' . $langd;
   }
   my $skala = $langd || 1;
   my $xCor2 = $xCor - 5;
      
   $str .= "0.3 w\n";
   $str .= "0.5 0.5 0.5 RG\n";
   $x = $xAreaEnd + 5;
   my $last = 0;
     
   while ($skala <= $chartMax)
   {   my $yPos = $prop * $skala + $y0;
       if (($yPos - $last) > 13)  
       {  if (! $self->{nounits})
          {  $xT = $xCor - (length($skala) * 7.5) - 7;
             $str .= "BT\n";
             $str .= "/$font 12 Tf\n";
             $str .= "$xT $yPos Td\n";
             $str .= "($skala)Tj\n";
             $str .= "ET\n";
          }
          $last = $yPos;
          $str .= "$xCor2 $yPos m\n";
          $str .= "$x $yPos l\n";
          $str .= "b*\n";
       }       
       $skala += $langd;
   }
   $last  = $prop * $langd + $y0;
   $skala = 0;
   while ($skala >= $chartMin)
   {   my $yPos = $prop * $skala + $y0;
       if (($last - $yPos) > 13)
       {  if (! $self->{nounits})
          {   $xT = $xCor - (length($skala) * 6) - 10;
              $xT = 1 if ($xT < 1);
              $str .= "BT\n";
              $str .= "/$font 12 Tf\n";
              $str .= "$xT $yPos Td\n";
              $str .= "($skala)Tj\n";
              $str .= "ET\n";
          }
          $last = $yPos;
          $str .= "$xCor2 $yPos m\n";
          $str .= "$x $yPos l\n";
          $str .= "b*\n";
       }       
       $skala -= $langd;
   }

   if ((defined $self->{marginAction})
   &&  (defined $self->{iparam}))
   {   $self->insert( 0,
                      0,
                      $xCor,
                      $yArrow,
                      $self->{iparam},
                      $self->{marginAction},
                      $self->{marginToolTip});
   }


   if (defined $rightScale)
   {  my $rightFactor = $rightScale->{ydensity};
      my $rightMax = sprintf("%.0f", ($chartMax * $rightFactor));
      my $rightMin = sprintf("%.0f", ($chartMin * $rightFactor));
      $tal1 = $rightMax; 
      $tal2 = $rightMin;
      $rightFactor = sprintf("%.5f", ($prop / $rightFactor));
      $tal = (length($tal1) > length($tal2)) ? $tal1 : $tal2;
      $langd = length($tal);
      my $rx1 = $xAreaEnd + 2;
      my $rx2 = $rx1 + 4;
      my $rx3 = $rx2 + 3;
      my $rx4 = $rx3 + 7;
      $str .= "0.3 w\n";
      $str .= "0.5 0.5 0.5 RG\n";
      $str .= "$rx2 $yAreaEnd m\n";
      $str .= "$rx2 $yCor l\n"; 
      $str .= "b*\n";

      $xStart  += ($langd * 7.5) || 25;
      if ($tal < 0)
      {  $tal *= -1;
         $langd = length($tal);
      }
   
      if ($langd > 1)
      {  $langd--;
         if (($langd > 1) 
         ||  (($langd == 1) &&  (substr($tal, 0, 1) le '5')))   
         {  $langd--;
         }
         $langd = '0' x $langd;
         $langd = '1' . $langd;
      }
      $skala = $langd || 1;
            
      $last = 0;
     
      while ($skala <= $rightMax)
      {   my $yPos = $rightFactor * $skala + $y0;
          if (($yPos - $last) > 13)  
          {  if (! $self->{nounits})
             {  $str .= "BT\n";
                $str .= "/$font 12 Tf\n";
                $str .= "$rx4 $yPos Td\n";
                $str .= "($skala)Tj\n";
                $str .= "ET\n";
             }
             $last = $yPos;
             $str .= "$rx1 $yPos m\n";
             $str .= "$rx3 $yPos l\n";
             $str .= "b*\n";
          }       
          $skala += $langd;
      }
      $last  = $rightFactor * $langd + $y0;
      $skala = 0;
      while ($skala >= $rightMin)
      {   my $yPos = $rightFactor * $skala + $y0;
          if (($last - $yPos) > 13)
          {  if (! $self->{nounits})
             {   $str .= "BT\n";
                 $str .= "/$font 12 Tf\n";
                 $str .= "$rx4 $yPos Td\n";
                 $str .= "($skala)Tj\n";
                 $str .= "ET\n";
             }
             $last = $yPos;
             $str .= "$rx1 $yPos m\n";
             $str .= "$rx3 $yPos l\n";
             $str .= "b*\n";
          }       
          $skala -= $langd;
      }
      if ((defined $rightScale->{marginAction})
      &&  (defined $self->{iparam}))
      {   $rightScale->insert( $xAreaEnd,
                               0,
                               35,
                               $yArrow,
                               $self->{iparam},
                               $rightScale->{marginAction},
                               $rightScale->{marginToolTip});
      }

   }
   $str .= "0 0 0 RG\n";
   
   my $col1 = 0.9;
   my $col2 = 0.4;
   my $col3 = 0.9;
   srand(9);

   my $tStart = $xStart + 20;

   unshift @array, $self;

   for my $overlay (@array)
   {  if (defined $overlay->{groupstitle})
      {   my $yTemp = $yStart;
          if ($yTemp < ($y0 + 20))
          {  $yTemp = $y0 - 20;
             $yStart = $yTemp - 20;
          } 
          $str .= "0 0 0 rg\n";
          $str .= "BT\n";
          $str .= "/$font 12 Tf\n";
          $str .= "$xStart $yTemp Td\n";       
          $str .= '(' . $overlay->{groupstitle} . ') Tj' . "\n";
          $str .= "ET\n";
          $yStart -= $iStep;
      }

      if (defined $overlay->{groupstext})
      {   my $yTemp = $yStart;
          if ($yTemp < ($y0 + 20))
          {  $yTemp = $y0 - 20;
             $yStart = $yTemp - 20;
          } 
          $str .= "0 0 0 rg\n";
          $str .= "BT\n";
          $str .= "/$font 12 Tf\n";
          $str .= "$xStart $yTemp Td\n";       
          $str .= '(' . $overlay->{groupstext} . ') Tj' . "\n";
          $str .= "ET\n";
          $yStart -= $iStep;
      }

      my @color = (defined $overlay->{color}) ? @{$overlay->{color}} : ();
      my $groups = $#{$overlay->{sequence}} + 1;
      for (my $i = 0; $i < $groups; $i++)
      {  if (! defined $color[$i])
         {  $col1 = $col3;
            my $alt1 = sprintf("%.2f", (rand(1)));
            my $alt2 = sprintf("%.2f", (rand(1)));
            $col2 = abs($col2 - $col3) > abs(1 - $col3) ? $col3 : (1 - $col3);
            $col3 = abs($col3 - $alt1) > abs($col3 - $alt2) ? $alt1 : $alt2;
            $color[$i] = "$col1 $col2 $col3";
         }
         if ((defined $overlay->{nogroups}) && ($overlay->{nogroups}))
         {  next;
         }
         my $name = $overlay->{sequence}->[$i];
         $str .= "$color[$i] rg\n";
         if (($yStart < ($y0 + 13)) && ($yStart > ($y0 - 18)))
         {   $yStart = $y0 - 20;
         }
         $str .= "$xStart $yStart 10 7 re\n";
         $str .= "b*\n";
         $str .= "0 0 0 rg\n";
         $str .= "BT\n";
         $str .= "/$font 12 Tf\n";
         $str .= "$tStart $yStart Td\n";       
         if ($name)
         {  $str .= '(' . $name . ') Tj' . "\n";
         }
         else
         {  $str .= '(' . $i . ') Tj' . "\n";
         }
         $str .= "ET\n";

         if  ((defined $self->{iparam})
         &&   (defined $overlay->{boxAction}->{$name}))
         {   $overlay->insert($xStart,
                           $yStart,
                           10,
                           7,
                           $self->{iparam},
                           $overlay->{boxAction}->{$name},
                           $overlay->{boxToolTip}->{$name});
          }
       
          $yStart -= $iStep;
      }
      @{$overlay->{color}} = @color;
   }

   for my $overlay ( reverse @array)
   {  $str .= "0 0 0 RG\n0 j\n0 J\n";
      if ($overlay->{type} eq 'bars')
      {  $str .= $overlay->draw_bars($xSteps, $xCor, $y0, $labelStep, $prop);
      }
      elsif ($overlay->{type} eq 'totalbars')
      {  $str .= $overlay->draw_totalbars($xSteps, $xCor, $y0, $labelStep, $prop);
      }
      elsif ($overlay->{type} eq 'lines')
      {  $str .= $overlay->draw_lines($xSteps, $xCor, $yCor, $labelStep, $prop, $min);      
      }
      elsif ($overlay->{type} eq 'percentbars')
      {  $str .= $overlay->draw_percentbars($xSteps, $xCor, $y0, $labelStep, $prop);
      }
      elsif ($overlay->{type} eq 'area')
      {  $str .= $overlay->draw_area($xSteps, $xCor, $y0, $labelStep, $prop);
      }
   }
   $str .= "Q\n";
   PDF::Reuse::prAdd($str);
   
   return $self;
}

sub draw_bars
{  my $self = shift;
   my ($xSteps, $xCor, $y0, $labelStep, $prop) = @_;
   if ($self->{level} ne 'top') 
   {   if ($self->{ydensity} != 1)
       {  $prop = sprintf("%.5f", ($prop / $self->{ydensity}));
       }
       if ($self->{xdensity} != 1)
       {  $labelStep = sprintf("%.5f", ($labelStep / $self->{xdensity}));
       }
   }

   my $string = '';
   my @color = @{$self->{color}};
   my $groups = $#{$self->{sequence}} + 1;

   my $width  = sprintf("%.5f", ($labelStep /  $groups ));
   for (my $j = 0; $j <= $xSteps; $j++)
   {   my $height;
       my $i = -1;
       for my $namn (@{$self->{sequence}})
       {  $i++;
          if (defined $self->{series}->{$namn}->[$j])
          {  if (ref($self->{series}->{$namn}->[$j]) eq 'ARRAY')
             {   my $number = $#{$self->{series}->{$namn}->[$j]} + 1;
                 my $fraction = sprintf("%.4f", ($width / $number));
                 my @actions = (ref($self->{barAction}->{$namn}->[$j]) eq 'ARRAY') ?
                          @{$self->{barAction}->{$namn}->[$j]} : ();
                 my @toolTips = (ref($self->{barToolTip}->{$namn}->[$j]) eq 'ARRAY')
                      ? @{$self->{barToolTip}->{$namn}->[$j]} : ();
                 my $k = 0;
                 for (@{$self->{series}->{$namn}->[$j]})
                 {  if (! defined $_)
                    {  $xCor += $fraction;
                       $k++;
                       next;
                    }
                    $height = sprintf("%.5f", ($_ * $prop)); 
                    $string .= "$color[$i] rg\n";
                    $string .= "$xCor $y0 $fraction $height re\n";
                    $string .= "b*\n";
                    if ((defined $self->{iparam})
                    &&  (defined $actions[$i]))
                    {   $self->insert( $xCor,
                                       $y0,
                                       $fraction,
                                       $height,
                                       $self->{iparam},
                                       $actions[$i],
                                       $toolTips[$i]);
                    }
                    $xCor += $fraction;
                    $k++;
                 }
             }
             else
             {   $height = sprintf("%.5f", ($self->{series}->{$namn}->[$j] * $prop));
                 $string .= "$color[$i] rg\n";
                 $string .= "$xCor $y0 $width $height re\n";
                 $string .= "b*\n";
                 if ((defined $self->{iparam})
                 &&  (defined $self->{barAction}->{$namn}->[$j]))
                 {   $self->insert( $xCor,
                                    $y0,
                                    $width,
                                    $height,
                                    $self->{iparam},
                                    $self->{barAction}->{$namn}->[$j],
                                    $self->{barToolTip}->{$namn}->[$j]);
                 }
                 $xCor += $width;
             }
          }
          else
          {  $xCor += $width;
          }
      }
   }
   return $string;
}

sub draw_totalbars
{  my $self = shift;
   my ($xSteps, $xCor, $y0, $labelStep, $prop) = @_;
   my $string = '';
   if ($self->{level} ne 'top') 
   {   if ($self->{ydensity} != 1)
       {  $prop = sprintf("%.5f", ($prop / $self->{ydensity}));
       }
       if ($self->{xdensity} != 1)
       {  $labelStep = sprintf("%.5f", ($labelStep / $self->{xdensity}));
       }
   }
   my ($x, $y, $yNeg, $height, $number, $fraction, $namn, $k, $value,
       @actions, @toolTips);
   my @color = @{$self->{color}};
      
   for (my $j = 0; $j <= $xSteps; $j++)
   {   $x = ($j * $labelStep) + $xCor;
       my $i = -1;
       if (! defined $self->{tot}[$j])
       {  next;
       }
       if (ref($self->{tot}[$j]) eq 'ARRAY')
       {   $number   = $#{$self->{tot}[$j]} + 1;
           $fraction = sprintf("%.4f", ($labelStep / $number));
           for ($i = 0; $i < $number; $i++)
           {   $k    = 0;
               $y    = $y0;
               $yNeg = $y0;
               for $namn (@{$self->{sequence}})
               {   @actions = (ref($self->{barAction}->{$namn}->[$j]) eq 'ARRAY') ?
                   @{$self->{barAction}->{$namn}->[$j]} : ();
                   @toolTips = (ref($self->{barToolTip}->{$namn}->[$j]) eq 'ARRAY')
                      ? @{$self->{barToolTip}->{$namn}->[$j]} : ();
                   $value = $self->{series}->{$namn}->[$j][$i];
                   if (! defined $value)
                   {  $k++; 
                      next;
                   }      
                   if ($value > 0)
                   {   $height  = sprintf("%.5f", ($value * $prop)); 
                       $string .= "$color[$k] rg\n";
                       $string .= "$x $y $fraction $height re\n";
                       $string .= "b*\n";
                       if ((defined $self->{iparam})
                       &&  (defined $actions[$i]))
                       {   $self->insert( $x,
                                          $y,
                                          $fraction,
                                          $height,
                                          $self->{iparam},
                                          $actions[$i],
                                          $toolTips[$i]);
                       }
                       $y += $height;
                       $k++;
                   }
                   elsif ($value < 0)
                   {   $height  = sprintf("%.5f", ($value * $prop)); 
                       $string .= "$color[$k] rg\n";
                       $string .= "$x $yNeg $fraction $height re\n";
                       $string .= "b*\n";
                       if ((defined $self->{iparam})
                       &&  (defined $actions[$i]))
                       {   $self->insert( $x,
                                          $yNeg,
                                          $fraction,
                                          $height,
                                          $self->{iparam},
                                          $actions[$i],
                                          $toolTips[$i]);
                       }
                       
                       $yNeg += $height;
                       $k++;
                   }
               }
               $x    += $fraction;
           }
       }
       else
       {   $number   = 1;
           $fraction = sprintf("%.4f", ($labelStep / $number));
           $y      = $y0;
           $yNeg   = $y0;
           $height = 0;
           $k   = 0;
           for $namn (@{$self->{sequence}})
           {   $value = $self->{series}->{$namn}->[$j];
               if (! defined $value)
               {  $k++; 
                  next;
               }      
               if ($value > 0)
               {   $height  = sprintf("%.5f", ($value * $prop)); 
                   $string .= "$color[$k] rg\n";
                   $string .= "$x $y $fraction $height re\n";
                   $string .= "b*\n";
                   if ((defined $self->{iparam})
                   &&  (defined $self->{barAction}->{$namn}->[$j]))
                   {   $self->insert( $x,
                                      $y,
                                      $fraction,
                                      $height,
                                      $self->{iparam},
                                      $self->{barAction}->{$namn}->[$j],
                                      $self->{barToolTip}->{$namn}->[$j]);
                   }
                   
                   $y += $height;
                   $k++;
               }
               elsif ($value < 0)
               {   $height  = sprintf("%.5f", ($value * $prop)); 
                   $string .= "$color[$k] rg\n";
                   $string .= "$x $yNeg $fraction $height re\n";
                   $string .= "b*\n";
                   if ((defined $self->{iparam})
                   &&  (defined $self->{barAction}->{$namn}->[$j]))
                   {   $self->insert( $x,
                                      $yNeg,
                                      $fraction,
                                      $height,
                                      $self->{iparam},
                                      $self->{barAction}->{$namn}->[$j],
                                      $self->{barToolTip}->{$namn}->[$j]);
                   }
                    $yNeg += $height;
                    $k++;
                }
           }          
      }
   }
   return $string;
}


sub draw_lines
{  my $self = shift;
   my ($xSteps, $xCor, $yCor, $labelStep, $prop, $min) = @_;
   if ($self->{level} ne 'top') 
   {   if ($self->{ydensity} != 1)
       {  $prop = sprintf("%.5f", ($prop / $self->{ydensity}));
       }
       if ($self->{xdensity} != 1)
       {  $labelStep = sprintf("%.5f", ($labelStep / $self->{xdensity}));
       }
   }
   
   my $string = "1 w\n1 j\n1 J\n";
   my @color = @{$self->{color}};
   my $offSet = ($min < 0) ? $min : 0;
   my $i = -1;
   
   for my $namn (@{$self->{sequence}})
   {   $i++;
       my ($move, $step);
       my $height;
       my $x = $xCor;
       my $x2;
       my $y2;
       $string .= "$color[$i] RG\n";
       $string .= "$color[$i] rg\n";
       for (my $j = 0; $j <= $xSteps; $j++)
       {   if (defined $self->{series}->{$namn}->[$j])
           {  if (ref($self->{series}->{$namn}->[$j]) eq 'ARRAY')
              {   my $number = $#{$self->{series}->{$namn}->[$j]} + 2;
                  $step = sprintf("%.4f", ($labelStep / $number));
                  my @actions = (ref($self->{barAction}->{$namn}->[$j]) eq 'ARRAY') ?
                           @{$self->{barAction}->{$namn}->[$j]} : ();
                  my @toolTips = (ref($self->{barToolTip}->{$namn}->[$j]) eq 'ARRAY')
                       ? @{$self->{barToolTip}->{$namn}->[$j]} : ();
                
                  my $k = 0;
                  $x += $step;
                  for (@{$self->{series}->{$namn}->[$j]})
                  {    if (! defined $_)
                       {  if ($move)
                          {  $string .= "b*\n";
                             $move = undef;
                          }
                          $k++;
                          $x += $step;
                          next;
                       }
                       $height = sprintf("%.5f", (($_ - $offSet) * $prop));
                       $height += $yCor;
                       $x2 = $x - 1.5;
                       $y2 = $height - 1.5;
                       if ($move)
                       {   $string .= "$move m\n" if ($move);
                           $string .= "$x $height l\n";
                       }
                       if (! defined $self->{nomarker}) 
                       {   $string .= "$x2 $y2 3 3 re\n";
                           if ((defined $self->{iparam})
                           &&  (defined $actions[$i]))
                           {   $self->insert( $x2,
                                              $y2,
                                              3,
                                              3,
                                              $self->{iparam},
                                              $actions[$i],
                                              $toolTips[$i]);
                            }
                        }
                       $move = "$x $height";
                       $k++;
                       $x += $step;
                   }
              }
              else
              {   $x += $labelStep / 2;
                  $height = sprintf("%.5f", (($self->{series}->{$namn}->[$j] - $offSet) * $prop));
                  $height += $yCor;
                  $x2 = $x - 1.5;
                  $y2 = $height - 1.5;
                  if ($move)
                  {   $string .= "$move m\n" if ($move);
                      $string .= "$x $height l\n";
                  }
                  if (! defined $self->{nomarker}) 
                  {   $string .= "$x2 $y2 3 3 re\n";
                      if ((defined $self->{iparam})
                      &&  (defined $self->{barAction}->{$namn}->[$j]))
                      {   $self->insert( $x2,
                                         $y2,
                                         3,
                                         3,
                                         $self->{iparam},
                                         $self->{barAction}->{$namn}->[$j],
                                         $self->{barToolTip}->{$namn}->[$j]);
                      }
                  }
                  $move  = "$x $height";
                  $x += $labelStep / 2;
               }           
           }
           else
           {  $string .= "b*\n";
              $move = undef;
              $x += $labelStep;
           }
              
       }
       $string .= "b*\n";
    }
    return $string;
}

sub draw_percentbars
{  my $self = shift;
   my ($xSteps, $xCor, $y0, $labelStep, $prop) = @_;
   if ($self->{level} ne 'top') 
   {   if ($self->{ydensity} != 1)
       {  $prop = sprintf("%.5f", ($prop / $self->{ydensity}));
       }
       if ($self->{xdensity} != 1)
       {  $labelStep = sprintf("%.5f", ($labelStep / $self->{xdensity}));
       }
   }
   my $string = '';
   my ($x, $y, $yNeg, $height, $number, $fraction, $namn, $k, $value,
       @actions, @toolTips);
   my @color = @{$self->{color}};
      
   for (my $j = 0; $j <= $xSteps; $j++)
   {   $x = ($j * $labelStep) + $xCor;
       my $i = -1;
       if (! defined $self->{tot}[$j])
       {  next;
       }
       if (ref($self->{tot}[$j]) eq 'ARRAY')
       {   $number   = $#{$self->{tot}[$j]} + 1;
           $fraction = sprintf("%.4f", ($labelStep / $number));
           for ($i = 0; $i < $number; $i++)
           {   $k    = 0;
               $y    = $y0;
               $yNeg = $y0;
               for $namn (@{$self->{sequence}})
               {   @actions = (ref($self->{barAction}->{$namn}->[$j]) eq 'ARRAY') ?
                   @{$self->{barAction}->{$namn}->[$j]} : ();
                   @toolTips = (ref($self->{barToolTip}->{$namn}->[$j]) eq 'ARRAY')
                      ? @{$self->{barToolTip}->{$namn}->[$j]} : ();
                   $value = $self->{series}->{$namn}->[$j][$i];
                   if (! defined $value)
                   {  $k++; 
                      next;
                   }      
                   if ($value > 0)
                   {   $height  = sprintf("%.4f", (($value / $self->{tot}[$j][$i])
                                                  * 100) * $prop); 
                       $string .= "$color[$k] rg\n";
                       $string .= "$x $y $fraction $height re\n";
                       $string .= "b*\n";
                       if ((defined $self->{iparam})
                       &&  (defined $actions[$i]))
                       {   $self->insert( $x,
                                          $y,
                                          $fraction,
                                          $height,
                                          $self->{iparam},
                                          $actions[$i],
                                          $toolTips[$i]);
                       }
                       $y += $height;
                       $k++;
                   }
                   elsif ($value < 0)
                   {   $height  = sprintf("%.4f", (($value / $self->{tot}[$j][$i])
                                                  * 100) * $prop); 
                       $string .= "$color[$k] rg\n";
                       $string .= "$x $yNeg $fraction $height re\n";
                       $string .= "b*\n";
                       if ((defined $self->{iparam})
                       &&  (defined $actions[$i]))
                       {   $self->insert( $x,
                                          $yNeg,
                                          $fraction,
                                          $height,
                                          $self->{iparam},
                                          $actions[$i],
                                          $toolTips[$i]);
                       }
                       
                       $yNeg += $height;
                       $k++;
                   }
               }
               $x    += $fraction;
           }
       }
       else
       {   $number   = 1;
           $fraction = sprintf("%.4f", ($labelStep / $number));
           $y      = $y0;
           $yNeg   = $y0;
           $height = 0;
           $k   = 0;
           for $namn (@{$self->{sequence}})
           {   $value = $self->{series}->{$namn}->[$j];
               if (! defined $value)
               {  $k++; 
                  next;
               }      
               if ($value > 0)
               {   $height  = sprintf("%.4f", (($value / $self->{tot}[$j])
                                                  * 100) * $prop); 
                   $string .= "$color[$k] rg\n";
                   $string .= "$x $y $fraction $height re\n";
                   $string .= "b*\n";
                   if ((defined $self->{iparam})
                   &&  (defined $self->{barAction}->{$namn}->[$j]))
                   {   $self->insert( $x,
                                      $y,
                                      $fraction,
                                      $height,
                                      $self->{iparam},
                                      $self->{barAction}->{$namn}->[$j],
                                      $self->{barToolTip}->{$namn}->[$j]);
                   }
                   
                   $y += $height;
                   $k++;
               }
               elsif ($value < 0)
               {   $height  = sprintf("%.4f", (($value / $self->{tot}[$j])
                                                  * 100) * $prop); 
                   $string .= "$color[$k] rg\n";
                   $string .= "$x $yNeg $fraction $height re\n";
                   $string .= "b*\n";
                   if ((defined $self->{iparam})
                   &&  (defined $self->{barAction}->{$namn}->[$j]))
                   {   $self->insert( $x,
                                      $yNeg,
                                      $fraction,
                                      $height,
                                      $self->{iparam},
                                      $self->{barAction}->{$namn}->[$j],
                                      $self->{barToolTip}->{$namn}->[$j]);
                   }
                    $yNeg += $height;
                    $k++;
                }
           }          
      }
   }
   return $string;
}


sub draw_area
{  my $self = shift;
   my ($xSteps, $xCor, $y0, $labelStep, $prop) = @_;
   if ($self->{level} ne 'top') 
   {   if ($self->{ydensity} != 1)
       {  $prop = sprintf("%.5f", ($prop / $self->{ydensity}));
       }
       if ($self->{xdensity} != 1)
       {  $labelStep = sprintf("%.5f", ($labelStep / $self->{xdensity}));
       }
   }
   my $string = '';
   my @color = @{$self->{color}};
   my $width = $labelStep / 2;
   my @pos = @{$self->{pos}};
   my @neg = @{$self->{neg}};
   my $i = -1;
   my ($y, $fraction);
   for my $namn (@{$self->{sequence}})
   {   $i++;
       my $move;
       my $x = $xCor;
       $string .= "$color[$i] RG\n";
       $string .= "$color[$i] rg\n";
       for (my $j = 0; $j <= $xSteps; $j++)
       {   if (defined $self->{series}->{$namn}->[$j])
           {  my $value = $self->{series}->{$namn}->[$j];
              if (ref($value) eq 'ARRAY')
              {   my $number = $#{$value} + 1;
                  my $fraction = sprintf("%.3f", ($labelStep / ($number * 2)));
                  my $k = 0;
                  for (@{$value})
                  {   if (! defined $_)
                      {   if ($move)
                          {   $string .= "$x $y l\n";
                              $string .= "$x $y0 l\n";
                              $string .= "B*\n";
                              undef $move;
                          }
                          $x += $fraction;
                      }
                      elsif ($_ > 0)
                      {   $y = sprintf("%.5f", (($pos[$j][$k] * $prop) + $y0));
                          if (! defined $move)
                          {  $string .= "$x $y0 m\n";
                             $string .= "$x $y l\n";
                             $move = 1;
                          }
                          $x += $fraction;
                          $string .= "$x $y l\n";
                          $pos[$j][$k] -= $_;
                      }
                      elsif ($_ < 0)
                      {   $neg[$j][$k] = 0 if (! defined $neg[$j][$k]);
                          $y = sprintf("%.5f", ($y0 - ($neg[$j][$k] * $prop)));
                          if (! defined $move)
                          {  $string .= "$x $y0 m\n";
                             $string .= "$x $y l\n";
                             $move = 1;
                          }
                          $x += $fraction;
                          $string .= "$x $y l\n";
                          $neg[$j][$k] += $_;  
                      }
                      else
                      {   $x += $fraction;
                      }
                      $x += $fraction;
                      $k++;
                  }      
              }
              else
              {   $fraction = $labelStep / 2;
                  if ($value > 0)
                  {   $y = sprintf("%.5f", (($pos[$j] * $prop) + $y0));
                      if (! defined $move)
                      {  $string .= "$x $y0 m\n";
                         $string .= "$x $y l\n";
                         $move = 1;
                      }
                      $x += $fraction;
                      $string .= "$x $y l\n";
                      $pos[$j] -= $value;
                  }
                  elsif ($value < 0)
                  {   $neg[$j] = 0 if (! defined $neg[$j]);
                      $y = sprintf("%.5f", ($y0 - ($neg[$j] * $prop)));
                      if (! defined $move)
                      {  $string .= "$x $y0 m\n";
                         $string .= "$x $y l\n";
                         $move = 1;
                      }
                      $x += $fraction;
                      $string .= "$x $y l\n";
                      $neg[$j] += $value;
                  }
                  else
                  {   $x += $fraction;
                  }
                  $x += $fraction;      
              }
           }
           else
           {   if ($move)
               {   $string .= "$x $y l\n";
                   $string .= "$x $y0 l\n";
                   $string .= "B*\n";
                   undef $move;
               }
               $x += $labelStep;
           }
                          
       }
       if ($move)
       {  $string .= "$x $y l\n";
          $string .= "$x $y0 l\n";
          $string .= "B*\n";          
       }
   }
   return $string;
}



sub insert
{   my $self = shift;
    my ($xPos, $yPos, $wid, $hei, $page, $action, $mess) = @_;
       
    my $x      = $self->{x} + $xPos * ($self->{xsize} * $self->{size});
    my $y      = $self->{y} + $yPos * ($self->{ysize} * $self->{size});
    my $width  = $wid * ($self->{xsize} * $self->{size});
    my $height = $hei * ($self->{ysize} * $self->{size});
    
    if ($mess)
    {  prInit("iArea($page, $x, $y, $width, $height, $action, $mess);");
    }
    else
    {  prInit("iArea($page, $x, $y, $width, $height, $action);");
    }
    1;
}

1;

__END__


=head1 NAME

PDF::Reuse::OverlayChart - Produce simple or mixed charts with PDF::Reuse

=head1 SYNOPSIS

=for synopsis.pl begin

   use PDF::Reuse::OverlayChart;
   use PDF::Reuse;
   use strict;
  
   prFile('myFile.pdf');
   my $s = PDF::Reuse::OverlayChart->new();

   $s->columns(qw(Month  January February  Mars  April  May June July));
   $s->add(      'Riga',     314,     490,  322,  -965, 736, 120, 239);
   $s->add(      'Helsinki', 389,    -865, -242,     7, 689, 294, 518);
   $s->add(      'Stockholm',456,    -712,  542,   367, 742, 189, 190);
   $s->add(      'Oslo',     622,     533,  674,  1289, 679, -56, 345);
  
   $s->draw(x     => 10,
            y     => 200,
            yUnit => '1000 Euros',
            type  => 'bars');
   prEnd();

=for end

=head1 DESCRIPTION

To draw charts with the help of PDF::Reuse. Currently there are 5 types:
'bars', 'totalbars','percentbars', 'lines' and 'area'. 

The charts can be overlaid, so you can mix the types in the same chart. (Except for
'percentbars', which can't be freely combined with the others.)
The entities shown, should have something in common, like the unit of the y-axis, but
that is not really necessary. It is up to you, what you want to combine and relate.

The object you create is a collection of data, which has a B<common> structure, and
which you want to present as a unit. It should consist of arrays B<or> arrays of
arrays. All the data of an object should have the same structure, so the module can
calculate sums and percentages in a consistent way.

If you want to compare data collections with different structure or very different
sizes, you should create different objects, which can be presented and "scaled" 
more or less independently of each other.


=head2 Extracting the examples from this POD

In the beginning of PDF::Reuse::Tutorial there is a snippet of code which can be
used to extract the examples from this POD.

Probably the best idea is to run the examples first, before looking at them in
detail.

=head1 Methods

=head2 new

    my $s = PDF::Reuse::OverlayChart->new();

Constructor. Mandatory.

You can also create a clone of an object like this:

    my $clone = $s->new();

=head2 add

    $s->add('name', value1, value2, ..., valueN);

To define data for the graph. 

The name will be put to the right of the graph. It will be the identifier 
(case sensitive) of the series, so you can add new values afterwards. (Then the 
values also have to come in exactly the same order.)

The values can be numbers with '-' and '.'. You can also have '' or undef to denote
a missing value. If the values contain other characters, the series is interpreted
as 'columns'.

The values can be either an array, B<or> an array of arrays (only two levels). Within
one object the data should have the same structure.
The elements of the top array will be put as columns in the chart.

If you have a text file ('textfile.txt') with a simple 2-dimensional table, like
the one here below, you can use each line as parameters to the method. 
(The value in the upper left corner will refer to the columns to the right, not to
the names under it.)

=for textfile.txt begin

    Month   January February Mars  April  May  June  July
    Riga        314    490    322   -965  736   120   239
    Helsinki    389   -865   -242      7  689   294   518
    Stockholm   456   -712    542    367  742   189   190
    Oslo        622    533    674   1289  679   -56   345

=for end

ex. ('example.pl'):

=for example.pl begin

   use PDF::Reuse::OverlayChart;
   use PDF::Reuse;
   use strict;
     
   prFile('myFile.pdf');
   my $s = PDF::Reuse::OverlayChart->new();
   
   open (INFILE, "textfile.txt") || die "Couldn't open textfile.txt, $!\n";
   while (<INFILE>)
   {  my @list = m'(\S+)'og;
      $s->add(@list) if (scalar @list) ;
   }
   close INFILE; 
  
   $s->draw(x     => 10,
            y     => 200,
            yUnit => '1000 Euros',
            type  => 'bars');
   prEnd();

=for end

=head2 columns

    $s->columns( qw(unit column1 column2 .. columnN));

Defines what you want to write along the x-axis. The first value will be put to 
the right of the arrow of the axis. It could be the "unit" of the columns.

=head2 draw

This method does the actual "plotting" of the graph. The parameters are

=over 4

=item x

x-coordinate of the lower left corner in pixels, where the graph is going to be drawn.
The actual graph comes still a few pixels to the right.

=item y

y-coordinate of the lower left corner in pixels, where the graph is going to be drawn.
The actual graph comes still a few pixels higher up.

=item width

Width of the graph. 450 by default. Long texts might end up outside.

=item height

Height of the graph. 450 by default.

=item size

A number to resize the graph, with lines, texts and everything

(If you change the size of a graph with the parameters width and height, the
font sizes, distances between lines etc. are untouched, but with 'size' they 
also change.)

=item xsize

A number to resize the graph horizontally, with lines, texts and everything

=item ySize

A number to resize the graph vertically, with lines, texts and everything

=item type

By default: 'bars'. Can also be 'totalbars', percentbars', 'lines' and 'area',
(you could abbreviate to the first character if you want). 

When you have 'lines' or 'area', you get vertical lines. They show where the 
values of the graph are significant. The values between these points are possible,
but of course not necessarily true. It is an illustration.

=item yUnit

What to write above the y-axis

=item background

Three RGB numbers ex. '0.95 0.95 0.95'.

=item noUnits

If this parameter is equal to 1, no units are written.

=item title

Title above the chart

=item groupsTitle

Titel above the column to the right of the chart

=item groupsText

Text under groupsTitle

=item initialMaxY

To force the program start with a specific max (positive) value for the scale along the y-axis.

=item initialMinY

To force the program start with a specific min (negative) value for the scale along the y-axis.

=item merge

To merge different graph-objects into one chart. The graph-objects should be put
in an anonymous array. Each graph-object should use the "overlay" method.
Ex :

   $val->draw(x            => 20,
              y            => 460,
              width        => 400,
              height       => 300,
              type         => 'lines',
              noMarker     => 1, 
              groupstitle  => 'Left Scale',
              title        => 'Amazon',
              yUnit        => 'USD',
              merge        => [ $sek->overlay    ( type         => 'lines',
                                                   yDensity     => $sekDensity,
                                                   noMarker     => 1),
                                $spIndex->overlay( type         => 'lines',
                                                   yDensity     => $spDensity,
                                                   noMarker     => 1),
                                $vol->overlay    ( type         => 'area',
                                                   rightScale   => 1,
                                                   yDensity     => $volumeDensity,
                                                   groupstitle  => 'Right Scale'),] );


In the example above 4 objects are combined into 1 chart. Each object can have its'
own density (but it is not necessary) and some other characteristics described under
"overlay". The objects are painted in reversed order: $vol, $spIndex, $sek and at 
last $val, which automatically gets the left scale and also the normative density 
of the chart. (Interactive functions for each object are also imported.)

The merge parameter is ignored, if the type of the main object is percentbars

=item noMarker

Only for lines. No markers will be painted.

=item noGroups

To suppress the names of the groups, so they will not be printed to the right of 
the chart.

=back

=head2 color

   $s->color( ('1 1 0', '0 1 1', '0 1 0', '1 0 0', '0 0 1'));

To define colors to be used. The parameter to this method is a list of RGB numbers.

You can also use some predefined color arrays: 'bright', 'dark', 'gray' or 'light',
but only one at a time. Then you get 10 predefined colors ex:

   $s-color('dark');  

If the module needs more colors than what has been given in the script,
it creates more, just from random numbers.

=head2 overlay

Defines how an imported graph-object should be painted. See the parameter merge 
under draw for an example.

Parameters:

=over 4

=item type

Can be bars, totalbars, lines and area, but not percentbars.

=item rightScale

If many objects have this parameter, only the first object will have a right scale
painted, and the "yDensity" of the scale will be derived from that object.

=item topScale

If many objects have this parameter, only the first object will have a top scale
painted, and the "xDensity" of the scale will be derived from that object. If
that object has some column labels defined (with the columns method), they will
also be used here.

=item noMarker

Only for lines. No markers will be painted.

=item noGroups

To suppress the names of the groups, so they will not be printed to the right of 
the chart.

=item xDensity

Density along the x-axis, a numeric value, possibly with decimals. If it is 10, it
denotes that 10 units along the x-axis in this sub chart corresponds to 1 unit in
the main chart. If it is 0.1, 1 unit in this chart corresponds to 10 units in the
main chart

=item yDensity

Density along the y-axis, a numeric value, possibly with decimals. If it is 10, it
denotes that 10 units along the y-axis in this sub chart corresponds to 1 unit in
the main chart.

=back

=head1 A simple example 

An invented company with a few offices.

=for general.pl begin

   use PDF::Reuse::OverlayChart;
   use PDF::Reuse;
   use strict;
     
   prFile('myFile.pdf');
   prCompress(1);
   my $s = PDF::Reuse::OverlayChart->new();

   ###########
   # Money in
   ###########

   $s->columns( qw(Month   January February Mars  April  May  June  July));
   $s->add(     qw(Riga        436   790     579   1023   964  520    390));
   $s->add(     qw(Helsinki    529   630     789    567   570   94    180));
   $s->add(     qw(Stockholm   469   534     642    767   712  399    190));
   $s->add(     qw(Oslo        569   833     967   1589   790  158    345));

   $s->draw(x      => 45,
            y      => 455,
            yUnit  => '1000 Euros',
            type   => 'bars',
            title  => 'Money In',
            height => 300,
            width  => 460);

   ###################################
   # Costs are to be shown separately
   ###################################

   my $costs = PDF::Reuse::OverlayChart->new();
   
   $costs->columns( qw(Month   January February Mars April  May  June  July));
   $costs->add(     qw(Riga        -316  -290  -376   -823 -243  -320  -509));
   $costs->add(     qw(Helsinki    -440  -830  -989   -671 -170  -394  -618));
   $costs->add(     qw(Stockholm   -218  -345  -242   -467 -412  -299  -590));
   $costs->add(     qw(Oslo        -369  -343  -567   -589 -390  -258  -459));

   $costs->draw(x      => 45,
                y      => 55,
                yUnit  => '1000 Euros',
                type   => 'bars',
                title  => 'Costs',
                height => 300,
                width  => 460);

   ####################################
   # The costs are added to 'money in'
   ####################################

   $s->add( qw(Riga        -316  -290  -376   -823 -243  -320  -509));
   $s->add( qw(Helsinki    -440  -830  -989   -671 -170  -394  -618));
   $s->add( qw(Stockholm   -218  -345  -242   -467 -412  -299  -590));
   $s->add( qw(Oslo        -369  -343  -567   -589 -390  -258  -459));

   prPage();

   $s->draw(x     => 45,
            y     => 455,
            yUnit => '1000 Euros',
            type  => 'bars',
            title => 'Profit');

   ########
   # Taxes
   ########

   $s->add( qw(Riga        -116  -90   -179   -230  -43  -20  -90));
   $s->add( qw(Helsinki     40   -130  -190   -32   -70  -30  -18));
   $s->add( qw(Stockholm    28   -45   -42    -107  -92  -99  -90));
   $s->add( qw(Oslo        -169  -43   -67    -189  -190 -58  -59));

   $s->draw(x     => 45,
            y     => 55,
            yUnit => '1000 Euros',
            type  => 'bars',
            title => 'After Tax');

    prEnd();

=for end

=head1 An example how to mix different graph types in the same chart

In this example you let a program collect historical quotes for 'Amazon', approximately
1 year back, and also values for 'S&P 100' and then you get a chart with combined
data, an area graph for volumes, and lines for the other values. (You need to have the
environment variable TZ defined somewhere, see Date::Manip, which is a module needed by
Finance::QuoteHist. TZ, time zone, could e.g. be CET or GMT in Western Europe.) 


=for overlay.pl begin

   use PDF::Reuse::OverlayChart;
   use Finance::QuoteHist;
   use PDF::Reuse;
   use strict;

   #################
   # Some variables
   #################
   my (%values, @values, %volumes, @volumes, %sp100, @sp100, $startValue, 
       $startSpValue);
   my $maxVolume = 0;
   my $maxValue  = 0;
   my $month = sprintf("%02d", ((localtime())[4]) + 1);
   my $lastYear = sprintf("%04d", ((localtime())[5] + 1900 - 1));
   my $aYearAgo = "$month/01/$lastYear";

   prFile('myFile.pdf');
   prCompress(1);
    
   ###########################################################
   # Get historical quotes via the web for Amazon and S&P100
   ###########################################################

   my $q = Finance::QuoteHist->new ( symbols    => [qw(AMZN ^OEX)],
                                     start_date => $aYearAgo,
                                     end_date   => 'today',);

   ##################################
   # Accumulate the values in hashes
   ##################################

   for my $row ($q->quotes()) 
   {  my ($symbol, $date, $open, $high, $low, $close, $volume) = @$row;
      if ($date =~ m'(\d+\/\d+)\/(\d+)'o)
      {   my $yearMonth = $1;
          my $day       = $2;
          if ($symbol ne '^OEX')
          {   $volume = sprintf("%.0f", ($volume / 1000000));
              $values{$yearMonth}->[$day]  = $close  if ($close);
              $volumes{$yearMonth}->[$day] = $volume if ($volume);
              $maxVolume  = $volume if $volume > $maxVolume;
              $maxValue   = $close  if $close  > $maxValue;
              $startValue = $close  if (! defined $startValue);
          }
          else
          {   $sp100{$yearMonth}->[$day]  = $close if ($close);
              $startSpValue               = $close if (!defined $startSpValue);
          }
      }
   }

   my @keys = sort (keys %volumes);
   my $i;

   ##########################################
   # Make one array of arrays of the volumes
   ##########################################

   for my $key  (@keys)
   {   my @array;
       for (@{$volumes{$key}})
       {  push @array, $_ if $_;        # Only days with trade
       }
       for ($i = $#array; $i < 18; $i++)
       {  push @array, undef;           # Fill the month, if not complete
       }
       push @volumes, [@array];         # One array per month is pushed to volumes
   }

   #################################################
   # Make one array of arrays of the closing values
   #################################################

   for my $key  (@keys)
   {   my @array;
       for (@{$values{$key}})
       {   push @array, $_ if $_;
       }
       for ($i = $#array; $i < 18; $i++)
       {  push @array, undef;
       }
       push @values, [@array];
   }

   ##########################################################
   # Make one array of arrays of the closing values of SP100
   ##########################################################

   for my $key  (@keys)
   {   my @array;
       for (@{$sp100{$key}})
       {   push @array, $_ if $_;
       }
       for ($i = $#array; $i < 18; $i++)
       {  push @array, undef;
       }
       push @sp100, [@array];
   }

   #########################################################################
   # Calculate a suitable density for the volumes so they fill up the chart 
   #########################################################################

   my $volumeDensity = sprintf("%.6f", ($maxVolume / $maxValue));

   ################################################################
   # Make the density for S&P 100 so it gets a good starting point
   ################################################################

   my $spDensity = sprintf("%.1f", ($startSpValue / $startValue));

   ########################################
   # Create and populate the chart-objects
   ########################################

   my $vol = PDF::Reuse::OverlayChart->new();
   $vol->add('Volume (1/1000000)', ( @volumes ));
   $vol->color('dark');

   my $val = PDF::Reuse::OverlayChart->new();
   $val->columns('Month', ( @keys ) ); 
   $val->add('Closing Value USD', ( @values ));
   $val->color('bright');

   my $spIndex = PDF::Reuse::OverlayChart->new();
   $spIndex->add("S&P 100 (1/$spDensity)", ( @sp100 ));
   $spIndex->color( ('0 0 0') );  

   #####################
   # Now draw the chart
   #####################

   $val->draw(x            => 20,
              y            => 460,
              width        => 400,
              height       => 300,
              type         => 'lines',
              noMarker     => 1, 
              groupstitle  => 'Left Scale',
              title        => 'Amazon',
              merge        => [ $spIndex->overlay( type         => 'lines',
                                                   yDensity     => $spDensity,
                                                   noMarker     => 1),
                                $vol->overlay    ( type         => 'area',
                                                   rightScale   => 1,
                                                   yDensity     => $volumeDensity,
                                                   groupstitle  => 'Right Scale')] );
 
   prEnd();

=for end

Comments about the example:

All the values are put in arrays of arrays like this:

    [  [day1 ... dayN],    # This is the first month
       [day1 ... dayN],    # Next month
       ...
       [day1 ... dayN]]    # Last month

In the chart there will be one column for each month. The column labels will be
taken from the main object. 

The 3 different chart-objects have different density along the y-axis
(yDensity). The main chart-object, '$val', gets a value automatically calculated.
It cannot be directly influenced. The other objects can get a yDensity defined.
Then it is always related to the main object. To make the S&P 100 index start in 
the same point as the first closing value for Amazon ($startValue), the yDensity for
the index-graph is calculated like this:

   my $spDensity = sprintf("%.1f", ($startSpValue / $startValue));

To make the graph for volumes fill the chart, the maximum values are coordinated
in a similar way:

   my $volumeDensity = sprintf("%.6f", ($maxVolume / $maxValue));

When the combined chart is drawn, the charts are painted in reversed order, so the
main cart is pained last. It also automatically gets the left scale.


=head1 SEE ALSO

   PDF::Reuse
   PDF::Reuse::Tutorial

=head1 MAILING LIST

   http://groups.google.com/group/PDF-Reuse

=head1 AUTHOR

Lars Lundberg, larslund@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 - 2005 by Lars Lundberg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 DISCLAIMER

You get this module free as it is, but nothing is guaranteed to work, whatever 
implicitly or explicitly stated in this document, and everything you do, 
you do at your own risk - I will not take responsibility 
for any damage, loss of money and/or health that may arise from the use of this module.

=cut