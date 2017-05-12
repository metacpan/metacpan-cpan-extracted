package Parse::Liberty::Attribute;

use strict;
use warnings;

our $VERSION    = 0.13;

use Parse::Liberty::Constants qw($e $e2 %errors %attribute_types %value_types);
use Parse::Liberty::Value;


sub new {
    my $class = shift;
    my %options = @_;

    my $self = {
        object_type => 'attribute',
        parser      => $options{'parser'},
        parent      => $options{'parent'},
        si2_object  => $options{'si2_object'},
        depth       => $options{'depth'},
    };
    bless $self, $class;
    return $self;
}


sub methods {
    my $self = shift;
    return (join "\n", qw(lineno comment remove type name is_var get_values set_values extract))."\n";
}


sub lineno {
    my $self = shift;
    my $si2_attribute = $self->{si2_object};
    return liberty::si2drObjectGetLineNo($si2_attribute, \$e);
}


sub comment {
    my $self = shift;
    my $si2_attribute = $self->{si2_object};
    return liberty::si2drAttrGetComment($si2_attribute, \$e);
}


sub remove {
    my $self = shift;
    my $si2_attribute = $self->{si2_object};
    liberty::si2drObjectDelete($si2_attribute, \$e);
#    $self->DESTROY; # no sure we need this
    return 1;
}

################################################################################

sub type {
    my $self = shift;
    my $si2_attribute = $self->{si2_object};
    return $attribute_types{liberty::si2drAttrGetAttrType($si2_attribute, \$e)};
}


sub name {
    my $self = shift;
    my $si2_attribute = $self->{si2_object};
    return liberty::si2drAttrGetName($si2_attribute, \$e);
}


sub is_var {
    my $self = shift;
    my $si2_attribute = $self->{si2_object};
    my $type = $self->type;
    return ($type eq 'simple') ? liberty::si2drSimpleAttrGetIsVar($si2_attribute, \$e) : 0;
}


sub get_values {
    my $self = shift;
    my $si2_attribute = $self->{si2_object};

    my $type = $self->type;
    my @values;

    if($type eq 'simple') {

        my $si2_type = liberty::si2drSimpleAttrGetValueType($si2_attribute, \$e);
        push @values, new Parse::Liberty::Value (
            parser      => $self->{parser},
            parent      => $self,
            _si2_type   => $si2_type,
        );

    } elsif($type eq 'complex') {

        my $si2_values = liberty::si2drComplexAttrGetValues($si2_attribute, \$e);
        while(1) {
            my $si2_value = liberty::si2drIterNextComplex($si2_values, \$e);
            my $si2_type = liberty::si2drComplexValGetValueType($si2_value, \$e);
            last if $si2_type == $liberty::SI2DR_UNDEFINED_VALUETYPE;
            push @values, new Parse::Liberty::Value (
                parser      => $self->{parser},
                parent      => $self,
                si2_object  => $si2_value,
                _si2_type   => $si2_type,
            );
            last if !wantarray;
        }
        liberty::si2drIterQuit($si2_values, \$e);

    } else {
        push @values, 'undefined';
    }

    return wantarray ? @values : $values[0];
}


sub set_values {
    my $self = shift;
    my @req_values = @_;
    my $si2_attribute = $self->{si2_object};

    die "* Error: Odd number of type-value elements in set_values()\n" if !($#req_values % 2);

    my $type = $self->type;

    if($type eq 'simple') {

        my ($req_value_type, $req_value) = @req_values;

        ## convert value type to si2dr type
        my ($si2_value_type) = grep {$value_types{$_}->{type} eq $req_value_type} keys %value_types;

        my $func = $value_types{$si2_value_type}->{simple_set};
        &$func($si2_attribute, $req_value, \$e);

    } elsif($type eq 'complex') {

        my $name = $self->name;
        my $si2_parent = $self->{parent}->{si2_object};
        my $si2_type = $liberty::SI2DR_COMPLEX;

        ## delete original si2 attribute
        liberty::si2drObjectDelete($si2_attribute, \$e);

        ## create new one
        $si2_attribute = liberty::si2drGroupCreateAttr($si2_parent, $name, $si2_type, \$e);

        ## add values one by one
        while(@req_values) {
            my $req_value_type = shift @req_values;
            my $req_value = shift @req_values;

            ## convert value type to si2dr type
            my ($si2_value_type) = grep {$value_types{$_}->{type} eq $req_value_type} keys %value_types;

            my $func = $value_types{$si2_value_type}->{complex_add};
            &$func($si2_attribute, $req_value, \$e);
        }
    }

    return 1;
}


sub extract {
    my $self = shift;
    my $indent = $self->{parser}->{indent};
    my $depth = $self->{depth};
    my $comment = $self->comment;

    my $type = $self->type;
    my $name = $self->name;
    my @values = $self->get_values;

    my $string = '';

    my $indent_string = ' ' x $indent;
    my $full_indent1 = $indent_string x $depth;
    my $full_indent2 = $indent_string x ($depth+1);

    $string .= "/*$comment*/\n" if defined $comment;
    $string .= $full_indent1;
    if($type eq 'simple') {

        my $is_var = $self->is_var;
        my $value = $values[0]->value;
        my $delimeter = $is_var ? '=' : ':';
        $string .= "$name $delimeter $value ;";

    } elsif($type eq 'complex') {

        $string .= "$name (";
#        ## if >=2 values and all values has 'string' type, extract as table
#        if($#values && (grep {$_->type eq 'string'} @values) == scalar @values) {
        if($name eq 'values' && $#values >= 1) { # extract as table
            $string .=  " \\\n$full_indent2";
            $string .= join(", \\\n$full_indent2", map {$_->value} @values);
            $string .= "  \\\n$full_indent1";
        } else {
            $string .= join(', ', map {$_->value} @values);
        }
        $string .= ') ;';

    }

    $string .= "\n";
    return $string;
}


1;
