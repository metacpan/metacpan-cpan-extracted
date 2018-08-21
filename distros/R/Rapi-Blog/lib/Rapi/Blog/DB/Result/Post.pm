use utf8;
package Rapi::Blog::DB::Result::Post;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("post");
__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "title",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 1,
    size => 255,
  },
  "image",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 1,
    size => 255,
  },
  "ts",
  { data_type => "datetime", is_nullable => 0 },
  "create_ts",
  { data_type => "datetime", is_nullable => 0 },
  "update_ts",
  { data_type => "datetime", is_nullable => 0 },
  "author_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "creator_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "updater_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "section_id",
  {
    data_type      => "integer",
    default_value  => \"null",
    is_foreign_key => 1,
    is_nullable    => 1,
  },
  "published",
  { data_type => "boolean", default_value => 0, is_nullable => 0 },
  "publish_ts",
  { data_type => "datetime", default_value => \"null", is_nullable => 1 },
  "size",
  { data_type => "integer", default_value => \"null", is_nullable => 1 },
  "tag_names",
  { data_type => "text", default_value => \"null", is_nullable => 1 },
  "custom_summary",
  { data_type => "text", default_value => \"null", is_nullable => 1 },
  "summary",
  { data_type => "text", default_value => \"null", is_nullable => 1 },
  "body",
  { data_type => "text", default_value => "", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("name_unique", ["name"]);
__PACKAGE__->belongs_to(
  "author",
  "Rapi::Blog::DB::Result::User",
  { id => "author_id" },
  { is_deferrable => 0, on_delete => "RESTRICT", on_update => "CASCADE" },
);
__PACKAGE__->has_many(
  "comments",
  "Rapi::Blog::DB::Result::Comment",
  { "foreign.post_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->belongs_to(
  "creator",
  "Rapi::Blog::DB::Result::User",
  { id => "creator_id" },
  { is_deferrable => 0, on_delete => "RESTRICT", on_update => "CASCADE" },
);
__PACKAGE__->has_many(
  "hits",
  "Rapi::Blog::DB::Result::Hit",
  { "foreign.post_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "post_categories",
  "Rapi::Blog::DB::Result::PostCategory",
  { "foreign.post_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "post_tags",
  "Rapi::Blog::DB::Result::PostTag",
  { "foreign.post_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->belongs_to(
  "section",
  "Rapi::Blog::DB::Result::Section",
  { id => "section_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "SET DEFAULT",
    on_update     => "CASCADE",
  },
);
__PACKAGE__->has_many(
  "trk_section_posts",
  "Rapi::Blog::DB::Result::TrkSectionPost",
  { "foreign.post_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->belongs_to(
  "updater",
  "Rapi::Blog::DB::Result::User",
  { id => "updater_id" },
  { is_deferrable => 0, on_delete => "RESTRICT", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2017-10-04 18:42:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:EgoroG32J0nSECxuTHx0yQ

__PACKAGE__->load_components('+RapidApp::DBIC::Component::TableSpec');
__PACKAGE__->TableSpec_m2m( categories => "post_categories", 'category_name');
__PACKAGE__->apply_TableSpec;

__PACKAGE__->load_components('+Rapi::Blog::DB::Component::SafeResult');

__PACKAGE__->has_many(
  "direct_comments",
  "Rapi::Blog::DB::Result::Comment",
  { "foreign.post_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0, where => { parent_id => undef } },
);

__PACKAGE__->many_to_many( 'tags', 'post_tags', 'tag_name' );

use RapidApp::Util ':all';
use Rapi::Blog::Util;
use HTML::Strip;

sub schema { (shift)->result_source->schema }
# This relies on us having been loaded via RapidApp::Util::Role::ModelDBIC
sub parent_app_class { (shift)->schema->_ra_catalyst_origin_model->app_class }
sub Access { (shift)->parent_app_class->template_controller->Access }

sub public_url_path {
  my $self = shift;
  return undef unless $self->Access->default_view_path;
  $self->{_public_url_path} //= do {
    my $pfx = '';
    if(my $c = RapidApp->active_request_context) { $pfx = $c->mount_url || ''; }
    my $path = join('',$pfx,'/',$self->Access->default_view_path);
    $path =~ s/\/?$/\//; # make sure there is a trailing '/';
    $path
  }
}

sub public_url {
  my $self = shift;
  my $path = $self->public_url_path or return undef;
 return join('',$path,$self->name)
}

sub preview_url_path {
  my $self = shift;
  return undef unless $self->Access->preview_path;
  $self->{_preview_url_path} //= do {
    my $pfx = '';
    if(my $c = RapidApp->active_request_context) { $pfx = $c->mount_url || ''; }
    my $path = join('',$pfx,'/',$self->Access->preview_path);
    $path =~ s/\/?$/\//; # make sure there is a trailing '/';
    $path
  }
}

sub preview_url {
  my $self = shift;
  my $path = $self->preview_url_path or return undef;
 return join('',$path,$self->name)
}

sub open_url_path {
  my $self = shift;
  my $mode = shift;
  my $app = $self->parent_app_class;
  my $pfx = '';
  if(my $c = RapidApp->active_request_context) { $pfx = $c->mount_url || ''; }
  if($mode) {
    $mode = lc($mode);
    die "open_url_path(): bad argument '$mode' -- must be undef, 'direct' or 'navable'"
      unless ($mode eq 'direct' or $mode eq 'navable');
    return join('',$pfx,'/rapidapp/module/',$mode,$self->getRestPath)
  }
  else {
    my $ns = $app->module_root_namespace;
    return join('',$pfx,'/',$ns,'/#!',$self->getRestPath)
  }
}


sub insert {
  my $self = shift;
  my $columns = shift;
  
  if(my $User = Rapi::Blog::Util->get_User) {
    die usererr "Insert Post: PERMISSION DENIED" if ($User->id && !$User->can_post);
  }
  
  $self->set_inflated_columns($columns) if $columns;
  
  $self->_set_column_defaults('insert');

  $self->next::method;
  
  $self->_update_tags;
  
  return $self;
}

sub update {
  my $self = shift;
  my $columns = shift;
  $self->set_inflated_columns($columns) if $columns;
  
  my $uid = Rapi::Blog::Util->get_uid;
  die usererr "Update Post: PERMISSION DENIED" if ($uid && !$self->can_modify);
  
  $self->updater_id( $uid );
  
  $self->_set_column_defaults('update');
  
  $self->_update_tags if ($self->is_column_changed('body'));
  
  $self->next::method;
}

sub delete {
  my $self = shift;
  
  my $uid = Rapi::Blog::Util->get_uid;
  die usererr "Delete Post: PERMISSION DENIED" if ($uid && !$self->can_delete);

  $self->next::method(@_)
}

sub image_url {
  my $self = shift;
  $self->{_image_url} //= $self->image 
    ? join('/','_ra-rel-mnt_','simplecas','fetch_content',$self->image) 
    : undef
}

sub tag_names_list {
	my $self = shift;
	split(/\s+/,$self->tag_names)
}

sub num_categories {
  my $self = shift;
  $self->post_categories->count
}

sub category_list {
  my $self = shift;
  sort $self
    ->post_categories
    ->get_column('category_name')
    ->all
}

sub section_name {
  my $self = shift;
  $self->section ? $self->section->get_column('name') : undef
}

sub section_name_or {
  my ($self, $default) = @_;
  $self->section_name || $default
}

sub _set_column_defaults {
  my $self = shift;
  my $for = shift || '';
  
  # default title:
  $self->title($self->name) unless $self->title;
  
  if ($for eq 'insert' || $self->is_column_changed('body') || $self->is_column_changed('custom_summary')) {
    $self->size( length $self->body );
    $self->summary( 
      $self->custom_summary ? $self->custom_summary : $self->_generate_auto_summary
    );
    $self->tag_names(join(' ',$self->_extract_normalized_hashtags));
  }
  
  my $uid = Rapi::Blog::Util->get_uid;
  my $now_ts = Rapi::Blog::Util->now_ts;
  
  if ($self->published) {
    $self->publish_ts($now_ts) unless $self->publish_ts;
  }
  else {
    $self->publish_ts(undef) if $self->publish_ts;
  }
  
  $self->update_ts($now_ts);
  $self->updater_id( $uid );
  $self->author_id( $uid ) unless $self->author_id;
  
  if($for eq 'insert') {
    $self->create_ts($now_ts);
    $self->creator_id( $uid );
  }
  
  if ($for eq 'insert' || $self->is_column_changed('section_id')) {
    $self->_apply_track_sections
  }

}

sub _extract_normalized_hashtags {
  my $self = shift;
  # normalized list of keywords, lowercased and _ converted to -
  uniq(map { $_ =~ s/\_/\-/g; lc($_) } $self->_extract_hashtags);
}

sub _update_tags {
  my $self = shift;
  my @kw = $self->_extract_normalized_hashtags;
  $self->set_tags([ map {{ name => $_ }} @kw ]);
}


sub _parse_social_entities {
  my $self = shift;
  my $body = $self->body or return ();
  
  my @ents = $body =~ /(?:^|\s)([#@][-\w]{1,64})\b/g;
  
  return uniq(@ents)
}

sub _extract_hashtags {
  my $self = shift;
  map { $_ =~ s/^#//; $_ } grep { $_ =~ /^#/ } $self->_parse_social_entities
}


sub _generate_auto_summary {
  my $self = shift;
  
  my $num_words = 70;
  
  my $body = $self->body;
  
  # Convert markdown links to plain text (labels) (provided by @deven)
  $body =~ s/(!?)\[(.*?)\]\((.*?)\)/$1 ? "" : $2/ge;
  
  # Convert ![], [] and () to <> so they will look like tags and get stripped in the next step
  $body =~ s/\!?[\[\(]/\</g;
  $body =~ s/[\]\)]/\>/g;
  
  # Strip HTML markup from body
  my $text = HTML::Strip->new->parse( $body );
  
  my $i = 0;
  my $buf = '';
  for my $line (split(/\r?\n/,$text)) {
    for my $word (split(/\s+/,$line)) {
      next if ($word =~ /^\W+$/);
      $buf .= "$word ";
      return $buf if (++$i >= $num_words);
    }
  }
  
  return $buf
}


sub _apply_track_sections {
  my $self = shift;
  
  $self->trk_section_posts->delete_all;
  return unless ($self->section);
  
  my @ids = $self->section->all_section_ids;
  my ($id, $depth) = ($self->get_column('id'), 0);

  $self->trk_section_posts->populate([
    map {{
      section_id => $_,
      post_id    => $id,
      depth      => $depth++
    }} @ids
  ])
}



sub record_hit {
  my $self = shift;
  
  my @args = ({ post_id => $self->id, ts => Rapi::Blog::Util->now_ts });
  if(my $c = RapidApp->active_request_context) {
    push @args, $c->request;
  }
	
  # This is a rare example where we do want to allow an insert from a template 
	local $Rapi::Blog::DB::Component::SafeResult::ALLOW = 1;
	
  $self->hits->create_from_request(@args);
  
  return "";
}

sub can_delete {
  my $self = shift;
  my $User = Rapi::Blog::Util->get_User or return 0;
  $User->admin or ($User->author && $self->author_id == $User->id)
}

sub can_modify {
  my $self = shift;
  my $User = Rapi::Blog::Util->get_User or return 0;
  $User->admin or ($User->author && $self->author_id == $User->id)
}

sub can_change_author {
  my $self = shift;
  my $User = Rapi::Blog::Util->get_User or return 0;
  $User->admin
}


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;


__END__

=head1 NAME

Rapi::Blog::DB::Result::Post - Post row object

=head1 DESCRIPTION

This is the default Post Result class/row object for L<Rapi::Blog>. The C<list_posts()> template 
directive returns an array of these objects (in the sub property C<rows>), and when viewing a post 
via a C<view_wrapper> the associated post is available as the template variable C<Post>.

This is a L<DBIx::Class::Row>.

=head1 COLUMNS

=head2 id

Auto-increment post id. Read-only.

=head2 name

The unique name of the Post. The name is used to generate the public URL for the post.
Should contain only lower case alpha characters, dash and underscore.

=head2 title

Human-friendly Post title

=head2 image

CAS image column (C<'cas_img'>). Contains the sha1 of a file within the SimpleCAS.

=head2 ts

The declared Date/Time of the Post. Defaults to the timestamp of when the Post is created but can be
set to anything.

=head2 create_ts

The real Date/Time the Post is created, read-only.

=head2 update_ts

The Date/Time of the last modification of the Post, read-only.

=head2 author

The author of the Post, FK to L<Rapi::Blog::DB::Result::User> object. C<author> is a relationship, the 
underlying foreign-key column is C<author_id> which is hidden.

The author defaults to the user creating the Post, but if the user is an C<admin> they can select a
different user.

=head2 creator

The creator of the Post, FK to L<Rapi::Blog::DB::Result::User> object. C<creator> is a relationship, the 
underlying foreign-key column is C<creator_id> which is hidden. Read-only.

=head2 updater

The last user who modified the Post, FK to L<Rapi::Blog::DB::Result::User> object. C<updater> is a 
relationship, the underlying foreign-key column is C<updater_id> which is hidden. Read-only.

=head2 published

True or false bool value. Posts which are not published will not be listed in C<list_posts()> and will
return a 404 not found except for C<admins> and the C<author> of the Post.

=head2 publish_ts

The Date/Time the Post was marked C<published> or C<undef> if the Post is not published. Read-only.

=head2 size

The size in bytes of the C<body>. Read-only.

=head2 tag_names

List of tag names for the Post as a space-separated string, read-only. Tags are defined by specifying 
them in Twitter C<#hashtag> format in the Post C<body>.

=head2 summary

The summary for the Post which is either set from C<custom_summary> or auto-generated from the C<body>.
Read-only.

=head2 custom_summary

Custom summary for the Post. Setting any nonzero-length value will populate as the C<summary>, while
an empty string will cause C<summary> to be auto-generated.

=body

The main content body of the Post in HTML/Markdown format.

=head2 section

The section of the Post, if one is set, or C<undef>. FK to L<Rapi::Blog::DB::Result::Section> object. 
C<section> is a relationship, the underlying foreign-key column is C<section_id> which is hidden.

=head1 METHODS

=head2 comments 

Multi-relationship to all the Comments of this Post.

=head2 hits

Multi-relationship to all the Hits of this Post. Hits record details of the HTTP request when C<record_hit>
is called from the view template.

hits post_tags

Multi-relationship recording the tags of this Post.

=head2 tag_names_list 

List of tag names. Like C<tag_names> but returns a list of strings rather than a single string.

=head2 num_categories

Returns the number of Categories this Post is in, which can be zero.

=head2 category_list

List of Category names (strings).

=head2 section_name

Returns the text name of the Section or C<undef> if the Post has no Section set.

=head2 section_name_or

Convenience method, works just like C<section_names>, except when there is no Section, the value
of the supplied argument is returned instead of C<undef>.

=head2 image_url 

URL which can be used to access the C<image> for the active site/scaffold.

=head2 public_url_path

URL path prefix to access the default public view of all Posts.

=head2 public_url

URL path prefix to access the default public view of B<this> Post. This is just the C<public_url_path>
plus the C<name>

=head2 preview_url_path

URL path prefix to access the public preview of all Posts. By default this is the same as 
C<public_url_path> unless the Scaffold has defined C<preview_path>. The preview is used to display
the post in an iframe on the internal post page. This is useful to be able to show the post without
the full navigation of the site.

=head2 preview_url

URL path prefix to access the public preview of B<this> Post. This is just the C<preview_url_path>
plus the C<name>

=head2 open_url_path

URL path to access the Post internally within the password-protected area of the site. This is the
same page that opens if you double-click a Post from the Posts grid and is how you can edit a post. If
the user is not logged in they will automatically be prompted to login.

Supports an optional mode argument which can be C<'direct'> or C<'navable'>. These are full-screen modes
which will open the Post page without the full navigation tree and header. The C<'direct'> mode will be
totally full-screen, while C<'navable'> will load a full-screen tabpanel which allows following links to 
related objects.

=head2 record_hit 

Called to record the current request in the Hits table for the post. Designed to be called from the
default view path in the scaffold.

=head2 can_delete

Util method returns true if the current user can delete the post. Will be true if the user is either 
an admin or or the author of the post.

=head2 can_modify

Util method returns true if the current user can modify the post. Will be true if the user is either 
an admin or or the author of the post.

=head2 can_change_author

Util method returns true if the current user can change the author of the post. Will be true if the 
user is an admin.


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



