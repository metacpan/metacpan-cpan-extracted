#
# This module is generated with gen.pl
# Do not modify.
#

package Net::OpenStack::Client::API::Identity::v3;

use strict;
use warnings;

use version;
our $VERSION = version->new("v3");

use Readonly;

Readonly our $API_DATA => {
    
    add_domain => {
        method => 'POST',
        endpoint => '/domains',
        
        
        options => {    
            'description' => {'path' => ['domain','description'],'type' => 'string'},
            'enabled' => {'path' => ['domain','enabled'],'type' => 'boolean'},
            'name' => {'path' => ['domain','name'],'type' => 'string'},
        },
    
    },
    
    add_project => {
        method => 'POST',
        endpoint => '/projects',
        
        
        options => {    
            'description' => {'path' => ['project','description'],'type' => 'string'},
            'domain_id' => {'path' => ['project','domain_id'],'type' => 'string'},
            'enabled' => {'path' => ['project','enabled'],'type' => 'boolean'},
            'name' => {'path' => ['project','name'],'type' => 'string'},
            'parent_id' => {'path' => ['project','parent_id'],'type' => 'string'},
        },
        result => '/project',
    
    },
    
    add_tag => {
        method => 'PUT',
        endpoint => '/projects/{project_id}/tags/{tag}',
        templates => ['project_id','tag'],
        
        
        options => {    
        },
    
    },
    
    catalog => {
        method => 'GET',
        endpoint => '/auth/catalog',
        
        
        options => {    
        },
        result => '/catalog',
    
    },
    
    delete_tag => {
        method => 'DELETE',
        endpoint => '/projects/{project_id}/tags/{tag}',
        templates => ['project_id','tag'],
        
        
        options => {    
        },
    
    },
    
    domain => {
        method => 'GET',
        endpoint => '/domains/{domain_id}',
        templates => ['domain_id'],
        
        
        options => {    
        },
        result => '/domain',
    
    },
    
    domains => {
        method => 'GET',
        endpoint => '/domains',
        
        
        options => {    
        },
        result => '/domains',
    
    },
    
    project => {
        method => 'GET',
        endpoint => '/projects/{project_id}',
        templates => ['project_id'],
        
        
        options => {    
        },
        result => '/project',
    
    },
    
    projects => {
        method => 'GET',
        endpoint => '/projects?domain_id=did&enabled=1&name=name&parent_id=pid',
        
        parameters => ['domain_id','enabled','name','parent_id'],
        
        options => {    
        },
        result => '/projects',
    
    },
    
    tag => {
        method => 'GET',
        endpoint => '/projects/{project_id}/tags/{tag}',
        templates => ['project_id','tag'],
        
        
        options => {    
        },
    
    },
    
    tags => {
        method => 'GET',
        endpoint => '/projects/{project_id}/tags',
        templates => ['project_id'],
        
        
        options => {    
        },
        result => '/tags',
    
    },
    
    tokens => {
        method => 'POST',
        endpoint => '/auth/tokens',
        
        
        options => {    
            'methods' => {'islist' => 1,'path' => ['auth','identity','methods'],'type' => 'string'},
            'password' => {'path' => ['auth','identity','password','user','password'],'type' => 'string'},
            'project_domain_name' => {'path' => ['auth','scope','project','domain','name'],'type' => 'string'},
            'project_name' => {'path' => ['auth','scope','project','name'],'type' => 'string'},
            'user_domain_name' => {'path' => ['auth','identity','password','user','domain','name'],'type' => 'string'},
            'user_name' => {'path' => ['auth','identity','password','user','name'],'type' => 'string'},
        },
        result => 'X-Subject-Token',
    
    },

};

1;
