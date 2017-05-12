# $Id: Def.pm 2013-09-17 erick.antezana $
#
# Module  : Def.pm
# Purpose : Definition structure.
# License : Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.
#           This program is free software; you can redistribute it and/or
#           modify it under the same terms as Perl itself.
# Contact : Erick Antezana <erick.antezana -@- gmail.com>
#
package OBO::Core::Def;

use OBO::Util::DbxrefSet;

use Carp;
use strict;
use warnings;

sub new {
	my $class           = shift;
	my $self            = {};

	$self->{TEXT}       = undef;                       # required, scalar (1)
	$self->{DBXREF_SET} = OBO::Util::DbxrefSet->new(); # required, Dbxref (0..n)

	bless ($self, $class);
	return $self;
}

=head2 text

  Usage    - print $def->text() or $def->text($text)
  Returns  - the definition text (string)
  Args     - the definition text (string)
  Function - gets/sets the definition text
  
=cut

sub text {
	if ($_[1]) { $_[0]->{TEXT} = $_[1] }
	return $_[0]->{TEXT};
}

=head2 dbxref_set

  Usage    - $def->dbxref_set() or $def->dbxref_set($dbxref_set)
  Returns  - the definition dbxref set (OBO::Util::DbxrefSet)
  Args     - the definition dbxref set (OBO::Util::DbxrefSet)
  Function - gets/sets the definition dbxref set
  
=cut

sub dbxref_set {
	$_[0]->{DBXREF_SET} = $_[1] if ($_[1]);
	return $_[0]->{DBXREF_SET};
}

=head2 dbxref_set_as_string

  Usage    - $definition->dbxref_set_as_string() or $definition->dbxref_set_as_string("[GOC:elh, PMID:9334324, UM-BBD_pathwayID:2\,4\,5-t]")
  Returns  - the dbxref set (string) of this definition; [] if the set is empty
  Args     - the dbxref set (string) describing the source(s) of this definition
  Function - gets/sets the dbxref set of this definition. The set operation actually *adds* the new dbxrefs to the existing set
  Remark   - make sure that colons (,) are scaped (\,) when necessary
  
=cut

sub dbxref_set_as_string {
	my $dbxref_as_string = $_[1];
	if ($dbxref_as_string) {
		my $xref_set = $_[0]->{DBXREF_SET};
		
		__dbxref($xref_set, $dbxref_as_string);

		$_[0]->{DBXREF_SET} = $xref_set; # We are overwriting the existing set; otherwise, add the new elements to the existing set!
	}
	my @result = (); # a Set?
	foreach my $dbxref (sort {lc($b->as_string()) cmp lc($a->as_string())} $_[0]->dbxref_set()->get_set()) {
		unshift @result, $dbxref->as_string();
	}
	return '['.join(', ', @result).']';
}

=head2 equals

  Usage    - $def->equals($another_def)
  Returns  - either 1 (true) or 0 (false)
  Args     - the definition to compare with
  Function - tells whether this definition is equal to the parameter
  
=cut

sub equals {
	my ($self, $target) = @_;
	my $result = 0;
	if ($target && eval { $target->isa('OBO::Core::Def') }) {

		if (!defined($self->{TEXT})) {
			croak 'The text of this definition is undefined.';
		}
		if (!defined($target->{TEXT})) {
			croak 'The text of the target definition is undefined.';
		}

		$result = (($self->{TEXT} eq $target->{TEXT}) && ($self->{DBXREF_SET}->equals($target->{DBXREF_SET})));
	} else {
		croak "An unrecognized object type (not a OBO::Core::Def) was found: '", $target, "'";
	}
	return $result;
}

sub __dbxref () {
	caller eq __PACKAGE__ or croak "You cannot call this (__dbxref) prived method!";
	#
	# $_[0] ==> set
	# $_[1] ==> dbxref string
	#
	my $dbxref_set       = $_[0];
	my $dbxref_as_string = $_[1];
	
	$dbxref_as_string =~ s/^\[//;
	$dbxref_as_string =~ s/\]$//;
	$dbxref_as_string =~ s/\\,/;;;;/g;  # trick to keep the comma's
	$dbxref_as_string =~ s/\\"/;;;;;/g; # trick to keep the double quote's
	
	my @lineas = $dbxref_as_string =~ /\"([^\"]*)\"/g; # get the double-quoted pieces
	foreach my $l (@lineas) {
		my $cp = $l;
		$l =~ s/,/;;;;/g; # trick to keep the comma's
		$dbxref_as_string =~ s/\Q$cp\E/$l/;
	}
	
	my @dbxrefs = split (',', $dbxref_as_string);
	
	my $r_db_acc      = qr/([ \*\.\w-]*):([ '\#~\w:\\\+\?\{\}\$\/\(\)\[\]\.=&!%_-]*)/o;
	my $r_desc        = qr/\s+\"([^\"]*)\"/o;
	my $r_mod         = qr/\s+(\{[\w ]+=[\w ]+\})/o;
	
	foreach my $entry (@dbxrefs) {
		my ($match, $db, $acc, $desc, $mod) = undef;
		my $dbxref = OBO::Core::Dbxref->new();
		if ($entry =~ m/$r_db_acc$r_desc$r_mod?/) {
			$db    = __unescape($1);
			$acc   = __unescape($2);
			$desc  = __unescape($3);
			$mod   = __unescape($4) if ($4);
		} elsif ($entry =~ m/$r_db_acc$r_desc?$r_mod?/) {
			$db    = __unescape($1);
			$acc   = __unescape($2);
			$desc  = __unescape($3) if ($3);
			$mod   = __unescape($4) if ($4);
		} else {
			croak "ERROR: Check the 'dbxref' field of '", $entry, "'.";
		}
		
		# set the dbxref:
		$dbxref->name($db.':'.$acc);
		$dbxref->description($desc) if (defined $desc);
		$dbxref->modifier($mod) if (defined $mod);
		$dbxref_set->add($dbxref);
	}
}

sub __unescape {
	caller eq __PACKAGE__ or die;
	my $match = $_[0];
	$match =~ s/;;;;;/\\"/g;
	$match =~ s/;;;;/\\,/g;
	return $match;
}

1;

__END__

=head1 NAME

OBO::Core::Def  - A definition structure of a term. A term should 
have zero or one instance of this type per term description.
    
=head1 SYNOPSIS

use OBO::Core::Def;

use OBO::Core::Dbxref;

use strict;

# three new def's

my $def1 = OBO::Core::Def->new();

my $def2 = OBO::Core::Def->new();

my $def3 = OBO::Core::Def->new();


$def1->text("APO:vm text");

$def2->text("APO:ls text");

$def3->text("APO:ea text");


my $ref1 = OBO::Core::Dbxref->new();

my $ref2 = OBO::Core::Dbxref->new();

my $ref3 = OBO::Core::Dbxref->new();


$ref1->name("APO:vm");

$ref2->name("APO:ls");

$ref3->name("APO:ea");


my $dbxref_set1 = OBO::Util::DbxrefSet->new();

$dbxref_set1->add($ref1);


my $dbxref_set2 = OBO::Util::DbxrefSet->new();

$dbxref_set2->add($ref2);


my $dbxref_set3 = OBO::Util::DbxrefSet->new();

$dbxref_set3->add($ref3);

$def1->dbxref_set($dbxref_set1);

$def2->dbxref_set($dbxref_set2);

$def3->dbxref_set($dbxref_set3);


# dbxref_set_as_string

$def2->dbxref_set_as_string('[APO:vm, APO:ls, APO:ea "Erick Antezana"] {opt=first}');

my @refs_def2 = $def2->dbxref_set()->get_set();

my %r_def2;

foreach my $ref_def2 (@refs_def2) {
	
	$r_def2{$ref_def2->name()} = $ref_def2->name();
	
}


=head1 DESCRIPTION

A OBO::Core::Def object encapsules a definition for a universal. There must be 
zero or one instance of this type per term description. An object of this type
should have a quote enclosed definition text, and a OBO::Core::Dbxref set 
containing data base cross references which describe the origin of this 
definition (see OBO::Core::Dbxref for information on how Dbxref lists are used).

c.f. OBO flat file specification.

=head1 AUTHOR

Erick Antezana, E<lt>erick.antezana -@- gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut
