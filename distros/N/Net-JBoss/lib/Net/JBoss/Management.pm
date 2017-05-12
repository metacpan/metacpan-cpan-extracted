package Net::JBoss::Management;

use 5.010;
use Carp;
use URL::Encode qw /url_encode_utf8/;
use Moo;

with 'Net::JBoss';

=head1 NAME

Net::JBoss::Management - Bindings for JBoss Management API

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';


=head1 SYNOPSIS

use Net::JBoss::Management;

 my %con = (
            username                => 'admin',
            password                => 'password',
            server                  => 'jboss1.example.com',
            port                    => 9443,                    #optional, default is 9990
            ssl                     => 'on',                    #optional, default is 'off'
            ssl_verify              => 'yes',                   #optional, default is 'no'
            realm                   => 'ManagementRealmHTTPS'   #optional, default is 'ManagementRealm'
 );
 
 my $jboss              = Net::JBoss::Management->new(%con);
 
 my $state              = $jboss->get_state();
 my $jvm_usage          = $jboss->get_jvm_usage();
 my $runtime_stats      = $jboss->get_runtime_stats();
 my $deploy_info        = $jboss->get_deployment_info();
 my $app_runtime_stats  = $jboss->get_app_runtime_stats('hawtio.war');
 my $runtime_details    = $jboss->get_runtime_details();
 my $app_status         = $jboss->get_app_status('hawtio.war');
 my $active_session     = $jboss->get_active_sessions('hawtio.war');
 my $server_env         = $jboss->get_server_env();
 my $datasources        = $jboss->get_datasources();
 my $test               = $jboss->test_con_pool('ExampleDS');
 my $pool_stats         = $jboss->get_ds_pool_stats('java:jboss/datasources/jboss_Pool');
 my $enable_pool_stats  = $jboss->set_ds_pool_stats('java:jboss/datasources/jboss_Pool', 'true');
 my $disable_pool_stats = $jboss->set_ds_pool_stats('java:jboss/datasources/jboss_Pool', 'false');
 my $min_pool_size      = $jboss->set_ds_pool_size('min', 'java:jboss/datasources/jboss_Pool', 20);
 my $max_pool_size      = $jboss->set_ds_pool_size('max', 'java:jboss/datasources/jboss_Pool', 50);
 my $jndi               = $jboss->get_jndi();
 my $loglevel           = $jboss->get_log_level('CONSOLE');
 my $loglevel           = $jboss->set_log_level('CONSOLE', 'ERROR');
 my $reload             = $jboss->reload();
 my $shutdown           = $jboss->shutdown();
 my $restart            = $jboss->restart();
 
=head1 Attributes

 Other attributes is also inherited from JBoss.pm
 Check 'perldoc Net::JBoss' for detail
 
 notes :
 ro                     = read only, can be specified only during initialization
 rw                     = read write, user can set this attribute
 rwp                    = read write protected, for internal class
 
 management_url         = (ro) store default management url path
 reload_time            = (rw) set wait time (in seconds) to check the server state after reload is fired (default 10s)

=cut

has 'management_url'    => ( is => 'ro', default => '/management' );
has 'reload_time'       => ( is => 'rw', default => 10 );

=head1 SUBROUTINES/METHODS

=head2 BUILD

 The Constructor, build logging, call pass_log_obj method
 Build final url
=cut

sub BUILD {
    my $self = shift;
    
    $self->pass_log_obj;

    my $url  = $self->base_url . $self->management_url;
    $self->_set_url($url);
    
    $self->log->debug($url);
}

=head2 get_state

 return server state
 my $state = $jboss->state();
    
=cut

sub get_state {
    my $self = shift;
     
    $self->_set_http_post(1);
    
    if ($self->http_post) {
        $self->_set_post_json('{"operation":"read-attribute","name":"server-state","json.pretty":1}');
        $self->log->debug($self->post_json);
    }
    else {
        $self->_set_resource_url('/?operation=attribute&name=server-state&json.pretty');
        $self->log->debug($self->resource_url);
    }
    
    $self->get_api_response();
}

=head2 get_jvm_usage

 return jvm usage
 my $jvm_usage = $jboss->get_jvm_usage();
    
=cut

sub get_jvm_usage {
    my $self = shift;
    
    $self->_set_resource_url('/core-service/platform-mbean/type/memory?operation=resource&include-runtime=true&json.pretty');
    $self->log->debug($self->resource_url);
    
    $self->get_api_response();
}

=head2 get_runtime_stats

 get HTTP connector runtime statistics
 my $runtime_stats = $jboss->runtime_stats();
    
=cut

sub get_runtime_stats {
    my $self = shift;
    
    $self->_set_resource_url('/subsystem/web/connector/http?operation=resource&include-runtime=true&recursive&json.pretty');
    $self->log->debug($self->resource_url);
    
    $self->get_api_response();
}

=head2 get_runtime_details

 get JBoss runtime details
 my $runtime_details = $jboss->get_runtime_details();
    
=cut

sub get_runtime_details {
    my $self = shift;
    
    $self->_set_resource_url('/core-service/platform-mbean/type/runtime?operation=resource&include-runtime=true&json.pretty');
    $self->log->debug($self->resource_url);
    
    $self->get_api_response();
}

=head2 get_app_runtime_stats

 get application runtime statistics
 my $app_runtime_stats = $jboss->get_app_runtime_stats('hawtio.war');
    
=cut

sub get_app_runtime_stats {
    my $self = shift;
    
    my $app_name    = shift; 
    croak "web application name is required"
        unless $app_name;
    
    $self->_set_http_post(1);
    
    my $json = qq|{"operation":"read-resource","recursive":"true", "include-runtime":"true", "address":["deployment","$app_name"], "json.pretty":1}|;
    
    $self->_set_post_json($json);
    
    $self->log->debug($self->post_json);
    $self->get_api_response();
}

=head2 get_server_env

 get JBoss server environment
 my $server_env = $jboss->get_server_env();
    
=cut

sub get_server_env {
    my $self = shift;
    
    $self->_set_resource_url('/core-service/server-environment?operation=resource&include-runtime=true&json.pretty');
    $self->log->debug($self->resource_url);
    
    $self->get_api_response();
}

=head2 get_datasources 

 get data source and driver
 my $datasources = $jboss->get_datasources();
    
=cut

sub get_datasources {
    my $self = shift;
    
    $self->_set_resource_url('/subsystem/datasources/?operation=resource&recursive=true&json.pretty');
    $self->log->debug($self->resource_url);
    
    $self->get_api_response();
}

=head2 get_app_status

 get web application status
 web application name is required
 my $app_status = $jboss->get_app_status('hawtio.war');
    
=cut

sub get_app_status {
    my $self        = shift;
    
    my $app_name    = shift; 
    croak "web application name is required"
        unless $app_name;
    
    $self->_set_resource_url(qq|/deployment/$app_name?operation=attribute&name=status&json.pretty|);
    $self->log->debug($self->resource_url);
    
    $self->get_api_response();
}

=head2 get_active_sessions

 get web application active sessions
 web application name is required
 my $active_session = $jboss->get_active_sessions('hawtio.war');
    
=cut

sub get_active_sessions {
    my $self        = shift;
    
    my $app_name    = shift; 
    croak "web application name is required"
        unless $app_name;
    
    $self->_set_resource_url(qq|/deployment/$app_name/subsystem/web?operation=attribute&name=active-sessions&json.pretty|);
    $self->log->debug($self->resource_url);
    
    $self->get_api_response();
}

=head2 get_ds_pool_stats

 get usage metric of connection pooling of the data source
 my $pool_stats = $jboss->get_ds_pool_stats('java:jboss/datasources/jboss_Pool');

=cut

sub get_ds_pool_stats {
    my $self        = shift;
    my $ds_name     = shift; 
    
    croak "data source name is required"
        unless $ds_name;
    $ds_name = url_encode_utf8($ds_name);
    $self->log->debug("encode : $ds_name");
    
    if ($self->is_xa eq 'no')
    {
        $self->_set_resource_url(qq|/subsystem/datasources/data-source/$ds_name/statistics/pool/?operation=resource&recursive=true&include-runtime=true&json.pretty|);
    }
    elsif ($self->is_xa eq 'yes')
    {
        $self->_set_resource_url(qq|/subsystem/datasources/xa-data-source/$ds_name/statistics/pool/?operation=resource&recursive=true&include-runtime=true&json.pretty|);
    }

    $self->log->debug($self->resource_url);
    
    $self->get_api_response();   
}

=head2 test_con_pool

 test datasource connection polling
 my $test = $jboss->test_con_pool('ExampleDS');

=cut

sub test_con_pool {
    my $self        = shift;
    
    my $ds_name     = shift; 
    
    croak "data source name is required"
        unless $ds_name;
    
    $self->_set_http_post(1);
    
    my $json = qq|{"operation":"test-connection-in-pool","address":[{"subsystem":"datasources"},{"data-source":"$ds_name"}],"json.pretty":1}|;
                    
    $self->_set_post_json($json);
    
    $self->log->debug($self->post_json);
    $self->get_api_response();   
}

=head2 set_ds_pool_size

 set data source min/max pool size
 my $min_pool_size = $jboss->set_ds_pool_size('min', 'java:jboss/datasources/jboss_Pool', 20);
 my $max_pool_size = $jboss->set_ds_pool_size('max', 'java:jboss/datasources/jboss_Pool', 20);

=cut

sub set_ds_pool_size {
    my $self = shift;
    
    my ($name, $ds_name, $size)    = @_; 
    
    croak "min/max is required"
        unless $name;
        
    croak "$name is not valid value, valid argument is min|max"
        unless $name =~ /^\b(min|max)\b/;
    
    croak "data source name is required"
        unless $ds_name;
        
    croak "size is required and must be positive integer"
        unless $size =~ /^\d+$/;
        
    croak "size must be greater than zero"
        unless $size > 0;
    
    $self->_set_http_post(1);
    
    my $json;
    
    if ($name eq 'min') {
        $json = qq|{"operation":"write-attribute","address":[{"subsystem":"datasources"},{"data-source":"$ds_name"}],"name":"min-pool-size","value":$size,"json.pretty":1}|;      
    }
    elsif ($name eq 'max') {
        $json = qq|{"operation":"write-attribute","address":[{"subsystem":"datasources"},{"data-source":"$ds_name"}],"name":"max-pool-size","value":$size,"json.pretty":1}|;
    }
                  
    $self->_set_post_json($json);
    
    $self->log->debug($self->post_json);
    $self->get_api_response();   
}

=head2 set_ds_pool_stats

 set enable/disable data source pool statistics
 my $enable_pool_stats  = $jboss->set_ds_pool_stats('java:jboss/datasources/jboss_Pool', 'true');
 my $disable_pool_stats = $jboss->set_ds_pool_stats('java:jboss/datasources/jboss_Pool', 'false');

=cut

sub set_ds_pool_stats {
    my $self        = shift;
    
    my ($ds_name, $value)     = @_; 
    
    croak "data source name is required"
        unless $ds_name;
    
    croak "value is not defined"
        unless $value;
    
    $value  = lc ($value) if $value;
    
    croak "value is invalid, valid value is 'true' or 'false'"
        unless $value =~ /^\b(true|false)\b/;
    
    $self->_set_http_post(1);
    
    my $json = qq|{"operation":"write-attribute","address":[{"subsystem":"datasources"},{"data-source":"$ds_name"}],"name":"statistics-enabled","value":"$value","json.pretty":1}|;
                    
    $self->_set_post_json($json);
    
    $self->log->debug($self->post_json);
    $self->get_api_response();   
}

=head2 reload

 reload jboss only
 my $reload = $jboss->reload();

=cut

sub reload {
    my $self = shift;
    
    $self->_set_http_post(1);
    
    my $json = qq|{"operation":"reload","json.pretty":1}|;
                    
    $self->_set_post_json($json);
    
    $self->log->debug($self->post_json);
    $self->get_api_response();
    
    # wait for the state
    $self->log->debug("wait for " . $self->reload_time . " seconds before checking the state");
    sleep ($self->reload_time);
    $self->get_state();
}

=head2 shutdown

 shutdown jboss
 my $shutdown = $jboss->shutdown();

=cut

sub shutdown {
    my $self = shift;
    
    $self->_set_http_post(1);
    
    my $json = qq|{"operation":"shutdown","json.pretty":1}|;
                    
    $self->_set_post_json($json);
    
    $self->log->debug($self->post_json);
    $self->get_api_response();
}

=head2 restart

 restart jboss and jvm
 my $restart = $jboss->restart();

=cut

sub restart {
    my $self = shift;
    
    $self->_set_http_post(1);
    
    my $json = qq|{"operation":"shutdown","restart":"true","json.pretty":1}|;
                    
    $self->_set_post_json($json);
    
    $self->log->debug($self->post_json);
    $self->get_api_response();
}

=head2 get_deployment_info

 return deployment detail information
 my $deploy_info = $jboss->get_deployment_info();

=cut

sub get_deployment_info {
    my $self = shift;
    
    $self->_set_http_post(1);
    
    my $json = qq|{"operation":"read-children-resources","child-type":"deployment","recursive":"true","json.pretty":1}|;
                    
    $self->_set_post_json($json);
    
    $self->log->debug($self->post_json);
    $self->get_api_response();
}

=head2 get_jndi

 return jndi view information
 my $jndi = $jboss->get_jndi();

=cut

sub get_jndi {
    my $self = shift;
    
    $self->_set_http_post(1);
    
    my $json = qq|{"operation":"jndi-view", "address":["subsystem","naming"], "json.pretty":1}|;
                    
    $self->_set_post_json($json);
    
    $self->log->debug($self->post_json);
    $self->get_api_response();
}

=head2 set_log_level

 my $loglevel = $jboss->set_log_level('CONSOLE', 'ERROR');

=cut

sub set_log_level {
    my $self = shift;
    
    my ($type, $severity) = @_;
    
    my $valid_type      = 'CONSOLE';
    my $valid_severity  = 'ALL|DEBUG|INFO|WARN|WARNING|ERROR|SEVERE|FATAL|OFF';
    
    croak "type of console is required"
        unless $type;
        
    croak "valid type is $valid_type"
        unless $type =~ /^\b($valid_type)\b/;
        
    croak "valid log severity is $valid_severity"
        unless $severity =~ /^\b($valid_severity)\b/;
        
    croak "severity level is required"
        unless $severity;
    
    $self->_set_http_post(1);
    
    my $json = qq|{"operation":"write-attribute","address":[{"subsystem":"logging"},{"console-handler":"$type"}],"name":"level","value":"$severity", "json.pretty":1}|;
                    
    $self->_set_post_json($json);
    
    $self->log->debug($self->post_json);
    $self->get_api_response();
}

=head2 get_log_level

 my $loglevel = $jboss->get_log_level('CONSOLE');

=cut

sub get_log_level {
    my $self = shift;
    
    my $type = shift;
    
    my $valid_type      = 'CONSOLE';
    
    croak "type of console is required"
        unless $type;
        
    croak "valid type is $valid_type"
        unless $type =~ /^\b($valid_type)\b/;
    
    $self->_set_http_post(1);
    
    my $json = qq|{"operation":"read-attribute","address":[{"subsystem":"logging"},{"console-handler":"$type"}],"name":"level", "json.pretty":1}|;
                    
    $self->_set_post_json($json);
    
    $self->log->debug($self->post_json);
    $self->get_api_response();
}

=head1 AUTHOR

"Heince Kurniawan", C<< <"heince at cpan.org"> >>

=head1 BUGS

Please report any bugs or feature requests to "heince at cpan.org", or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net::JBoss::Management>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::JBoss
    perldoc Net::JBoss::Management

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net::JBoss>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net::JBoss>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net::JBoss>

=item * Search CPAN

L<http://search.cpan.org/dist/Net::JBoss/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 "Heince Kurniawan".

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of JBoss
