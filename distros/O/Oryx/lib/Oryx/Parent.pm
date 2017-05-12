package Oryx::Parent;

use Scalar::Util qw(blessed);

use base qw(Oryx::MetaClass);

=head1 NAME

Oryx::Parent - multiple inheritance meta-type for Oryx

=head1 SYNOPSIS

 package Fruit;
 use base qw(Oryx::Class);
 our $schema = {
     attributes => [{
         colour => 'String',
     }],
 }
 1;
 
 package Food;
 use base qw(Oryx::Class);
 our $schema = {
     attributes => [{
         energy => 'Float',
     }],
 }
 1;
 
 package Orange;
 use base qw(Fruit Food);
 our $schema = {
     attributes => [{
         segments => 'Integer',
     }]
 }
 1;
 
 use Orange;
 my $orange = Orange->create({
     segments => 10,
     energy   => 543.21,
     colour   => 'orange',
 });
 
 $orange->update;
 $orange->commit;
 
 my $id = $orange->id;
 undef $orange;
 
 my $retrieved = Orange->retrieve($id);
 print $retrieved->colour;        # prints 'orange'
 
 my $food_instance = $retrieved->PARENT('Food');
 print $food_instance->energy;    # prints 543.21
 
 $food_instance->energy(42.00);
 $food_instance->update;
 
 my $changed_orange = Orange->retrieve($id);
 print $changed_orange->energy;   # prints 42.00 (parent instance updated)

=head1 DESCRIPTION

Oryx::Parent objects are constructed during L<Oryx::Class> initialization
by inspecting your class' C<@ISA> array, so you get one of these hanging
off your class for each superclass that is also an L<Oryx::Class> derivative.

=cut

sub new {
    my $_class = shift;
    my ($class, $child) = @_;
    my $self = bless {
        class => $class, # superclass
        child => $child, # subclass
    }, $_class;

    eval "use $class"; $self->_croak($@) if $@;

    unless (UNIVERSAL::can($child, 'PARENT')) {
	no strict 'refs';
	*{$child.'::PARENT'} = $self->_mk_accessor;
    }

    return $self;
}

sub dbh { $_[0]->{class}->dbh }

sub class { $_[0]->{class} }

sub child { $_[0]->{child} }

sub link_table {
    lc($_[0]->child->name.'_parents');
}

sub child_field {
    return lc($_[0]->child->name.'_id');
}

sub _mk_accessor {
    return sub {
        my $self  = shift;
        my $class = shift;
        $self->{__parents} = { } unless defined $self->{__parents};
        if (@_) {
            $self->{__parents}->{$class} = shift;
        } else {
            $self->{__parents}->{$class};
        }
    };
}

1;

__END__

