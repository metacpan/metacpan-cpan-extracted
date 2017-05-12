package Plucene::Index::Term;

=head1 NAME 

Plucene::Index::Term - a word from text

=head1 SYNOPSIS

	my $term = Plucene::Index::Term->new({
			field => $field_name,
			text  => $text,
	});

	# with two Plucene::Index::Term objects you can do:
	
	if ($term1->eq($term2)) { ... }

	# etc
	
=head1 DESCRIPTION

A Term represents a word from text, and is the unit of search.  It is 
composed of two elements, the text of the word, as a string, and the 
name of the field that the text occured in, as a string.

Note that terms may represent more than words from text fields, but 
also things like dates, email addresses, urls, etc.

=head1 METHODS

=cut

use strict;
use warnings;
no warnings 'uninitialized';

use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw(field text));

=head2 eq / ne / lt / gt / ge / le

Exactly what you would think they are.

=cut

sub _cmp {
	($_[0]->{field} cmp $_[1]->{field}) || ($_[0]->{text} cmp $_[1]->{text});
}

sub eq {
	$_[0]->{field} eq $_[1]->{field} && $_[0]->{text} eq $_[1]->{text};
}

sub ne {
	$_[0]->{field} ne $_[1]->{field} || $_[0]->{text} ne $_[1]->{text};
}

sub lt {
	($_[0]->{field} cmp $_[1]->{field} || $_[0]->{text} cmp $_[1]->{text}) < 0;
}

sub gt {
	($_[0]->{field} cmp $_[1]->{field} || $_[0]->{text} cmp $_[1]->{text}) > 0;
}

sub ge {
	($_[0]->{field} cmp $_[1]->{field} || $_[0]->{text} cmp $_[1]->{text}) >= 0;
}

sub le {
	($_[0]->{field} cmp $_[1]->{field} || $_[0]->{text} cmp $_[1]->{text}) <= 0;
}

1;
