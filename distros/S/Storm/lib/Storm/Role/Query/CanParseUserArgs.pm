package Storm::Role::Query::CanParseUserArgs;
{
  $Storm::Role::Query::CanParseUserArgs::VERSION = '0.240';
}

use Storm::SQL::Column;
use Storm::SQL::Literal;
use Storm::SQL::Placeholder;


use Moose::Role;

sub args_to_sql_objects {
    my $self = shift;
    my @args = @_;
    
    # perform substitution on arguments
    my $map = $self->can('_attribute_map') ?  $self->_attribute_map : {};
    for ( @args ) {
        next if ! defined $_;
        
        if ( ! blessed $_) {
            # replace backtick quoted items with ::SQL::Literal object
            if (/^`(.*)`$/) {
                $_ = Storm::SQL::Literal->new( $1 );
            }
            # replace attribute names with column objects
            elsif ( /^\.(\w+)$/) {
                my $attname = $1;
                if ( exists $map->{$1} ) {
                    my $column = Storm::SQL::Column->new(
                        $self->orm->table( $self->class ) . '.' . $map->{$1}->column->name
                    );
                    
                    $_ = $column;
                }
                else {
                    confess qq[bad attribute $1];
                }
            }
            # parse object.attribute notation
            elsif ( $_ =~ /^\.(\w+)\.(\w+)/) {
                if (exists $map->{$1} ) {
                    
                    my $attr = $map->{$1};
                    my $type_constraint = $attr->type_constraint;
                    
                    
                    # we need to account for how maybe types work
                    if ($type_constraint->parent && $type_constraint->parent->name eq 'Maybe') {
                        use Moose::Util::TypeConstraints;
                        $type_constraint = find_type_constraint($type_constraint->{type_parameter});
                        no Moose::Util::TypeConstraints;
                    }
                    
                    my $class;
                    
                    # go through the type heirarchy until we find a Gi::ORM object
                    while ( $type_constraint && ! $class ) {
                        
                        if ($type_constraint->can('class') &&
                            $type_constraint->class &&
                            $type_constraint->class->can('meta') &&
                            $type_constraint->class->meta->does_role('Storm::Role::Object')) {
                    
                            
                            $class = $type_constraint->class;
                            my $meta  = $class->meta;
                            
                            my $child_attr = $meta->get_attribute( $2 );
                            my $column = Storm::SQL::Column->new(
                                $meta->storm_table->name . '.' . $child_attr->column->name
                            );
                            
                            $_ = $column;
                            
                            $self->_from( $class->meta->storm_table  );
                            $self->_link(  $attr, $class );
                        }
                        else {
                            $type_constraint = $type_constraint->parent;
                        }
                    }
                }
            }
            # question marks are turned into parameters
            elsif ( $_ eq '?' ) {
                $_ = Storm::SQL::Placeholder->new( value => Storm::SQL::Parameter->new );
            }
            # regular strings are turned into placeholders
            else {
                $_ = Storm::SQL::Placeholder->new( value => $_ );
            }
            
        }
        # if is blessed
        else {
            # if we have a gi-orm object
            # replace the argument with a placeholder
            # containing the identifier
            if ( $_->does( 'Storm::Role::Object' ) ) {                
                $_ = Storm::SQL::Placeholder->new( value => $_->meta->primary_key->get_value($_)); 
            }
        }
    }
    return @args;
}

no Moose::Role;

1;
