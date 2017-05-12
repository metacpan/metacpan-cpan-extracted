package Seis::MetaClass;
use strict;
use warnings;
use utf8;
use 5.010_001;
use Sub::Identify qw();
use Class::XSAccessor ();

# DO NOT CALL THIS METHOD DIRECTLY.
sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;
    my $self = bless {%args}, $class;
    $self;
}

sub name {
    my $self = shift;
    $self->{name};
}

sub methods {
    my $self = shift;
    no strict 'refs';

    my @ret;
    my $klass = $self->{name};
    my %hash = %{"${klass}::"};
    while (my ($k, $v) = each %hash) {
        next if $k =~ /^(?:BEGIN|CHECK|END)$/;
        next unless *{"${klass}::${k}"}{CODE};
        next if $klass ne Sub::Identify::stash_name($klass->can($k));
        push @ret, $k;
    }
    return @ret;
}

sub add_attribute {
    my ($self, $name) = @_;
    push @{$self->{attribute_names}}, $name;
    Class::XSAccessor->import(
        class => $self->{name},
        accessors => {
            $name => substr($name, 2),
        },
        replace => 1,
    );
}

1;

