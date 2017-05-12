package Storm::Role::CanDeflate;
{
  $Storm::Role::CanDeflate::VERSION = '0.240';
}

use Moose::Role;

sub _deflate_values {
    my ( $self, $atts_ref, $values_ref ) = @_;

    my @deflated_values;    
    for my $i( 0..$#{$atts_ref} ) {
        push @deflated_values, $self->orm->policy->deflate_value($atts_ref->[$i], $values_ref->[$i]);
    }
    
    return @deflated_values;
}

no Moose::Role;
1;
