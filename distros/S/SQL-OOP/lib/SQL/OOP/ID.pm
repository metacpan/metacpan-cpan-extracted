### ---
### Class for dot-chained Identifier ex) "public"."table"."colmun1"
### ---
package SQL::OOP::ID;
use strict;
use warnings;
use base qw(SQL::OOP::Array);

### ---
### Constructor
### ---
sub new {
    my ($class, @array) = @_;
    return $class->SUPER::new(@array)->set_sepa('.');
}

### ---
### Append ID
### ---
sub append {
    my ($self, @array) = @_;
    $self->_init_gen;
    if (ref $array[0] && ref $array[0] eq 'ARRAY') {
        @array = @{$array[0]};
    }
    for my $elem (@array) {
        if ($elem) {
            push(@{$self->{array}}, SQL::OOP::ID::Parts->new($elem));
        }
    }
    return $self;
}

### ---
### "field AS foo" syntax
### ---
sub as {
    my ($self, $as) = (@_);
    $self->{as} = $as;
    return $self;
}

### ---
### Generate SQL snippet
### ---
sub generate {
    my $self = shift;
    my @array = map {$_->to_string} @{$self->{array}};
    $self->{gen} = join($self->{sepa}, grep {$_} @array);

    if ($self->{as}) {
        $self->{gen} .= ' AS '. $self->quote($self->{as});
    }
    
    return $self;
}

### ---
### Class for Identifier such as table, field schema
### ---
package SQL::OOP::ID::Parts;
use strict;
use warnings;
use base qw(SQL::OOP::Base);

### ---
### Generate SQL snippet
### ---
sub generate {
    my $self = shift;
    $self->SUPER::generate(@_);
    $self->{gen} = $self->quote($self->{gen});
}

1;

__END__

=head1 NAME

SQL::OOP::ID - IDs for SQL

=head1 SYNOPSIS
    
    ### field
    my $field = SQL::OOP::ID->new(@path_to_field);
    $field->to_string # e.g. "tbl"."col"
    
    ### from
    my $from = SQL::OOP::ID->new(@path_to_table);
    $from->to_string # e.g. "schema"."tbl"

=head1 DESCRIPTION

SQL::OOP::ID class represents IDs for such as table, schema fields.

=head1 SQL::OOP::ID CLASS

This class represents IDs such as table names, schema, field names. This class
inherits SQL::OOP::Array class.

=head2 SQL::OOP::ID->new(@ids)

=head2 $instance->as($str)

Here is some examples.
    
    my $id_obj = SQL::OOP::ID->new('public', 'tbl1'); 
    $id_obj->to_string; # "public"."tbl1"
    
    $id_obj->as('TMP');
    $id_obj->to_string; # "public"."tbl1" AS TMP

=head2 $instance->append($elems)

Appends elements into existing instance.

=head2 $instance->generate

This method generates SQL. This is automatically called by to_string so you
don't have to call it directly.

=head1 SQL::OOP::ID::Parts CLASS

This class is for internal use.

=head1 SEE ALSO

=cut
