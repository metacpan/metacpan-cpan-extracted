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
use DBIx::Class::Schema::Diff 1.05;

#<<<  tell perltidy not to mess with this
before 'setup' => sub {
  my $self = shift;

  my $db_path = $self->_get_sqlite_db_path 
    or die "Couldn't determine SQLite db path (currently only SQLite is supported)";

  unless ( -f $db_path ) {
    warn "  ** Auto-Deploy $db_path **\n";
    my $db = $self->_one_off_connect;
    $db->deploy;
    # Make sure the built-in uid:0 system account exists:
    $db->resultset('User')->find_or_create(
      { id => 0, username => '(system)', full_name => '[System Acount]', admin => 1 },
      { key => 'primary' }
    );
    # Need to insert the default rows:
    my @inserts = (
      q~INSERT INTO [preauth_action_type] VALUES('enable_account','Enable a disabled user account')~,
      q~INSERT INTO [preauth_action_type] VALUES('password_reset','Change a user password')~,
      q~INSERT INTO [preauth_action_type] VALUES('login','Single-use login')~,
      q~INSERT INTO [preauth_event_type] VALUES(1,'Valid',     'Pre-Authorization Action accessed and is valid')~,
      q~INSERT INTO [preauth_event_type] VALUES(2,'Invalid',   'Pre-Authorization Action exists but is invalid')~,
      q~INSERT INTO [preauth_event_type] VALUES(3,'Deactivate','Pre-Authorization Action deactivated')~,
      q~INSERT INTO [preauth_event_type] VALUES(4,'Executed',  'Pre-Authorization Action executed')~,
      q~INSERT INTO [preauth_event_type] VALUES(5,'Sealed',    'Action sealed - can no longer be accessed with key, except by admins')~
    );
    $db->storage->dbh->do($_) for (@inserts);
  }
  
  my ($DiffObj,$schemsum) = $self->_migrate_and_diff_deployed;
  
  my $fn = (reverse split(/\//,$db_path))[0];
  warn '  ** ' . __PACKAGE__ . " - loaded $fn [$schemsum]\n";

  my $diff = $DiffObj
    ->filter_out('*:relationships')
    ->filter_out('*:constraints')
    ->filter_out('*:isa')
    ->filter_out('*:columns/*._inflate_info')
    ->filter_out('*:columns/*._ic_dt_method')
    ->filter_out('*:columns/*.is_numeric') # this apparently can get set later on
    ->diff;

  if ($diff) {
    die join( "\n",
      '', '', '', '**** ' . __PACKAGE__ . ' - column differences found in deployed database! ****',
      '', 'Dump (DBIx::Class::Schema::Diff): ',
      Dumper($diff), '', '', '' );
  }
};

sub _get_sqlite_db_path {
  my $self = shift;
  
  # extract path from dsn because the app reaches in to set it
  my $dsn = $self->connect_info->{dsn};
  my ( $pre, $db_path ) = split( /\:SQLite\:/, $dsn, 2 );

  return $db_path
}


sub _migrate_and_diff_deployed {
  my ($self, $seen) = @_;
  $seen ||= {};
  
  my $DiffObj = $self->_diff_deployed_schema;

  my $schemsum = $DiffObj->_schema_diff->new_schema
    ->prune('isa')
    ->prune('relationships')
    ->prune('private_col_attrs')
    ->fingerprint;
    
  if($seen->{$schemsum}++) {
    die "looping/failing migrations detected! Already saw schema signature $schemsum";
  }

  $self->_migrate_for_schemsum($schemsum) 
    ? $self->_migrate_and_diff_deployed($seen)
    : ($DiffObj,$schemsum)
}

# Dynamic, signature-based migrations
sub _migrate_for_schemsum {
  my ($self, $schemsum) = @_;
  
  # Failsafe to only process for SQLite in this version
  my $db_path = $self->_get_sqlite_db_path or return 0;
  
  my $meth = join('_','','run','migrate',$schemsum);
  $meth =~ s/\-/\_/g;
  
  if($self->can($meth)) {
    warn "  ** detected known schema signature '$schemsum' -- running migration ...\n";
    
    my $Db = file($db_path);
    my $BkpDir = $Db->parent->subdir(join('.','','bkp',$Db->basename));
    my $Bkp = $BkpDir->file(join('.',$schemsum,'db'));
    
    warn join('',
      "    [backing up '",$Db->basename,"' to '",
      $Bkp->relative($Db->parent)->stringify,"']\n"
    );
    
    -d $BkpDir or $BkpDir->mkpath();
    $Bkp->spew(scalar $Db->slurp);
    
    warn "    ++ calling ->$meth():\n";

    $self->$meth or warn "  warning: migration method $meth did not return a true value ... \n";
    
    # We return true regardless to indicate that the migration was run:
    return 1;
  }
  else {
    # Unknown schema signature:
    return 0;
  }
}


###############################################################################
######################      SCHEMA MIGRATION METHODS      #####################
###############################################################################


######################################
###     Migration from  pre-v1     ###
######################################
# This is the migration from the last dev state before public 1.000 release... was
# never seen in the wild (this entry made for test/dev as we never expect to see it)
sub _run_migrate_schemsum_7ef8b36d22d6c7d {
  my $self = shift;
  
  my @statements = (
    'PRAGMA foreign_keys=off',
    'BEGIN TRANSACTION',
    
    'ALTER TABLE [post] RENAME TO [temp_post]',q~
CREATE TABLE [post] (
  [id]             INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  [name]           varchar(255) UNIQUE NOT NULL,
  [title]          varchar(255) DEFAULT NULL,
  [image]          varchar(255) DEFAULT NULL,
  [ts]             datetime NOT NULL,
  [create_ts]      datetime NOT NULL,
  [update_ts]      datetime NOT NULL,
  [author_id]      INTEGER NOT NULL,
  [creator_id]     INTEGER NOT NULL,
  [updater_id]     INTEGER NOT NULL,
  [published]      BOOLEAN NOT NULL DEFAULT 0,
  [publish_ts]     datetime DEFAULT NULL,
  [size]           INTEGER DEFAULT NULL,
  [tag_names]      text default NULL,
  [custom_summary] text default NULL,
  [summary]        text default NULL,
  [body]           text default '',
  
  FOREIGN KEY ([author_id]) REFERENCES [user]              ([id])   ON DELETE RESTRICT ON UPDATE CASCADE,
  FOREIGN KEY ([creator_id]) REFERENCES [user]             ([id])   ON DELETE RESTRICT ON UPDATE CASCADE,
  FOREIGN KEY ([updater_id]) REFERENCES [user]             ([id])   ON DELETE RESTRICT ON UPDATE CASCADE
)~, q~
INSERT INTO [post] SELECT
  [id],[name],[title],[image],[ts],[create_ts],[update_ts],[author_id],[creator_id],
  [updater_id],[published],[publish_ts],[size],null,[custom_summary],[summary],[body]
FROM [temp_post]
~,
 'DROP TABLE [temp_post]',
  
  
    'ALTER TABLE [user] RENAME TO [temp_user]', q~
CREATE TABLE [user] (
  [id]        INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  [username]  varchar(32) UNIQUE NOT NULL,
  [full_name] varchar(64) UNIQUE DEFAULT NULL,
  [image]     varchar(255) DEFAULT NULL,
  [email]     varchar(255) DEFAULT NULL,
  [admin]     BOOLEAN NOT NULL DEFAULT 0,
  [author]    BOOLEAN NOT NULL DEFAULT 0,
  [comment]   BOOLEAN NOT NULL DEFAULT 1
)~, q~
INSERT INTO [user] SELECT
  [id],[username],[full_name],null,null,[admin],[author],[comment]
FROM [temp_user]
~,
 'DROP TABLE [temp_user]',
 
 'COMMIT',
 'PRAGMA foreign_keys=on',
  );
  
  my $db = $self->_one_off_connect;
  
  $db->storage->dbh->do($_) for (@statements);
  
  # Must trigger biz-logic to update new tag_names column for every row
  # (note: calling this here causes some column attr 'is_numeric' to get applied, not sure why)
  for my $Post ($db->resultset('Post')->all) {
    $Post->make_column_dirty('body');
    $Post->update
  }
  
  return 1
}
######################################


######################################
###     Migration from v1.0000     ###
######################################

#sub _run_migrate_schemsum_8955354febf5675 {
#  my $self = shift;
#  scream('[1] WE WOULD RUN MIGRATION FOR schemsum-8955354febf5675 !!!');
#}

# This is the first public migration, adds categories
sub _run_migrate_schemsum_8955354febf5675 {
  my $self = shift;
  
  my @statements = (
    'PRAGMA foreign_keys=off',
    'BEGIN TRANSACTION',q~
CREATE TABLE [category] (
  [name] varchar(64) PRIMARY KEY NOT NULL,
  [description] varchar(1024) DEFAULT NULL
)~,

q~CREATE TABLE [post_category] (
  [id]            INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  [post_id]       INTEGER NOT NULL,
  [category_name] varchar(64) NOT NULL,
  
  FOREIGN KEY ([post_id])       REFERENCES [post] ([id])         ON DELETE CASCADE  ON UPDATE CASCADE,
  FOREIGN KEY ([category_name]) REFERENCES [category] ([name]) ON DELETE RESTRICT ON UPDATE RESTRICT
)~,

     'COMMIT',
     'PRAGMA foreign_keys=on',
  );
  
  my $db = $self->_one_off_connect;
  
  $db->storage->dbh->do($_) for (@statements);
  
  return 1
}
######################################


######################################
###     Migration from v1.0101     ###
######################################
# This is the second public migration from the schema as of v1.0101 release... 
sub _run_migrate_schemsum_6c99c16bdcb0fab {
  my $self = shift;
  
  my @statements = (
    'PRAGMA foreign_keys=off',
    'BEGIN TRANSACTION',
    
q~CREATE TABLE [section] (
  [id] INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  [name] varchar(64) NOT NULL,
  [description] varchar(1024) DEFAULT NULL,
  [parent_id] INTEGER DEFAULT NULL,
  
  FOREIGN KEY ([parent_id]) REFERENCES [section] ([id]) ON DELETE CASCADE ON UPDATE CASCADE
)~,
'CREATE UNIQUE INDEX [unique_subsection] ON [section] ([parent_id],[name])',

    'ALTER TABLE [post] RENAME TO [temp_post]',q~
CREATE TABLE [post] (
  [id] INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  [name] varchar(255) UNIQUE NOT NULL,
  [title] varchar(255) DEFAULT NULL,
  [image] varchar(255) DEFAULT NULL,
  [ts] datetime NOT NULL,
  [create_ts] datetime NOT NULL,
  [update_ts] datetime NOT NULL,
  [author_id] INTEGER NOT NULL,
  [creator_id] INTEGER NOT NULL,
  [updater_id] INTEGER NOT NULL,
  [section_id] INTEGER DEFAULT NULL,
  [published] BOOLEAN NOT NULL DEFAULT 0,
  [publish_ts] datetime DEFAULT NULL,
  [size] INTEGER DEFAULT NULL,
  [tag_names] text default NULL,
  [custom_summary] text default NULL,
  [summary] text default NULL,
  [body] text default '',
  
  FOREIGN KEY ([author_id])  REFERENCES [user]    ([id]) ON DELETE RESTRICT    ON UPDATE CASCADE,
  FOREIGN KEY ([creator_id]) REFERENCES [user]    ([id]) ON DELETE RESTRICT    ON UPDATE CASCADE,
  FOREIGN KEY ([updater_id]) REFERENCES [user]    ([id]) ON DELETE RESTRICT    ON UPDATE CASCADE,
  FOREIGN KEY ([section_id]) REFERENCES [section] ([id]) ON DELETE SET DEFAULT ON UPDATE CASCADE
)~, q~
INSERT INTO [post] SELECT
  [id],[name],[title],[image],[ts],[create_ts],[update_ts],[author_id],[creator_id],
  [updater_id],null,[published],[publish_ts],[size],[tag_names],[custom_summary],[summary],[body]
FROM [temp_post]
~,
 'DROP TABLE [temp_post]',
 
q~CREATE TABLE [trk_section_posts] (
  [id]            INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  [section_id]    INTEGER NOT NULL,
  [post_id]       INTEGER NOT NULL,
  [depth]         INTEGER NOT NULL,
  
  FOREIGN KEY ([section_id]) REFERENCES [section] ([id]) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY ([post_id])    REFERENCES [post] ([id])    ON DELETE CASCADE ON UPDATE CASCADE
)~,

q~CREATE TABLE [trk_section_sections] (
  [id]            INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  [section_id]    INTEGER NOT NULL,
  [subsection_id] INTEGER NOT NULL,
  [depth]         INTEGER NOT NULL,
  
  FOREIGN KEY ([section_id])    REFERENCES [section] ([id]) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY ([subsection_id]) REFERENCES [section] ([id]) ON DELETE CASCADE ON UPDATE CASCADE
)~, 
 
 'COMMIT',
 'PRAGMA foreign_keys=on',
  );
  
  my $db = $self->_one_off_connect;
  
  $db->storage->dbh->do($_) for (@statements);
 
  return 1
}
######################################


######################################
###     Migration from v1.0200     ###
######################################
sub _run_migrate_schemsum_fea65238f92786e {
  my $self = shift;
  
# All this just so we can change hit.post_id from not null to nullable:
my @modify_hit = (
 'PRAGMA foreign_keys=off', 'BEGIN TRANSACTION',
  
 'ALTER TABLE [hit] RENAME TO [temp_hit]',q~
CREATE TABLE [hit] (
  [id] INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  [post_id] INTEGER,
  [ts] datetime NOT NULL,
  [client_ip] varchar(16),
  [client_hostname] varchar(255),
  [uri] varchar(512),
  [method] varchar(8),
  [user_agent] varchar(1024),
  [referer] varchar(512),
  [serialized_request] text,
  
  FOREIGN KEY ([post_id])   REFERENCES [post] ([id])    ON DELETE CASCADE ON UPDATE CASCADE
)~, q~
INSERT INTO [hit] 
 SELECT [id],[post_id],[ts],[client_ip],[client_hostname],[uri], [method],[user_agent],[referer],[serialized_request]
 FROM [temp_hit]
~,
 'DROP TABLE [temp_hit]',
 
 'COMMIT', 'PRAGMA foreign_keys=on'
);
  
  
  my @statements = (
  
    @modify_hit,
  
    'ALTER TABLE [user] ADD COLUMN [disabled] BOOLEAN NOT NULL DEFAULT 0',
    
    q~CREATE TABLE [preauth_action_type] (
      [name] varchar(16) PRIMARY KEY NOT NULL,
      [description] varchar(1024) DEFAULT NULL
    )~,
    q~INSERT INTO [preauth_action_type] VALUES('enable_account','Enable a disabled user account')~,
    q~INSERT INTO [preauth_action_type] VALUES('password_reset','Change a user password')~,

    q~CREATE TABLE [preauth_action] (
      [id] INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      [type] varchar(16) NOT NULL,
      [active] BOOLEAN NOT NULL DEFAULT 1,
      [sealed] BOOLEAN NOT NULL DEFAULT 0,
      [create_ts] datetime NOT NULL,
      [expire_ts] datetime NOT NULL,
      [user_id] INTEGER,
      [auth_key] varchar(128) UNIQUE NOT NULL,
      [json_data] text,
      
      FOREIGN KEY ([type]) REFERENCES [preauth_action_type] ([name]) ON DELETE CASCADE ON UPDATE CASCADE,
      FOREIGN KEY ([user_id]) REFERENCES [user] ([id]) ON DELETE CASCADE ON UPDATE CASCADE
    )~,
    
    q~CREATE TABLE [preauth_event_type] (
      [id]          INTEGER PRIMARY KEY NOT NULL,
      [name]        varchar(16) UNIQUE NOT NULL,
      [description] varchar(1024) DEFAULT NULL
    )~,
    q~INSERT INTO [preauth_event_type] VALUES(1,'Valid',     'Pre-Authorization Action accessed and is valid')~,
    q~INSERT INTO [preauth_event_type] VALUES(2,'Invalid',   'Pre-Authorization Action exists but is invalid')~,
    q~INSERT INTO [preauth_event_type] VALUES(3,'Deactivate','Pre-Authorization Action deactivated')~,
    q~INSERT INTO [preauth_event_type] VALUES(4,'Executed',  'Pre-Authorization Action executed')~,
    q~INSERT INTO [preauth_event_type] VALUES(5,'Sealed',    'Action sealed - can no longer be accessed with key, except by admins')~,
    
    q~CREATE TABLE [preauth_action_event] (
      [id]        INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      [ts]        datetime NOT NULL,
      [type_id]   INTEGER NOT NULL,
      [action_id] INTEGER NOT NULL,
      [hit_id]    INTEGER,
      [info]      text,
      
      FOREIGN KEY ([type_id])   REFERENCES [preauth_event_type] ([id]) ON DELETE RESTRICT ON UPDATE CASCADE,
      FOREIGN KEY ([action_id]) REFERENCES [preauth_action]     ([id]) ON DELETE RESTRICT ON UPDATE CASCADE,
      FOREIGN KEY ([hit_id])    REFERENCES [hit]                ([id]) ON DELETE RESTRICT ON UPDATE CASCADE
    )~
    
  );
  
  my $db = $self->_one_off_connect;
  
  $db->storage->dbh->do($_) for (@statements);
  
  return 1
}
######################################



###############################################################################
######################       END MIGRATION METHODS        #####################
###############################################################################



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
    menu_require_role => 'administrator',
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
        require_role => 'administrator'
      },
      PreauthAction      => { require_role => 'administrator' },
      PreauthActionEvent => { require_role => 'administrator' },
      PreauthActionType  => { require_role => 'administrator' },
      PreauthEventType   => { require_role => 'administrator' },
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
            header => 'Posts with Tag',
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
            header => 'Body',
            hidden => 1,
            width  => 400,
            #renderer => 'RA.ux.App.someJsFunc',
            profiles      => ['markdown'],
            documentation => 'The main content body of the post stored in Markdown/HTML format'
          },
          post_tags => {
            header       => 'Post/Tag Links',
            width        => 160,
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
            width         => 135,
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
            header     => 'Tag Names',
            width      => 200,
            hidden     => 1,
            allow_add  => 0,
            allow_edit => 0,
            renderer   => 'rablTagNamesColumnRenderer',
            #profiles => [],
          },
          post_categories => {
            header => 'Post/Category Links',
            width => 180,
            hidden => 1,
            #sortable => 1,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          categories => {
            header => 'Categories',
            width  => 180,
            #sortable => 1,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          section_id => {
            header => 'section_id',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            profiles => ['hidden'],
          },
          section => {
            header => 'Section',
            width  => 140,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          trk_section_posts => {
            header => 'Track Section-Posts',
            width => 180,
            hidden => 1,
            #sortable => 1,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
        },
      },
      PostTag => {
        display_column => 'id',
        title          => 'Post-Tag Link',
        title_multi    => 'Post-Tag Links',
        iconCls        => 'icon-node',
        multiIconCls   => 'icon-logic-and-blue',
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
            header => 'Tag',
            width  => 160,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          post => {
            header => 'Post',
            width  => 350,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
        },
      },
      User => {
        display_column => 'username',
        title          => 'User Account',
        title_multi    => 'User Accounts',
        iconCls        => 'icon-user',
        multiIconCls   => 'icon-users',
        columns        => {
          id => {
            allow_add => 0,
            header    => 'Id',
            width     => 45,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          username => {
            header => 'Username',
            width  => 120,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          full_name => {
            header => 'Full Name',
            width  => 150,
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
            hidden   => 1,
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
            header   => 'Image',
            profiles => ['cas_img'],
            width    => 55,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          email => {
            header => 'E-Mail',
            width => 180,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          disabled => {
            header => 'disabled',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          preauth_actions => {
            header => 'Pre Authorizations',
            hidden => 1
            #width => 100,
            #sortable => 1,
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
            width     => 65,
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
          preauth_action_events => {
            header => 'Pre-Auth Events',
            hidden => 1,
            #width => 100,
            #sortable => 1,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
        },
      },
      Category => {
        display_column => 'name',
        title          => 'Category',
        title_multi    => 'Categories',
        iconCls        => 'icon-image',
        multiIconCls   => 'icon-images',
        columns        => {
          name => {
            header => 'Name',
            width  => 140,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          description => {
            header => 'Description',
            width  => 280,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          post_categories => {
            header => 'Posts in Category',
            width  => 190,
            #sortable => 1,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
        },
      },
      PostCategory => {
        display_column => 'id',
        title          => 'Post-Category Link',
        title_multi    => 'Post-Category Links',
        iconCls        => 'icon-node',
        multiIconCls   => 'icon-logic-and',
        columns        => {
          id => {
            allow_add => 0,
            header    => 'Id',
            width     => 45,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          post_id => {
            header => 'post_id',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            profiles => ['hidden'],
          },
          category_name => {
            header => 'Category',
            width => 180,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [ 'hidden' ],
          },
          post => {
            header => 'Post',
            width => 350,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
        },
      },
      Section => {
        display_column => 'name',
        title          => 'Section',
        title_multi    => 'Sections',
        iconCls        => 'icon-element',
        multiIconCls   => 'icon-chart-organisation',
        columns        => {
          id => {
            allow_add => 0,
            header    => 'Id',
            width     => 45,
            hidden    => 1,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          parent_id => {
            header => 'parent_id',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            profiles => ['hidden'],
          },
          name => {
            header => 'Name',
            width  => 180,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          description => {
            header => 'Description',
            width  => 280,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          parent => {
            header => 'Parent Section',
            width  => 160,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          posts => {
            header => 'Posts',
            width  => 120,
            #sortable => 1,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          sections => {
            header => 'Sub-sections (one-level)',
            width  => 150,
            #sortable => 1,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          trk_section_posts => {
            header => 'Posts in Section/Sub-sections',
            width => 180,
            #sortable => 1,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          trk_section_sections_sections => {
            header => 'Sub-sections (deep)',
            width => 200,
            #sortable => 1,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          trk_section_sections_subsections => {
            header => 'All Parent Sections',
            width => 200,
            #sortable => 1,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
        },
      },
      TrkSectionPost => {
        display_column => 'id',
        title          => 'Section-Post Link',
        title_multi    => 'Section-Post Links',
        iconCls        => 'icon-table-relationship',
        multiIconCls   => 'icon-table-relationship',
        columns        => {
          id => {
            allow_add => 0,
            header    => 'Id',
            width     => 45,
            hidden    => 1,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          section_id => {
            header => 'section_id',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            profiles => ['hidden'],
          },
          post_id => {
            header => 'post_id',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            profiles => ['hidden'],
          },
          depth => {
            header => 'Depth',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          post => {
            header => 'Post',
            width => 300,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          section => {
            header => 'Section',
            width => 150,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
        },
      },
      TrkSectionSection => {
        display_column => 'id',
        title          => 'Section-Subsection Link',
        title_multi    => 'Section-Subsection Links',
        iconCls        => 'icon-table-relationship',
        multiIconCls   => 'icon-table-relationship',
        columns        => {
          id => {
            allow_add => 0,
            header    => 'Id',
            width     => 45,
            hidden    => 1,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          section_id => {
            header => 'section_id',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            profiles => ['hidden'],
          },
          subsection_id => {
            header => 'subsection_id',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            profiles => ['hidden'],
          },
          depth => {
            header => 'Depth',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          section => {
            header => 'Section',
            width => 180,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          subsection => {
            header => 'Sub-section',
            width => 180,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
        },
      },
      PreauthAction => {
        display_column => 'id',
        title          => 'Pre Authorization',
        title_multi    => 'Pre Authorizations',
        iconCls        => 'icon-preauth-action',
        multiIconCls   => 'icon-preauth-actions',
        columns        => {
          id => {
            allow_add => 0,
            header    => 'Id',
            width     => 55,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          type => {
            header => 'Type',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          active => {
            header => 'Active?',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          sealed => {
            header => 'Sealed?',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          create_ts => {
            header => 'Created',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          expire_ts => {
            header => 'Expires at',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          user_id => {
            header => 'user_id',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            profiles => ['hidden'],
          },
          auth_key => {
            header => 'Auth Key',
            width => 250,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          json_data => {
            header => 'JSON Data',
            width => 300,
            hidden => 1,
            profiles => ['monotext'],
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          user => {
            header => 'User',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          preauth_action_events => {
            header => 'Events',
            #width => 100,
            #sortable => 1,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
        },
      },
      PreauthActionType => {
        display_column => 'name',
        title          => 'Pre-Auth Type',
        title_multi    => 'Pre-Auth Types',
        iconCls        => 'icon-preauth-action-type',
        multiIconCls   => 'icon-preauth-action-types',
        columns        => {
          name => {
            header => 'Name',
            width => 150,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          description => {
            header => 'Description',
            width => 300,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          preauth_actions => {
            header => 'Pre Authorizations',
            #width => 100,
            #sortable => 1,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
        },
      },
      PreauthActionEvent => {
        display_column => 'id',
        title          => 'Pre-Auth Event',
        title_multi    => 'Pre-Auth Events',
        iconCls        => 'icon-preauth-event',
        multiIconCls   => 'icon-preauth-events',
        columns        => {
          id => {
            allow_add => 0,
            header    => 'Id',
            width => 55,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          ts => {
            header => 'Timestamp',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          type_id => {
            header => 'type_id',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            profiles => ['hidden'],
          },
          action_id => {
            header => 'action_id',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            profiles => ['hidden'],
          },
          hit_id => {
            header => 'hit_id',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            profiles => ['hidden'],
          },
          info => {
            header => 'Info',
            width => 380,
            profiles => ['monotext']
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          action => {
            header => 'Action',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          hit => {
            header => 'Hit',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          type => {
            header => 'Event Type',
            width => 120,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
        },
      },
      PreauthEventType => {
        display_column => 'name',
        title          => 'Pre-Auth Event Type',
        title_multi    => 'Pre-Auth Event Types',
        iconCls        => 'icon-preauth-event-type',
        multiIconCls   => 'icon-preauth-event-types',
        columns        => {
          id => {
            allow_add => 0,
            header    => 'Id',
            width     => 40,
            hidden => 1
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          name => {
            header => 'Name',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          description => {
            header => 'Description',
            width => 380,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          preauth_action_events => {
            header => 'Events',
            width => 160,
            #sortable => 1,
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
