package Net::Amazon::MechanicalTurk::DataStructure;
use strict;
use warnings;

our $VERSION = '1.00';

sub wrap {
    my ($class, $data) = @_;
    visit($data, sub {
        my ($key, $value, $nodes) = @_;
        if (ref($value)) {
            bless($value, $class);
        }
    });
}

sub fromProperties {
    # Assume static call if 1st arg is not this class
    shift if ($#_ >= 0 and $_[0] eq "Net::Amazon::MechanicalTurk::DataStructure");
    my $data = {};
    my $props = shift;
    
    while (my ($fullKey,$value) = each %$props) {
        my $nodeRef = \$data;
        foreach my $key (split(/\./, $fullKey)) {
            if (UNIVERSAL::isa(${$nodeRef}, "HASH")) {
                $nodeRef = \${$nodeRef}->{$key};
            }
            elsif (UNIVERSAL::isa(${$nodeRef}, "ARRAY")) {
                if ($key !~ /^\d+$/ or $key < 1) {
                    Carp::croak("Can't convert key $fullKey to data structure.");
                }
                $nodeRef = \${$nodeRef}->[$key-1];
            }
            elsif ($key =~ /^\d+$/) {
                ${$nodeRef} = [];
                $nodeRef = \${$nodeRef}->[$key-1];
            }
            else {
                ${$nodeRef} = {};
                $nodeRef = \${$nodeRef}->{$key};
            }
        }
        ${$nodeRef} = $value;
    }
    
    return $data;
}

sub toProperties {
    # Assume static call if 1st arg is not this class
    shift if ($#_ >= 0 and $_[0] eq "Net::Amazon::MechanicalTurk::DataStructure");
    my $self = shift;
    my $props = {};
    eachFlattenedProperty($self, sub {
        my ($key, $value) = @_;
        $props->{$key} = $value;
    });
    return $props;
}

sub eachFlattenedProperty {
    # Assume static call if 1st arg is not this class
    shift if ($#_ >= 0 and $_[0] eq "Net::Amazon::MechanicalTurk::DataStructure");
    my ($self, $block) = @_;
    return unless defined($self);
    _eachFlattenedProperty(undef, $self, 0, $block);
}

sub _eachFlattenedProperty {
    my ($key, $value, $parentIsHash, $block) = @_;
    if (UNIVERSAL::isa($value, "ARRAY")) {
        for (my $i=0; $i<=$#{$value}; $i++) {
            _eachFlattenedProperty($key.".".($i+1), $value->[$i], 0, $block);
        }
    }
    elsif (UNIVERSAL::isa($value, "HASH")) {
        while (my ($subKey,$subValue) = each %$value) {
            my $newKey = $subKey;
            if (defined($key)) {
                $newKey = ($parentIsHash) ? "${key}.1.${subKey}" : "${key}.${subKey}";
            }
            _eachFlattenedProperty($newKey, $subValue, 1, $block);
        }
    }
    else {
        $block->($key, $value);
    }
}

sub visit {
    # Assume static call if 1st arg is not this class
    shift if ($#_ >= 0 and $_[0] eq "Net::Amazon::MechanicalTurk::DataStructure");
    my ($self, $block, $orderKeys) = @_;
    _visit(undef, $self, [], $block, $orderKeys);
}

sub _visit {
    my ($key, $value, $nodes, $block, $orderKeys) = @_;
    return unless defined($value);
    
    $block->($key, $value, $nodes);
    push(@$nodes, $value);
    if (UNIVERSAL::isa($value, "HASH")) {
        if ($orderKeys) {
            foreach my $k (sort keys %$value) {
                _visit($k, $value->{$k}, $nodes, $block, $orderKeys);
            }
        }
        else {
            while (my ($k,$v) = each %{$value}) {
                _visit($k, $v, $nodes, $block, $orderKeys);
            }
        }
    }
    elsif (UNIVERSAL::isa($value, "ARRAY")) {
        for (my $i=0; $i<=$#{$value}; $i++) {
            _visit($i, $value->[$i], $nodes, $block, $orderKeys);
        }
    }
    pop(@$nodes);
}

sub toString {
    # Assume static call if 1st arg is not this class
    shift if ($#_ >= 0 and $_[0] eq "Net::Amazon::MechanicalTurk::DataStructure");
    my $self = shift;
    my $message = "<<" . ref($self) . ">>";
    visit($self, sub {
        my ($key, $value, $nodes) = @_;
        if (!defined($key)) {
            return;
        }
        if (!UNIVERSAL::isa($value, "ARRAY") && !UNIVERSAL::isa($value, "HASH")) {
            $message .= "\n" . (" " x ($#{$nodes}*2)) . "[$key]" . " " . $value;
        }
        else {
            $message .= "\n" . (" " x ($#{$nodes}*2)) . "[$key]";
        }
    }, 1);
    return $message;
}

sub getFirst {
    # Assume static call if 1st arg is not this class
    shift if ($#_ >= 0 and $_[0] eq "Net::Amazon::MechanicalTurk::DataStructure");
    my $self = shift;
    my $result = get($self, @_);
    if (UNIVERSAL::isa($result, "ARRAY")) {
        return ($#{$result} >= 0) ? $result->[0] : undef;
    }
    else {
        return $result;
    }
}

sub get {
    # Assume static call if 1st arg is not this class
    shift if ($#_ >= 0 and $_[0] eq "Net::Amazon::MechanicalTurk::DataStructure");
    my $self = shift;

    my @matches;
    if ($#_ == 0) {
        if (UNIVERSAL::isa($_[0], "ARRAY")) {
            @matches = @$_[0];
        }
        else {
            @matches = split /\./, $_[0];
        }
    }
    else {
        @matches = @_;
    }

    my $node = $self; 
    my $i = 0;
    while ($i <= $#matches) {
        my $match = $matches[$i];
        if (UNIVERSAL::isa($node, "ARRAY")) {
            # numeric indices are 1 based
            if ($match =~ /^\d+$/) {
                if ($match < 1 or $match > ($#{$node}+1)) {
                    return undef;
                }
                $node = $node->[$match-1];
                $i++;
            }
            elsif ($#{$node} >= 0) {
                $node = $node->[0];
            }
            else {
                return undef;
            }
        }
        elsif (UNIVERSAL::isa($node, "HASH")) {
            if (!exists $node->{$match}) {
                if ($match =~ /^\d+$/ and $match == 1) {
                    # handle case where data structure has 
                    # a hash containing a hash
                    # but get supplied an index of 1
                    # family.1.kid.1
                    # { family => { kid => ['k1', 'k2' ] }
                    # allows get to read properties produced
                    # by toProperties
                    $i++;
                }
                else {
                    return undef;
                }
            }
            else {
                $node = $node->{$match};
                $i++;
            }
        }
        else {
            return undef;
        }
    }

    return $node;
}

return 1;
