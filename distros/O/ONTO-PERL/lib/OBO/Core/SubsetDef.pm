# $Id: SubsetDef.pm 2011-06-06 erick.antezana $
#
# Module  : SubsetDef.pm
# Purpose : A subset definition.
# License : Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.
#           This program is free software; you can redistribute it and/or
#           modify it under the same terms as Perl itself.
# Contact : Erick Antezana <erick.antezana -@- gmail.com>
#
package OBO::Core::SubsetDef;

use Carp;
use strict;
use warnings;

sub new {
	my $class             = shift;
	my $self              = {};

	$self->{NAME}         = undef; # required
	$self->{DESCRIPTION}  = undef; # required

	bless ($self, $class);
	return $self;
}
=head2 name

  Usage    - print $subset_def->name() or $subset_def->name($name)
  Returns  - the subset def name (string)
  Args     - the subset def name (string)
  Function - gets/sets the subset def name
  
=cut

sub name {
	$_[0]->{NAME} = $_[1] if ($_[1]);
	return $_[0]->{NAME};
}

=head2 description

  Usage    - print $subset_def->description() or $subset_def->description($desc)
  Returns  - the subset def description (string)
  Args     - the subset def description (string)
  Function - gets/sets the synonym description
  
=cut

sub description {
	$_[0]->{DESCRIPTION} = $_[1] if ($_[1]);
	return $_[0]->{DESCRIPTION};
}

=head2 as_string

  Usage    - $subset_def->as_string() or $subset_def->as_string("GO_SLIM", "GO Slim")
  Returns  - the subset def definition (string)
  Args     - the subset def definition (string)
  Function - gets/sets the definition of this synonym
  
=cut

sub as_string {
	if ($_[1] && $_[2]){
		$_[0]->{NAME}        = $_[1];
		$_[0]->{DESCRIPTION} = $_[2];
	}
	return $_[0]->{NAME}.' "'.$_[0]->{DESCRIPTION}.'"';
}

=head2 equals

  Usage    - print $subset_def->equals($another_subset_def)
  Returns  - either 1 (true) or 0 (false)
  Args     - the subset def definition to compare with
  Function - tells whether this subset def definition is equal to the given argument (another subset def definition)
  
=cut

sub equals {
	my $result = 0;
	if ($_[1] && eval { $_[1]->isa('OBO::Core::SubsetDef') }) {
			
		croak 'The name of this subset definition is undefined.' if (!defined($_[0]->{NAME}));
		croak 'The name of the target subset definition is undefined.' if (!defined($_[1]->{NAME}));
		
		croak 'The description of the this subset definition is undefined.' if (!defined($_[0]->{DESCRIPTION}));
		croak 'The description of the target subset definition is undefined.' if (!defined($_[1]->{DESCRIPTION}));
		
		$result = ($_[0]->{NAME} eq $_[1]->{NAME}) && ($_[0]->{DESCRIPTION} eq $_[1]->{DESCRIPTION});
	} else {
		croak "An unrecognized object type (not a OBO::Core::SubsetDef) was found: '", $_[1], "'";
	}
	return $result;
}

1;

__END__

=head1 NAME

OBO::Core::SubsetDef  - A description of a term subset. The value for 
this tag should contain a subset name and a subset description.
    
=head1 SYNOPSIS

use OBO::Core::SubsetDef;

use strict;


my $std1 = OBO::Core::SubsetDef->new();

my $std2 = OBO::Core::SubsetDef->new();


# name

$std1->name('GO_SLIM');

$std2->name('APO_SLIM');


# description

$std1->description('GO slim');

$std2->description('APO slim');

# subset def as string

my $std3 = OBO::Core::SubsetDef->new();

$std3->as_string('GO_SLIM', 'GO Slim');

if ($std1->equals($std3)) {
	
	print "subset 1 is the same as subset 3\n";
	
}


=head1 DESCRIPTION

A description of a term subset. The value for this tag should contain 
a subset name, a space, and a quote enclosed subset description, as follows:

	subsetdef: GO_SLIM "GO Slim"

=head1 AUTHOR

Erick Antezana, E<lt>erick.antezana -@- gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut