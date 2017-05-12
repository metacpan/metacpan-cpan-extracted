package Parse::Liberty::Value;

use strict;
use warnings;

our $VERSION    = 0.13;

use Parse::Liberty::Constants qw($e $e2 %errors %value_types);


sub new {
    my $class = shift;
    my %options = @_;

    my $self = {
        object_type => 'value',
        parser      => $options{'parser'},
        parent      => $options{'parent'},
        si2_object  => $options{'si2_object'},
        _si2_type   => $options{'_si2_type'},
    };
    bless $self, $class;
    return $self;
}


sub methods {
    my $self = shift;
    return (join "\n", qw(type value))."\n";
}

################################################################################

sub type {
    my $self = shift;

    my $si2_type = $self->{_si2_type};
    my $type = $value_types{$si2_type}->{type};

    return $type;
}


sub value {
    my $self = shift;

    my $attribute = $self->{parent};
    my $si2_attribute = $attribute->{si2_object};
    my $attribute_type = $attribute->type;
    my $si2_value = $self->{si2_object};
    my $si2_type = $self->{_si2_type};
    my $type = $self->type;

    my $value = '';

    ## get value
    if($attribute_type eq 'simple') {
        my $func = $value_types{$si2_type}->{simple_get};
        $value = &$func($si2_attribute, \$e);
    } elsif($attribute_type eq 'complex') {
        my $func = $value_types{$si2_type}->{complex_get};
        $value = &$func($si2_value, \$e);
    }

    ## clean up
    if($type eq 'expression') {
        $value = liberty::si2drExprToString($value, \$e);
    } elsif($type eq 'boolean') {
        $value = ($value == 0) ? 'false' : 'true';
    } elsif($value !~ m/"/
    && ($value =~ m/[\s()]/
    || $attribute->name =~ m/function$/
    || $attribute->name eq 'clear'
    || $attribute->name =~ m/clocked_on/
    || $attribute->name eq 'contention_condition'
    || $attribute->name eq 'data_in'
    || $attribute->name eq 'enable'
    || $attribute->name eq 'enable_also'
    || $attribute->name eq 'next_state'
    || $attribute->name eq 'preset'
    || $attribute->name =~ m/^sdf_/
    || $attribute->name eq 'three_state'
    || $attribute->name =~ m/^when/)) {
        $value = "\"$value\"";
    }

    return $value;
}


1;
