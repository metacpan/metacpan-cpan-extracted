#---------------------------------------------------------------------
package Pod::Loom::Template;
#
# Copyright 2009 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created:  6 Oct 2009
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Standard base class for Pod::Loom templates
#---------------------------------------------------------------------

use 5.008;
our $VERSION = '0.07';
# This file is part of Pod-Loom 0.08 (March 23, 2014)

use Moose;

use Pod::Loom::Parser ();


has tmp_collected => (
  is       => 'rw',
  isa      => 'HashRef[ArrayRef]',
);

has tmp_encoding => (
  is       => 'rw',
  isa      => 'Object',
);

has tmp_groups => (
  is       => 'rw',
  isa      => 'HashRef[HashRef]',
);

has tmp_filename => (
  is       => 'rw',
  isa      => 'Str',
);

#---------------------------------------------------------------------
# Tied hashes for interpolating function calls into strings:

{ package Pod::Loom::_Interpolation;

  sub TIEHASH { bless $_[1], $_[0] }
  sub FETCH   { $_[0]->($_[1]) }
} # end Pod::Loom::_Interpolation

our %E;
tie %E, 'Pod::Loom::_Interpolation', sub { $_[0] }; # eval

use Exporter 'import';
our @EXPORT_OK = qw(%E);

#---------------------------------------------------------------------
has _tmp_warned => (
  is       => 'rw',
  isa      => 'Bool',
);


sub warning
{
  my ($self, $message) = @_;

  unless ($self->_tmp_warned) {
    warn "While processing " . $self->tmp_filename . "\n";
    $self->_tmp_warned(1);
  }

  warn "  $message";
} # end warning


sub error
{
  my ($self, $message) = @_;

  die 'Error procesing ' . $self->tmp_filename . "\n  $message";
} # end error

#---------------------------------------------------------------------
# These methods are likely to be overloaded in subclasses:


sub collect_commands { [ 'head1' ] }
sub override_section { 0 }

has sections => (
  is       => 'ro',
  isa      => 'ArrayRef[Str]',
  required => 1,
  builder  => '_build_sections',
);

#---------------------------------------------------------------------


sub expect_sections
{
  my ($self) = @_;

  my $collected = $self->tmp_collected;

  my @sections;

  foreach my $block (@{ $collected->{'Pod::Loom-sections'} || [] }) {
    push @sections, split /\s*\n/, $block;
  } # end foreach $block

  @sections = @{ $self->sections } unless @sections;

  $self->_insert_sections(\@sections, before => -1);
  $self->_insert_sections(\@sections, after  =>  0);

  my %omit;

  foreach my $block (@{ $collected->{'Pod::Loom-omit'} || [] }) {
    $omit{$_} = 1 for split /\s*\n/, $block;
  } # end foreach $block

  return [ grep { not $omit{$_} } @sections ];
} # end expect_sections

#---------------------------------------------------------------------
# Insert sections before or after other sections:

sub _insert_sections
{
  my ($self, $sectionsList, $type, $index) = @_;

  my $blocks = $self->tmp_collected->{"Pod::Loom-insert_$type"}
      or return;

  my @empty;

  foreach my $block (@$blocks) {
    my @list = split /\s*\n/, $block;

    next unless @list;

    $self->error("Can't insert $type nonexistent section $list[$index]")
        unless grep { $_ eq $list[$index] } @$sectionsList;


    # We remove each section listed:
    my %remap = map { $_ => \@empty } @list;

    # Except the one at $index, where we insert the entire list:
    $remap{ $list[$index] } = \@list;

    @$sectionsList = map { $remap{$_} ? @{$remap{$_}} : $_ } @$sectionsList;
  } # end foreach $block

} # end _insert_sections
#---------------------------------------------------------------------


sub required_attr
{
  my $self     = shift;
  my $section  = shift;

  map {
    my $v = $self->$_;
    defined $v
        ? $v
        : $self->error("The $section section requires you to set `$_'\n")
  } @_;
} # end required_attr

#---------------------------------------------------------------------
# Sort each arrayref in tmp_collected (if appropriate):

sub _sort_collected
{
  my $self = shift;

  my $collected = $self->tmp_collected;
  my $groups    = $self->tmp_groups;

  foreach my $type (@{ $self->collect_commands }) {
    # Is this type of entry sorted at all?
    my $sort = $self->_find_sort_order($type) or next;

    foreach my $group ($type, map { "$type-$_" } keys %{ $groups->{$type} }) {
      # Begin Schwartzian transform (entry_name => entry):
      #   We convert the keys to lower case to make it case insensitive.
      my @sortable = map { /^=\S+ \s+ (\S (?:.*\S)? )/x
                               ? [ lc $1 => $_ ]
                               : [ '' => $_ ] # Should this even be allowed?
                         } @{ $collected->{$group} };

      # Set up %special to handle any top-of-the-list entries:
      my $count = 1;
      my %special;
      %special = map { lc $_ => $count++ } @$sort if ref $sort;

      # Sort specials first, then the rest ASCIIbetically:
      my @sorted =
          map { $_->[1] }         # finish the Schwartzian transform
          sort { ($special{$a->[0]} || $count) <=> ($special{$b->[0]} || $count)
                 or $a->[0] cmp $b->[0]   # if the keys match
                 or $a->[1] cmp $b->[1] } # compare the whole entry
          @sortable;

      $collected->{$group} = \@sorted;
    } # end foreach $group of $type
  } # end foreach $type of $collected entry
} # end _sort_collected

#---------------------------------------------------------------------
# Determine whether a collected command should be sorted:
#
# Returns false if they should remain in document order
# Returns true if they should be sorted
#
# If the return value is a reference, it is an arrayref of entry names
# that should appear (in order) before any other entries.

sub _find_sort_order
{
  my ($self, $type) = @_;

  # First, see if the document specifies the sort order:
  my $blocks = $self->tmp_collected->{"Pod::Loom-sort_$type"};

  if ($self->tmp_collected->{"Pod::Loom-no_sort_$type"}) {
    $self->error("You used both no_sort_$type and sort_$type\n")
        if $blocks;

    return;
  } # end if document says no sorting

  if ($blocks) {
    my @sortFirst;
    foreach my $block (@$blocks) {
      push @sortFirst, split /\s*\n/, $block;
    } # end foreach $block

    return \@sortFirst;
  } # end if document specifies sort order

  # The document said nothing, so ask the template:
  my $method = $self->can("sort_$type") or return;

  $self->$method;
} # end _find_sort_order
#---------------------------------------------------------------------


sub weave
{
  my ($self, $podRef, $filename) = @_;

  $self->tmp_filename($filename);

  $self->parse_pod($podRef);

  $self->post_parse;

  my $sectionList = $self->expect_sections;

  $self->generate_pod($sectionList, $self->collect_sections($sectionList));
} # end weave
#---------------------------------------------------------------------


sub parse_pod
{
  my ($self, $podRef) = @_;

  my $pe = Pod::Loom::Parser->new( $self->collect_commands );
  # We can't use read_string, because that treats the string as
  # encoded in UTF-8, for which some byte sequences aren't valid.
  # Pod::Loom::Parser will determine the actual encoding.
  open my $handle, '<:encoding(iso-8859-1)', $podRef
      or die "error opening string for reading: $!";
  $pe->read_handle($handle);
  $self->tmp_collected( $pe->collected );
  $self->tmp_encoding(  $pe->encoding  );
  $self->tmp_groups(    $pe->groups    );
} # end parse_pod
#---------------------------------------------------------------------


sub post_parse
{
  my ($self) = @_;

  $self->_sort_collected;
} # end post_parse
#---------------------------------------------------------------------


sub collect_sections
{
  my ($self, $sectionList) = @_;

  # Split out the expected sections:

  my %expectedSection = map { $_ => 1 } @$sectionList;

  my $heads = $self->tmp_collected->{head1};
  my %section;

  foreach my $h (@$heads) {
    $h =~ /^=head1\s+(.+?)(?=\n*\z|\n\n)/
        or $self->error("Can't find heading in $h");
    my $title = $1;

    if ($expectedSection{$title}) {
      warn "Duplicate section $title" if $section{$title};
      $section{$title} .= $h;
    } else {
      $section{'*'} .= $h;
    }
  } # end foreach $h in @$heads

  return \%section;
} # end collect_sections
#---------------------------------------------------------------------


sub generate_pod
{
  my ($self, $sectionList, $sectionText) = @_;

  # Now build the new POD:
  my $pod = '';

  foreach my $title (@$sectionList) {
    if ($sectionText->{$title} and not $self->override_section($title)) {
      $pod .= $sectionText->{$title};
    } # end if document supplied section and we don't override it
    else {
      my $method = $self->method_for_section($title);

      $pod .= $self->$method($title, $sectionText->{$title})
          if $method;
    } # end else let method generate section

    # Make sure the document ends with a blank line:
    $pod =~ s/\n*\z/\n\n/ if $pod;
  } # end foreach $title in @$sectionList

  my $encoding = $self->tmp_encoding;
  if (length $pod) {
    $pod = $encoding->encode($pod);
    my $name = $encoding->name;
    $pod = "=encoding " . $encoding->encode($name) . "\n\n$pod"
        unless $name eq 'iso-8859-1';
  }

  $pod;
} # end generate_pod
#---------------------------------------------------------------------


sub method_for_section
{
  my ($self, $title) = @_;

  # Generate the method name:
  my $method = "section_$title";
  if ($title eq '*') { $method = "other_sections" }
  else {
    $method =~ s/[^A-Z0-9_]/_/gi;
  }

  # See if we actually have a method by that name:
  $self->can($method);
} # end method_for_section
#---------------------------------------------------------------------


sub joined_section
{
  my ($self, $cmd, $newcmd, $title, $pod) = @_;

  my $entries = $self->tmp_collected->{$cmd};
  my $groups  = $self->tmp_groups->{$cmd};

  return ($pod || '') unless ($entries and @$entries)
                          or ($groups  and %$groups);

  $pod = "=head1 $title\n" unless $pod;

  return $self->_join_groups($cmd, $newcmd, $title, $pod, $groups)
      if $groups and %$groups;


  warn("Found Pod::Loom-group_$cmd in " . $self->tmp_filename .
       ", but no groups were used\n")
      if $self->tmp_collected->{"Pod::Loom-group_$cmd"};

  return $pod . $self->join_entries($newcmd, $entries);
} # end joined_section
#---------------------------------------------------------------------


sub join_entries
{
  my ($self, $newcmd, $entries) = @_;

  my $pod = '';

  $pod .= "\n=over\n" if $newcmd eq 'item';

  foreach (@$entries) {
    s/^=\S+/=$newcmd/ or $self->error("Bad entry $_");
    $pod .= "\n$_";
  } # end foreach

  $pod .= "\n=back\n" if $newcmd eq 'item';

  return $pod;
} # end join_entries

#---------------------------------------------------------------------
# Called by joined_section when it determines there are groups:

sub _join_groups
{
  my ($self, $cmd, $newcmd, $title, $pod, $groups) = @_;

  my $groupHeaders = $self->tmp_collected->{"Pod::Loom-group_$cmd"};


  die("=$cmd was grouped, but no Pod::Loom-group_$cmd found in " .
      $self->tmp_filename . "\n")
      unless $groupHeaders;

  # We might need to go down a level:
  if ($newcmd =~ /^head\d/) {
    for (;;) {
      my $re = qr/^=\Q$newcmd\E/m;
      last unless grep { /$re/ } @$groupHeaders;
      ++$newcmd;
    } # end for as long as $newcmd is used in any header
  } # end if $newcmd is headN

  my $collected = $self->tmp_collected;

  $groups->{''} = 1 if @{ $collected->{$cmd} };

  foreach my $header (@$groupHeaders) {
    $header =~ s/^\s*(\S+)\s*?\n//
        or $self->error("No category in Pod::Loom-group_$cmd\n$header");


    my $type = $1;
    my $collectedUnder = "$cmd-$type";

    if ($type eq '*') {
      $type = '';
      $collectedUnder = $cmd;
    }

    unless (delete $groups->{$type}) {
      $self->warning("No entries for =$cmd-$type");
      next;
    }

    $pod =~ s/\n*\z/\n\n/;      # Make sure it ends with a blank line
    $pod .= ($header .
             $self->join_entries($newcmd, $collected->{$collectedUnder}));
  } # end foreach $header in @$groupHeaders

  if (%$groups) {
    $self->warning("You used =$cmd, but had no Pod::Loom-group_$cmd * section\n")
        if delete $groups->{''};


    $self->warning("You used =$cmd-$_, but had no Pod::Loom-group_$cmd $_ section\n")
        for sort keys %$groups;

    die "Terminating because of errors\n";
  } # end if used groups that had no header

  $pod;
} # end _join_groups

#=====================================================================
# Package Return Value:

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

Pod::Loom::Template - Standard base class for Pod::Loom templates

=head1 VERSION

This document describes version 0.07 of
Pod::Loom::Template, released March 23, 2014
as part of Pod-Loom version 0.08.

=head1 DESCRIPTION

Pod::Loom::Template is intended as the standard base class for
Pod::Loom templates.  It provides the engine that splits apart the POD
and reassembles it.  The subclass needs to specify how the POD is
reassembled.  See the L</"weave"> method for details.

=head2 Controlling the template

A POD document can contain special commands for the template.  These
commands should work with all templates based on Pod::Loom::Template.
They are placed in a C<=for> command, and must not come in the middle
of a section.

=over

=item Pod::Loom-insert_after

=item Pod::Loom-insert_before

Insert (or move) one or more sections into the specified position.
See L</"expect_sections">.

=item Pod::Loom-omit

Omit the specified sections from the document.
See L</"expect_sections">.

=item Pod::Loom-sections

Specify the complete list of sections for the document.
See L</"expect_sections">.

=item Pod::Loom-sort_COMMAND

If a template allows pseudo-POD commands like C<=method>, you can have
the resulting entries sorted alphabetically.  For example, to have
your methods sorted, use

  =for Pod::Loom-sort_method

You can also supply a list of entries (one per line) that should come
first.  The list must match the corresponding entry exactly.  For
example:

  =for Pod::Loom-sort_method
  new

  =method new

or

  =for Pod::Loom-sort_method
  C<< $object = Class->new() >>

  =method C<< $object = Class->new() >>

=item Pod::Loom-group_COMMAND

If you have a lot of attributes or methods, you might want to group
them into categories.  You do this by appending the category (which is
an arbitrary string without whitespace) to the command.  For example:

  =attr-fmt font

says that the font attribute is in the C<fmt> category.  You must have
a C<Pod::Loom-group_COMMAND> block for each category you use.  The
block begins with the category name on a line by itself.  The rest of
the block (which may be blank) is POD that will appear before the
associated entries.

  =begin Pod::Loom-group_attr fmt

  =head2 Formatting Attributes

  These attributes control formatting.

Note: Because Pod::Eventual is not a full-fledged POD parser, you do
not actually need a matching C<=end> after the C<=begin>, but it won't
hurt if you use one.  If you don't, the block ends at the next POD
command in L</"collect_commands">.

Entries that do not contain a category are placed in the special
category C<*>.

The categories will be listed in the order that the
Pod::Loom-group_COMMAND blocks appear in the document.  The order of
entries within each category is controlled as usual.  See
L</"Pod::Loom-sort_COMMAND">.  (Just ignore the category when defining
the sort order.)

=item Pod::Loom-template

Specify the template for the document.  (This is actually handled by
L<Pod::Loom>, and applies to all templates, whether or not they
subclass Pod::Loom::Template.)

=back

=head1 ATTRIBUTES

All attributes beginning with C<tmp_> are reserved and must not be
defined by subclasses.  In addition, attributes beginning with
C<sort_> are reserved for indicating whether collected entries should
be sorted.


=head2 sections

Subclasses must provide a builder for this attribute named
C<_build_sections>. It is an
arrayref of section titles in the order they should appear.  The
special title C<*> indicates where sections that appear in the
document but are not in this list will be placed.  (If C<*> is not in
this list, such sections will be dropped.)

The list can include sections that the template does not provide.  In
that case, it simply indicates where the section should be placed if
the document provides it.


=head2 tmp_collected

This is a hashref of arrayrefs.  The keys are the POD commands
returned by L</"collect_commands">, plus any format names that begin
with C<Pod::Loom>.  Each value is an arrayref of POD blocks.
It is filled in by the L</"parse_pod"> method.


=head2 tmp_filename

This is the name of the file being processed.  This is only for
informational purposes; it need not represent an actual file on disk.
(The L</"weave"> method stores the filename here.)


=head2 tmp_groups

This is a hashref of hashrefs.  The keys are the POD commands returned
by L</"collect_commands">, Each value is an hashref of group codes.
It is filled in by the L</"parse_pod"> method.

=head1 METHODS

=head2 collect_commands

  $arrayRef = $tmp->collect_commands;

This method should be overriden in subclasses to indicate what POD
commands should be collected for the template to stitch together.
This should include C<head1>, or the template is unlikely to work
properly.  The default method indicates only C<head1> is collected.


=head2 collect_sections

  $section_text = $tmp->collect_sections($section_list)

This method collects the text of each section in the original document
based on the $section_list (which comes from L</"expect_sections">).
It returns a hashref keyed on section title.

Any sections that appeared in the original document but are not in
C<$section_list> are concatenated to form the C<*> section.


=head2 error

  $tmp->error($message);

This method calls Perl's C<die> builtin with the C<$message> after
prepending the filename to it.


=head2 expect_sections

  $section_titles = $tmp->expect_sections;

This method returns an arrayref containing the section titles in the
order they should appear.  By default, this is the list from
L</"sections">, but it can be overriden by the document:

If the document contains C<=for Pod::Loom-sections>, the sections
listed there (one per line) replace the template's normal section
list.

If the document contains C<=for Pod::Loom-omit>, the sections listed
there will not appear in the final document.  (Unless they appeared in
the document, in which case they will be with the other C<*>
sections.)

If the document contains C<=for Pod::Loom-insert_before>, the sections
listed there will be inserted before the last section in the list
(which must already be in the section list).  If the sections were
already in the section list, they are moved to the new location.

If the document contains C<=for Pod::Loom-insert_after>, the sections
listed there will be inserted after the first section in the list.
For example,

  =for Pod::Loom-insert_after
  DESCRIPTION
  NOTES

will cause the NOTES section to appear immediately after the DESCRIPTION.


=head2 generate_pod

  $pod = $tmp->generate_pod($section_list, $section_text)

This method is passed a list of section titles (from
L</"expect_sections">) and a hash containing the original text of each
section (from L</"collect_sections">.  It then considers each section
in order:

=over

=item 1.

If the section appeared in the original document, it calls
C<< $tmp->override_section($title) >>.  If that returns false,
it copies the section from the original document to the new document
and proceeds to the next section.  Otherwise, it continues to step 2.

=item 2.

It calls C<< $tmp->method_for_section($title) >> to get the method
that will handle that section.  If that returns no method, it proceeds
to the next section.

=item 3.

It calls the method from step 2, passing it two parameters: the
section title and the text of the section from the original document
(or undef).  Whatever text the method returns is appended to the new
document.  (The method may return the empty string, but should not
return undef).

=back


=head2 join_entries

  $podText = $tmp->join_entries($newcmd, \@entries);

This method is used by L</"joined_section">, but may be useful to
subclasses also.  Each element of C<@entries> must begin with a POD
command, which will be changed to C<$newcmd>.  It returns the entries
joined together, surrounded by C<=over> and C<=back> if C<$newcmd> is
C<item>.


=head2 joined_section

  $podText = $tmp->joined_section($oldcmd, $newcmd, $title, $pod);

This method may be useful to subclasses that want to build sections
out of collected commands.  C<$oldcmd> must be one of the entries from
L</"collect_commands">.  C<$newcmd> is the POD command that should be
used for each entry (like C<head2> or C<item>).  C<$title> is the
section title, and C<$pod> is the text of that section from the
original document (if any).

Each collected entry is appended to the original section.  If there
was no original section, a simple C<=head1 $title> command is added.
If C<$newcmd> is C<item>, then C<=over> and C<=back> are added
automatically.

If the document divided this section into groups (see
L</"Pod::Loom-group_COMMAND">), that is handled automatically by this
method.  If C<$newcmd> is a C<headN>, and any of the category headers
contains a C<=headN> command, then C<$newcmd> is automatically
incremented.  (E.g., C<head2> becomes C<head3>).


=head2 method_for_section

  $methodRef = $tmp->method_for_section($section_title);

This associates a section title with the template method that
implements it.  By default, it prepends C<section_> to the title, and
then converts any non-alphanumeric characters to underscores.

The special C<*> section is associated with the method C<other_sections>.


=head2 override_section

  $boolean = $tmp->override_section($section_title);

Normally, if a section appears in the document, it remains unchanged
by the template.  However, a template may want to rewrite certain
sections.  C<override_section> is called when the specified section is
present in the document.  If it returns true, then the normal
C<section_TITLE> method will be called.  (If it returns true but the
C<section_TITLE> method doesn't exist, the section will be dropped.)


=head2 parse_pod

  $tmp->parse_pod(\$pod);

Parse the document, which is passed by reference.  The default
implementation splits up the POD using L<Pod::Loom::Parser>, breaking
it up according to L</"collect_commands">.  The resulting chunks are
stored in the C<tmp_collected> attribute.


=head2 post_parse

  $tmp->post_parse()

This method is called after C<parse_pod>.  The default implementation
sorts the collected POD chunks if requested to by the document or the
C<sort_> attributes.


=head2 required_attr

  @values = $tmp->required_attr($section_title, @attribute_names);

Returns the value of each attribute specified in C<@attribute_names>.
If any attribute is C<undef>, dies with a message that
C<$section_title> requires that attribute.


=head2 warning

  $tmp->warning($message);

This method calls Perl's C<warn> builtin with the C<$message>.  If
this is the first warning, it first prints a warning with the filename.


=head2 weave

  $new_pod = $tmp->weave(\$old_pod, $filename);

This is the primary entry point, normally called by Pod::Loom's
C<weave> method.

First, it stores the filename in the C<tmp_filename> attribute.

It then calls:

=over

=item 1.

L</"parse_pod"> to parse the POD.

=item 2.

L</"post_parse"> to do additional processing.

=item 3.

L</"expect_sections"> to get the list of section titles.

=item 4.

L</"collect_sections"> to get the text of each section from
the original document.

=item 5.

L</"generate_pod"> to produce the new document.

=back

=head1 DIAGNOSTICS

The following errors are classified like Perl's built-in diagnostics
(L<perldiag>):

     (S) A severe warning
     (F) A fatal error (trappable)

=over

=item C<< %s was grouped, but no Pod::Loom-group_%s found in %s >>

(F) You used categories with a command (like C<=method-cat>), but didn't
have any Pod::Loom-group_COMMAND blocks.  See L</"Pod::Loom-group_COMMAND">.


=item C<< Can't find heading in %s >>

(F) Pod::Loom couldn't determine the section title for the specified
section.  Is it formatted properly?


=item C<< Can't insert before/after nonexistent section %s >>

(F) You can't insert sections near a section title that isn't already in
the list of sections.  Make sure you spelled it right.


=item C<< Found Pod::Loom-group_%s in %s, but no groups were used >>

(S) You indicated that a command (like C<=method>) was going to be
grouped, but didn't actually use any groups.
See L</"Pod::Loom-group_COMMAND">.


=item C<< No category in Pod::Loom-group_%s >>

(F) A Pod::Loom-group_COMMAND block must begin with the category.


=item C<< The %s section requires you to set `%s' >>

(F) The specified section of the template requires an attribute that
you did not set.


=item C<< You used =%s, but had no Pod::Loom-group_$cmd %s section >>

(F) You must have one Pod::Loom-group_COMMAND block for each category
you use.  Entries without a category are placed in the C<*> category.


=back

=head1 CONFIGURATION AND ENVIRONMENT

Pod::Loom::Template requires no configuration files or environment variables.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>

Please report any bugs or feature requests
to S<C<< <bug-Pod-Loom AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=Pod-Loom >>.

You can follow or contribute to Pod-Loom's development at
L<< https://github.com/madsen/pod-loom >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Christopher J. Madsen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
