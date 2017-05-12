# Perl
#
# Example of Scalar::Validation,
# using explicit in sub defined rules
#
# Ralf Peine, Sat Jul 12 12:49:47 2014

$| = 1;

use strict;
use warnings;

use Scalar::Validation qw (:all);

sub explicit {
    local $Scalar::Validation::trouble_level = 0;

    my $p_bool = par p_bool => -Enum => [0 => '1']               => shift;
    my $p_123  = par p_123  => -Enum => {1 => 1, 2 => 1, 3 => 1} => shift;
    my $p_free = par p_free => sub { $_ > 5 } => shift,
                               sub { "$_ is not larger than 5" };

    # --- something left in parameters ? ---
    p_end \@_;

    # --- stop if still running and some validations have failed ---
    return undef if validation_trouble();
	
    # --- run sub ------------

    print "explicit (p_bool = $p_bool, p_123 = $p_123, p_free = $p_free)";
    return $p_bool + $p_123 + $p_free;
}

# --- valid args -----------

print ": result = ". explicit(0.0, 1, 6)   ."\n";
print ": result = ". explicit(1, 2.0, 7.1) ."\n";

# --- NOT valid args -----------
print "\n";

eval { explicit();           }; print "Died: $@";
eval { explicit(3);          }; print "Died: $@";
eval { explicit(0, 7);       }; print "Died: $@";
eval { explicit(0, 2, 2);    }; print "Died: $@";
eval { explicit('a');        }; print "Died: $@";
eval { explicit(0, 'a');     }; print "Died: $@";
eval { explicit(0, 2, 6, 7); }; print "Died: $@";

# only real Floats are not valid, *.0 will be converted to integer
eval { explicit(1.1, 2, 7);   }; print "Died: $@";
eval { explicit(1.0, 2.1, 7); }; print "Died: $@";

print "\n# === see the problems, better use: greater_than 5 => Float => ... ===\n";

eval { explicit(0, 2, 'a');       }; print "Died: $@";

print "\n# === is not invalid, but should be!! ===\n";

my $number = 10;
print ": result = ". explicit(0, 2, \$number) ."\n";

print "\n# === handled correct by greater_than(...) === \n";

eval { par value_c   => greater_than 5 => Float => 'c'};      print "Died: $@";
eval { par value_ref => greater_than 5 => Float => \$number}; print "Died: $@";
