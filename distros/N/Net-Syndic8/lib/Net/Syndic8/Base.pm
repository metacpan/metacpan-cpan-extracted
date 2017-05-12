#$Id: Base.pm,v 1.3 2004/03/09 20:34:26 zagap Exp $

package Net::Syndic8::Base;
#require Exporter;
# Import freeze() and thaw() for methods ref2str & str2ref
use FreezeThaw qw(freeze thaw); 
use Carp;
@Net::Syndic8::Base::ISA = qw(Exporter);
@Net::Syndic8::Base::EXPORT = qw(attributes rtl_attributes);

$DEBUG = 0; # assign 1 to it to see code generated on the fly 
sub attributes {
  my ($pkg) = caller;
  croak "Error: attributes() invoked multiple times" 
    if scalar @{"${pkg}::_ATTRIBUTES_"};

  @{"${pkg}::_ATTRIBUTES_"} = @_;
  my $code = "";
  print STDERR "Creating methods for $pkg\n" if $DEBUG;
  foreach my $attr (@_) {
    print STDERR "  defining method $attr\n" if $DEBUG;
    # If the accessor is already present, give a warning
    if (UNIVERSAL::can($pkg,"$attr")) {
      carp "$pkg already has method: $attr";
	next;
    }
#    $code .= (UNIVERSAL::can($pkg,"__define_accessor")) ? __define_accessor ($pkg, $attr):_define_accessor ($pkg, $attr);
    $code .= _define_accessor ($pkg, $attr);
  }
#  $code .= _define_constructor($pkg);
  eval $code;
  if ($@) {
    die  "ERROR defining and attributes for '$pkg':"
       . "\n\t$@\n" 
       . "-----------------------------------------------------"
       . $code;
  }
}
sub rtl_attributes {
  my ($pkg) = caller;
  my $code = "";
  foreach my $attr (@_) {
    print STDERR "  defining method $attr\n" if $DEBUG;
    # If the accessor is already present, give a warning
    if (UNIVERSAL::can($pkg,"$attr")) {
      carp "$pkg already has rtl method: $attr";
	next;
    }
    $code .= _define_rtl_accessor ($pkg, $attr);
  }
  eval $code;
  if ($@) {
    die  "ERROR defining  rtl_attributes for '$pkg':"
       . "\n\t$@\n" 
       . "-----------------------------------------------------"
       . $code;
  }

}

sub _define_accessor {
  my ($pkg, $attr) = @_;
    # qq makes this block behave like a double-quoted string
  my $code = qq{
    package $pkg;
    sub $attr {                                      # Accessor ...
      my \$self=shift;
      \@_ ? \$self->set_attribute($attr,shift):\$self->get_attribute($attr);
    }
  };
  $code;
}

sub _define_rtl_accessor {
  my ($pkg, $attr) = @_;
    # qq makes this block behave like a double-quoted string
  my $code = qq{
    package $pkg;
    sub $attr {                                      # Accessor ...
      my \$self=shift;
      \@_ ? \$self->set_attribute($attr,shift):\$self->get_attribute($attr);
    }
  };
  $code;
}
sub _define_constructor {
  my $pkg = shift;
  my $code = qq {
    package $pkg;
    sub new {
	my \$class =shift;
	my \$self={};
	my \$stat;
	bless (\$self,\$class);
	return (\$stat=\$self->_init(\@_)) ? \$self: \$stat;
#	return \$self if (\$self->_init(\@_));
#	return (\$stat=\$self->Error) ? \$stat : "Error initialize";
    }
  };
  $code;
}
sub get_attribute_names {
  my $pkg = shift;
  $pkg = ref($pkg) if ref($pkg);
  my @result = @{"${pkg}::_ATTRIBUTES_"};
  if (defined (@{"${pkg}::ISA"})) {
    foreach my $base_pkg (@{"${pkg}::ISA"}) {
      push (@result, get_attribute_names($base_pkg));
    }
  }
  @result;
}


sub set_attribute {
  my ($obj, $attr_name, $attr_value) = @_;
 $obj->{"Var"}->{$attr_name}=$attr_value;
}
#
sub get_attribute {
  my ($self, $attr_name) = @_;
  return $self->{"Var"}->{$attr_name};
}

# $obj->set_attributes (name => 'John', age => 23);     
# Or, $obj->set_attributes (['name', 'age'], ['John', 23]);
sub set_attributes {
  my $obj = shift;
  my $attr_name;
  if (ref($_[0])) {
    my ($attr_name_list, $attr_value_list) = @_;
    my $i = 0;
    foreach $attr_name (@$attr_name_list) {
      $obj->$attr_name($attr_value_list->[$i++]);
    }
  } else {
    my ($attr_name, $attr_value);
    while (@_) {
      $attr_name = shift;
      $attr_value = shift;
      $obj->$attr_name($attr_value);
    }
  }
}

# @attrs = $obj->get_attributes (qw(name age));
sub get_attributes {
  my $obj = shift;
  my (@retval);
  map {$obj->$_()} @_;
}
sub new {
	my $class =shift;
	my $self={};
	my $stat;
	bless ($self,$class);
	return ($stat=$self->_init(@_)) ? $self: $stat;
}
sub _init{
my $self=shift;
return 1;
}
#-------- this methods use for 
#encodes complex data structures into printable ASCII strings
#used module FreezeThaw, written by Ilya Zakharevich
sub ref2str{
my ($self,$ref)=@_;
return freeze($ref);
}
sub str2ref{
my ($self,$str)=@_;
return (thaw($str))[0];
}
#put message into syslog
sub logmsgs { 
my $self=shift;
open FH, ">>system.log";
print FH ref($self)." @_\n";
close FH;
}
1;
