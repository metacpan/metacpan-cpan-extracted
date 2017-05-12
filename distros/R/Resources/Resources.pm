# Copyright 1995 Francesco Callari, McGill University. See notice
# at end of this file.
#
# Filename: Resources.pm
# Author: Francesco Callari (franco@cim.mcgill.ca)
# Created: Wed May 31 17:55:21 1995
# Version: $Id: 
#    Resources.pm,v 0.1 1995/10/19 02:49:43 franco Exp franco $


=head1 NAME 

Resources - handling application defaults in Perl.

=head1 SYNOPSIS

    use Resources;

    $res = new Resources;
    $res = new Resources "resfile";

=head1 DESCRIPTION

Resources are a way to specify information of interest to program or
packages. 

Applications use resource files to specify and document the values of
quantities or attributes of interest.

Resources can be loaded from or saved to resource files. Methods are
provided to search, modify and create resources.

Packages use resources to hardwire in their code the default values for
their attributes, along with documentation for the attibutes themselves.

Packages inherit resources when subclassed, and the resource names are
updated dynamically to reflect a class hierarchy.

Methods are provided for interactive resource inspection and editing.

=head2 1. Resource inheritance

Package attributes are inherited from base and member classes, their names are
dynamically updated to reflect the inheritance, and values specified in
derived/container classes override those inherited from base/member classes.

More precisely, there a few rules governing the inheritance of resource
names and values, and they will be explained by way of examples.

As far as resource names, the rules are:

=over 8

=item Base class

If Vehicle has a "speed" property, then it can use a resource named 
"vehicle.speed" to specify its default value.

=item Derived class

If Car B<is a> Vehicle, then Car has a "car.speed" resource automagically
defined by inheritance from the base class.

=item Container class

If Car B<has a> member object called Tire, and Tire has a "tire.pressure"
resource, then Car inherits a "car.tire.pressure" resource from the member
class.

=item Application class

All resources of Car objects used by a program named "race" have the prefix
"race." prepended to their names, e.g. "race.car.speed",
"race.car.tire.pressure", etc.

=back

With regard to assigning values to resources, the rules are:

=over 8

=item Specification in a file

Resources specified in a resource file always override hardcoded resources
(with the exception of "hidden" resources, see below).

=item Inheritance

Resources defined in a derived class (like Car) override those specified in
a base class. Likewise, resources defined in a container class override
those specified in the members. 

In the above example, a default value for "car.speed" in Car overrides the
value of "vehicle.speed" in any Car object, otherwise "car.speed" assumes the
value of "vehicle.speed".  Same for "car.tire.pressure".

=back

=head2 2. Resource Files.

A resource specification in a (text) resource file is a line of the form:

        sequence: value

There may be any number of whitespaces between the name and the colon
character, and between the colon and the value. 

=over 8

=item B<sequence> can have four forms:

       (1) word

A B<word> not containing whitespaces, colons (':'), dots ('.') or asterisks
('*'), nor starting with an underscore ('_').

Or, recursively:

        (2) word.sequence   
        (3) word*sequence   
        (4) *sequence

The asterisks in a resource name act as wildcards, matching any sequence of
characters. 

For cases (3) or (4) the B<word> must be or match the current application
class, otherwise the resource specification is silently ignored (this means
that an applications loads from a file only its own resources, and those whose
application class is a wildcard).

No distinction is made between uppercase and lowercase letters.

=item B<value> can be:

An unadorned word or a quoted sequence of whitespace-separated words. Both
single (' ') and double quotes quotes (" ") are allowed, and they must be
paired.  

Any I<constant> scalar constructor in Perl, including anon references to
constant arrays or hashes.  

The special words B<yes>, B<true>, B<no>, B<false> (case insensitive) are
treated as boolean resources and converted 1 and 0, unless they are quoted.

=back

Examples of valid resource specifications:

     car*brand       : Ferrari    # A word.
     car.price       : 200K       # Another word
     car.name        : '312 BB'   # A quoted sentence
     car*runs*alot   : yes        # A boolean, converted to 1.
     car*noise*lotsa : 'yes'      # yes, taken verbatim
     car.size        : [1, [2, 3]]           # An anon array.
     car.lett        : {"P"=>1, "Q"=>[2, 3]} # An anon hash.

Examples of illegal resource names:

     car pedal    # Whitespace in the name.
     .carpedal    # Leading dot in name.
     car._pedal   # Leading underscore in _dog.
     carpedal*    # Trailing asterisk.
     carpedal.    # Trailing dot.

A resource file may contain comments: anything from a hash ('#') character to
the end of a line is ignored, unless the hash character appears inside a
quoted value string.

Resource specifications may be split across successive lines, by terminating
the split lines with a backslash, as per cpp(1).

=head2 3. The Resources hash

A non-my hash named %Resources can be used to specify the default values for
the attributes of a package in its source code, along with documentation for
the attributes themselves. The documentation itself is "dynamical" (as opposed
to the static, pod-like variety) in that it follows a class hyerarchy and is
suitable for interactive display and editing.

The %Resources hash is just a hash of 

     $Name => [$Value, $Doc]

things. Each hash key B<$Name> is a resource name in the above sequence
form. Each hash value is a reference to an anon array B<[$Value, $Doc]>, with
B<$Doc> being an optional resource documentation.

The resource $Name I<cannot> contain wildcard ('*') or colon (':') characters,
nor start or end with a dot ('.'). Also, it must I<not> be prefixed with the
package name (since this is automatically prepended by the B<merge> method,
see below). Names starting with an underscore ('_') character are special in
that they define "hidden" resources. These may not be specified in resource
files, nor dynamically viewed/edited: they come handy to specify global
parameters when you do not want to use global application-wide variables,
and/or want to take advantage of the inheritance mechanism.

The resource $Value can be any I<constant> scalar Perl constructor, including
references to arrays and/or hashes of constants (or references
thereof). Boolean values must be specified as 1 or 0.

The resource documentation is a just string of any length: it will be
appropriately broken into lines for visualization purposes. It can also be
missing, in which case an inherited documentation is used (if any exists, see
the B<merge> method below).

The content of a resource hash is registered in a global Resource object using
the B<merge> method.

Here is an example of deafults specification for a package.

     package Car;
     @ISA = qw( Vehicle );
     use vars qw( %Resources );

     %Resources = (
         brand    => ["FIAT", "The carmaker"],
         noise    => ["Ashtmatic", "Auditory feeling"],
         sucks    => [1, "Is it any good?"],
	 nuts     => [ { on => 2, off => [3, 5] }, "Spares"],
	 '_ghost' => [0, "Hidden. Mr. Invisible"] 
	 'tire.flat' => [0],
     );

The last line overrides a default in member class Tire. The corresponding
doc string is supposedly in the source of that class. The last two hash keys
are quoted because of the non alphanumeric characters in them.

=head2 4. Objects and resources

The recommended way to use resources with Perl objects is to pass a
Resource object to the "new" method of a package.  The method itself will
merge the passed resources with the package defaults, and the passed resource
will override the defaults where needed.

Resource inheritance via subclassing is then easily achieved via the B<merge>
method, as shown in the EXAMPLES section. 

=cut
   
require 5.001;
package Resources;
use strict;
use Carp;
use Safe;
use FileHandle;

# 
# Global variables
#
use vars qw( $VERSION %Resources $NAME $Value $Doc $Loaded $Merged );

$VERSION = "1.03";

$Value=0, $Doc=1, $Loaded=2, $Merged=3; # Indices in resource value


# Resources of Resources ;-)
%Resources = 
  ( 
   'resources.appclass'      => [$0,
				"The application name of this Resource " .
				"object."],
   'resources.editor'       => ["/bin/vi", 
				"Resource editor command."], 
   'resources.mergeclass'   => [1,
				"Boolean. True to merge with " .
				"class inheritance."],
   'resources.pager'        => ["/bin/cat", 
				"Resource pager command."],

   'resources.resources'    => ['%Resources',
				"The name of the standard default hash."],
   'resources.separator'    => [':',
				"Pattern separating names from values in " .
				"resource files."],
   'resources.tmpfil'       => ["/tmp/resedit$$", 
				"Editor temporary file."],
   'resources.updates'      => [0, 
				"Number of resource updates."],
   'resources.verbosity'    => [1, 
				"True to print warnings."],
   'resources.viewcols'     => [78, 
				"Width of view/edit window."],
   'resources.viewmincols'  => [15, 
				"Minimum width of a comment line in view."],
   'resources.writepod'     => [0,
				"Boolean. True if the write method should " .
				"output in POD format."],
  );

#
# Method declarations
#
sub new;
sub DESTROY;
sub load;
sub merge;
sub put;
sub valbyname;
sub docbyname;
sub valbypattern;
sub docbypattern;
sub namebyclass;
sub valbyclass;
sub docbyclass;
sub each;
sub names;
sub view;
sub edit;


#
# Unexported subroutines
#
sub _chain_classes;
sub _parse;
sub _parse_ref;
sub _error;
sub _printformat; 
sub _dump;   

=head2 5. Methods in class Resources

=head2 5.1. Creation and initialization

=over 8

=item B<new Resources ($resfile);>

Creates a new resource database, initialized with the defaults for
class Resources (see below for a list of them).

If a nonempty file name is specified in $resfile, it initializes the object
with the content of the so named resource file. For safe (non overwriting)
loading, see the B<load> method below.

If the special file name "_RES_NODEFAULTS" is specified, the object is created
completely empty, with not even the Resources class defaults in it.

Returns the new object, or undef in case of error.

=cut

sub new {
   my $type = shift;
   my $resfile = shift;
   my ($name, $valdoc, $app);
   my $res = bless {};
   
   $res->{Load}    = 0;    # 1 if loading
   $res->{Merge}   = 0;    # 1 if merging
   $res->{Wilds}   = {};   # Wildcarded resources.
   $res->{Res}     = {};   # Named resources.
   $res->{Owned}   = {};   # Inverted index of member clases.
   $res->{Isa}     = {};   # Inverted index of base classes.

   # Safe environment for the evaluation of constructors.
   $res->{Safe} = new Safe or 
      ($res->_error("new", "can't get a Safe object."), return undef);

   # Hack hack - the special filename "_RES_NODEFAULTS" is
   # used to prevent resource initialization (e.g. when called by the
   # "bypattern" method
   unless ($resfile && $resfile eq "_RES_NODEFAULTS") {
      # Must make sure this is not overridden by a wildcard
      $res->{Wilds}->{'.*resources\.updates'} = [0];
      $res->{Res}->{'resources.updates'}->[$Value] = 0;
      
      # Get appclass without extensions
      if (($app = $Resources{'resources.appclass'}->[$Value]) =~ /\./) {
	 $Resources{'resources.appclass'}->[$Value] = (split(/\./, $app))[0];
      }

      # Bootstrap defaults. We don't want any subclassing here 
      while (($name, $valdoc) = each(%Resources)) {
	 $res->{Res}->{$name} = $valdoc;
      }
   }

   if ($resfile && $resfile ne "_RES_NODEFAULTS") {
      $res->load($resfile) || 
	 ($res->_error("new", "can't load"), return undef); 
   }

   $res;
}
    

sub DESTROY {
   my $res=shift;
   Safe::DESTROY($res->{Safe});
}


=item B<load($resfile, $nonew);>

Loads resources from a file named $resfile into a resource database. 

The $nonew argument controls whether loading of non already defined resurces is
allowed. If it is true, safe loading is performed: attempting to load
non-wildcarded resource names that do not match those already present in the
database causes an error. This can be useful if you want to make sure that
only pre-defined resources (for which you presumably have hardwired defaults)
are loaded. It can be a safety net against typos in a resource file.

Use is made of B<Safe::reval> to parse values specified through Perl
constructors (only constants, anon hashes and anon arrays are allowed).

Returns 1 if ok, 0 if error.

=cut
 
sub load {
   my $res = shift;
   my ($filnam, $nonew) = @_;
   my ($lin, $prevlin, $comlin, @line);
   my ($name, @allvals, $value, %allres, $def, @dum);
   my ($sep, $expr, $evaled);
   my ($app, $mrgcls);

   $res->_error("load","No filename.") && return 0 unless defined $filnam;
   
   $res->_error("load", $!) && return 0 unless open(_RESFILE, $filnam);
   $res->{Safe}->share('$expr');
   $sep = $res->{Res}->{'resources.separator'}->[$Value] || ':';
   $app = $res->{Res}->{'resources.appclass'}->[$Value];
   $mrgcls = $res->{Res}->{'resources.mergeclass'}->[$Value];

   $prevlin = '';
   while ($lin = <_RESFILE>) {  
      chomp $lin;
      $comlin = $prevlin . $lin;

      # Hash chars in quoted strings are not comments.
      1 while $comlin =~ s/^(.*\".*)\#(.*\".*)$/$1__RES_NO_COMM__$2/ ;
      1 while $comlin =~ s/^(.*\'.*)\#(.*\'.*)$/$1__RES_NO_COMM__$2/ ;
      
      # Join split lines
      if ($comlin !~ /\#/ && $comlin =~ /\\$/) {
	 $prevlin .= $comlin;
	 next;
      } else {
	 $prevlin = '';
      }

      # Now get rid of comments
      @line = split(/\#/, $comlin);

      # Skip empty lines, get def and put hashes back in place
      $def = $line[0] || next;
      $def =~ s/__RES_NO_COMM__/\#/go;

      # Split def on first separator
      ($name, @allvals)=split(/$sep/, $def);
      $value=join($sep, @allvals);

      # Get rid of trailing/leading whitespaces.
      $name  =~ s/^\s+|\s+$//g;
      $value =~ s/^\s+|\s+$//g;

      next unless $name;

      # Application class check
      next if ($mrgcls && $name !~ /^\*|^$app\./);
      
      # Name may not 
      #     - contain whitespaces or
      #     - terminate with wildcard or dot,
      #     - start with dot
      #     - contain ._ sequences (which are for hidden resources only)
      $res->_error("load", "$filnam: line $.: bad resource name: $name") 
	 && return 0 if $name =~ /\s+|^\.|\.$|\*$|\._/o;
     
      # Parse value: 
      # If the whole thing is quoted, take it as it is:
      if ($value =~ s/^\'(.*)\'$|^\"(.*)\"$/$1/ ) {
	 $allres{$name} = [ $value ];
      } elsif ($value =~ /^[\[\{].*/) {
	 # Do anon hashes and arrays
	 $evaled = $res->{Safe}->reval('$expr=' . $value);
	 if ($@) {
	    $res->_error("load", 
			 "$filnam: error in line $. ($@) - $name : $value");
	    return 0;
	 } else {
	    $allres{$name} = [ $evaled ];
	 }
      } else {
	 # Swallow it anyway, babe ;-)
	 $allres{$name} = [ $value ];
      }
   } 
   close(_RESFILE);
    
   # Safe loading checks
   if ($nonew) {
      my $resnames = join(' ', sort($res->names()));

      foreach $name (keys(%allres)) {
	 unless ($resnames =~ /$name/) {
	    $res->_error("load", "unknown resource $name in $filnam");
	    return(0);
	 }
      }
   }

   $res->{Load}=1;
   while (($name, $value) = each(%allres)) {
      $res->put($name, @{$value}) || do {
	 _error("load", "failed put $name : $value");
	 $res->{Load}=0;
	 return 0;
      };
   }
   $res->{Load}=0;

   1;
}


=item B<merge($class, @memberclasses);>

Merges the %Resources hash of the package defining $class with
those of its @memberclasses, writing the result in the resource database.

The merging reflects the resource inheritance explained above: the %Resources
of all base classes and member classes of $class are inherited along the
way. Eventually all these resources have their names prefixed with the name of
the package in which $class is defined (lowercased and stripped of all
foo::bar:: prefixes), and with the application class as well.

In the above example, the defaults of a Car object will be renamed, after
merging as:

   car.brand, car.noise, ..., 
   car.tire.flat

and for a Civic object, where Civic is a (i.e. ISA) Car, they will be
translated instead as

   civic.brand, civic.noise, ..., 
   civic.tire.flat

Finally, the application name ($0, a.k.a $PROGRAM_NAME in English) is 
prepended to all resource names, so, if the above Civic package is used
by a Perl script named "ilove.pl", the final names after merging are

   ilove.civic.brand, ilove.civic.noise, ..., 
   ilove.civic.tire.flat

The new names are the ones to use when accessing these resources by name.

The resource values are inherited accoring to the rules previously indicated,
hence with resource files having priority over hardcoded defaults, nnd derived
or container classes over base or member classes.

Returns 1 if for success, otherwise 0.

=cut

sub merge {
   my ($res, $class, @members) = @_;
   my ($app, @tops, $top, $topclass, $toppack, $mem);
   my ($level, $caller, @ignore);
   my ($isaname, $isa, $base);

   # Add to inverted indexes.
   #  Members
   for $mem (@members) {
     $res->{Owned}->{$mem} = '' unless $res->{Owned}->{$mem};
     $res->{Owned}->{$mem} .= "$class ";
   }
   #  Base classes
   do {
      no strict;
      $isaname = "$class\::ISA"; 
      $isa = \@$isaname;
   };
   if (defined(@{$isa})) {
      for $base (@{$isa}) {
	 $res->{Isa}->{$base} = '' unless $res->{Isa}->{$base};
	 $res->{Isa}->{$base} .= "$class ";
      }
   }

   # Walk up the caller frames. 
   #   If one of the callers is in the Isa list for $class, then $class
   #   defaults have been already merged, so we can bail out.
   #   Otherwise make up class name for $object, taking into account the Owned
   #   list. 
   if ($class ne "main" 
       && $class ne lc($res->{Res}->{'resources.appclass'}->[$Value])) {
      $level=0;
      $toppack = $class;
      while (($caller, @ignore)=caller(++$level)) {
	 last if $caller eq "main";
	 if (exists($res->{Isa}->{$class})
	     && $res->{Isa}->{$class} =~ /\b$caller\b/) {
	    return 1;
	 }
	 
	 if (exists($res->{Owned}->{$toppack}) 
	     && $res->{Owned}->{$toppack} =~ /\b$caller\b/) {
	    $toppack = $caller;
	    ($topclass = lc($toppack)) =~ s/(.*::)?(\w+)/$2/;
	    unshift(@tops, $topclass);
	 }
      }
      shift(@tops) if $tops[0] =~ /main/o; # get rid of main
   }
   unshift(@tops, lc($res->{Res}->{'resources.appclass'}->[$Value]))
      if $res->valbyname('resources.mergeclass');
   $app = join('.', @tops);
   $app .= '.' if $app;
   ($top = lc($class)) =~ s/(.*::)?(\w+)/$2/;

   # Now recursive merge. 
   $res->{Merge} = 1;
   unshift(@members, $class);
   for $mem (@members) {
      $res->_merge_pack($app, $top, $mem);
   }
   $res->{Merge} = 0;

   1;
}

=head2 5.2. Looking up resources

The values and documentation strings stored in a Resource object can be
accessed by specifying their names in three basic ways:

=item directly ("byname" methods)

As in "my.nice.cosy.couch" .

=item by a pattern ("bypattern" methods)

As in "m??nice.*" .

=item hierarchically ("byclass" methods)

If class Nice B<is a> Cosy, then asking for "couch" in package Cosy gets you
the value/doc of "my.couch". If, instead, Nice B<has a> Cosy member, that the
method gets you "my.nice.cosy.couch". This behaviour is essential for the
proper initialization of subclassed and member packages, as explained in
detail below.

=back

It is also possible to retrieve the whole content of a resource database
("names" and "each" methods)

Note that all the resource lookup methods return named (non "wildcarded")
resources only. Wildcarded resources (i.e. those specified in resource files,
and whose names contain one or more '*') are best thought as placeholders, to
be used when the value of an actual named resource is set. 

For example, a line in a resource file like

          *background : yellow

fixes to yellow the color of all resources whose name ends with "background".
However, your actual packages will never worry about unless they really need
a background. In this case they either have a "background" resource in
their defaults hash, or subclass a package that has one.

=over 8

=item B<valbyname($name);>

Retrieves the value of a named resource from a Resource database. The $name
argument is a string containing a resource name with no wildcards. 

Returns the undefined value if no such resource is defined.

=cut

sub valbyname {
   my $res = shift;	
   my ($name) = @_;	
   my $fullname;

   $fullname = $res->{Res}->{'resources.appclass'}->[$Value] . ".$name";

   if (exists($res->{Res}->{$fullname})) {
      return $res->{Res}->{$fullname}->[$Value];
   } elsif (exists($res->{Res}->{$name})) {
      return $res->{Res}->{$name}->[$Value];
   } else {
      return undef;
   }
}

=item B<docbyname($name);>

Retrieves the documentation string of a named resource from a Resource
database. The $name argument is a string containing a resource name with no
wildcards. 

Returns the undefined value if no such resource is defined.

=cut

sub docbyname {
   my $res = shift;	
   my ($name) = @_;	
   my $fullname;

   $fullname = $res->{Res}->{'resources.appclass'}->[$Value] . ".$name";

   if (exists($res->{Res}->{$fullname})) {
      return $res->{Res}->{$fullname}->[$Doc];
   } elsif (exists($res->{Res}->{$name})) {
      $res->{Res}->{$name}->[$Doc];
   } else {
      return undef;
   }
}


=item B<bypattern($pattern);>

Retrieves the full names, values and documentation strings of all the named
(non wildcarded) resources whose name matches the given $pattern. The pattern
itself is string containing a Perl regular expression, I<not> enclosed in
slashes.

Returns a new Resource object containing only the matching resources, or 
the undefined value if no matches are found.

=cut

sub bypattern {
   my $res = shift;	
   my ($pattern) = @_;	
   my ($name, $valdoc);
   my $newres = new Resources() || return undef;

   while (($name, $valdoc) = $res->each()) {
      $newres->put($name, @{$valdoc}) if $name =~ /$pattern/ ;
   }

   return $newres if %{$newres->{Res}};
   undef;
}

=item B<valbypattern($pattern);>

Retrieves the full names and values of all named (non wildcarded) resources
whose name matches the given pattern. 

Returns a new Resource object containing only names and values of the matching
resources (i.e. with undefined doc strings), or the undefined value if no
matches are found.

=cut

sub valbypattern {
   my $res = shift;	
   my ($pattern) = @_;	
   my ($newres, $i);
   
   $newres = $res->bypattern($pattern) || return undef;
   for $i ($newres->names()) {
      undef($newres->{Res}->{$i}->[$Doc]); 
   }
   
   $newres;
}

=item B<docbypattern($pattern);>

Retrieves the full names and documentation strings of all named (non
wildcarded) resources whose name matches the given pattern.

Returns a new Resource object containing only names and docs of the matching
resources (i.e. with undefined resource values), or the undefined value if no
matches are found.

=cut

sub docbypattern {
   my $res = shift;	
   my ($pattern) = @_;	
   my ($newres, $i);
   
   $newres = $res->bypattern($pattern) || return undef;
   for $i ($newres->names()) {
      undef($newres->{Res}->{$i}->[$Value]); 
   }
   
   $newres;
}



=item B<byclass($object, $suffix);>

To properly initialize the attributes of a package via resources we need a
way to know whether the package defaults (contained in its %Resources hash)
have been overridden by a derived or container class.  For example, to set
a field like $dog->{Weight} in a Dog object, we must know if this $dog
is being subclassed by Poodle or Bulldog, or if it is a member of Family,
since all these other classes might override whatever "weight" default is
defined in the %Resources hash of Dog.pm. 

This information must of course be gathered at runtime: if you tried to name
explicitly a resource like "family.dog.weight" inside Dog.pm all the OOP
crowd would start booing at you. Your object would not be reusable anymore,
being explicitly tied to a particular container class. After all we do use
objects mainly because we want to easily reuse code...

Enter the "by class" resource lookup methods: B<byclass>, B<valbyclass> and
B<docbyclass>.

Given an $object and a resource $suffix (i.e. a resource name stripped of all
container and derived class prefixes), the B<byclass> method returns a 3
element list containing the name/value/doc of that resource in $object. The
returned name will be fully qualified with all derived/container classes, up
to the application class.

For example, in a program called "bark", the statements

  $dog = new Dog ($res); # $res is a Resources database
  ($name,$value,$doc) = $res->byclass($dog, "weight");

will set $name, $value and $doc equal to those of the "bark.poodle.weight"
resource, if this Dog is subclassed by Poodle, and to those of
"bark.family.dog.weight", if it is a member of Family instead.

The passed name suffix must not contain wildcards nor dots.

Be careful not to confuse the "byclass" with the "byname" and "bypattern"
retrieval methods: they are used for two radically different goals. See the
EXAMPLES section for more.

Returns the empty list if no resources are found for the given suffix,
or if the suffix is incorrect.

=cut

sub byclass {
   my ($res, $object, $suffix) = @_;
   my ($class, $name, $value, $doc);
   my ($level, $topclass, $toppack, @ignore, @tops);

   ($class = ref($object)) || do {
      $res->_error("byclass", "must pass an object reference");
      return ();
   };
   # No patterns or leading/trailing dots
   $suffix =~ /\.|\*/ && do {
      $res->_error("byclass", "bad suffix $suffix");
      return ();
   };
   
   # Walk up the caller frames. 
   #   If one of the callers is in the Isa list for $class, then $class
   #   defaults have been already merged, so we can bail out.
   #   Otherwise make up class name for $object, taking into account the Owned
   #   list. 
   $level=0;
   ($name = lc($class)) =~ s/(.*::)?(\w+)/$2/;
   unshift(@tops, $name); 
   while (($toppack, @ignore)=caller(++$level)) {
      last if $toppack eq "main";

      ($topclass = lc($toppack)) =~ s/(.*::)?(\w+)/$2/;

      if (exists($res->{Isa}->{$class})
	  && $res->{Isa}->{$class} =~ /\b$toppack\b/) {
	 shift(@tops);
	 unshift(@tops, $topclass);
	 $class = $toppack;
	 next;
      }

      if (exists($res->{Owned}->{$class}) 
	  && $res->{Owned}->{$class} =~ /\b$toppack\b/) {
	 unshift(@tops, $topclass);
	 $class = $toppack;
      }
   }

   unshift(@tops, lc($res->{Res}->{'resources.appclass'}->[$Value]));

   $name = join('.', @tops) . ".$suffix";

   return () unless exists($res->{Res}->{$name});

   ($value, $doc) = @{$res->{Res}->{$name}};

   return ($name, $value, $doc);
}


=item B<namebyclass($obj, $suffix);>

As the B<byclass> method above, but returns just the resource name (i.e. the
suffix with all the subclasses prepended).

=cut

sub namebyclass {
   my ($res, $obj, $suffix) = @_;
   my @nvd = $res->byclass($obj, $suffix);
   
   $nvd[0];
}

=item B<valbyclass($obj, $suffix);>

As the B<byclass> method above, but returns just the resource value.

=cut

sub valbyclass {
   my ($res, $obj, $suffix) = @_;
   my @nvd = $res->byclass($obj, $suffix);
   
   $nvd[1];
}


=item B<docbyclass($suffix);>

As the B<byclass> method above, but returns just the resource documentation.

=cut

sub docbyclass {
   my ($res, $suffix) = @_;
   my @nvd = $res->byclass($suffix);
   
   $nvd[2];
}



=item B<each;>

Returns the next name/[value,doc] pair of the named (non wildcarded) resources
in a resource database, exactly as the B<each> Perl routine. 

=cut

sub each {
   my $res=shift;
   return each(%{$res->{Res}});
}


=item B<names;>

Returns a list of the names of all named (non-wildcarded) resources in a
resource database, or undef if the databasee is empty.

=cut

sub names {
   my $res=shift;
   return keys(%{$res->{Res}});
}

=head2 5.3. Assigning and removing Resources

=item B<put($name, $value, $doc);>

Writes the value and doc of a resource in the database.  It is possible to
specify an empty documentation string, but name and value must be defined.

Wildcards ('*' characters) are allowed in the $name, but the $doc is ignored
in this case (documentation is intended for single resources, not for sets
of them).

The value is written unchanged unless the resource database already
contains a wildcarded resource whose name includes $name (foo*bar
includes foo.bar, foo.baz.bar, etc.). In this case the value of the
wildcarded resource overrides the passed $value.

Returns 1 if ok, 0 if error.

=cut 

# Resource locking
#   Some conditions may affect if and how a resource gets put inthe database.
#   In order to implement the value priority policy (loaded resources have
#   priority, derived and container class have priority over base and member
#   classes) use is made to the Load and Merge fields in a Resources object,
#   and of two additional fields in the resources value (indexed by the global
#   variables $Loaded and $Merged).
#
sub put {
   my $res=shift;
   my ($name, $value, $doc) = @_;
   my (@words);

   $res->_error("put", "name or value undefined") and return 0 
      unless defined($name) && defined($value);

   $name = lc($name);
   @words = split(/\s+/, $name);

   # Name must be one word and may not terminate with wildcard or dot
   # or start with dot. Must check here too because of defaults.
   $res->_error("put", "bad resource name: $name") && return 0
      if scalar(@words) > 1 || $name=~/^\.|\.$|\*$/;


   # Do booleans.
   $value =~ s/^true$|^yes$/1/i;
   $value =~ s/^false$|^no$/0/i;
   
   # Do wildcards (they take priority over named)
   # Match of wildcards is done hyerarchically:
   #      *b  contains a*b
   #      a*b contains a*c*b
   # In case of conlict, newer overwrite older ones.
   if ($name =~ /\*/) {
      my ($I_have, $r, $patname, $wild);

      $I_have=0;

      # Dots must be matched literally when name is used as a pattern
      ($patname = $name) =~ s/\./\\\./go;

      # a*b => a.*b (regexp cannot start with *)
      $patname =~ s/\*/\.\*/g;

      # First compare with known wildcarded resources.
      foreach $wild (keys(%{$res->{Wilds}})) {
	 # Remove old wildcards if the new one contains them 
	 ($wild =~ /$patname\Z/) && delete($res->{Wilds}->{$wild});

	 # Skip if a more general old one is found
	 ($name =~ /$wild\Z/) && ($I_have = 1, last);
      }
      $res->{Wilds}->{$patname}=[$value, undef] unless $I_have;

      # Then update the old named ones 
      foreach $r (keys(%{$res->{Res}})) {
	 $res->{Res}->{$r}->[$Value] = $value if $r =~ /$patname\Z/; 
      }

   } else { 
      # Named resources.
      # Check if it is already wildcarded: if so, use wildcard's value
      my ($wild, $nref, $ex, $putall, $putdoc);
 
      foreach $wild (keys(%{$res->{Wilds}})) {
	 if ($name =~ /$wild\Z/) {
	    $value = $res->{Wilds}->{$wild}->[$Value];
	    last;
	 }
      }

      # Do merging-locking stuff and write
      #  Had to use a Karnaugh map to find the right condition...
      $ex =  exists($res->{Res}->{$name}) || 0;
      $nref = $ex ? $res->{Res}->{$name} : undef;
      $putall = $res->{Load} || !$ex ||
	 !$nref->[$Loaded] && (!$res->{Merge} || !$nref->[$Merged]) || 0;
      $putdoc = !$putall && $ex && (!$nref->[$Doc] && $doc) || 0;

      if ($putall) {	 
	 $res->{Res}->{$name}->[$Value] = $value;
	 $res->{Res}->{$name}->[$Doc] = $doc if $doc;
	 $res->{Res}->{$name}->[$Loaded] = $res->{Load};
	 $res->{Res}->{$name}->[$Merged] = $res->{Merge};	 
      } elsif ($putdoc) {
	 $res->{Res}->{$name}->[$Doc] = $doc;
      }
   }

   1;
}


=item B<removebyname($name);>

Removes the named (non wildcarded) resources from the database.

Returns 1 if OK, 0 if the resource is not found in the database.

=cut

sub removebyname {
   my $res = shift;
   my ($name) = @_;
   my ($i, $cnt, $newres);

   return 0 unless exists $res->{Res}->{$name};
   delete($res->{Res}->{$name});
   1;
}

=item B<removebypattern($name);>

Removes from the database all resources (both named I<and> wildcarded) whose
name mathes $pattern. An exactly matching name must be specified for
wildcarded resources (foo*bar to remove foo*bar).

Returns the number of removed resources.

=cut

sub removebypattern {
   my $res = shift;
   my ($name) = @_;
   my ($i, $cnt, $newres);

   $newres=$res->bypattern($name) || return 0;

   foreach $i ($newres->names()) {
      delete($res->{Res}->{$i});
      $cnt++;
   }
   foreach $i (keys(%{$res->{Wilds}})) {
      ($cnt++ , delete($res->{Wilds}->{$i})) if $i eq $name;
   }

   $cnt;
}


=head2 5.6. Viewing and editing resources.

=item B<view;>

Outputs the current content of a Resource object by piping to a pager program.

The environment variable $ENV{RESPAGER}, the resource "resources.pager" and
the environment variable $ENV{PAGER} are looked up, in this very order, to
find the pager program. Defaults to B</bin/more> if none of them is found.

The output format is the same of a resource file, with the resource names
alphabetically ordered, and the resource documentation strings written
as comments.

Returns 1 if ok, 0 if error.

=cut

sub view {
   my $res=shift;
   my ($name, $value, $doc, $view, $pager, $p);

   if ($p = $ENV{RESPAGER}) {
      $pager = $p;
   } elsif ($p = $res->valbyname("resources.pager")) {
      $pager = $p;
   } elsif ($p = $ENV{PAGER}) {
      $pager = $p;
   } else {
      $pager='/bin/more';
   }

   # Make sure we don't output POD.
   my $pod = $res->valbyname("resources.writepod");
   $res->put("resources.writepod", 0);

   $p = $res->write("|$pager");
   $res->_error("view", "write failed") unless $p;

   $res->put("resources.writepod", $pod);
   
   return $p;
}


=item B<edit($nonew);>

Provides dynamical resource editing of a Resource object via an external
editor program. Only resource names and values can be edited (anyway, what is
the point of editing a resource comment on the fly?).

The environment variables $ENV{RESEDITOR} and the resource "resouces.editor",
are looked up, in this very order, to find the editor program. Defaults to
B</bin/vi> if none is found.

The editor buffer is initialized in the same format of a resource file, with
the resource names alphabetically ordered, and the resource documentation
strings written as comments. The temporary file specified by the
"resources.tmpfil" resource is used to initialize the editor, or
'/tmp/resedit<pid>' if that resource is undefined.

When the editor is exited (after saving the buffer) the method attempts to
reload the edited resources. If an error is found the initial object is left
unchanged, a warning with the first offending line in the file is printed, and
the method returns with undef. Controlled resource loading is obtained by
specifying a true value for the $nonew argument (see B<load>).

If the loading is successful, a new (edited) resource object is returned,
which can be assigned to the old one for replacement. 

After a successful edit, the value of the resource "resources.updates" (which
is always defined to 0 whenever a new resource is created) is increased by
one. This is meant to notify program the and/or packages of the resource
change, so they can proceed accordingly if they wish.

=cut

sub edit {
   my ($res, $nonew) = @_;
   my ($newres, $editor, $p, $status, $tmpfil);

   if ($p = $ENV{RESEDITOR}) {
      $editor = $p;
   } elsif ($p = $res->valbyname("resources.editor")) {
      $editor = $p;
   } 

   $tmpfil = ($res->valbyname("resources.tmpfil") || "/tmp/resedit$$.txt");

   # Make sure we don't output POD.
   my $pod = $res->valbyname("resources.writepod");
   $res->put("resources.writepod", 0);
   $p = $res->write($tmpfil);
   $res->put("resources.writepod", $pod);

   $p || ($res->_error("edit", "write failed") && return $p);

   $status = system("$editor $tmpfil");
   return 0 if $status>>8; # Editor failed

   $newres = new Resources("_RES_NODEFAULTS") || undef;
   $newres->load($tmpfil, $nonew) || undef($newres);
   unlink($tmpfil);

   for $p ($newres->names()) {
      if (exists($res->{Res}->{$p}) && defined($res->{Res}->{$p}->[$Doc])) {
	 $newres->{Res}->{$p}->[$Doc] = $res->{Res}->{$p}->[$Doc];
      }
   }
   ++$newres->{Res}->{'resources.updates'}->[$Value];
   return $newres;
}

=head2 5.5. Miscellaneous methods

=item B<write($filename);>

Outputs all resources of a resource database into a resource file (overwriting
it). 

The resource documentation strings are normally written as comments, so the
file itself is immediately available for resource loading. However, if the
boolean resource "resources.writepod" is true, then the (non wildcarded)
resources are output in POD format for your documentational pleasure.

As usual in Perl, the filename can allo be of the form "|command", in which
case the output is piped into "comma1nd".

For resources whose value is a reference to an anon array or hash, it produces
the appropriate constant Perl contructor by reverse parsing. The parser itself
is available as a separate method named B<_parse> (see package source for
documentation).

Returns 1 if ok, 0 if error.

=cut
 
sub write {
   my $res = shift;
   my ($filnam) = @_;
   my ($name, $value, $doc, $view);

   $res->_error("write", "No filename") && return 0 unless defined $filnam;
   $filnam = ">$filnam" unless $filnam =~ /^\|/;
   ($res->_error("write", $!) && return 0) unless open(RESOUT, $filnam);

   autoflush RESOUT (1);

   if ($res->valbyname("resources.writepod")) {

      print RESOUT "=head2 Resources\n\n=over 8\n";

      for $name (sort($res->names())) {
	 next if $name =~ /\._/; # hidden

	 my $val = $res->valbyname($name);
	 my @doclines=split(/ /, $res->docbyname($name));
	 my $len=0;
	 my $lin;

	 $val = $res->_parse($val) if ref($val);
	 print RESOUT "\n=item $name : $val\n\n";
	 
	 while (scalar(@doclines)) {
	    $lin='';
	    while (length($lin)<60 && scalar(@doclines)) {
	       $lin .= shift(@doclines) . ' ';
	    }
	    chomp $lin;
	    print RESOUT "$lin\n";
	 }
      }

   } else {
      $view = "#\n# Wildcarded resources\n#\n";
      
      for $name (sort(keys(%{$res->{Wilds}}))) {
	 ($value, $doc) = @{$res->{Wilds}->{$name}};
	 $doc = '' unless $doc;
	 $name =~ s/\\\./\./go;
	 $name =~ s/\.\*/\*/go;
	 $value = $res->_parse($value) if ref($value);
	 $view .= "$name : $value\__RES_COMM__$doc\n";
      }
      
      $view .= "#\n# Named resources\n#\n";
      
      for $name (sort($res->names())) {
	 next if $name =~ /\._/o; # "hidden" resource
	 $value = $res->valbyname($name);
	 $doc = $res->docbyname($name);
	 $value = $res->_parse($value) if ref($value);
	 $view .= "$name : $value\__RES_COMM__" . ($doc ? "$doc\n" : "\n");
      }
      
      $res->_printformat(\*RESOUT, $view);
      close(RESOUT);
   }
}

 
#
# LOCAL (UNEXPORTED) METHODS
#
#


# $res->_dump -- dumps the content of res on stderr. Used for debugging.
#
sub _dump {
   my $res=shift;
   my ($name, $value, $doc, $valdoc);
   warn "_dump: WILDCARDED RESOURCES\n";
   for $name (sort(keys(%{$res->{Wilds}}))) {
      $value= $res->{Wilds}->{$name}->[$Value]; 
      $name =~ s/\.\*/\*/g;
      $name =~ s/\\//g;
      warn "_dump: $name : $value\n";
   }

   warn "_dump: NAMED RESOURCES\n";
   for $name (sort(keys(%{$res->{Res}}))) {
      $valdoc= $res->{Res}->{$name}; 
      $name =~ s/\\//g;
      $value= $valdoc->[$Value];
      $doc=$valdoc->[$Doc];
      warn "_dump: $name : $value #" . ($doc || '') . "\n";
   }
}

# _parse($value) -- Returns a string containing the value of a resource $name,
#                   written in the same format as for a resource file (i.e. in
#                   Perl syntax if the value is not a scalar.
#                   Returns the string, or undef in case of errors.
#
sub _parse {
   my $res=shift;
   my ($value) = @_;
   my ($ref);

   return $value unless $ref = ref($value);
   return _parse_ref($value, $ref);
}   

#  
# _parse_ref -- This does recursive parsing for hass/array references .
#
sub _parse_ref {
   my ($value, $ref) =@_;
   my $parsed='';
   
   $ref eq 'ARRAY' && do {
      my $element;
      $parsed = '[';
      for $element (@{$value}) {
	 my $refref;
	 if ($refref = ref($element)) {
	    my $parspars = _parse_ref($element, $refref)
	       || return undef;
	    $parsed .= $parspars;
	 } elsif (_isint($element) || _isreal($element)) {
	    $parsed .= "$element, ";
	 } else {
	    $parsed .= "'$element', ";
	 }
      }
      $parsed =~ s/,\s$//;
      $parsed .= ']';
      return $parsed;
   };

   $ref eq 'HASH' && do {
      my ($nam, $val);
      $parsed = '{';
      while (($nam, $val) = each(%{$value})) {
	 my $refref;
	 return undef if (ref($nam));
	 if ($refref = ref($val)) {
	    my $parspars = _parse_ref($val, $refref)
	       || return undef;
	    $parsed .= "'$nam' => $parspars, ";
	 } elsif (_isint($val) || _isreal($val)) {
	    $parsed .= "'$nam' => $val, ";
	 } else {
	    $parsed .= "'$nam' => '$val', ";
	 }
      }
      $parsed =~ s/,\s$//;
      $parsed .= '}';
      return $parsed;
   };

   return undef; # We do only arrays and hashes

   sub _isint {
      my ($num)=@_;
      $num =~ /\A-?\d+/o;
   }
   sub _isreal {
      my ($num)=@_;
      $num =~ /((-?\d*\.\d+)|(-?\d*\.\d+[eE]-?\d+))/o;
   }
}


# _merge_pack($app, $class) 
#
#    Recursively merges the %Resources of object $obj of package $pack into a
#    $res object in application $app.  The merging is done topdown, from
#    derived and container classes to base and member ones.
#
# The algorithm is as follows:
# 1) Resource names are syntax-checked, then merging is performed for those
#    not yet defined
# 2) All base classes of $pack are _merge_packed in turn.
# 
# Returns 1 for success, 0 otherwise.
#
sub _merge_pack {
   my ($res, $app, $top, $pack, $packclass) = @_; 
   my ($defname, $def);

   $packclass || ($packclass = lc($pack))  =~ s/(.*::)?(\w+)/$2/; 

   do {
      no strict; # To use symbolic references
      $_ = $res->{Res}->{"resources.resources"}->[$Value];
      unless (/^%/) {
	 $res->_error("merge", "bad name for %Resources hash: $_");
	 return 0;
      }
      s/^%//; 
      $defname = "$pack\::$_";
      $def = \%{$defname};
   };

   if (defined(%{$def})) {
      my ($dname, $dvalue, $val, $vref);
      defloop: while (($dname, $dvalue) = each(%{$def})) {
	 # Check for bad args: 
	 # Names cannot contain * or :, nor start/end with a dot
	 $dname =~ /\*|^\.|\.$|\:/ && do {
	    $res->error("merge", "Bad default resource name: $dname ");
	    return 0;
	 };
	 # Values must be 2-elements arrays, with a scalar 2nd
	 # component (the doc)
	 unless(($vref = ref($dvalue)) && ($vref =~ /ARRAY/o) &&
		scalar(@{$dvalue})<=2 && !ref($dvalue->[1])      )  {
	    $res->_error("merge", "Bad default resource value for ".
			 "resource $dname in hash $defname");
	    return 0;
	 };
	 
	 # Build class name for resource by inheritance 
	 if ($top eq "main") {
	    $dname = $app . $dname;
	 } elsif ($top eq $packclass) {
	    $dname = "$app$top\.$dname";
	 } else {
	    $dname = "$app$top\.$packclass\.$dname";
	 }

	 $res->put($dname, @{$dvalue}) ||
	    ($res->_error("merge", "error on $dname: $dvalue") && return 0);
      }
   }

   # Now let's recur on base  classes of $obj
   #
   my ($isaname, $isa, $base);
   my (@hasa, $mem);

   # Base classes
   do {
      no strict;
      $isaname = "$pack\::ISA"; 
      $isa = \@$isaname;
   };
   if (defined(@{$isa})) {
      for $base (@{$isa}) {
	 return 0 unless $res->_merge_pack($app, $top, $base, $packclass);
      }
   }

   # All done.
   return 1;
}


#
# _error ($subname) - wrapper around caller(), used for debugging
#
sub _error {
   my $res=shift;
   my ($place, $msg) = @_;

   $res->valbyname("resources.verbosity") &&
      warn("error: $0: Resources: $place, $msg\n");
      
   1;
}


#
# _printformat($fh, $msg) 
#        prints to filehandle $fh the documentation $doc.
#       formatted in resources.viewcolumn  columns, not breking expression and
#       continuing comments. 
#

sub _printformat {
   my $res=shift;
   my ($fh, $msg) = @_;
   my ($line, $cols, $def, $comm, @comms, $below);
   my ($deflen, $commlen, $mincols, $whites);

   $cols = $res->valbyname("resources.viewcols");
   $mincols = $res->valbyname("resources.viewmincols");
   $cols = 78 unless $cols;

   for $line (split(/\n/, $msg)) {
      # print right away if it's short
      if (length($line) <= $cols) {
	 $line =~ s/__RES_COMM__$//o;
	 $line =~ s/__RES_COMM__/ \# /;
	 print $fh "$line\n";
	 next;
      }
      
      ($def, $comm) = split(/__RES_COMM__/, $line);
      $deflen = length($def)+1;
      # down one line if def is too long
      if (($commlen = $cols-($deflen % $cols)) < $mincols) {
	 $below=1;
	 $commlen=$cols/2;
      } else {
	 $below=0;
      }

      @comms = split(/\s+/, $comm);
      shift(@comms) unless $comms[0];

      unless ($below) {
	 print $fh ("$def # ", _commwds($commlen, \@comms), "\n");
	 $whites = $deflen % $cols;
	 while ($comm=_commwds($commlen, \@comms)) {
	    $comm = (' ' x $whites) . "# $comm";
	    print $fh "$comm\n";
	 }
      } else {
	 print $fh "$def\n";
	 $whites = $cols/2 - 1;
	 while ($comm=_commwds($commlen, \@comms)) {
	    $comm = (' ' x $whites) . "# $comm";
	    print $fh "$comm\n";
	 }
      }	 
   }

   sub _commwds {
      my ($len, $comp) = @_;
      my ($shft, $wd, $ls, $lw);
       
      $ls=1; 
      $shft = $wd = ''; 
      while (1) {
	 $wd=shift(@{$comp});
	 last unless $wd;
	 $lw=length($wd)+1;
	 last if $lw + $ls > $len;
	 $shft .= "$wd ";
	 $ls += $lw;
      }
      unshift(@{$comp}, $wd) if $wd;
      return $shft;
   }
}

			     
1;

__END__
# Local Variables:
# mode: perl
# End:

=head2 5. Resources of Resources

As you may have guessed at this point, the default configuration of this
package itself is defined by resources. The resource class is, of course,
"resources" (meaning that all the names have a leading "resources.").

To prevent chaos, however, these resources cannot be subclassed. This should
not be a problem in normal applications, since the Resource package itself is
not meant to be subclassed, but to help building a hierarchy of classes
instead.

The currently recognized resources, and their default values, are:

=item resources.appclass : "$PROGRAM_NAME"

The application name of this Resource object. 

=item resources.editor : /bin/vi

Resource editor. 

=item resources.mergeclass : true

Boolean. True to merge with class inheritance.

=item resources.pager : /bin/more

Resource pager. 

=item resources.separator : ':'

Pattern separating names from values in resource files. 

=item resources.tmpfil : ''

Editor temporary file. 

=item resources.updates : 0

Number of resource updates. 

=item resources.verbosity : 1

True to print warnings. 

=item resources.viewcols : 78

Width of view/edit window. 

=item resources.writepod : false

Boolean. True if the write method should output in POD format. 

=back

=head1 EXAMPLES

Here is an example of resource inheritance.
HotDog is a subclass of Food, and has a member Wiener whichi happens to be a
Food as well. 

The subclass has defaults for two resources defined by the base classes
("edible" and "wiener.mustard"), and their values will override the base
class defaults.

Remember that after merging all resources names are prefixed with the current
class name.

   use Resources;
   package Food;
   %Resources = ( 
     edible => [1, "Can it be eaten."], 
     tasty  => ["sort_of",  "D'ya like it?"],
   );
   
   sub new {
      my ($type, $res) = @_;
      $res || $res =  new Resources || (return undef);
      $res->merge($type) || die ("can't merge defaults");
       
      my $food= bless({}, type);
      $food->{Edible} = $res->valbyclass("edible");
      $food->{Tasty}  = $res->valbyclass("tasty");
      # Use valbyclass so a subclass like HotDog can change this by its
      # defaults.   
   }
 
   # A Food method to say if it can be eaten.
   sub eatok { 
      my $food=shift; 
      return $food->{Edible}; 
   }

   package Wiener;
   @ISA = qw( Food );
   %Resources = (
        tasty => ["very"], # this overrides a base class default
        mustard => ["plenty", "How much yellow stuff?"],
   );
   # Nothing else: all methods are inherited from the base class.

   package HotDog;
   @ISA = qw( Food );

   %Resources = (
       edible    => [0],
       tasty     => ["yuck!"],
       'wiener.mustard' => ["none"], # To override member class default.
   );

   sub new {
      my ($type, $res) = @_;
      
      $res || $res =  new Resources || (return undef);
      $res->merge($type) || die ("can't merge defaults");
	       
      my $hd = bless(new Food ($res), $type);
      $hd->{Wien} = new Wiener ($res);
      return $hd;
   }

   # All tastes of hotdog
   sub tastes {
      my $hd = shift;
      return ($hd->{Tasty}, $hd->{Wien}->{Tasty});
   }
   
   package main;
   # Whatever
   #
   $res = new Resources("AppDefltFile") || die;
   $snack = new HotDog($res);  
   $gnam = $snack->eat();  # hotdog.edible overridees food.edible, 
                           # so here $gnam equals 0

   @slurp = $snack->tastes()    # @slurp equals ("yuck!", "very") 
                                # the resources were overridden 
                                # by a subclass of HotDog , or
                                # differently specified in 
                                # "AppDefltFile"


=head1 SEE ALSO

Safe(3). 

=head1 BUGS

The underlying idea is to use a centralized resource database for the whole
application. This ensures uniformity of behaviour across kin objects, but
allow special characterizations only at the cost of subclassing.

=head1 AUTHOR

	Francesco Callari <franco@cim.mcgill.ca> 
	Artifical Perception Laboratory,
	Center for Intelligent Machines, 
	McGill University.

        WWW: http://www.cim.mcgill.ca/~franco/Home.html

=head1 COPYRIGHT

Copyright 1996 Francesco Callari, McGill University

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose without fee is hereby granted without fee,
provided that the above copyright notice appear in all copies and that both
that copyright notice and this permission notice appear in supporting
documentation, and that the name of McGill not be used in advertising or
publicity pertaining to distribution of the software without specific,
written prior permission.  McGill makes no representations about the
suitability of this software for any purpose.  It is provided "as is"
without express or implied warranty.

MCGILL DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING ALL
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS.  IN NO EVENT SHALL
MCGILL BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY
DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

=cut
