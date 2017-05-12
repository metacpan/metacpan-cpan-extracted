package Storm::Role::Query::HasBindParams;
{
  $Storm::Role::Query::HasBindParams::VERSION = '0.240';
}
use Moose::Role;

use MooseX::Types::Moose qw( ArrayRef );

requires 'bind_params';

sub _combine_bind_params_and_args {
    my ( $self, $params, $args ) = @_;
    
    
    
    my @pass_values;
    
    for (@$args) {
        if ( ref $_ && $_->can('meta') &&  $_->meta->does_role('Storm::Role::Object') ) {
            $_ =  $_->meta->primary_key->get_value( $_ );
        }
    }
    
    for my $param (@$params) {
        if ( ref $param ) {
            if (  $param->isa('Storm::SQL::Parameter') ) {
                push @pass_values, shift @$args;
            }
            elsif ( $param->can('meta') && $param->meta->does_role('Storm::Role::Object') ) {
                my $id = $param->meta->primary_key->get_value( $param );
                push @pass_values, $id;
            }
            else {
                push @pass_values, $param;
            }
        }
        else {
            push @pass_values, $param;
        }
    }
    
    return @pass_values;
}

no Moose::Role;
1;
