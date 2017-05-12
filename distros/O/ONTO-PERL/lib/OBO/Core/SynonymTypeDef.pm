# $Id: SynonymTypeDef.pm 2011-06-06 erick.antezana $
#
# Module  : SynonymTypeDef.pm
# Purpose : A synonym type definition.
# License : Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.
#           This program is free software; you can redistribute it and/or
#           modify it under the same terms as Perl itself.
# Contact : Erick Antezana <erick.antezana -@- gmail.com>
#
package OBO::Core::SynonymTypeDef;

use Carp;
use strict;
use warnings;

sub new {
	my $class            = shift;
	my $self             = {};

	$self->{NAME}        = undef; # required
	$self->{DESCRIPTION} = undef; # required
	$self->{SCOPE}       = undef; # optional: The scope specifier indicates the default scope for any synonym that has this type.

	bless ($self, $class);
	return $self;
}
=head2 name

  Usage    - print $synonym_type_def->name() or $synonym_type_def->name($name)
  Returns  - the synonym type name (string)
  Args     - the synonym type name (string)
  Function - gets/sets the synonym type name
  
=cut

sub name {
	$_[0]->{NAME} = $_[1] if ($_[1]);
	return $_[0]->{NAME};
}

=head2 description

  Usage    - print $synonym_type_def->description() or $synonym_type_def->description($desc)
  Returns  - the synonym description (string)
  Args     - the synonym description (string)
  Function - gets/sets the synonym description
  
=cut

sub description {
	$_[0]->{DESCRIPTION} = $_[1] if ($_[1]);
	return $_[0]->{DESCRIPTION};
}

=head2 scope

  Usage    - print $synonym_type_def->scope() or $synonym_type_def->scope($scope)
  Returns  - the scope of this synonym type definition (string)
  Args     - the scope of this synonym type definition (string)
  Function - gets/sets the scope of this synonym type definition
  
=cut

sub scope {
	$_[0]->{SCOPE} = $_[1] if ($_[1]);
	return $_[0]->{SCOPE};
}

=head2 as_string

  Usage    - $synonym_type_def->as_string() or $synonym_type_def->as_string("UK_SPELLING", "British spelling", "EXACT")
  Returns  - the synonym type definition (string)
  Args     - the synonym type definition (string)
  Function - gets/sets the definition of this synonym
  
=cut

sub as_string {
	if ($_[1] && $_[2]){
		$_[0]->{NAME}        = $_[1];
		$_[0]->{DESCRIPTION} = $_[2];
		$_[0]->{SCOPE}       = $_[3] if ($_[3]);
	}
	my $result = $_[0]->{NAME}." \"".$_[0]->{DESCRIPTION}."\"";
	my $scope  = $_[0]->{SCOPE};
	$result   .= (defined $scope)?" ".$scope:"";
}

=head2 equals

  Usage    - print $synonym_type_def->equals($another_synonym_type_def)
  Returns  - either 1 (true) or 0 (false)
  Args     - the synonym type definition (OBO::Core::SynonymTypeDef) to compare with
  Function - tells whether this synonym type definition is equal to the given argument (another synonym type definition)
  
=cut

sub equals {
	my $result = 0;
	if ($_[1] && eval { $_[1]->isa('OBO::Core::SynonymTypeDef') }) {

		croak 'The name of this synonym type definition is undefined.' if (!defined($_[0]->{NAME}));
		croak 'The name of the target synonym type definition is undefined.' if (!defined($_[1]->{NAME}));
		
		croak "The description of the this ($_[0]->{NAME}) synonym type definition is undefined." if (!defined($_[0]->{DESCRIPTION}));
		croak "The description of the target ($_[1]->{NAME}) synonym type definition is undefined." if (!defined($_[1]->{DESCRIPTION}));
		
		$result = ($_[0]->{NAME} eq $_[1]->{NAME}) && ($_[0]->{DESCRIPTION} eq $_[1]->{DESCRIPTION});
		$result = $result && ($_[0]->{SCOPE} eq $_[1]->{SCOPE}) if (defined $_[0]->{SCOPE} && defined $_[1]->{SCOPE}); # TODO Future improvement, consider case: scope_1 undefined and scope_2 defined!
	} else {
		croak "An unrecognized object type (not a OBO::Core::SynonymTypeDef) was found: '", $_[1], "'";
	}
	return $result;
}

1;

__END__

=head1 NAME

OBO::Core::SynonymTypeDef  - A synonym type definition. It should contain a synonym 
type name, a space, a quote enclosed description, and an optional scope specifier.
    
=head1 SYNOPSIS

use OBO::Core::SynonymTypeDef;

use strict;


my $std1 = OBO::Core::SynonymTypeDef->new();

my $std2 = OBO::Core::SynonymTypeDef->new();


# name

$std1->name("goslim_plant");

$std2->name("goslim_yeast");


# description

$std1->description("Plant GO slim");

$std2->description("Yeast GO slim");


# scope

$std1->scope("EXACT");

$std2->scope("BROAD");


# synonym type def as string

my $std3 = OBO::Core::SynonymTypeDef->new();

$std3->as_string("goslim_plant", "Plant GO slim", "EXACT");

if ($std1->equals($std3)) {
	
	print "std1 is the same as std3\n";
	
}


=head1 DESCRIPTION

A synonym type definition provides a description of a user-defined synonym 
type. This object holds: a synonym type name, a description, and an 
optional scope specifier (c.f. OBO flat file specification). The scope 
specifier indicates the default scope for any synonym that has this type.

=head1 AUTHOR

Erick Antezana, E<lt>erick.antezana -@- gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut