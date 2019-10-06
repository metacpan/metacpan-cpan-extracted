package Rapi::Blog::Module::NavTree;
use strict;
use warnings;
use Moose;
extends 'Catalyst::Plugin::RapidApp::NavCore::NavTree';

use RapidApp::Util qw(:all);
use Rapi::Blog::Util;


around 'TreeConfig' => sub {
  my ($orig,$self,@args) = @_;
  
  my $items = $self->$orig(@args);
  
  return [@$items, @{$self->_rapi_blog_extra_navtree_nodes}]
};


sub _rapi_blog_extra_navtree_nodes {
  my $self = shift;
  
  my $items = [
    {
      text     => 'Content',
      iconCls  => 'icon-folder-table',
      expanded => \1,
      children => [
        {
          text    => 'Posts',
          iconCls => 'icon-posts',
          url     => '/adm/main/db/db_post',
          leaf    => \1
        },
        {
          text    => 'Comments',
          iconCls => 'icon-comments',
          url     => '/adm/main/db/db_comment',
          leaf    => \1 
        },
      ]
    },
    {
      text    => 'Taxonomies',
      iconCls => 'icon-fa-cogs',
      cls		=> 'pad-top-4px',
      expanded => \1,
      children => [
        {
          text    => 'Tags',
          iconCls => 'icon-tags-blue',
          url     => '/adm/main/db/db_tag',
          leaf    => \1
        },
        {
          text    => 'Categories',
          iconCls => 'icon-images',
          url     => '/adm/main/db/db_category',
          leaf    => \1
        },
        {
          text    => 'Sections (Tree)',
          iconCls => 'icon-sitemap-color',
          url     => '/adm/sections',
          leaf    => \1
        },
        {
          text    => 'Sections (Grid)',
          iconCls => 'icon-chart-organisation',
          url     => '/adm/main/db/db_section',
          leaf    => \1
        },
      ]
    },
    {
      text    => 'Index &amp; tracking tables',
      iconCls => 'icon-database-gear',
      children => [
        {
          text    => 'Post-Category Links',
          iconCls => 'icon-logic-and',
          url     => '/adm/main/db/db_postcategory',
          leaf    => \1  
        },
        {
          text    => 'Post-Tag Links',
          iconCls => 'icon-logic-and-blue',
          url     => '/adm/main/db/db_posttag',
          leaf    => \1 
        },
        {
          text    => 'Section-Post Links',
          iconCls => 'icon-table-relationship',
          url     => '/adm/main/db/db_trksectionpost',
          leaf    => \1 
        },
        {
          text    => 'Section-Subsection Links',
          iconCls => 'icon-table-relationship',
          url     => '/adm/main/db/db_trksectionsection',
          leaf    => \1 
        },
      ]
    },
    {
      text    => 'Stats &amp; settings',
      iconCls => 'icon-group-gear',
      require_role => 'administrator',
      expanded => \1,
      children => [
        {
          text    => 'Hits',
          iconCls => 'icon-world-gos',
          url     => '/adm/main/db/db_hit',
          leaf    => \1 
        },
        {
          text    => 'User Sessions',
          iconCls => 'ra-icon-environment-network',
          url     => '/adm/main/db/rapidapp_coreschema_session',
          leaf    => \1 
        },
        {
          text    => 'Pre Authorization tables',
          iconCls => "icon-key1",
          require_role => 'administrator',
          expanded => \1,
          children => [
            {
              text    => "Pre Authorizations",
              iconCls => "icon-preauth-actions",
              url     => '/adm/main/db/db_preauthaction',
              leaf    => \1
            },
            {
              text    => "Pre-Auth Events",
              iconCls => "icon-preauth-event",
              url     => '/adm/main/db/db_preauthactionevent',
              leaf    => \1
            },
            {
              text    => "Pre-Auth Types",
              iconCls => "icon-preauth-action-types",
              url     => '/adm/main/db/db_preauthactiontype',
              leaf    => \1
            },
            {
              text    => "Pre-Auth Event Types",
              iconCls => "icon-preauth-event-types",
              url     => '/adm/main/db/db_preautheventtype',
              leaf    => \1
            },
          ]
        },
        {
          text    => 'User Saved Views',
          iconCls => 'ra-icon-data-views',
          url     => '/adm/main/db/rapidapp_coreschema_savedstate',
          leaf    => \1  
        },
        
        {
          text    => 'Default Views by Source',
          iconCls => 'ra-icon-data-preferences',
          url     => '/adm/main/db/rapidapp_coreschema_defaultview',
          leaf    => \1 
        },
        {
          text    => 'Roles',
          iconCls => 'ra-icon-user-prefs',
          url     => '/adm/main/db/rapidapp_coreschema_role',
          leaf    => \1 
        },
      ]
    },
     {
      text    => 'User Accounts',
      iconCls => 'icon-users',
      url     => '/adm/main/db/db_user',
      leaf    => \1  
    },
  ];


  return $items;
}




1;
