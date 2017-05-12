package Template::Plugin::Group;

=pod

=head1 NAME

Template::Plugin::Group - Template plugin to group lists into simple subgroups

=head1 SYNOPSIS

  # In your Template
  [% USE rows = Group(cells, 3) %]
  
  <table>
  [% FOREACH row IN rows %]
    <tr>
    [% FOREACH cell IN rows %]
      <td class="[% cell.class %]">[% cell.content %]</td>
    [% END %]
    </tr>  
  [% END %]
  <table>

=head1 DESCRIPTION

C<Template::Plugin::Group> is a fairly simple (for now) module for
grouping a list of things into a number of subgroups.

In this intial implementation you can only group C<ARRAY> references,
and they can only be grouped into groups of a numbered size.

In practical terms, you can make columns of things and you can break up a
list into smaller chunks (for example to chop a large lists into a number
of smaller lists for display purposes)

=head1 METHODS

=cut

use 5.005;
use strict;
use Template::Plugin ();
use Params::Util     qw{ _ARRAY _HASH _INSTANCE };

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.03';
	@ISA     = 'Template::Plugin';
}





#####################################################################
# Constructor

=pod

=head2 new [ $Context, ] \@ARRAY, $cols [, 'pad' ]

Although this is the "new" method, it doesn't really actually create any
objects. It simply takes an array reference, splits up the list into
groups, and returns the whole things as another array reference.

The rest you do normally, with normal Template Toolkit commands.

If there isn't a perfectly divisible number of elements normally the last group
will have less elements than the rest of the groups. If you provide the optional
parameter 'pad', the last group will be padded with additional C<undef> values
so that it has the full number.
 
=cut

sub new {
	my $class = shift;
	shift if _INSTANCE($_[0], 'Template::Context');
	unless ( defined $_[1] and $_[1] =~ /^[1-9]\d*$/ ) {
		$class->error('Group constructor argument not a positive integer');
	}
	return $class->_new_array(@_) if _ARRAY($_[0]);
	return $class->_new_hash(@_)  if _HASH($_[0]);
	$class->error('Group constructor argument not an ARRAY or HASH ref');
}

sub _new_array {
	# Make sure to copy the original array in case they care about it
	my ($class, $array_ref, $cols) = @_;
	my @array = @$array_ref;

	# Support the padding option
	if ( grep { defined $_ and lc $_ eq 'pad' } @_ ) {
		my $items = scalar(@array) % $cols;
		push @array, (undef) x $items;
	}

	# Create the outside array and pack it
	my @groups = ();
	while ( @array ) {
		push @groups, [ splice @array, 0, $cols ];
	}

	\@groups;
}

sub _new_hash {
	my ($class, $hash, $cols) = @_;
	$class->error('HASH grouping is not implented in this release');

	# Implementation steps.
	# 1. Get the list of keys, sorted in default order
	# 2. Take groups of these and build new hashs for only those
	#    keys, with the same values as the original.
	# 3. Wrap them all inside an ARRAY ref and return.

	# I'm not sure we can do padding in this case...
}

1;

=pod

=head1 TO DO

- Support grouping HASH references

- If everything in the list is an object, support group/sort by method

- Support complex multi-level grouping (I have code for this already, but
it needs to be rewritten and should probably be a separate plugin).

=head1 SUPPORT

Bugs should be submitted via the CPAN bug tracker, located at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Plugin-Group>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>cpan@ali.asE<gt>

=head1 COPYRIGHT

Copyright 2004 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
