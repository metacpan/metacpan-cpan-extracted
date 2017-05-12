package Storm::Role::CanInflate;
{
  $Storm::Role::CanInflate::VERSION = '0.240';
}

use Moose::Role;

sub _inflate_values  {
    my ( $self, $atts_ref, $values_ref ) = @_;
    
    my @inflated_values;    
    for my $i( 0..$#{$atts_ref} ) {
        push @inflated_values, $self->orm->policy->inflate_value($self->orm, $atts_ref->[$i], $values_ref->[$i]);
    }
    
    return @inflated_values;
}

no Moose::Role;
1;
