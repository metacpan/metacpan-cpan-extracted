package Rapi::Blog::Model::DB;
use Moo;
extends 'Catalyst::Model::DBIC::Schema';
with 'RapidApp::Util::Role::ModelDBIC';

use strict;
use warnings;

use Path::Class qw(file);
use RapidApp::Util ':all';
my $db_path = file( RapidApp::Util::find_app_home('Rapi::Blog'), 'rapi_blog.db' );
sub _sqlt_db_path { "$db_path" };    # exposed for use by the regen devel script

use Rapi::Blog::Util;

#<<<  tell perltidy not to mess with this
before 'setup' => sub {
  my $self = shift;

  # extract path from dsn because the app reaches in to set it
  my $dsn = $self->connect_info->{dsn};
  my ( $pre, $db_path ) = split( /\:SQLite\:/, $dsn, 2 );

  unless ( -f $db_path ) {
    warn "  ** Auto-Deploy $db_path **\n";
    my $db = $self->_one_off_connect;
    $db->deploy;
    # Make sure the built-in uid:0 system account exists:
    $db->resultset('User')->find_or_create(
      { id => 0, username => '(system)', full_name => '[System Acount]', admin => 1 },
      { key => 'primary' }
    );
  }

  my $diff =
    $self->_diff_deployed_schema
    ->filter_out('*:relationships')
    ->filter_out('*:constraints')
    ->filter_out('*:isa')
    ->filter_out('*:columns/*._inflate_info')
    ->filter_out('*:columns/*._ic_dt_method')
    ->diff;

  if ($diff) {
    die join( "\n",
      '', '', '', '**** ' . __PACKAGE__ . ' - column differences found in deployed database! ****',
      '', 'Dump (DBIx::Class::Schema::Diff): ',
      Dumper($diff), '', '', '' );
  }
};
#>>>

__PACKAGE__->config(
  schema_class => 'Rapi::Blog::DB',

  connect_info => {
    dsn             => "dbi:SQLite:$db_path",
    user            => '',
    password        => '',
    quote_names     => q{1},
    sqlite_unicode  => q{1},
    on_connect_call => q{use_foreign_keys},
  },

  # Configs for the RapidApp::RapidDbic Catalyst Plugin:
  RapidDbic => {

    # use only the relationship column of a foreign-key and hide the
    # redundant literal column when the names are different:
    hide_fk_columns => 1,

    # The grid_class is used to automatically setup a module for each source in the
    # navtree with the grid_params for each source supplied as its options.
    grid_class  => 'Rapi::Blog::Module::GridBase',
    grid_params => {
      # The special '*defaults' key applies to all sources at once
      '*defaults' => {
        page_class      => 'Rapi::Blog::Module::PageBase',
        include_colspec => ['*'],                            #<-- default already ['*']
        ## uncomment these lines to turn on editing in all grids
        updatable_colspec   => ['*'],
        creatable_colspec   => ['*'],
        destroyable_relspec => ['*'],
        extra_extconfig     => {
          store_button_cnf => {
            save => { showtext => 1 },
            undo => { showtext => 1 }
          }
        }
      },
      Post => {
        page_class => 'Rapi::Blog::Module::PostPage'
      },
      PostKeyword => {
        include_colspec => [ '*', '*.*' ],
      },
      Hit => {
        updatable_colspec => undef,
        creatable_colspec => undef,
      }
    },

    # TableSpecs define extra RapidApp-specific metadata for each source
    # and is used/available to all modules which interact with them
    TableSpecs => {
      Tag => {
        display_column => 'name',
        title          => 'Tag',
        title_multi    => 'Tags',
        iconCls        => 'icon-tag-blue',
        multiIconCls   => 'icon-tags-blue',
        columns        => {
          name => {
            header => 'Tag Name',
            width  => 180,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          post_tags => {
            header => 'Tag/Post Links',
            width  => 170,
            #sortable => 1,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
        },
      },
      Post => {
        display_column => 'title',
        title_multi    => 'Posts',
        iconCls        => 'icon-post',
        multiIconCls   => 'icon-posts',
        columns        => {
          id => {
            allow_add => 0,
            header    => 'Id',
            width     => 55,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          name => {
            header           => 'Name',
            extra_properties => {
              editor => {
                vtype => 'rablPostName',
              }
            },
            width => 170,
#documentation => 'Unique post name, used in the URL -- can only contain lowercase/digit characters',
            hidden => 1
              #renderer => 'RA.ux.App.someJsFunc',
              #profiles => [],
          },
          title => {
            header => 'Title',
            width  => 220,
        #documentation => 'Human-frendly post title. If not set, defaults to the same value as Name'
        #renderer => 'RA.ux.App.someJsFunc',
        #profiles => [],
          },
          image => {
            header => 'Image',
            hidden => 1,
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            profiles => ['cas_img'],
  #documentation => 'Post-specific image. It is up to the scaffold to decide how (or if) to use it.'
          },
          create_ts => {
            header        => 'Created',
            allow_add     => \0,
            allow_edit    => \0,
            documentation => 'Timestamp of when the post was created (inserted)',
            hidden        => 1
              #width => 100,
              #renderer => 'RA.ux.App.someJsFunc',
              #profiles => [],
          },
          update_ts => {
            header        => 'Updated',
            allow_add     => \0,
            allow_edit    => \0,
            documentation => 'Timestamp updated automatically every time the post is modified',
            hidden        => 1
              #width => 100,
              #renderer => 'RA.ux.App.someJsFunc',
              #profiles => [],
          },
          published => {
            header => '<i style="font-size:1.3em;" class="fa fa-eye" title="Published?"></i>',
            width  => 45,
            documentation => 'Published yes or no. Post will not be listed unless this is yes/true',
       #documentation => join('',
       #  'True/false value which determines if a post should be made publically available. ',
       #  'If false, external users will receive a 404 when trying to access the URL and the post ',
       #  'will not show up in any list_posts() calls. However, admins and the author will still ',
       #  'be able to access the post via its public URL.'
       #),
       #renderer => 'RA.ux.App.someJsFunc',
       #profiles => [],
          },
          publish_ts => {
            header        => 'Published at',
            allow_add     => \0,
            allow_edit    => \0,
            documentation => join( '',
              'Timestamp updated automatically every time the published flag changes from 0 to 1 ',
              'and is cleared when it changes from 1 back to 0.' ),
            hidden => 1
              #width => 100,
              #renderer => 'RA.ux.App.someJsFunc',
              #profiles => [],
          },
          body => {
            header => 'body',
            hidden => 1,
            width  => 400,
            #renderer => 'RA.ux.App.someJsFunc',
            profiles      => ['markdown'],
            documentation => 'The main content body of the post stored in Markdown/HTML format'
          },
          post_tags => {
            header       => 'Post/Tag Links',
            width        => 170,
            documentaton => join( '',
'Multi-rel which links this post to 0 or more Tags. These links are automatically created ',
'and destroyed according to #hashtag values found (or not found) in the body text on create/update.'
              )
              #sortable => 1,
              #renderer => 'RA.ux.App.someJsFunc',
              #profiles => [],
          },
          ts => {
            header => 'Date/Time',
        # extra_properties get merged instead of replaced, so we don't clobber the rest of
        # the 'editor' properties
        #documentation => join('',
        #  'The official date/time of the post. Defaults (i.e. pre-populates) to the current time ',
        #  'in the add post form, however, the author is allowed to set a manual value by default'
        #),
            extra_properties => {
              editor => {
                value => sub { Rapi::Blog::Util->now_ts }
              }
              }
              #width => 100,
              #renderer => 'RA.ux.App.someJsFunc',
              #profiles => [],
          },
          author_id => {
            header => 'author_id',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            profiles => ['hidden'],
          },
          creator_id => {
            header => 'creator_id',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            profiles => ['hidden'],
          },
          updater_id => {
            header => 'updater_id',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            profiles => ['hidden'],
          },
          author => {
            header => 'Author',
            width  => 100,
    #documentation => join('',
    #  'The user listed as the author of the post. The author has special permissions to modify ',
    #  'and/or delete the post. Admin users are able to select any user as the author, but normal ',
    #  'users have no control over the setting other than to create new posts (which they will ',
    #  'automatically be set as the author)'
    #),
    #renderer => 'RA.ux.App.someJsFunc',
    #profiles => [],
            editor => {
              value => sub {
                return Rapi::Blog::Util->get_uid;
              }
            }
          },
          creator => {
            header        => 'Creator',
            allow_add     => \0,
            allow_edit    => \0,
            documentation => join( '',
'The user which created the post. This will be the same as the author unless an admin ',
              'manually selects a different author.' ),
            hidden => 1
              #width => 100,
              #renderer => 'RA.ux.App.someJsFunc',
              #profiles => [],
          },
          updater => {
            header        => 'Updater',
            allow_add     => \0,
            allow_edit    => \0,
            documentation => 'The last user to modify the post.',
            hidden        => 1
              #width => 100,
              #renderer => 'RA.ux.App.someJsFunc',
              #profiles => [],
          },
          size => {
            header     => 'Size of body',
            allow_add  => \0,
            allow_edit => \0,
            width      => 80,
            #renderer => 'RA.ux.App.someJsFunc',
            profiles      => ['filesize'],
            documentation => 'Size (in bytes) of the body content.'
          },
          comments => {
            header        => 'Comments',
            width         => 140,
            documentation => 'Comments on this post, including comments on comments.',
            #sortable => 1,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          direct_comments => {
            header => 'Direct Comments',
            width  => 140,
            documentation =>
'Comments on this post, limited to comments on the post itself (i.e. not subcomments)',
            hidden => 1
              #sortable => 1,
              #renderer => 'RA.ux.App.someJsFunc',
              #profiles => [],
          },
          custom_summary => {
            header => 'Custom Summary (optional)',
            width  => 200,
        #documentation => join('',
        #  'Summary text can be supplied here to be able to control the summary. If this field is ',
        #  'left blank, the summary will be autogenerated using a built-in algorithm'
        #),
            hidden => 1
              #renderer => 'RA.ux.App.someJsFunc',
              #profiles => [],
          },
          summary => {
            header     => 'Post Summary',
            width      => 160,
            allow_add  => 0,
            allow_edit => 0,
            hidden     => 1,
            documentation =>
              'Summary blurb on the post. Either uses Custom Summary or an auto-generated value',
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          hits => {
            header        => 'Recorded Hits',
            width         => 90,
            documentation => join( '',
              'Multi-rel to "Hits" table which records web requests to each post. Currently ',
              'relies on the scaffold view_wrapper to call [% Post.record_hit %]' ),
            hidden => 1
              #sortable => 1,
              #renderer => 'RA.ux.App.someJsFunc',
              #profiles => [],
          },
          tag_names => {
            header => 'Tag Names',
            width => 200,
            hidden => 1,
            allow_add => 0,
            allow_edit => 0,
            renderer => 'rablTagNamesColumnRenderer',
            #profiles => [],
          },
        },
      },
      PostTag => {
        display_column => 'id',
        title          => 'Post-Tag Link',
        title_multi    => 'Post-Tag Links',
        iconCls        => 'icon-node',
        multiIconCls   => 'icon-nodes',
        columns        => {
          id => {
            allow_add => 0,
            header    => 'Id',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          post_id => {
            header => 'post_id',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            profiles => ['hidden'],
          },
          tag_name => {
            header => 'Tag Name',
            width  => 120,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          post => {
            header => 'Post',
            width  => 200,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
        },
      },
      User => {
        display_column => 'username',
        title          => 'Blog User',
        title_multi    => 'Blog Users',
        iconCls        => 'icon-user',
        multiIconCls   => 'icon-users',
        columns        => {
          id => {
            allow_add => 0,
            header    => 'Id',
            width     => 65,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          username => {
            header => 'username',
            width  => 120,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          full_name => {
            header => 'Full Name',
            width  => 160,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          post_authors => {
            header => 'Author of',
            width  => 120,
            #sortable => 1,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          post_creators => {
            header => 'Creator of',
            width  => 120,
            #sortable => 1,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          post_updaters => {
            header => 'Last Updater of',
            width  => 120,
            #sortable => 1,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          admin => {
            header => 'admin',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          author => {
            header => 'author',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          comment => {
            header => 'comment',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          set_pw => {
            header   => 'Set Password*',
            width    => 130,
            editor   => { xtype => 'ra-change-password-field' },
            renderer => 'Ext.ux.RapidApp.renderSetPwValue'
          },
          comments => {
            header => 'Comments',
            width  => 130,
            #sortable => 1,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          image => {
            header => 'Image',
            profiles => ['cas_img'],
            width => 55,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          email => {
            header => 'email',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
        },
      },
      Comment => {
        display_column => 'id',
        title          => 'Comment',
        title_multi    => 'Comments',
        iconCls        => 'icon-comment',
        multiIconCls   => 'icon-comments',
        columns        => {
          id => {
            allow_add => 0,
            header    => 'Id',
            width     => 80,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          post_id => {
            header => 'post_id',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            profiles => ['hidden'],
          },
          user_id => {
            header => 'user_id',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            profiles => ['hidden'],
          },
          ts => {
            header => 'Timestamp',
            width  => 120,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
            extra_properties => {
              editor => {
                value => sub { Rapi::Blog::Util->now_ts }
              }
            }
          },
          body => {
            header => 'Comment body',
            width  => 180,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          comments => {
            header => 'Sub-comments',
            width  => 130,
            #sortable => 1,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          post => {
            header => 'Post',
            width  => 180,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          user => {
            header => 'Commenter',
            width  => 120,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
            editor => {
              value => sub {
                return Rapi::Blog::Util->get_uid;
              }
            }
          },
          parent_id => {
            header => 'parent_id',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            profiles => ['hidden'],
          },
          parent => {
            header => 'Replies to',
            width  => 120,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
        },
      },
      Hit => {
        display_column => 'id',
        title          => 'Hit',
        title_multi    => 'Hits',
        iconCls        => 'icon-world-go',
        multiIconCls   => 'icon-world-gos',
        columns        => {
          id => {
            allow_add => 0,
            header    => 'Id',
            width     => 60,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          post_id => {
            header => 'post_id',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            profiles => ['hidden'],
          },
          ts => {
            header => 'Request Timestamp',
            width  => 130,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          client_ip => {
            header => 'IP Addr',
            width  => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          client_hostname => {
            header => 'Hostname (if resolved)',
            hidden => 1,
            width  => 160,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          uri => {
            header => 'URI Accessed',
            width  => 250,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          method => {
            header => 'HTTP Method',
            width  => 90,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          user_agent => {
            header => 'User Agent String',
            width  => 250,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          referer => {
            header => 'Referer URL',
            width  => 250,
            hidden => 1
              #renderer => 'RA.ux.App.someJsFunc',
              #profiles => [],
          },
          serialized_request => {
            header     => 'Serialized Request',
            width      => 200,
            hidden     => 1,
            allow_add  => 0,
            allow_edit => 0,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          post => {
            header => 'Accessed Post',
            width  => 180,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
        },
      },
    }
  },

);

=head1 NAME

Rapi::Blog::Model::DB - Catalyst/RapidApp DBIC Schema Model

=head1 SYNOPSIS

See L<Rapi::Blog>

=head1 DESCRIPTION

L<Catalyst::Model::DBIC::Schema> Model using schema L<Rapi::Blog::DB>

=head1 GENERATED BY

Catalyst::Helper::Model::DBIC::Schema::ForRapidDbic - 0.65

=head1 AUTHOR

root

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
