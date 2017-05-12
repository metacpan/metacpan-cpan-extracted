=head1 NAME

Bio::Polloc::RuleI - Generic rules interface

=head1 DESCRIPTION

Use this interface to initialize the Bio::Polloc::Rule::* objects.  Any
rule inherits from this Interface.  Usually, rules are initialized
in sets (via the L<Bio::Polloc::RuleIO> package).

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=head1 IMPLEMENTS OR EXTENDS

=over

=item *

L<Bio::Polloc::Polloc::Root>

=back

=cut

package Bio::Polloc::RuleI;
use strict;
use base qw(Bio::Polloc::Polloc::Root);
use Bio::Polloc::RuleIO;
our $VERSION = 1.0503; # [a-version] from Bio::Polloc::Polloc::Version


=head1 APPENDIX

Methods provided by the package

=cut

=head2 new

=over

=item 

Attempts to initialize a C<Bio::Polloc::Rule::*> object

=item Arguments

=over

=item -type

The type of rule

=item -value

The value of the rule (depends on the type of rule)

=item -context

The context of the rule.  See L<Bio::Polloc::RuleI-E<gt>context>.

=back

=item Returns

The C<Bio::Polloc::Rule::*> object

=item Throws

L<Bio::Polloc::Polloc::Error> if unable to initialize the proper object

=back

=cut

sub new {
   my($caller,@args) = @_;
   my $class = ref($caller) || $caller;
   
   # Pre-fix based on type, unless the caller is a proper class
   if($class !~ m/Bio::Polloc::Rule::(\S+)/){
      my $bme = Bio::Polloc::Polloc::Root->new(@args);
      my($type) = $bme->_rearrange([qw(TYPE)], @args);
      
      if($type){
         $type = Bio::Polloc::RuleI->_qualify_type($type);
         $class = "Bio::Polloc::Rule::" . $type if $type;
      }
   }

   # Try to load the object
   if($class =~ m/Bio::Polloc::Rule::(\S+)/){
      if(Bio::Polloc::RuleI->_load_module($class)){;
         my $self = $class->SUPER::new(@args);
	 $self->debug("Got the RuleI class $class ($1)");
	 my($value,$context,$name,$id,$executable) =
	 	$self->_rearrange([qw(VALUE CONTEXT NAME ID EXECUTABLE)], @args);
	 $self->value($value);
	 $self->context(@{$context});
	 $self->name($name);
	 $self->id($id);
	 $self->executable($executable);
         $self->_initialize(@args);
         return $self;
      }
      my $bme = Bio::Polloc::Polloc::Root->new(@args);
      $bme->throw("Impossible to load the module", $class);
   }

   # Throws exception if any previous return
   my $bme = Bio::Polloc::Polloc::Root->new(@args);
   $bme->throw("Impossible to load the proper Bio::Polloc::RuleI class with ".
   		"[".join("; ",@args)."]", $class);
}

=head2 type

=over

=item 

Gets/sets the type of rule

=item Arguments

Value (str).  Can be: pattern, profile, repeat, tandemrepeat, similarity, coding,
boolean, composition, crispr.  See the corresponding C<Bio::Polloc::Rule::*> objects
for further details.

Some variations can be introduced, like case variations or short versions like
B<patt> or B<rep>.

=item Return

Value (str).  The type of the rule, or C<undef> if undefined.  The value returned
is undef or a string from the above list, regardless of the input variations.

=item Throws

L<Bio::Polloc::Polloc::Error> if an unsupported type is received.

=back

=cut

sub type {
   my($self,$value) = @_;
   if($value){
      my $v = $self->_qualify_type($value);
      $self->throw("Attempting to set an invalid type of rule",$value) unless $v;
      $self->{'_type'} = $v;
   }
   return $self->{'_type'};
}



=head2 context

=over

=item 

Gets/sets the context of the rule.

The context is a reference to an array of two elements (I<int> or I<str>),
the first being:
   1 => with respect to the start of the sequence
   0 => somewhere within the sequence (ignores the second)
  -1 => with respect to the end of the sequence

And the second being the number of residues from the reference point.  The second
value can be positive, negative, or zero.

=item Arguments

Three integers, or one integer equal to zero.  Please note that this function is
extremely tolerant, and tries to guess the context regardless of the input.

=item Returns

A reference to the array described above.

=back

=cut

sub context {
   my($self,@args) = @_;
   if($#args>=0){
      $self->{'_context'} = [$args[0]+0, $args[1]+0, $args[2]+0];
   }
   $self->{'_context'} ||= [0,0,0];
   if($self->{'_context'}->[0] < 0) {$self->{'_context'}->[0] = -1;}
   elsif($self->{'_context'}->[0] > 0) {$self->{'_context'}->[0] = 1;}
   else {$self->{'_context'}->[0] = 0;}
   $self->{'_context'}->[1]+=0;
   return $self->{'_context'};
}

=head2 value

=over

=item 

Gets/sets the value of the rule

=item Arguments

Value (mix)

=item Returns

Value (mix)

=item Note

This function relies on C<_qualify_value>

=item Throws

L<Bio::Polloc::Polloc:Error> if unsupported value is received

=back

=cut

sub value {
   my($self,$value) = @_;
   if(defined $value){
      my $v = $self->_qualify_value($value);
      defined $v or $self->throw("Bad rule value", $value);
      $self->{'_value'} = $v;
   }
   return $self->{'_value'};
}

=head2 executable

=over

=item 

Sets/gets the C<executable> property.  A rule can be executed even if this
property is false, if the L<Bio::Polloc::RuleI::execute> method is called directly
(C<$rule-E<gt>execute>) or by other rule.  This property is provided only for
L<Bio::Polloc::RuleIO> objects.

=item Arguments

Boolean (0 or 1; optional)

=item Returns

1 if expicilty executable, 0 otherwise

=item Note

It is advisable to have only few (ideally one) executable rules, handling
all the others with the rule type B<operation>

=back

=cut

sub executable {
   my($self,$value) = @_;
   $self->{'_executable'} = $value+0 if defined $value;
   $self->{'_executable'} = $self->safe_value('executable')
   	unless defined $self->{'_executable'};
   $self->{'_executable'} =
   	(defined $self->{'_executable'} && $self->{'_executable'} =~ m/^(t|1|y)/i) ? 1 : 
		(defined $self->{'_executable'} ? 0 : undef);
   return $self->{'_executable'};
}


=head2 name

=over

=item 

Sets/gets the name of the rule

=item Arguments

Name (str), the name to set

=item Returns

The name (str or undef)

=back

=cut

sub name {
   my($self,$value) = @_;
   $self->{'_name'} = $value if defined $value;
   return $self->{'_name'};
}


=head2 id

=over

=item 

Sets/gets the ID of the rule

=item Purpose

Provide a somewhat I<unique> but human-readable identifier

=item Arguments

The supposedly unique ID of the rule (str), any dot (B<.>) will be changed to B<_>

=item Returns

The ID (str or undef)

=back

=cut

sub id {
   my($self,$value) = @_;
   if($value){
      $value =~ s/\./_/g;
      $self->debug("Setting Locus ID '$value'");
      $self->{'_id'} = $value;
   }
   return $self->{'_id'};
}

=head2 restart_index

=cut

sub restart_index {
   my $self = shift;
   $self->{'_children_id'} = 1;
}

=head2 stringify

=over

=item

Provides an easy method for the (I<str>) description of any L<Bio::Polloc::RuleI> object.

=item Returns

The stringified object (str, off course)

=back

=cut

sub stringify {
   my($self,@args) = @_;
   my $out = ucfirst $self->type;
   $out.= " '" . $self->name . "'" if defined $self->name;
   $out.= " at [". join("..", @{$self->context}) . "]" if $self->context->[0];
   $out.= ": ".$self->stringify_value if defined $self->value;
   return $out;
}

=head2 stringify_value

=over

=item 

Dummy function to be overriten if non-string value like in Bio::Polloc::Rule::repeat

=item Returns

The value as string

=back

=cut

sub stringify_value {
   my($self,@args) = @_;
   return "".$self->value(@args);
}

=head2 ruleset

=over

=item 

Gets/sets the parent ruleset of the rule

=item Arguments

The ruleset to set (a L<Bio::Polloc::RuleIO> object).

=item Returns

A L<Bio::Polloc::RuleIO> object or C<undef>.

=back

=cut

sub ruleset {
   my($self,$value) = @_;
   if(defined $value){
      $self->throw("Unexpected type of value '".ref($value)."'",$value)
      		unless $value->isa('Bio::Polloc::RuleIO');
      $self->{'_ruleset'} = $value;
   }
   return $self->{'_ruleset'};
}

=head2 execute

=over

=item 

Evaluates the rule in a given sequence.

=item Arguments

A L<Bio::Seq> object.

=item Returns

An array of Bio::Polloc::LocusI objects

=item Throws

A L<Bio::Polloc::Polloc::NotImplementedException> if not implemented

=back

=cut

sub execute { $_[0]->throw("execute", $_[0], "Bio::Polloc::Polloc::NotImplementedException") }

=head2 safe_value

=over

=item 

Sets/gets a parameter of arbitrary name and value

=item Purpose

To provide a safe interface for setting values from the parsed file

=item Arguments

=over

=item -param

The parameter's name (case insensitive)

=item -value

The value of the parameter (optional)

=back

=item Returns

The value of the parameter or undef

=back

=cut

sub safe_value {
   my ($self,@args) = @_;
   my($param,$value) = $self->_rearrange([qw(PARAM VALUE)], @args);
   $self->{'_safe_values'} ||= {};
   return unless $param;
   $param = lc $param;
   if(defined $value){
      $self->{'_safe_values'}->{$param} = $value;
   }
   return $self->{'_safe_values'}->{$param};
}


=head2 source

=over

=item 

Sets/gets the source of the annotation

=item Arguments

The source (I<str>)

=item Returns

The source (I<str> or C<undef>)

=back

=cut

sub source {
   my($self,$source) = @_;
   $self->{'_source'} = $source if defined $source;
   $self->{'_source'} ||= $self->type;
   return $self->{'_source'};
}

=head1 INTERNAL METHODS

Methods intended to be used only witin the scope of Bio::Polloc::*

=head2 _qualify_type

=cut

sub _qualify_type {
   my($self,$value) = @_;
   return unless $value;
   $value = lc $value;
   $value = "pattern" if $value=~/^(patt(ern)?)$/;
   $value = "profile" if $value=~/^(prof(ile)?)$/;
   $value = "repeat" if $value=~/^(rep(eat)?)$/;
   $value = "tandemrepeat" if $value=~/^(t(andem)?rep(eat)?)$/;
   $value = "similarity" if $value=~/^((sequence)?sim(ilarity)?|homology|ident(ity)?)$/;
   $value = "coding" if $value=~/^(cod|cds)$/;
   $value = "boolean" if $value=~/^(oper(at(e|or|ion))?|bool(ean)?)$/;
   $value = "composition" if $value=~/^(comp(osition)?|content)$/;
   return $value;
   # TRUST IT! -lrr if $value =~ /^(pattern|profile|repeat|tandemrepeat|similarity|coding|boolean|composition|crispr)$/;
}

=head2 _parameters

=over

=item 

Returns the supported parameters for L<value>.

=item Returns

The supported value keys (C<arrayref>).

=back

=cut

sub _parameters { $_[0]->throw('_parameters', $_[0], 'Bio::Polloc::Polloc::NotImplementedException') }

=head2 _qualify_value

=over

=item 

Takes the different possible values and returns them the way they must be
saved (usually a I<hashref>).  Bio::Polloc::Rule::* modules must reimplement
either L<_qualify_value> or L<_parameters>.

=back

=cut

sub _qualify_value { return shift->_qualify_value_default(@_) }

=head2 _qualify_value_default

=cut

sub _qualify_value_default {
   my($self,$value) = @_;
   unless (defined $value){
      $self->warn("Empty value");
      return;
   }
   if(ref($value) =~ m/hash/i){
      my @arr = %{$value};
      $value = \@arr;
   }
   my @args = ref($value) =~ /array/i ? @{$value} : split /\s+/, $value;
   
   return unless defined $args[0];
   if($args[0] !~ /^-/){
      $self->warn("Expecting parameters in the format -parameter value", @args);
      return;
   }
   unless($#args%2){
      $self->warn("Unexpected (odd) number of parameters", @args);
      return;
   }
   my %vals = @args;
   my $out = {};
   for my $k ( @{$self->_parameters} ){
      my $p = $self->_rearrange([$k], @args);
      next unless defined $p;
      # This checks numeric values, but it's too restrictive
      #if( $p !~ /^[\d\.eE+-]+$/ ){
      #   $self->warn("Unexpected value for ".$k, $p);
	# return;
      #}
      $out->{"-".lc $k} = $p;
   }
   return $out;
}

=head2 _executable

=over

=item 

Attempts to find the executable

=item Arguments

=over

=item *

An alternative path to search at I<str>.

=back

=back

=cut

sub _executable { $_[0]->throw("_executable", $_[0], "Bio::Polloc::Polloc::NotImplementedException") }

=head2 _initialize

=cut

sub _initialize { $_[0]->throw("_initialize", $_[0], "Bio::Polloc::Polloc::NotImplementedException") }

=head2 _search_value

=over

=item Arguments

The key (I<str>)

=item Returns

The value (mix) or undef

=back

=cut

sub _search_value {
   my($self, $key) = @_;
   return unless defined $key;
   $key = lc $key;
   return $self->{"_$key"}
   	if defined $self->{"_$key"};
   return $self->value->{"-$key"}
   	if defined $self->value
	and ref($self->value) =~ /hash/i
	and defined $self->value->{"-$key"};
   return $self->safe_value($key)
   	if defined $self->_qualify_value({"-$key"=>$self->safe_value($key)});
   return;
}

=head2 _next_child_id

=over

=item 

Gets the ID for the next child.

=item Purpose

Provide support for children identification

=item Returns

The ID (I<str>) or C<undef> if the ID of the current Rule is not set.

=back

=cut

sub _next_child_id {
   my $self = shift;
   return unless defined $self->id;
   $self->{'_children_id'} ||= 1;
   return $self->id . "." . $self->{'_children_id'}++;
}

1;
