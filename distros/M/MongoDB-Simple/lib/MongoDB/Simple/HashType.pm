package MongoDB::Simple::HashType;

use strict;
use warnings;
our $VERSION = '0.005';

use Tie::Hash;
our @ISA = ('Tie::Hash');

# Copied from Tie::StdArray and modified to use a hash

sub log {
    my $self = shift;
    $self->{parent}->log(@_);
}
sub registerChange {
    my ($self, $field, $change, $value, $callbacks) = @_;
    # TODO namespacing
    $self->log("HashType::registerChange for field[$field], change[$change], value[$value]");
    $field = $self->{field} . '.' . $field;
    $self->log(" -- new field is: $field");
    $self->{parent}->registerChange($field, $change, $value, $callbacks);
}
sub lookForCallbacks {
    my $self = shift;
    return $self->{parent}->lookForCallbacks(@_);
}

sub new {
    my ($class, %args) = @_;

    my $self = bless {
        'hash' => {},
        'parent' => undef,
        'field' => undef,
        'meta' => undef,
        'doc' => {}, # represents the hashref used by mongodb
        'objcache' => {},
        'arraycache' => {},
        %args
    }, $class;

    $self->{meta} = $self->{parent}->{meta}->{fields}->{$self->{field}};

    return $self;
}

sub TIEHASH  { 
    my $class = shift;
    return $class->new(@_);
}

sub STORE    { 
    my ($self, $key, $value) = @_;
    $self->{parent}->log("HashType::Store key[$key], value[$value]");
    $self->{hash}->{$key} = $value;
#    if(ref $value =~ /HASH/ && !tied($value)) {
#        my %h = (%$value);
#        my $o = tie %h, 'MongoDB::Simple::HashType', hash => $value, parent => $self, field => $key;
#        $self->{objcache}->{$key} = {
#            objref => $o,
#            hashref => \%h
#        };
#    } elsif(ref $value =~ /ARRAY/ && !tied($value)) {
#        # TODO same for arrays
#    }
    #if(ref $value ne 'HASH' && ref $value ne 'ARRAY') {
        # array and hash types handle pushes etc themselves?
# TODO if we create an empty array ref and then push to it, the item gets added once here and once with the push
        $self->registerChange($key, '$set', $value);
    #}
}
sub FETCH    {
    my ($self, $key) = @_;
    my $value = $self->{hash}->{$key};
    if($value) {
        $self->{parent}->log("HashType::Fetch key[$key], value[$value], ref[" . ref($value) . "], tied[" . (tied $value ? tied $value : '') . "]");
    } else {
        $self->{parent}->log("HashType::Fetch key[$key], value is undefined");
    }

    if($value && (ref $value eq 'HASH') && !tied($value)) {
        $self->{parent}->log("HashType::Fetch value is hash and not tied");
        if($self->{objcache}->{$key}) {
            $self->{parent}->log("HashType::Fetch key found in objcache");
            return $self->{objcache}->{$key}->{hashref};
        }
        my %h = (%$value);
        my $o = tie %h, 'MongoDB::Simple::HashType', hash => $value, parent => $self, field => $key;
        $self->{objcache}->{$key} = {
            objref => $o,
            hashref => \%h
        };
        return \%h;
    } elsif($value && (ref $value eq 'ARRAY') && !tied($value)) {
        $self->{parent}->log("HashType::Fetch value is array and not tied");
        if($self->{arraycache}->{$key}) {
            $self->{parent}->log("HashType::Fetch key found in arraycache");
            return $self->{arraycache}->{$key}->{arrayref};
        }
        my @arr = (@$value);
        my $o = tie @arr, 'MongoDB::Simple::ArrayType', array => $value, parent => $self, field => $key;
        $self->{arraycache}->{$key} = {
            objref => $o,
            arrayref => \@arr
        };
        $self->{parent}->log("HashType::Fetch returning new array");
        return \@arr;
    } else {
        $self->{parent}->log("HashType::Fetch value is not array, hash or is already tied");
    }

    return $value;
}
sub FIRSTKEY { 
    my ($self) = @_;
    my $a = keys %{$self->{hash}};
    my $ret = each %{$self->{hash}};
    $self->{parent}->log("HashType::FirstKey returning[" . ($ret ? $ret : '<undef>') . "]");
    return $ret;
}
sub NEXTKEY  { 
    my ($self) = @_;
    my $ret = each %{$self->{hash}};
    $self->{parent}->log("HashType::NextKey returning[" . ($ret ? $ret : '<undef>') . "]");
    return $ret;
}
sub EXISTS   { 
    my ($self, $key) = @_;
    return exists $self->{$key};
}
sub DELETE   {
    my ($self, $key) = @_;
    # TODO register change for delete
    delete $self->{$key}; 
}
sub CLEAR    { 
    my ($self) = @_;
    # TODO register change for clear
    %{$self->{hash}} = ();
}
sub SCALAR   { 
    my ($self) = @_;
    return scalar %{$self->{hash}};
}

1;
