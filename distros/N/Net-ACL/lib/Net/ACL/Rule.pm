#!/usr/bin/perl

# $Id: Rule.pm,v 1.19 2003/06/06 18:45:02 unimlo Exp $

package Net::ACL::Rule;

use strict;
use Exporter;
use vars qw(
	$VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS
	@ACL_RC @ACL_ACTION );

## Inheritance and Versioning ##

@ISA     = qw( Exporter );
$VERSION = '0.07';

## Module Imports ##

use Carp;
use Scalar::Util qw( blessed );

## Accesslist Return Codes Constants ##

sub ACL_NOMATCH  {  0; };
sub ACL_MATCH    {  1; };

## Accesslist Action Codes Constants ##

sub ACL_DENY     {  2; };
sub ACL_PERMIT   {  3; };
sub ACL_CONTINUE {  4; };

## Export Tag Definitions ##

@ACL_RC      = qw( ACL_MATCH ACL_NOMATCH );
@ACL_ACTION  = qw( ACL_PERMIT ACL_DENY ACL_CONTINUE );
@EXPORT      = ();
@EXPORT_OK   = ( @ACL_RC, @ACL_ACTION );
%EXPORT_TAGS = (
    rc       => [ @ACL_RC ],
    action   => [ @ACL_ACTION ],
    ALL      => [ @EXPORT, @EXPORT_OK ]
);

## Public Class Methods ##

sub new
{
 my $proto = shift;
 my $class = ref $proto || $proto;

 my $this = {
        _action => ACL_PERMIT,
	_match => [],
	_set => [],
	_seq => undef
  };

 bless($this, $class);

 while ( defined(my $arg = shift) )
  {
   my $value = shift;
   if ( $arg =~ /action/i )
    {
     $value = ACL_PERMIT if $value =~ /permit/i;
     $value = ACL_DENY if $value =~ /deny/i;
     $this->{_action} = $value;
    }
   elsif ( $arg =~ /seq/i )
    {
     $this->{_seq} = $value;
    }
   elsif ( $arg =~ /match/i )
    {
     $this->_handlerules('Match','_match',$value);
    }
   elsif ( $arg =~ /set/i )
    {
     $this->_handlerules('Set','_set',$value);
    }
   else
    {
     croak "Unrecognized argument $arg";
    };
  };

 return $this;
}

sub clone
{
 my $proto = shift;
 my $class = ref $proto || $proto;
 $proto = shift unless ref $proto;

 my $clone;

 $clone->{_action} = $proto->{_action};
 $clone->{_seq} = $proto->{_seq};

 foreach my $key (qw(_set _match ))
  {
   # $clone->{$key} = [ map { $_->clone; } @{$proto->{$key}} ]; # Can't clone!
   $clone->{$key} = [ @{$proto->{$key}} ];
  }

 return ( bless($clone, $class) );
}

## Public Object Methods ##

sub seq
{
 my $this = shift;
 $this->{_seq} = @_ ? shift : $this->{_seq};
 return $this->{_seq};
}

sub action
{
 my $this = shift;
 $this->{_action} = @_ ? shift : $this->{_action};
 return $this->{_action};
}

sub action_str
{
 my $this = shift;
 $this->{_action} = @_ ? (shift =~ /permit/i ? ACL_PERMIT : ACL_DENY) : $this->{_action};
 return (($this->{_action} == ACL_PERMIT) ? 'permit' : 'deny'); 
}

sub match
{
 my $this = shift;
 return $this->_match(@_); # To allow replacement of match which doesn't effect query()
}

sub set
{
 my $this = shift;
 foreach my $subrule (@{$this->{_set}})
  {
   @_ = $subrule->set(@_);
  };
 return @_;
}

sub query
{
 my $this = shift;
 return (ACL_CONTINUE,@_) unless $this->_match(@_);
 return ($this->{_action},($this->{_action} == ACL_DENY) ? undef : $this->set(@_));
}

sub add_match
{
 shift->_add('_match',@_); 
}

sub remove_match
{
 shift->_remove('_match',@_); 
};

sub add_set
{
 shift->_add('_set',@_); 
}

sub remove_set
{
 shift->_remove('_set',@_); 
};

sub autoconstruction
{
 my ($this,$type,$class,$arg,@value) = @_;
 $class = 'Net::ACL::' . $type . '::' . $arg unless defined $class;
 unless ($class->isa('Net::ACL::'.$type))
  {
   eval "use $class;";
   croak "Unknown $type rule key $arg - No class $class found (Value: @value)." if ($@ =~ /Can't locate/);
   croak $@ if ($@);
   croak "$class is not a Net::ACL::$type class"
     unless $class->isa('Net::ACL::'.$type)
  };
 return $class->new(@value);
}

## Private Object Methods ##

sub _match
{
 my $this = shift;
 foreach my $subrule (@{$this->{_match}})
  {
   return ACL_NOMATCH unless $subrule->match(@_);
  };
 return ACL_MATCH;
}

sub _add
{
 my $this = shift;
 my $key = shift;
 push(@{$this->{$key}},@_);
}

sub _remove
{
 my $this = shift;
 my $key = shift;
 my @arg = @_;
 @{$this->{$key}} = grep {
	 foreach my $arg (@arg) { $_ = undef if $arg == $_; };
	} @{$this->{$key}};
}

sub _handlerules
{
 my ($this,$type,$key,$value) = @_;
 croak "$type option can not be a SCALAR" unless ref $value;
 if ((blessed $value) && $value->isa('Net::ACL::' . $type))
  {
   $this->_add($key,$value);
  }
 elsif (ref $value eq 'ARRAY')
  { 
   $this->_add($key,@{$value});
  }
 elsif (ref $value eq 'HASH')
  {
   foreach my $arg (keys %{$value})
    {
     my $subclass = 'Net::ACL::' . $type . '::' . $arg;
     $this->_add($key,$this->autoconstruction($type,$subclass,$arg,$value->{$arg}));
    };
  }
 else
  {
   croak "Unknown $type option value type";
  };
}

## POD ##

=pod

=head1 NAME

Net::ACL::Rule - Class representing a generic access-list/route-map entry

=head1 SYNOPSIS

    use Net::ACL::Rule qw( :action :rc );

    # Constructor
    $entry = new Net::ACL::Rule(
	Action	=> ACL_PERMIT
	Match	=> {
		IP	=> '127.0.0.0/8'
		}
	Set	=> {
		IP	=> '127.0.0.1'
		},
	Seq	=> 10
	);

    # Object Copy
    $clone = $entry->clone();

    # Accessor Methods
    $action = $entry->action($action);
    $action_str = $entry->action($action_str);

    $entry->add_match($matchrule);
    $entry->remove_match($matchrule);
    $entry->add_set($setrule);
    $entry->remove_set($setrule);

    $rc = $entry->match(@data);
    @data = $entry->set(@data);

    ($rc,@data) = $entry->query(@data);

    $subrule = $entry->autoconstruction($type,$class,$arg,@values);

=head1 DESCRIPTION

This module represents a single generic access-list and route-map entry. It is
used by the L<Net::ACL|Net::ACL> object. It can match any data against a
list of L<Net::ACL::Match|Net::ACL::Match> objects, and if all are matched, it
can have a list of L<Net::ACL::Set|Net::ACL::Set> objects modify the data.

=head1 CONSTRUCTOR

=over 4

=item new() - create a new Net::ACL::Rule object

    $entry = new Net::ACL::Rule(
        Action  => ACL_PERMIT
	Match	=> {
		IP	=> '127.0.0.0/8'
		}
	Set	=> {
		IP	=> '127.0.0.1'
		}
	);

This is the constructor for Net::ACL::Rule objects. It returns a
reference to the newly created object. The following named parameters may
be passed to the constructor.

=over 4

=item Action

The action parameter could be either of the constants exported using "action"
(See EXPORTS) or just a string matching permit or deny. ACL_PERMIT accepts
the data, ACL_DENY drops the data, while ACL_CONTINUE is used to indicate that
this entry might change the data, but does not decide whether the data should
be accepted or droped.

=item Match

The match parameter can have multiple forms, and my exists zero, one or more
times. The following forms are allowed:

=over 4

=item Match object - A Net::ACL::Match object (or ancestor)

=item List - A list of Net::ACL::Match objects (or ancestors)

=item Hash - A hash reference. The constructor will for each key/value-pair
call the autoconstructor() method and add the returned objects to the
rule-set.

=back

=item Set

The set parameter are in syntax just like the C<Match> parameter, except
it uses Net::ACL::Set objects.

=back

=back

=head1 OBJECT COPY

=over 4

=item clone() - clone a Net::ACL::Rule object

    $clone = $entry->clone();

This method creates an exact copy of the Net::ACL::Rule object,
with set, match and action attributes.

=back

=head1 ACCESSOR METHODS

=over 4

=item action()

This method returns the entry's action value. If called with an argument,
the action value is changed to that argument.

=item action_str()

This method returns the entry's action string as either C<permit> or C<deny>.
If called with an argument, the action value are changed to ACL_PERMIT if
the argument matches /permit/i - otherwise ACL_DENY.

=item add_match()

=item remove_match()

=item add_set()

=item remove_set()

The methods add and remove match and set rules. Each argument should be a
match or set rule object. New rules are added in the end of the rule set.

=item match()

The match method gets any arbitrary number of arguments. The arguments are passed
to the match() method of each of the Net::ACL::Match objects,
given at construction time - see new(). If all Match objects did
match, the method returns ACL_MATCH. Otherwise ACL_MATCH.

=item set()

The set method gets any arbitrary number of arguments. The arguments are passed
to the first of the Net::ACL::Set objects set() method. The
result of this function is then used to call the next. This is repeated for
all Set objects given at construction time - see new().
Finally the result of the last call is returned.

=item query()

The query method first attempt to match it's arguments with the match()
method. If this fails, it returns ACL_CONTINUE. Otherwise it uses
the set() method to potentially alter the arguments before they are returned
with C<Action> given on construction prefixed.

=item autoconstruction()

This method is used on construction to construct rules based on
key/value-pairs in a Rule argument hash reference.

The first argument is the type (C<Match> or C<Set>). The second is the class
name (see below). The third is the key name from the construction hash. The
forth and any remaining arguments are used as parameters to the constructor.

The return value will be the result of:

	$class->new(@values);

The class is by the constructor set as C<Net::ACL::$type::$key>

B<NOTE>: Do to this; the keys of the hash are case-sensitive!

By replacing this function in a sub-class, it is possible to modify the class
and/or key-value pairs and hence make more complex constructions from simple
key-value pairs, or have more user-friendly key values (e.g. make them
case-insensitive).

=back

=head1 EXPORTS

The module exports the following symbols according to the rules and
conventions of the Exporter module.

=over 4

=item :rc

	ACL_MATCH, ACL_NOMATCH

=item :action

	ACL_PERMIT, ACL_DENY, ACL_CONTINUE

=back

=head1 SEE ALSO

Net::ACL, Net::ACL::Set, Net::ACL::Match

=head1 AUTHOR

Martin Lorensen <bgp@martin.lorensen.dk>

=cut

## End Package Net::ACL::Rule ##
 
1;
