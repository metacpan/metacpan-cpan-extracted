use utf8;
package Rapi::Blog::DB::Result::Section;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("section");
__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "description",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 1,
    size => 1024,
  },
  "parent_id",
  {
    data_type      => "integer",
    default_value  => \"null",
    is_foreign_key => 1,
    is_nullable    => 1,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("parent_id_name_unique", ["parent_id", "name"]);
__PACKAGE__->belongs_to(
  "parent",
  "Rapi::Blog::DB::Result::Section",
  { id => "parent_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);
__PACKAGE__->has_many(
  "posts",
  "Rapi::Blog::DB::Result::Post",
  { "foreign.section_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "sections",
  "Rapi::Blog::DB::Result::Section",
  { "foreign.parent_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "trk_section_posts",
  "Rapi::Blog::DB::Result::TrkSectionPost",
  { "foreign.section_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "trk_section_sections_sections",
  "Rapi::Blog::DB::Result::TrkSectionSection",
  { "foreign.section_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "trk_section_sections_subsections",
  "Rapi::Blog::DB::Result::TrkSectionSection",
  { "foreign.subsection_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2017-10-04 18:42:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9NPmvsrCunpxPOYQuwBskg

use RapidApp::Util ':all';
use Rapi::Blog::Util;

__PACKAGE__->load_components('+Rapi::Blog::DB::Component::SafeResult');

sub schema { (shift)->result_source->schema }

sub insert {
  my $self = shift;
  my $columns = shift;
  
  if(my $User = Rapi::Blog::Util->get_User) {
    die usererr "Create Section: PERMISSION DENIED" if ($User->id && !$User->admin);
  }
  
  $self->set_inflated_columns($columns) if $columns;
  
  $self->_validate_depth;
  
  $self->next::method;
  
  $self->_track_as_subsection;
  
  $self
}

sub update {
  my $self = shift;
  my $columns = shift;
  
  if(my $User = Rapi::Blog::Util->get_User) {
    die usererr "Update Section: PERMISSION DENIED" if ($User->id && !$User->admin);
  }
  
  $self->set_inflated_columns($columns) if $columns;
  
  $self->_validate_depth;
  
  $self->next::method;
  
  $self->_track_as_subsection;
  
  $self
}


sub delete {
  my $self = shift;
  
  if(my $User = Rapi::Blog::Util->get_User) {
    die usererr "Delete Section: PERMISSION DENIED" if ($User->id && !$User->admin);
  }
  
  $self->next::method(@_)
}


sub parents_name_list {
  my $self = shift;
  $self->parent ? ($self->parent->name, $self->parent->parents_name_list) : ()
}

sub full_path_names {
  my ($self, $delim) = @_;
  my @parents = reverse $self->parents_name_list;
  my @path = ('', @parents, $self->name);
  return join($delim,@path) if ($delim);
  return wantarray ? @path : \@path
}

sub all_section_ids {
  my $self = shift;
  my @ids = ( $self->get_column('id') );
  push @ids, $self->parent->all_section_ids if ($self->parent);
  @ids
}


sub _validate_depth {
  my $self = shift;
  my $level = shift || 1;
  my $seen = shift || {};
  
  my $max_depth = 10;
  
  if (my $id = $self->get_column('id')) { # may not have an id yet
    die usererr "Circular references not allowed (cannot make a Section a child of itself)" if ($seen->{$id}++);
  }
  
  die usererr "Too many levels of Sections -- max allowed is $max_depth" if ($level > $max_depth);
  
  $self->get_column('parent_id')
    ? $self->parent->_validate_depth($level+1,$seen)
    : 1
}


sub _track_as_subsection {
  my $self = (shift)->get_from_storage;
  
  # Clear all existing rows listing us as a subsection:
  $self->trk_section_sections_subsections->delete_all;
  return unless ($self->parent);
  
  my @ids = $self->parent->all_section_ids;
  my ($id, $depth) = ($self->get_column('id'), 0);

  $self->trk_section_sections_subsections->populate([
    map {{
      section_id    => $_,
      subsection_id => $id,
      depth         => $depth++
    }} @ids
  ])
}
  

sub posts_count {
  my $self = shift;
  # In case the ResultSet has pre-loaded this value, don't do another query:
  my $preload = try{$self->get_column('posts_count')};
  defined $preload ? $preload : $self->trk_section_posts->count
}

sub subsections_count {
  my $self = shift;
  # In case the ResultSet has pre-loaded this value, don't do another query:
  my $preload = try{$self->get_column('subsections_count')};
  defined $preload ? $preload : $self->trk_section_sections_sections->count
}


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

Rapi::Blog::DB::Result::Section - Section row object

=head1 DESCRIPTION

This is the default Section Result class/row object for L<Rapi::Blog>. Posts can optionally be 
assigned to exactly one section, but sections may be sub-sections of other sections, forming
a hierarchy/tree structure.

This is a L<DBIx::Class::Row>.

=head1 COLUMNS

=head2 id

Auto-increment section id. Read-only.

=head2 name

The unique name of the Section at the current location in the hierarchy (i.e. the Section name can be
reused if it has a different parent Section).

=head2 description

Optionally text description of the Section

=head2 parent

The parent Section that this Section belongs to, or C<undef> if this is a top-level Section. This
is an FK relationship to another Section row object. C<parent> is a relationship name, the 
underlying foreign-key column is C<parent_id> which is hidden.

=head1 METHODS

=head2 posts

Multi-relationship to all the Posts in this Section.

=head2 sections

Multi-relationship to all the immediate child Sections in this Section.

=head2 parents_name_list

Returns a C<LIST> of all the names of parent Sections up the chain to the top, ordered from child to 
parent, excluding the name of the calling Section.

=head2 full_path_names

Returns the path-ordered (parent to child) Section names, including the name of the calling Section
which will be last.

If a delimeter argument is supplied, the list will be returned as a string joined by that delimeter.
If no argument is supplied, when called in LIST context the list is returned, when called in SCALAR
context, the default delimeter of C<'/'> is used and the path is returned as a joined string.

=head2 posts_count

Returns the count of direct Posts in this Section.

=head2 sections_count

Returns the count of direct sub-sections of this Section.

=head1 SEE ALSO

=over

=item * 

L<Rapi::Blog>

=item *

L<http://rapi.io/blog>

=back


=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

