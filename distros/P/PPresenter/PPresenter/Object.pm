# Copyright (C) 2000-2002, Free Software Foundation FSF.

# I would have liked to call this package UNIVERSAL, but then it
# is also a base-class of Tk objects.  This doesn't work well
# because the overloading.

package PPresenter::Object;

use strict;

use overload '""' => 'toString'
           , cmp  => 'compare';

sub new($@)
{   my $class = shift;
    my $self  = bless {}, $class;

    $self->getOptions($class)->change(@_);

    die "New $class object has no name (required).\n"
        unless defined $self->{-name};

    $self->InitObject;
}

sub getOptions($)
{   my ($self, $class) = @_;

    no strict 'refs';

    map {$self->getOptions($_)}  @{"${class}::ISA"};

    my $get_defaults = *{"${class}::ObjDefaults"}{CODE} || undef;
    return $self unless defined $get_defaults;

    my $defaults     = &$get_defaults;
    @$self{keys %$defaults} = values %$defaults;
    $self;
}

sub InitObject() {shift}

# All objects have a name, and optionally a list of aliases.
sub isNamed($)
{   my ($self, $name) = @_;

    return 1  if $self->{-name} eq $name;
    return 0  unless defined $self->{-aliases};
    return $self->{-aliases} eq $name unless ref $self->{-aliases};
    return grep {$_ eq $name} @{$self->{-aliases}};
}

# fromList is called with a number in the list, 'FIRST', 'LAST',
# or the name of an element from the list.  Returns a list
# when called with 'ALL'.

sub fromList($$)
{   my ($class, $list, $name) = @_;

    return undef unless defined $list->[0];

    die "fromList called without a list of class $class: $list.\n"
        if ref $list ne 'ARRAY';

    die "fromList called with empty list of $class.\n"
        unless @$list;

    die "fromList called for $class with list of ".ref($list->[0])."\n"
        unless $list->[0]->isa($class);

    if(ref $name)
    {   return $name if $name->isa($class);
        die "fromList called with ".ref($name)." as solution for $class\n"
    }

    return $list->[0]  if $name eq 'FIRST';
    return $list->[-1] if $name eq 'LAST';
    return @$list      if $name eq 'ALL';    # returns list!!

    if($name =~ m/\D/)
    {   foreach (@$list)
        {   return $_ if $_->isNamed($name);
        }
        return undef;
    }

    return undef if $name > $#$list || $name <0;

    $list->[$name];
}

sub change(@)
{   my $self    = shift;
    return $self unless @_;

    my $name    = $self->{-name};

    while($#_ >0)
    {   my ($field, $contents) = (shift, shift);

        unless(exists $self->{$field})
        {   warn "A ",ref $self,
                 " does not contain a setting named $field.  Skipped.\n";
            next;
        }

        $self->{$field} = $contents;
    }

    return $self;
}

#
# Flatten
# Some options can have a single element or a (nested?) array.  This
# function flattens this to a list.  Often called as:
#   $style_elem{option} = [ $style_elem->flatten($style_elem->{option}) ]
#

sub flatten($)
{   my ($self, $option) = @_;

    return () unless defined $option;

    my $ref = ref $option;
    return $option unless $ref;

    return $self->flatten(@$option) if $ref eq 'ARRAY';

    die "Got an reference to $ref to flatten as option for $self.\n";
}

#
# Overloads
#

sub toString($) { $_[0]->{-name} }

# obj cmp obj, or  obj cmp string.
sub compare($$) {$_[0]->isNamed("$_[1]")}

#
# The user specifies a percentage from a length.  This might be a string
# or a value.  Permitted formats:
#    0.125     means 12.5% from the start
#     -0.2     means 20% from the end
#      '-0'    means at the end
#     '10%'    means 10% from the start
#   '-5.5%'    means 5.5% from the end.
#     +0.3     means 30% from the start.
#

sub takePercentage($$)
{   my ($self, $percent, $length) = @_;
    $self->toPercentage($percent) * $length;
}

sub toPercentage($)
{   my ($self, $p) = @_;

    if(my ($sign, $value, $cent) = $p =~ /(\-|\+)?([\d.]+)(\%?)/ )
    {   $value /= 100 if $cent eq '%';
        return (defined $sign && $sign eq '-') ? (1-$value) : $value;
    }

    warn "Not valid as a percentage specification: $p.\n";
    0;
}

#
# Debugging and trace routines...
#

sub nested_types($$)
{   my ($type, $indent) = @_;

    if($type eq '' || $type eq 'HASH' || $type eq "ARRAY" || $type eq "CODE")
    {   return "$indent$type\n";
    }

    no strict 'refs';
    return join "\n", "${indent}is a $type"
                    , map {nested_types($_, "$indent   ")} @{"${type}::ISA"};
}

sub show_scalar_line($$);
sub show_scalar_line($$)
{   my ($scalar, $max) = @_;
    return "undef" unless defined $scalar;
    my $type = ref $scalar;
    if($type eq '')
    {   return undef unless length($scalar) < $max;
        return $scalar =~ /^\s*[\d.]+\s*$/ ? $scalar : "\"$scalar\"";
    }
    elsif($type eq 'ARRAY')
    {   my $l = 1;
        foreach (@$scalar)
        {   my $line = show_scalar_line($_, $max);
            return undef unless defined $line;
            $l   += length($line)+1;
            return undef if $l>$max;
        }
        return "[".join(',',map {show_scalar_line($_,$max)} @$scalar)."]";
    }
    elsif($type eq 'HASH')
    {   return undef;  # never compact.
    }
    elsif($type eq 'CODE' || $type eq 'REF')
    {   return "$scalar";
    }
    elsif($scalar->isa('PPresenter::StyleElem'))
    {   return undef if length($type)+length($scalar->{-name})+4>$max;
        return "$type ($scalar->{-name})";
    }
    else
    {   return "$scalar";
    }
}

sub show_scalar_block($$);
sub show_scalar_block($$)
{  my ($scalar, $indent) = @_;

   # Try to solve it in one line.
   my $ret = show_scalar_line($scalar, 75-length($indent));
   return "$indent$ret\n" if defined $ret;

   my $type = ref $scalar;
   if($type eq '')
   {   return "$indent\"".substr($scalar, 0, 70-length($indent))."...\"\n";
   }
   elsif($type eq 'ARRAY')
   {   $ret = "$indent\[ ";
       my $out;
       my $first = 1;
       foreach (@$scalar)
       {   my $n = show_scalar_line($_,300);
           if(length($ret)+length($n)+1 > 75)
           {   $out .= "$ret\n";
               $ret  = "$indent, $n";
           }
           else
           {   $ret .= $first ? "$n" : ",$n";
               $first = 0;
           }
       }
       return $out . "$ret ]\n";
   }
   elsif($type eq 'HASH')
   {   my $out;
       my $first = "{";
       foreach (sort keys %$scalar)
       {   my $k  = show_scalar_line($_,300);
           my $v  = show_scalar_line($scalar->{$_},
                       50-length($indent));

           $out  .= sprintf "$indent$first %-20s => ", $k;
           $first = ",";
           if(defined $v)
           {   $out .= $v."\n";
           }
           else
           {   $out .= "\n".show_scalar_block($scalar->{$_}, "$indent   ");
           }
       }
       return $out."$indent}\n";
   }
   elsif($scalar->isa('PPresenter::StyleElem'))
   {   return "$indent".show_scalar_line($scalar, 300);
   }

   return "Unknown\n";
}

sub tree(;$)
{   my $self   = shift;
    my $indent = defined($_[0]) ? $_[0] : "";
    my $result = "$indent $self\n";

    $indent    .= "   ";
    $result    .= nested_types(ref $self, $indent). "\n";

    foreach (sort keys %$self)
    {  $result .= sprintf "$indent%-20s => ", $_;
       my $scalar = show_scalar_line($self->{$_} || undef, 50-length($indent));
       $result .= defined $scalar
                ? $scalar . "\n"
                : "\n". show_scalar_block($self->{$_} || undef, "$indent   ");
    }

    return $result;
}

1;
