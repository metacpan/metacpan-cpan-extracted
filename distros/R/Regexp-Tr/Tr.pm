package Regexp::Tr;

### IMPORTS
# Boilerplate package beginning
use 5.008;
use strict;
use warnings;
use Carp;

### PACKAGE VARIABLES

# UNIVERSAL package variables
our $VERSION = "0.05";

# The following hash contains caller package names
# as keys and arrayrefs as values.  These arrayrefs
# begin with the parameters passed, and end with the
# object (therefore, $last{pkg}[-1] is the last object
# created for the namespace "pkg".
my %last;

# This is a scratch opening in the symbol table and 
# IS NOT GUARANTEED TO BE ANYTHING AT ALL. 
our @_called;

# This method creates a new instance of the object
sub new {
    # Get parameters and suppress warnings
    my($class,$from,$to,$mods) = @_;
    $from = "" unless(defined($from));
    $to   = "" unless(defined($to));
    $mods = "" unless(defined($mods));

    # Name (or make) the anonymous array in the
    # %last hash for the caller's package.
    # (The typeglob assignment saves a hash 
    # access each time @_called is...well, called.)
    *_called = ($last{caller()} ||= []);

    # Work the efficiency for loops
    unless(scalar(@_called) and 
	   ($from eq $_called[0]) and
	   ($to   eq $_called[1]) and
	   ($mods eq $_called[2]) ) 
    {
	my $subref = eval '
	sub(\$) {
	    my $ref = shift;
	    return ${$ref} =~ tr/'.$from.'/'.$to.'/'.$mods.';
	};';
	carp 'Bad tr///:'.$@ if $@;
	@_called = ($from,$to,$mods,bless($subref,$class));
    }
    return $_called[-1];
}

# Performs the actual tr/// operation set up by the object.
sub bind {
    my $self = shift;

    # Verify reference passed
    (my $ref = shift) 
	or carp "No reference passed";
    my $reftype = ref($ref);
    if(!$reftype) {
	carp "Parameter is not a reference.\n"
	    ."You might have forgotten to backslash the scalar";
    } elsif($reftype ne "SCALAR") {
	carp "Parameter not a scalar reference";
    }

    # Perform the operation
    return &{$self}($ref);
}

# Performs the tr/// operation on a scalar passed to the object.
sub trans {
    my($self,$val) = @_;
    my $cnt = $self->bind(\$val);
    return wantarray ? ($val, $cnt) : $val;
}

# Flushes the efficiency storage
sub flush {
    %last = ();
    @_called = ();
    return;
}

return 1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Regexp::Tr - Run-time-compiled tr/// objects.

=head1 SYNOPSIS

  use Regexp::Tr;
  my $trier = Regexp::Tr->new("a-z","z-a");
  my $swapped = "foobar";
  $trier->bind(\$swapped);               # $swapped is now "ullyzi"
  my $tred = $trier->trans("barfoo");    # $tred is "yziull"
  Regexp::Tr->flush();                   # Cache is gone!

=head1 ABSTRACT

Solves the problem requiring compile-time knowledge of tr/// 
constructs by generating the tr/// at run-time and storing it as an 
object.

=head1 DESCRIPTION

One very useful ability of Perl is to do relatively cheap 
transliteration via the tr/// regex operator.  Unfortunately, Perl 
requires tr/// to be known at compile-time.  The common solution has 
been to put an eval around any dynamic tr/// operations, but that is 
very expensive to be used often (for instance, within a loop).  This 
module solves that problem by compiling the tr/// a single time and 
allowing the user to use it repeatedly and delete it when it it no 
longer useful.  

=head2 User Efficiency Notes

The last instance created is stored for efficient recreation.  This is 
useful for repeated iterations over the same code (for instance, 
within a loop).  The last instance created is stored seperately for 
every package which uses this module, so multiple packages relying on 
this ability can still gain the speed benefit.

This cache may be emptied may be regained at any time by calling the 
class method CLASS->flush().  All objects will continue to function, 
but the internal cache will be emptied.  This is probably not worth it
unless there are many different namespaces using this package or the
program is very memory-sensitive.

=head1 METHODS

=head2 CLASS->new(FROMSTRING,TOSTRING,[MODIFIERS])

This creates a new instance of this object.  FROMSTRING is the 
precursor string for the tr/// (eg: "a-z"), TOSTRING is the succsessor 
string for the tr/// (eg: "bac-z"), and the optional MODIFIERS is a 
string containing any modifiers to the tr/// (eg: "e", etc.).

=head2 $obj->bind(SCALARREF)

This binds the given SCALARREF and then performs the object's tr/// 
operation, returning what the tr/// operation will return.  Note that
this method does not create the reference, so the user is responsible 
for backslashing the variable.

=head2 $obj->trans(SCALAR)

This takes a scalar, performs the tr/// operation, and returns the 
tr///ed string in scalar context, or a list consisting of the tr///ed 
string and the tr/// return value in list context.

=head2 CLASS->flush()

Flushes the efficiency cache, potentially gaining some memory back 
but forcing the next object to be created entirely from scratch.
Returns void.

=head1 SEE ALSO

=over

=item L<perlop>

Provides a definition of the tr/// operator.

=item L<perlre>

Provides more information on the operator.

=back
    
=head1 AUTHOR

Robert Fischer, E<lt>chia@cpan.orgE<gt>
Hamline University, class of 2004.

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Robert Fischer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
