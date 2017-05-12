# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
#
# This file is part of Set-DynamicGroups
#
# This software is copyright (c) 2010 by Randy Stauner.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package Set::DynamicGroups;
BEGIN {
  $Set::DynamicGroups::VERSION = '0.014';
}
BEGIN {
  $Set::DynamicGroups::AUTHORITY = 'cpan:RWSTAUNER';
}
# ABSTRACT: Manage groups of items dynamically

use Carp qw(croak);

our %Aliases = (
  in      => 'include_groups',
  items   => 'include',
  members => 'include',
  'not'   => 'exclude',
  not_in  => 'exclude_groups',
);


sub new {
  my ($class) = @_;
  my $self = {
    groups => {},
  };
  bless $self, $class;
}


sub add {
  my ($self) = shift;
  my %groups = ref $_[0] ? %{$_[0]} : @_;
  while( my ($name, $spec) = each %groups ){
    $spec = $self->normalize($spec);
    my $group = ($self->{groups}->{$name} ||= {});
    # could use Hash::Merge, but this is a simple case:
    while( my ($key, $val) = each %$spec ){
      $self->_push_unique(($group->{$key} ||= []), {}, @$val);
    }
  }
  return $self;
}


sub add_items {
  my ($self, @append) = @_;

  my $items = ($self->{items} ||= []);
  $self->_push_unique($items, {}, map { ref $_ ? @$_ : $_ } @append);
  return scalar @$items;
}
*add_members    = \&add_items;

# NOTE: See L</DEPENDENCY RESOLUTION> for comments

sub _determine_items {
  # $name is required (rathan than ref) to push name onto anti-recursion stack
  my ($self, $name, $current) = @_;
  $current ||= {};

  # avoid infinite recursion...
  # 'each' strategy:
  return []
    if exists $current->{$name};
  $current->{$name} = 1;

  # If the group doesn't exist just return an empty arrayref
  # rather than autovivifying and filling with the wrong items, etc.
  return []
    unless my $group = $self->{groups}{$name};

  my @exclude = $self->_flatten_items($group, 'exclude', $current);

  # If no includes (only excludes) are specified,
  # populate the list with all known items.
  # Use _push_unique to maintain order (and uniqueness).
  my @include;
  $self->_push_unique(\@include, +{ map { $_ => 1 } @exclude },
    (exists $group->{include} || exists $group->{include_groups})
    ? $self->_flatten_items($group, 'include', $current)
    : $self->items
  );

  return \@include;
}

sub _flatten_items {
  # $group can currently be ref (rather than name)
  my ($self, $group, $which, $current) = @_;
  my @items = @{ $group->{ $which } || [] };
  if( my $items = $group->{ "${which}_groups" } ){
    my @flat = map { @{ $self->_determine_items($_, $current) } } @$items;
    push(@items, @flat);
  }
  return @items;
}


sub group {
  my ($self) = shift;
  croak("group() requires a single argument.  Perhaps you want groups().")
    if @_ != 1;
  my ($name) = @_;

  croak("Group $name is not defined")
    unless exists $self->{groups}{$name};

  # get the value rather than a whole hash
  my $items = $self->groups($name)->{$name};
  # return a list (not an arrayref)
  return @$items;
}


sub groups {
  my ($self, @names) = @_;
  my %groups;
  my %group_specs = %{$self->{groups}};

  # if names provided, limit to those (and flatten), otherwise do all
  @names = @names
    ? map { ref $_ ? @$_ : $_ } @names
    : keys %group_specs;

  foreach my $name ( @names ){
    # the 'each' dependency resolution "strategy"
    $groups{$name} = $self->_determine_items($name);
  }

  return \%groups;
}


sub items {
  my ($self) = @_;
  # TODO: make it an option which things are included in this list?
  my @items = @{ $self->{items} || [] };
  # concatenate all items included in groups
  $self->_push_unique(\@items, {},
    map { @{ $_->{include} || [] } }
      values %{ $self->{groups} });
  return @items;
}
*members = \&items;


sub normalize {
  my ($self, $spec) = @_;

  # if not a hashref, assume it's an (arrayref of) item(s)
  $spec = {include => $spec}
    unless ref $spec eq 'HASH';

  # TODO: croak if any unrecognized keys are present

  while( my ($alias, $name) = each %Aliases ){
    if( exists($spec->{$alias}) ){
      croak("Cannot include both an option and its alias: " .
        "'$name' and '$alias' are mutually exclusive.")
          if exists $spec->{$name};
      $spec->{$name} = delete $spec->{$alias};
    }
  }

  while( my ($key, $value) = each %$spec ){
    # convert scalar (string) to arrayref
    $spec->{$key} = [$value]
      unless ref $value;
  }

  return $spec;
}

sub _push_unique {
  my ($self, $array, $seen, @push) = @_;

  # Ignore items already present.
  # List assignment on a hash slice benches faster than: ++$s{$_} for @a
  @$seen{ @$array } = (1) x @$array;

  push(@$array, grep { !$$seen{$_}++ } @push);
}


sub set {
  my ($self) = shift;
  my %groups = ref $_[0] ? %{$_[0]} : @_;
  delete $self->{groups}{$_} foreach keys %groups;
  $self->add(%groups);
}


sub set_items {
  my ($self) = shift;
  delete $self->{items};
  return $self->add_items(@_);
}
*set_members = \&set_items;

1;


__END__
=pod

=for :stopwords Randy Stauner arrayrefs TODO cpan testmatrix url annocpan anno bugtracker
rt cpants kwalitee diff irc mailto metadata placeholders

=head1 NAME

Set::DynamicGroups - Manage groups of items dynamically

=head1 VERSION

version 0.014

=head1 SYNOPSIS

  use Set::DynamicGroups;

  my $set = Set::DynamicGroups->new();
  $set->add(group_name => 'member1');

  $set->add(green => ['junior', 'french peas']);
  $set->add(blue  => {include => 'madame blueberry'});
  $set->add(other => {not_in => [qw(blue green)]});

  my @members = $set->group('group_name');
  # or
  my $all = $set->groups();

=head1 DESCRIPTION

An instance of C<Set::DynamicGroups>
can manage a list of groups and the items (members) of those groups.
It takes in various definitions of groups
(rules about how to build the member list (see L</GROUP SPECIFICATION>))
and will return the list of items contained in any named groups.

The module was specifically designed to allow groups
to be defined dynamically by rules based on other groups.
For instance you can define one group as a list of
all the items included in two other groups.
You can also say that one group will be composed of
any known members B<not> in some other group.

=head1 METHODS

=head2 new

  my $set = Set::DynamicGroups->new();

Constructor.

Takes no arguments.

=head2 add

  $set->add(group_name => $group_spec);

Add items to the specified group.

See L</GROUP SPECIFICATION> for details
on the possible values of C<$group_spec>.

=head2 add_items
X<add_members>

  $set->add_items(qw(bob larry));
  $set->add_items('archibald', [qw(jimmy jerry)]);

Add the provided items to the full list of known items.
Arguments can be strings or array references (which will be flattened).

This is useful to include items that you know are available
but may not be explicitly included in other groups.
Then groups defined by exclusions will base their members off of
all known items.

Items that B<are> specified in group definitions
do not need to be specified separately.

Aliased as C<add_members>.

=head2 group

  @items = $set->group($group_name);

Return a list of the items in the specified group.

This is a convenience method
that calls L</groups> with the provided group name
and returns a list (rather than a hash of arrayrefs).

The above example is equivalent to:

  @items = @{ $set->groups($group_name)->{$group_name} };

except that it will C<croak> if the specified group does not exist.

=head2 groups

  $set->groups(); # returns {groupname => \@items, ...}
  $set->groups(@group_names);

Return a hashref of each group and the items contained.

Sending a list of group names will
restrict the hashref to just those groups (instead of all).

The keys are group names and the values are arrayrefs of items.

See L</DEPENDENCY RESOLUTION> for a discussion on
the way members are determined for mutually dependent groups.

=head2 items
X<members>

  my @items = $set->items();

Return a list of all known items.

This includes any items specified explicitly with L</add_items>
as well all items explicitly C<include>d in group specifications.

Aliased as C<members>.

=head2 normalize

  $norm_spec = $set->normalize($group_spec);

Used internally to normalize group specifications.

Upgrades a string to an arrayref.
Upgrades an arrayref to a hash.
Renames aliases to the canonical keys.

See L</GROUP SPECIFICATION>.

=head2 set

  $set->set(group_name => $group_spec);

Set a group specification to the provided value
(resetting any previous specifications).

This is a shortcut for removing any previous specifications
and then calling L</add>.

=head2 set_items
X<set_members>

  $set->set_items(@items);

Set the full list of items to the provided items.

This is a shortcut for removing any previous items
and then calling L</add_items>.

Aliased as C<set_members>.

=head1 GROUP SPECIFICATION

A group specification can be in one of the following formats:

=over 4

=item I<string>

A single member;
This is converted to an arrayref with one element.

=item I<arrayref>

An array of items.
This is converted into a hashref with the C<include> key.

=item I<hashref>

Possible options:

=over 4

=item C<include> (or C<items> (or C<members>))

An arrayref of items to include in the group

=item C<exclude> (or C<not>)

An arrayref of items to exclude from the group

=item C<include_groups> (or C<in>)

An arrayref of groups whose items will be included

=item C<exclude_groups> (or C<not>)

An arrayref of groups whose items will be excluded

=back

Each option can be a an arrayref
or a string which will be converted to
an arrayref with a single element.

Specifications that only have C<exclude> and/or C<exclude_groups>
will first be filled with all known items.
(This is where L</add_items> comes in.)

=back

=head1 DEPENDENCY RESOLUTION

The main impetus for the design of this module
was the desire to define groups dependent
on the definition of other groups.

This appears to work for the limited test cases I have come up with.

However, mutually dependent groups present a problem.

I<< (If you're not dealing with mutually dependent groups
feel free to skip this section.) >>

In order to avoid infinite recursion when determining a group's members
a dependency resolution strategy is needed.

I have not determined a I<canonical> strategy,
but imagine that multiple could be argued for,
and perhaps an option/attribute on the object would be the most useful.

I do not have a use-case for mutually dependent groups,
so I have put little thought (and even less code) into it.

What follows is the discussion I've had so far
(with the two plush penguins on my desk):

Possible strategies:

=over 4

=item *

I<die> / I<croak> / I<stop>

C<croak> if a mutual dependency is found.

Simple, but possibly not always the most helpful.

=item *

I<each> / I<more>

Try to determine each group's members independently of any other groups.
This often results in groups getting I<more> members (than I<less>).

  b => {in => 'c'}
  c => {not_in => 'b', include => 'cat'}

  # result:
  #   b => ['cat']
  #   c => ['cat']

Why?
If we start with C<b>:

=over 4

=item *

C<b> will try to resolve C<c>

=item *

C<c> will include C<cat> and then try to resolve C<b>

=item *

Since C<b> is already in the stack it cannot be resolved and returns C<[]>

=item *

C<c> finishes as C<['cat']>

=item *

C<b> included C<['cat']> (from C<c>)

=item *

C<b> finishes as C<['cat']>

=back

Then C will try to resolve itself independently:

=over 4

=item *

C<c> will include C<cat> and then try to resolve C<b>

=item *

C<b> will try to resolve C<c>

=item *

Since C<c> is already in the stack it cannot be resolved and returns C<[]>

=item *

C<b> finished as C<[]>

=item *

C<c> included C<['cat']> and excluded C<[]> (from C<b>)

=item *

C<c> finishes as C<['cat']>

=back

It may not seem quite right that C<b> and C<c> end up equaling each other,
but honestly what would you expect from those definitions
(besides infinite recursion)?

=item *

I<once>? / I<less>?

Determine each group once rather than restarting for each group.
This may involve passing the entire stack of resolutions-thus-far
instead of just the names currently being resolved.
I haven't really determined if this could work reliably
or what exactly would happen.

=item *

I<includes_first>

First do the includes (the easy part) for each group,
then go through them all again and try to resolve groups
from what we have thus far.

This I<might> turn out differently than C<each>,
though I have not contemplated the actual implementation.

=item *

I<hard>

Try B<hard> to determine the members for each group.
Start with the C<include>s,
then make a stack of all the groups
and process each group...
If a group finishes successfully
(rather than exiting early to avoid infinite recursion)
remove it from the stack.
Keep looping over the stack
attempting to process each group until all have been removed
or until a full loop through the stack removes none.

Then resort to one of the other strategies to resolve any remaining groups.

=back

The current implementation is C<each> (C<more>)
because that is what I determined to be happening at my first attempt
to stop the infinite recursion.

If you have ideas on strategies, implementations, or test cases
feel free to send me your thoughts.

As always, patches are welcome.

=head1 BUGS AND LIMITATIONS

Possibly a lot if you get really complex with group dependencies.
See L</DEPENDENCY RESOLUTION> for the current discussion on the topic.

Currently everything is calculated upon request.
This may be an important part of one of the dependency resolution strategies,
but if at any time it is not,
then it's merely inefficient.

=head1 RATIONALE

I searched for other "grouping" modules on CPAN
but found none that supported basing one group off of another.
Unsatisfied by the API of the modules I looked at,
I borrowed their namespace and created this implementation.

=head1 SEE ALSO

=over 4

=item *

L<Set::Groups>

=item *

L<Set::NestedGroups>

=back

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Set::DynamicGroups

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Set-DynamicGroups>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Set-DynamicGroups>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Set-DynamicGroups>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/S/Set-DynamicGroups>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Set-DynamicGroups>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Set::DynamicGroups>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-set-dynamicgroups at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Set-DynamicGroups>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code


L<http://github.com/rwstauner/Set-DynamicGroups>

  git clone http://github.com/rwstauner/Set-DynamicGroups

=head1 AUTHOR

Randy Stauner <rwstauner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Randy Stauner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

