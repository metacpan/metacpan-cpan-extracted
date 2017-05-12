# perl
#
# Safer Perl: Template for method calls
#
# ClassTemplate
#
# Sat Sep 27 13:50:07 2014

package ClassTemplate;

use warnings;
use strict;

use Data::Dumper;

use Scalar::Validation qw(:all);
use MyValidation;

my ($is_self) = is_a __PACKAGE__; # parentesis are needed!!

# --- create Instance --------------------------------------------------
sub new
{
    my $caller = $_[0];
    my $class  = ref($caller) || $caller;
    
    # let the class go
    my $self = {};
    $self->{position} = {};
    bless $self, $class;

    return $self;
}

# ----------------------------------------------------------------------
sub no_args {
    my $trouble_level = p_start;
    p_end (\@_);
    
    return undef if validation_trouble $trouble_level; 
 
    # --- run sub -------------------------------------------------

    print "This sub has no arguments";

}
# ----------------------------------------------------------------------
sub add_date_positional {
    my $trouble_level = p_start;

    my $self     = par self => $is_self => shift;
    my $iso_date = par date => IsoDate  => shift;

    p_end (\@_);
 
    return undef if validation_trouble $trouble_level; 
 
    # --- run sub -------------------------------------------------

    $self->{date} = $iso_date;
    # print "ShoppingCart.put_in($article);\n";
}

# ----------------------------------------------------------------------
sub get_content {
    my $trouble_level = p_start;

    my $self    = par self => $is_self => shift;

    p_end \@_;
 
    return undef if validation_trouble $trouble_level; 
 
    # --- run sub -------------------------------------------------

    my $result = '';
    foreach my $article (sort(keys(%{$self->{articles}}))) {
	$result .= $self->{articles}->{$article}." * $article\n";
    }
    return $result;
}

# ----------------------------------------------------------------------
sub current_position_positional {
    my $trouble_level = p_start;

    my $self               = par self => $is_self => shift;

    $self->{position}->{x} = par x => Float => shift;
    $self->{position}->{y} = par y => Float => shift;
    $self->{position}->{z} = par z => Float => shift;

    p_end \@_;
 
    return undef if validation_trouble $trouble_level; 
 
    # --- run sub -------------------------------------------------

    print "Position: ".Dumper($self->{position});
}

# ----------------------------------------------------------------------
sub current_position_named {
    my $trouble_level = p_start;

    my $self    = par self => $is_self => shift;

    my %pars = convert_to_named_params \@_;

    $self->{position}->{x} = npar -x => Float => \%pars;
    $self->{position}->{y} = npar -y => Float => \%pars;
    $self->{position}->{z} = npar -z => Float => \%pars;

    p_end \%pars;
 
    return undef if validation_trouble $trouble_level; 
 
    # --- run sub -------------------------------------------------

    print "Position: ".Dumper($self->{position});
}

# --- mixed positional and named parameters -----------------------
sub current_position_at_date {
    my $trouble_level = p_start;

    my $self      = par self => $is_self => shift;
    $self->{date} = par date => IsoDate => shift;

    my %pars = convert_to_named_params \@_;

    $self->{position}->{x} = npar -x => Float => \%pars;
    $self->{position}->{y} = npar -y => Float => \%pars;
    $self->{position}->{z} = npar -z => Float => \%pars;

    p_end \%pars;
 
    return undef if validation_trouble $trouble_level; 
 
    # --- run sub -------------------------------------------------

    print "Position: ".Dumper($self);
}

# ----------------------------------------------------------------------
sub write {
    my $trouble_level = p_start;

    my $self = par self => $is_self => shift;
    my $file = par file => -Or => [FileName => FileHandle => 0] => shift;

    p_end \@_;
 
    return undef if validation_trouble $trouble_level; 
 
    # --- run sub -------------------------------------------------

    print "Position: ".Dumper($self);
}

# ----------------------------------------------------------------------
sub special_rule_test {
    my $trouble_level = p_start;

    my $self     = par self     => $is_self         => shift;
    my $optional = par optional => -Optional => Int => shift;

    my $file    = par file    => -Or    => [FileName => FileHandle => 0] => shift;
    my $number  = par number  => -And   => [Float    => Int        => 0] => shift;
    my $range   = par range   => -Range => [1,3]     => Int              => shift;
    my $enum    = par enum    => -Enum  => [qw(A B C D)]                 => shift;
    my $default = par default => -Default => 10.0    => Float            => shift;

    p_end \@_;
 
    return undef if validation_trouble $trouble_level; 
 
    # --- run sub -------------------------------------------------

    print "Position: ".Dumper($self);
}

  sub my_sub {
      my $trouble_level = p_start;

      my $first_par = par first_par => Int => shift;
      # additional parameters ...

      my %pars = convert_to_named_params \@_;

      my $max_potenz = npar -first_named => PositiveFloat => \%pars;
      # additional parameters ...

      p_end \%pars;

      # needed to exit sub in meta extraction mode
      return undef if validation_trouble($trouble_level);

      # ------------------

      # Code of sub doing something
  }


1;
