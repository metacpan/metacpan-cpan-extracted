package Net::JBoss;

use 5.010;
use HTTP::Request;
use LWP::UserAgent;
use Scalar::Util qw(looks_like_number);
use Carp;
use Moo::Role;

=head1 NAME

Net::JBoss - Bindings for JBoss Management API

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

 notes :
 ro             = read only, can be specified during initialization
 rw             = read write, user can set this attribute
 rwp            = read write protected, for internal class

 username       = (ro, required) store management user username
 password       = (ro, required) store management user password
 server         = (ro, required) store managemenet address, ip address / hostname only
 port           = (ro) store Ovirt Manager's port (must be number)
 log_severity   = (ro) store log severity level, valid value ERROR|OFF|FATAL|INFO|DEBUG|TRACE|ALL|WARN
                  (default is INFO)
 realm          = (ro) store realm, default to 'ManagementRealm'
 resource_url   = (rwp) store resource url for each method
 url            = (rwp) store final url to be requested
 log            = (rwp) store log from log4perl
 http_post      = (rwp) if true, use http post method instead of get
 post_json      = (rwp) set json content to be post
 ssl            = (ro) if 'on', use https (default is 'off')
 ssl_verify     = (ro) disable host verification, yes/no (default is 'no')
 is_xa          = (ro) define if it's xa datasource, yes/no (default is 'no')

=cut

has [qw/url log json_data resource_url http_post post_json /]   => ( is => 'rwp' );
has [qw/username password/]                                     => ( is => 'ro', required => 1 );
has [qw/server/]    => ( is     => 'ro', 
                         isa    => sub {
                                            croak "server can't contain http protocol, use ip / hostname only" 
                                                if $_[0] =~ /http/i;
                                        },
                        required => 1 )
                        ;

has 'port'          => ( is => 'ro', default => 9990,
                        isa => 
                            sub { 
                                    croak "$_[0] is not a number!" unless looks_like_number $_[0]; 
                                }
                        );

has 'log_severity'  => ( is => 'ro', 
                        isa => sub { croak "log severity value not valid\n" 
                                        unless $_[0] =~ /\b(ERROR|OFF|FATAL|INFO|DEBUG|TRACE|ALL|WARN)\b/;
                                    }, 
                        default => 'INFO'
);

has 'realm'         => ( is => 'ro', default => 'ManagementRealm' );
has 'ssl'           => ( is => 'ro', default => 'off', 
                         isa => 
                            sub {
                                croak "valid ssl value is on or off"
                                    unless $_[0] =~ /\b(on|off)\b/;
                            }
                        );
has 'ssl_verify'    => ( is => 'ro', 
                         isa    => sub { 
                                        my $ssl_verify  = $_[0];
                                        $ssl_verify     = lc ($ssl_verify);
                                        
                                        if ($ssl_verify eq 'yes') {
                                            $ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 1;
                                        }
                                        elsif ($ssl_verify eq 'no') {
                                            $ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0;
                                        }
                                        else {
                                            croak "ssl_verify valid argument is yes/no";
                                        }
                                    },    
                         default => sub { $ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0; return 'no'; } );

has 'is_xa'         => ( is => 'ro' => default => 'no',
                         isa => 
                            sub {
                                croak "valid is_xa value is yes or no"
                                    unless $_[0] =~ /\b(yes|no)\b/;
                            }
                         );

=head1 SUBROUTINES/METHODS

 You may want to check :
 - perldoc Net::JBoss::Management

=head2 BUILD

 The Constructor, build logging, call pass_log_obj method
=cut

sub BUILD {
    my $self = shift;
    
    $self->pass_log_obj();
}

=head2 pass_log_obj

 it will build the log which stored to $self->log
 you can assign the severity level by assigning the log_severity 
 
 # output to console / screen
 # format : 
 # %d = current date with yyyy/MM/dd hh:mm:ss format                       
 # %p = Log Severity                                                       
 # %P = pid of the current process                                         
 # %L = Line number within the file where the log statement was issued       
 # %M = Method or function where the logging request was issued            
 # %m = The message to be logged                                           
 # %n = Newline (OS-independent)                                           
 
=cut

sub pass_log_obj {
    my $self    = shift;
    
    # skip if already set
    return if $self->log; 
    
    my $severity = $self->log_severity;
    my $log_conf = 
    qq /
        log4perl.logger                                     = $severity, Screen
        log4perl.appender.Screen                            = Log::Log4perl::Appender::Screen
        log4perl.appender.Screen.stderr                     = 0
        log4perl.appender.Screen.layout                     = PatternLayout
        log4perl.appender.Screen.layout.ConversionPattern   = %d || %p || %P || %L || %M || %m%n
    /;
    
    use Log::Log4perl;
    Log::Log4perl::init(\$log_conf);
    my $log = Log::Log4perl->get_logger();
    $self->_set_log($log);
}

=head2 base_url

 return the base url
=cut

sub base_url {
    my $self = shift;
    
    my $url = $self->server;
    
    if ($self->port) {
        $url =  $self->server . ":" . $self->port;
    }
    
    # http or https
    if ($self->ssl eq 'off') {
        $url = "http://" . $url;
    }
    else {
        $url = "https://" . $url;
    } 
  
    $self->log->debug($url);
    return $url;
}

=head2 get_api_response

 return http api response
=cut

sub get_api_response {
    my $self    = shift;
    
    croak "url required"            unless $self->url;
    
    $self->log->debug("username = " . $self->username);
    $self->log->debug("password = " . $self->password);
    $self->log->debug("port     = " . $self->port);
    $self->log->debug("realm    = " . $self->realm);
    
    my $ua = LWP::UserAgent->new();
    $ua->credentials(   $self->server . ":" . $self->port, 
                        $self->realm    , 
                        $self->username , 
                        $self->password ,
                    );
    
    # write operation require post method                
    my $res;
    if ($self->http_post) {
        croak "post_json not set"
            unless $self->post_json;
        
        my $req = HTTP::Request->new(POST => $self->url);
        $req->content_type  ('application/json');
        $req->content       ($self->post_json);
        
        $res = $ua->request ($req);
    }
    else {
        croak "resource url required"   unless $self->resource_url;
        
        # set final url
        $self->_set_url($self->url . $self->resource_url);
    
        $self->log->debug($self->url);
        $res = $ua->get($self->url);
    }

    if ($res->is_success) {    
        $self->log->debug($res->decoded_content);
        return $res->decoded_content;
    }
    else {
        my $err = $res->status_line;
        $self->log->debug("LWP Error : " . $err);   
        return $res->decoded_content;
    } 
}

=head2 trim

 trim function to remove whitespace from the start and end of the string
=cut

sub trim()
{
    my ($self, $string) = @_;
    $string =~ s/^\s+|\s+$//g;
    return $string;
}

=head1 AUTHOR

"Heince Kurniawan", C<< <"heince at cpan.org"> >>

=head1 BUGS

Please report any bugs or feature requests to "heince at cpan.org", or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net::JBoss>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::JBoss


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
