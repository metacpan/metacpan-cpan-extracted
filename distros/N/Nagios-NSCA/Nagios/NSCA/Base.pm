package Nagios::NSCA::Base;
use strict;
use warnings;
use UNIVERSAL;
use base qw(UNIVERSAL);

our $VERSION = sprintf("%d", q$Id: Base.pm,v 1.2 2006/04/10 22:39:38 matthew Exp $ =~ /\s(\d+)\s/);

sub new {
    my ($class, %args) = @_;
    return bless({_fields => {}}, $class);
}

sub _initFields {
    my ($self, $fields) = @_;
    return if not UNIVERSAL::isa($fields, 'HASH');

    # Set the initial values and the default values for the fields from the
    # given hash reference.  Things in the _fields hash are defaults.
    for my $field (keys %$fields) {
        next if $field eq '_fields';
        $self->{$field} = $self->{_fields}->{$field} = $fields->{$field};
    }
}

sub AUTOLOAD {
    my ($self, $value) = @_;

    # Pull the method name via the package global $AUTOLOAD variable.
    our $AUTOLOAD; 
    my $name = $AUTOLOAD;
    $name =~ s/.*://;
    return if $name eq 'DESTROY'; # Don't AUTOLOAD on the destroy method.

    # Make sure that we have an object and that the method exists
    if (not ref $self) {
        die "$self is not an object reference.\n";
    } elsif (not UNIVERSAL::isa($self, 'HASH')) {
        die "$self is an object, but not a blessed hash reference.\n";
    } elsif (not exists $self->{_fields}->{$name}) {
        die "Can't access \"$name\" field in class " . ref($self) . "\n";
    }

    # Set the value of the object
    if (defined $value) {
        # Change the fields setting.
        $self->{$name} = $value;  
    } elsif (not defined $self->{$name}) {
        # Use the supplied default value.
        $value = $self->{_fields}->{$name};  
    } else {
        # Use the value the field is already set to.
        $value = $self->{$name};  
    }

    return $value;
}

1;
