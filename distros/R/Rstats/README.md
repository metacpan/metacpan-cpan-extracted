# Rstats

R language build on Perl (EXPERIMENTAL)

# Features

* R language build on Perl
* Support same syntax as R as possible

# Installation

If you alrealdy install local perl by perlbrew or plenv,
you can put only the following command.

    git clone https://github.com/yuki-kimoto/Rstats.git
    tar cfz Rstats.tar.gz Rstats;
    curl -L cpanmin.us | perl - -n Rstats.tar.gz

# Syntax

    use Rstats;
    
    # Vector
    my $v1 = c(1, 2, 3);
    my $v2 = c(3, 4, 5);
    
    my $v3 = $v1 + v2;
    print $v3;
    
    # Sequence m:n
    my $v1 = C('1:3');

    # Matrix
    my $m1 = matrix(C('1:12'), 4, 3);
    
    # Array
    my $a1 = array(C(1:24), c(4, 3, 2));

    # Complex
    my $z1 = 1 + 2 * i;
    my $z2 = 3 + 4 * i;
    my $z3 = $z1 * $z2;
    
    # Special value
    my $true = TRUE;
    my $false = FALSE;
    my $na = NA;
    my $nan = NaN;
    my $inf = Inf;
    my $null = NULL;
    
    # all methods is called from r
    my $x1 = r->sum(c(1, 2, 3));
    
    # Register function
    r->function(my_sum => sub {
      my ($self, $x1) = @_;
      
      my $total = 0;
      for my $value ($x1->values) {
        $total += $value;
      }
      
      return c($total);
    });
    my $x2 = r->my_sum(c(1, 2, 3));
