package Template::Plugin::Cycle;

=pod

=head1 NAME

Template::Plugin::Cycle - Cyclically insert into a Template from a sequence of values

=head1 SYNOPSIS

  [% USE cycle('row', 'altrow') %]
  
  <table border="1">
    <tr class="[% class %]">
      <td>First row</td>
    </tr>
    <tr class="[% class %]">
      <td>Second row</td>
    </tr>
    <tr class="[% class %]">
      <td>Third row</td>
    </tr>
  </table>
  
  
  
  
  
  ###################################################################
  # Alternatively, you might want to make it available to all templates
  # throughout an entire application.
  
  use Template::Plugin::Cycle;
  
  # Create a Cycle object and set some values
  my $Cycle = Template::Plugin::Cycle->new;
  $Cycle->init('normalrow', 'alternaterow');
  
  # Bind the Cycle object into the Template
  $Template->process( 'tablepage.html', class => $Cycle );
  
  
  
  
  
  #######################################################
  # Later that night in a Template
  
  <table border="1">
    <tr class="[% class %]">
      <td>First row</td>
    </tr>
    <tr class="[% class %]">
      <td>Second row</td>
    </tr>
    <tr class="[% class %]">
      <td>Third row</td>
    </tr>
  </table>
  
  [% class.reset %]
  <table border="1">
    <tr class="[% class %]">
      <td>Another first row</td>
    </tr>
  </table>
  
  
  
  
  
  #######################################################
  # Which of course produces
  
  <table border="1">
    <tr class="normalrow">
      <td>First row</td>
    </tr>
    <tr class="alternaterow">
      <td>Second row</td>
    </tr>
    <tr class="normalrow">
      <td>Third row</td>
    </tr>
  </table>
  
  <table border="1">
    <tr class="normalrow">
      <td>Another first row</td>
    </tr>
  </table>

=head1 DESCRIPTION

Sometimes, apparently almost exclusively when doing alternating table row
backgrounds, you need to print an alternating, cycling, set of values
into a template.

Template::Plugin::Cycle is a small, simple, and hopefully DWIM solution to
these sorts of tasks.

It can be used either as a normal Template::Plugin, or can be created
directly and passed in as a template argument, so that you can set up
situations where it is implicitly available in every page.

=head1 METHODS

=cut

use 5.005;
use strict;
use Params::Util     '_INSTANCE';
use Template::Plugin ();
use overload         'bool' => sub () { 1 },
                     '""'   => 'next';

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.06';
	@ISA     = 'Template::Plugin';
}





#####################################################################
# Constructor

=pod

=head2 new [ $Context ] [, @list ]

The C<new> constructor creates and returns a new C<Template::Plugin::Cycle>
object. It can be optionally passed an initial set of values to cycle
through.

When called from within a Template, the new constructor will be passed the
current L<Template::Context> as the first argument. This will be ignored.

By doing this, you can use it both directly, AND from inside a Template.

=cut

sub new {
	my $self = bless [ 0, () ], shift;

	# Ignore any Template::Context param
	shift if _INSTANCE($_[0], 'Template::Context');

	$self->init( @_ ) if @_;

	$self;
}

=pod

=head2 init @list

If you need to set the values for a new empty object, of change the values
to cycle through for an existing object, they can be passed to the C<init>
method.

The method always returns the C<''> null string, to avoid inserting
anything into the template.

=cut

sub init {
	my $self = ref $_[0] ? shift : return undef;
	@$self = ( 0, @_ );
	'';
}





#####################################################################
# Main Methods

=pod

=head2 elements

The C<elements> method returns the number of items currently set for the
C<Template::Plugin::Cycle> object.

=cut

sub elements {
	my $self = ref $_[0] ? shift : return undef;
	$#$self;
}

=pod

=head2 list

The C<list> method returns the current list of values for the
C<Template::Plugin::Cycle> object.

This is also the prefered method for getting access to a value at a
particular position within the list of items being cycled to.

  [%# Access a variety of things from the list %]
  The first item in the Cycle object is [% cycle.list.first %].
  The second item in the Cycle object is [% cycle.list.[1] %].
  The last item in the Cycle object is [% cycle.list.last %].

=cut

sub list {
	my $self = ref $_[0] ? shift : return undef;
	$self->elements ? @$self[ 1 .. $#$self ] : ();
}

=pod

=head2 next

The C<next> method returns the next value from the Cycle. If the end of
the list of valuese is reached, it will "cycle" back the first object again.

This method is also the one called when the object is stringified. That is,
when it appears on its own in a template. Thus, you can do something like
the following.

  <!-- An example of alternate row classes in a table-->
  <table border="1">
    <!-- Explicitly access the next class in the cycle -->
    <tr class="[% rowclass.next %]">
      <td>First row</td>
    </tr>
    <!-- This has the same effect -->
    <tr class="[% rowclass %]">
      <td>Second row</td>
    </tr>
  </table>

=cut

sub next {
	my $self = ref $_[0] ? shift : return undef;
	return '' unless $#$self;
	$self->[0] = 1 if ++$self->[0] > $#$self;
	$self->[$self->[0]];
}

=pod

=head2 value

The C<value> method is an analogy for the C<next> method.

=cut

sub value { shift->next(@_) }

=pod

=head2 reset

If a single C<Template::Plugin::Cycle> object is to be used it multiple
places within a template, and it is important that the same value be first
every time, then the C<reset> method can be used.

The C<reset> method resets the Cycle, so that the next value returned will
be the first value in the Cycle object.

=cut

sub reset {
	my $self = ref $_[0] ? shift : return undef;
	$self->[0] = 0;
	'';
}

1;

=pod

=head1 SUPPORT

Bugs should be submitted via the CPAN bug tracker, located at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Plugin-Cycle>

For other issues, or commercial enhancement or support, contact the author..

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

Thank you to Phase N Australia (L<http://phase-n.com/>) for permitting
the open sourcing and release of this distribution as a spin-off from a
commercial project.

=head1 COPYRIGHT

Copyright 2004 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
