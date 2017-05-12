package MyExampleApp::Parameters; 

######################################
# This module would be built for a
# particular application to use 
######################################

use strict;
use warnings;                         # Always good ideas in your code 

use ModPerl::ParamBuilder;            # Bring in the module 

use base qw( ModPerl::ParamBuilder ); # Set it up so MyExampleApp::Parameters
                                      # inherits from ModPerl::ParamBuilder
                                      

# Get a parameter building object. Note you could also use the 
# string 'MyExampleApp::Parameters' instead of __PACKAGE__ , but __PACKAGE__
# ensures that you don't end up renaming this module and forget to change
# it here
my $builder = ModPerl::ParamBuilder->new( __PACKAGE__ ); 

# Build a simple one argument parameter
# httpd.conf usage   ; PageTemplate foo.tt 
# Configuration hash : PageTemplate => 'foo.tt'
$builder->param( 'PageTemplate' ); 

# Build a simple On/Off directive
# httpd.conf usage   : AutoCommit On 
# Configuration hash : AutoCommit => 1 
$builder->on_off( 'AutoCommit' ); 

# Build a simple Yes/No directive 
# httpd.conf usage   : CacheData No
# Configuration hash : CacheData => 0 
$builder->yes_no( 'CacheData' ); 

# Build a directive that takes one mandatory argument and one optional. 
# httpd.conf usage    : Foo Bar Baz   
# where 'Baz' is optional 
# Cconfiguration hash : Foo => [ 'Bar', 'Baz' ]
$builder->param({
                   name => 'Foo', 
                   take => 'one_plus', 
});

# Build a directive that takes one mandatory argument and a list. 
# httpd.conf usage    : AddProcessingType textual text/xml text/css 
# Configuration hash  : 
#   AddProcessingType => { 'textual' } => [ 'text/xml', 'text/css' ]
#                  
$builder->param({
                   name => 'AddProcessingType',
                   take => 'one_plus_list',
}); 


$builder->load; 

1; 
