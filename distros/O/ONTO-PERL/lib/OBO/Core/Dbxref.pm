# $Id: Dbxref.pm 2014-03-29 erick.antezana $
#
# Module  : Dbxref.pm
# Purpose : Reference structure.
# License : Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.
#           This program is free software; you can redistribute it and/or
#           modify it under the same terms as Perl itself.
# Contact : Erick Antezana <erick.antezana -@- gmail.com>
#
package OBO::Core::Dbxref;

use Carp;
use strict;
use warnings;

sub new {
	my $class            = shift;
	my $self             = {};

	$self->{DB}          = ''; # required, scalar (1)
	$self->{ACC}         = ''; # required, scalar (1)
	$self->{DESCRIPTION} = ''; # scalar (0..1)
	$self->{MODIFIER}    = ''; # scalar (0..1)
    
	bless ($self, $class);
	return $self;
}

=head2 name

  Usage    - print $dbxref->name() or $dbxref->name($name)
  Returns  - the dbxref name (string)
  Args     - the dbxref name (string) that follows this convention DB:ACC (ACC may be an empty string like some dbxrefs from the ChEBI ontology)
  Function - gets/sets the dbxref name
  
=cut

sub name {
	if ($_[1]) {
		if ($_[1] =~ /([\*\.\w-]*):([ ,;'\#~\w:\\\+\?\{\}\$\/\(\)\[\]\.=&!%_-]*)/ || # See $r_db_acc in Term.pm
			$_[1] =~ /(http):\/\/(.*)/) {
			$_[0]->{DB}  = $1;
			$_[0]->{ACC} = $2;
		}
	} elsif (!defined($_[0]->{DB}) || !defined($_[0]->{ACC})) {
		croak 'The name of this dbxref is not defined.';
	} else {  # get-mode
		return $_[0]->{DB}.':'.$_[0]->{ACC};
	}
}

# Alias
*id = \&name;

=head2 db

  Usage    - print $dbxref->db() or $dbxref->db($db)
  Returns  - the dbxref db (string)
  Args     - the dbxref db (string)
  Function - gets/sets the dbxref db
  
=cut

sub db {
	if ($_[1]) {
		$_[0]->{DB} = $_[1];
	} elsif (!defined($_[0]->{DB})) {
		croak "The database (db) of this 'dbxref' is not defined.";
	} else { # get-mode
		return $_[0]->{DB};
	}
}

=head2 acc

  Usage    - print $dbxref->acc() or $dbxref->acc($acc)
  Returns  - the dbxref acc (string)
  Args     - the dbxref acc (string)
  Function - gets/sets the dbxref acc
  
=cut

sub acc {
	if ($_[1]) {
		$_[0]->{ACC} = $_[1];
	} elsif (!defined($_[0]->{ACC})) {
		croak 'The accession number (acc) of this dbxref is not defined.';
	} else { # get-mode
		return $_[0]->{ACC};
	}
}

=head2 description

  Usage    - print $dbxref->description() or $dbxref->description($description)
  Returns  - the dbxref description (string)
  Args     - the dbxref description (string)
  Function - gets/sets the dbxref description
  
=cut

sub description {
	if ($_[1]) { 
		$_[0]->{DESCRIPTION} = $_[1];
	} elsif (!defined($_[0]->{DB}) || !defined($_[0]->{ACC})) {
		croak 'The name of this dbxref is not defined.';
	} else { # get-mode
		return $_[0]->{DESCRIPTION};
	}
}

=head2 modifier

  Usage    - print $dbxref->modifier() or $dbxref->modifier($modifier)
  Returns  - the optional trailing modifier (string)
  Args     - the optional trailing modifier (string)
  Function - gets/sets the optional trailing modifier
  
=cut

sub modifier {
	if ($_[1]) { 
		$_[0]->{MODIFIER} = $_[1];
	} elsif (!defined($_[0]->{DB}) || !defined($_[0]->{ACC})) {
		croak 'The name of this dbxref is not defined.';
	} else { # get-mode
		return $_[0]->{MODIFIER};
	}
}

=head2 as_string

  Usage    - print $dbxref->as_string()
  Returns  - returns this dbxref ([name "description" {modifier}]) as string
  Args     - none
  Function - returns this dbxref as string
  
=cut

sub as_string {
	croak 'The name of this dbxref is not defined.' if (!defined($_[0]->{DB}) || !defined($_[0]->{ACC}));
	my $result = $_[0]->{DB}.':'.$_[0]->{ACC};
	$result   .= ' "'.$_[0]->{DESCRIPTION}.'"' if (defined $_[0]->{DESCRIPTION} && $_[0]->{DESCRIPTION} ne '');
	$result   .= ' '.$_[0]->{MODIFIER} if (defined $_[0]->{MODIFIER} && $_[0]->{MODIFIER} ne '');
	return $result;
}

=head2 equals

  Usage    - print $dbxref->equals($another_dbxref)
  Returns  - either 1(true) or 0 (false)
  Args     - the dbxref(OBO::Core::Dbxref) to compare with
  Function - tells whether this dbxref is equal to the parameter
  
=cut

sub equals {
	if ($_[1] && eval { $_[1]->isa('OBO::Core::Dbxref') }) {
		
		if (!defined($_[0]->{DB}) || !defined($_[0]->{ACC})) {
			croak 'The name of this dbxref is undefined.';
		} 
		if (!defined($_[1]->{DB}) || !defined($_[1]->{ACC})) {
			croak 'The name of the target dbxref is undefined.';
		}
		return (($_[0]->{DB}          eq $_[1]->{DB})          &&
				($_[0]->{ACC}         eq $_[1]->{ACC})         &&
				($_[0]->{DESCRIPTION} eq $_[1]->{DESCRIPTION}) &&
				($_[0]->{MODIFIER}    eq $_[1]->{MODIFIER}));
	} else {
		croak "An unrecognized object type (not a OBO::Core::Dbxref) was found: '", $_[1], "'";
	}
	return 0;
}

1;

__END__

=head1 NAME

OBO::Core::Dbxref -  A database reference structure.
    
=head1 SYNOPSIS

use OBO::Core::Dbxref;

use strict;

# three new dbxref's

my $ref1 = OBO::Core::Dbxref->new;

my $ref2 = OBO::Core::Dbxref->new;

my $ref3 = OBO::Core::Dbxref->new;


$ref1->name("APO:vm");

$ref1->description("this is a description");

$ref1->modifier("{opt=123}");

$ref2->name("APO:ls");

$ref3->name("APO:ea");


my $ref4 = $ref3;

my $ref5 = OBO::Core::Dbxref->new;

$ref5->name("APO:vm");

$ref5->description("this is a description");

$ref5->modifier("{opt=123}");


=head1 DESCRIPTION

A dbxref object encapsules a reference for a universal.

=head1 AUTHOR

Erick Antezana, E<lt>erick.antezana -@- gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut