package Ovirt;

use v5.10;
use LWP::UserAgent;
use Scalar::Util qw(looks_like_number);
use Carp;
use JSON;
use XML::LibXML;
use URI::Escape;
use Moo::Role;

=head1 NAME

Ovirt - Bindings for oVirt REST API

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

 use Ovirt::VM;
 use Ovirt::Template;
 use Ovirt::Cluster;
 use Ovirt::Host;
 use Ovirt::Display;

 my %con = (
            username                => 'admin',
            password                => 'password',
            manager                 => 'ovirt-mgr.example.com',
            api_output              => 'xml', # optional, default to json
            vm_output_attrs         => 'id,name,state,description', # optional
            cluster_output_attrs    => 'id,name,cpu_id,cpu_arch,description', # optional
 );

 my $vm         = Ovirt::VM         ->new(%con);
 my $cluster    = Ovirt::Cluster    ->new(%con);
 my $template   = Ovirt::Template   ->new(%con);
 my $host       = Ovirt::Host       ->new(%con);

 # return xml output / json
 print $vm->list_xml;   
 print $vm->list_json;                           

 # list attributes based on 'vm_output_attrs'
 print $vm      ->list;
 print $cluster ->list;
 print $template->list;
 print $host    ->list;

 # create, remove vm
 $vm->create('vm1','Default','CentOS7');
 $vm->remove('2d83bb51-9a77-432d-939c-35be207017b9');
 
 # add/remove/list vm's nic and disk
 $vm->add_disk('6efc0cfa-8495-4a96-93e5-ee490328cf48',  # vm id
                'virtio',                               # driver interface
                'cow',                                  # format
                '1073741824',                           # size
                'mydisk1',                              # disk name
                '9b952bdc-b7ec-4673-84b0-477b48945a9a'  # storage domain id
              );

 $vm->add_nic('6efc0cfa-8495-4a96-93e5-ee490328cf48',   # vm id
              'virtio',                                 # driver interface
              'nic1',                                   # nic name
              'rhevm'                                   # network name
             );
 
 # start, stop, reboot, migrate vm
 $vm->start     ('b4738b0f-b73d-4a66-baa8-2ba465d63132');
 $vm->stop      ('b4738b0f-b73d-4a66-baa8-2ba465d63132');
 $vm->reboot    ('b4738b0f-b73d-4a66-baa8-2ba465d63132');
 $vm->migrate   ('b4738b0f-b73d-4a66-baa8-2ba465d63132');

 # the output also available in hash
 # for example to print all vm name and state
 my $hash = $vm->hash_output;
 for my $array (keys $hash->{vm}) {
    print $hash->{vm}[$array]->{name} . " " . 
        $hash->{vm}[$array]->{status}->{state};
 }
 
 # we can also specify specific vm 'id' when initiating an object
 # so we can direct access the element for specific vm
 print $vm->hash_output->{name};                   
 print $vm->hash_output->{cluster}->{id};
 
 # Generate display configuration for remote viewer
 my $display = Ovirt::Display->new(%con);
 print $display->generate();

 sample spice configuration output :
 [virt-viewer]
    type=spice
    host=192.168.1.152
    port=-1
    password=+cnsq458Oq6T
    # Password is valid for 300 seconds.
    tls-port=5902
    fullscreen=0
    title=C1 : %d - Press SHIFT+F12 to Release Cursor
    enable-smartcard=0
    enable-usb-autoshare=1
    delete-this-file=1
    usb-filter=-1,-1,-1,-1,0
    tls-ciphers=DEFAULT
    host-subject=O=example.com,CN=192.168.1.152
    ca=-----BEGIN CERTIFICATE-----\n -- output removed -- S2fE=\n-----END CERTIFICATE-----\n
    toggle-fullscreen=shift+f11
    release-cursor=shift+f12
    secure-attention=ctrl+alt+end
    secure-channels=main;inputs;cursor;playback;record;display;usbredir;smartcard

 you can save it to a file then use remote viewer to open it:
 $ remote-viewer [your saved file].vv         

=head1 Attributes

 notes :
 ro             = read only, can be specified during initialization
 rw             = read write, user can set this attribute
 rwp            = read write protected, for internal class

 username       = (ro, required) store Ovirt username
 password       = (ro, required) store Ovirt password
 manager        = (ro, required) store Ovirt Manager address
 port           = (ro) store Ovirt Manager's port (must be number)
 id             = (ro) store object id, if it's provided during initialization,
                   the rest api output will only contain attributes for this id
 domain         = (ro) store Ovirt Domain (default domain : internal)
 ssl            = (ro) if yes, use https (default is yes)
 ssl_verify     = (ro) disable host verification (default is no)
 log_severity   = (ro) store log severity level, valid value ERROR|OFF|FATAL|INFO|DEBUG|TRACE|ALL|WARN
                  (default is INFO)
 api_output     = (ro) json/xml, default is json
 not_available  = (rw) store undef or empty output string, default to 'N/A'
 url            = (rwp) store final url to be requested to Ovirt
 root_url       = (rwp) store url on each object
 log            = (rwp) store log from log4perl
 xml_output     = (rwp) store xml output from API output
 json_output    = (rwp) store json output from API output
 hash_output    = (rwp) store hash output converted from xml output

=cut

has [qw/url root_url xml_output json_output hash_output log/]   => ( is => 'rwp' );
has [qw/id/]                                                    => ( is => 'ro' );
has [qw/username password manager/]                             => ( is => 'ro', required => 1 );

has 'port'          => ( is => 'ro', 
                        isa => 
                            sub { 
                                    croak "$_[0] is not a number!" unless looks_like_number $_[0]; 
                                }
                        );
                        
has 'domain'        => ( is => 'ro', default => 'internal' );
has 'ssl'           => ( is => 'ro', default => 'yes' );
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
has 'not_available' => ( is => 'rw', default => 'N/A' );

has 'log_severity'  => (is => 'ro', 
                        isa => sub { croak "log severity value not valid\n" 
                                        unless $_[0] =~ /(ERROR|OFF|FATAL|INFO|DEBUG|TRACE|ALL|WARN)/;
                                    }, 
                        default => 'INFO'
);

has 'api_output'    => (is => 'ro', 
                        isa => sub { croak "valid api_output is xml/json\n" 
                                        unless $_[0] =~ /(xml|json)/;
                                    }, 
                        default => 'json'
);

=head1 SUBROUTINES/METHODS

 You may want to check :
 - perldoc Ovirt::VM
 - perldoc Ovirt::Template
 - perldoc Ovirt::Cluster
 - perldoc Ovirt::Host
 - perldoc Ovirt::Display
 - perldoc Ovirt::DataCenter
 - perldoc Ovirt::Storage
 - perldoc Ovirt::Network

=head2 BUILD

 The Constructor, build logging, call pass_log_obj method
=cut

sub BUILD 
{
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

sub pass_log_obj 
{
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

sub base_url 
{
    my $self = shift;
    
    # make sure the http encoding
    # '%40' is '@'
    my $username = uri_escape($self->username);
    my $domain   = uri_escape($self->domain);
    my $password = uri_escape($self->password);
    
    my $url = $username . '%40'. $domain . ":" .$password . 
                "\@" . $self->manager;
    
    if ($self->port) {
        $url = $username . '%40'. $domain . ":" .$password . 
                "\@" . $self->manager . ":" . $self->port;
    }
    
    if ($self->ssl eq 'yes') { 
        $url = "https://" . $url;    
    }
    elsif ($self->ssl eq 'no') {
        $url = "http://" . $url; 
    }
    
    $self->log->debug($url);
    return $url;
}

=head2 api_url

 build the final url
=cut

sub api_url 
{
    my $self = shift;
    
    # root_url is being set in each particular library
    my $url = $self->base_url . $self->root_url;
    
    $self->log->debug("$url");
    $self->_set_url($url);
}

=head2 get_api_response

 get xml response, store to xml_output.
 the xml output is also converted to hash and stored
 at hash_output attribute.
 xml2hash somehow complaining the xml declaration, so we 
 need to skip it and use 'toString' method on the xml string
 parameter. 
=cut

sub get_api_response 
{
    my $self    = shift;
    
    my $ua      = LWP::UserAgent->new();
    
    if ($self->api_output eq 'json') {
        
        my $tx  = $self->get_json_response($self->api_url);
        
        if ($tx->is_success) {
            #store json output
            my $json = $tx->decoded_content;
            $self->_set_json_output($json);
            
            my $hash    = from_json($json);
            $self->_set_hash_output($hash);
        }
        else {
            $self->set_lwp_error($tx);
        }
    }
    elsif ($self->api_output eq 'xml') {
        my $tx      = $self->get_xml_response($self->api_url);
        
        if ($tx->is_success) {
            use XML::Hash::XS qw();
            
            local $XML::LibXML::skipXMLDeclaration = 1;
            my $parser = XML::LibXML->new();
            my $xml_string  = $parser->parse_string($tx->decoded_content);
            $self->_set_xml_output($xml_string);
            
            #store to hash
            my $conv    = XML::Hash::XS->new(utf8 => 1, encoding => 'utf8');
            my $hash    = $conv->xml2hash($xml_string->toString, encoding => 'cp1251');
            $self->_set_hash_output($hash);
            
        }
        else {
            $self->set_lwp_error($tx);
        }
    }     
}

=head2 set_lwp_error

 handle lwp if not success
 required args ($tx)
 
=cut

sub set_lwp_error
{
    my $self    = shift;
    my $tx      = shift;
    
    my $err = $tx->status_line;
    $self->log->debug("LWP Error : " . $err);
    $self->log->debug("LWP Decoded Content :" . $tx->decoded_content);
    
    croak "LWP Status line : " . $err;
    croak "LWP Decoded Content :" . $tx->decoded_content;
}

=head2 get_api_output

 handle and return output based on $self->api_output

=cut

sub get_api_output
{
    my $self    = shift;
    my $url     = shift;
    
    if ($self->api_output eq 'json')
    {
        my $tx = $self->get_json_response($url);
        if ($tx->is_success) 
        {
            return $tx->decoded_content;
        }
        else
        {
            $self->set_lwp_error($tx);  
        }
    }
    else
    {
        my $tx = $self->get_xml_response($url);
        
        if ($tx->is_success) 
        {
            local $XML::LibXML::skipXMLDeclaration = 1;
            my $parser      = XML::LibXML->new();
            my $xml_string  = $parser->parse_string($tx->decoded_content);
            return $xml_string;
        }
        else
        {
            $self->set_lwp_error($tx);
        }
    }
}

=head2 get_json_response

 handle http get for json output
 required argument ('url')
 
=cut

sub get_json_response 
{
    my $self    = shift;
    
    my $url     = shift;
    
    croak "url required"
        unless $url;
        
    my $ua      = LWP::UserAgent->new();   
    my $req     = HTTP::Request->new(GET => $url);
    $req->header('content-type' => 'application/json');
    $req->header('Accept' => 'application/json'); 
    
    my $tx  = $ua->request($req);
    return $tx;     
}

=head2 get_xml_response

 handle http get for xml output
 required argument ('url')
 
=cut

sub get_xml_response 
{
    my $self    = shift;
    
    my $url     = shift;
    
    croak "url required"
        unless $url;
    
    my $ua      = LWP::UserAgent->new();  
    my $tx      = $ua->get($url);
    
    return $tx;     
}

=head2 list_xml

 return xml output
=cut

sub list_xml 
{
    my $self = shift;
    
    if ($self->api_output eq 'xml') 
    {
        return $self->xml_output 
            if $self->xml_output;
    }
    else 
    {
        die "api output setting is not xml\n";
    }
}

=head2 list_json

 return json output
=cut

sub list_json 
{
    my $self = shift;
    
    if ($self->api_output eq 'json') 
    {
        return $self->json_output
            if $self->json_output;
    }
    else 
    {
        die "api output setting is not json\n";
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

=head2 ltrim

 Left trim function to remove leading whitespace
=cut

sub ltrim()
{
    my ($self, $string) = @_;
    $string =~ s/^\s+//;
    return $string;
}

=head2 rtrim

 Right trim function to remove leading whitespace
=cut

sub rtrim()
{
    my ($self, $string) = @_;
    $string =~ s/\s+$//;
    return $string;
}

=head1 AUTHOR

 "Heince Kurniawan", C<< <"heince at cpan.org"> >>

=head1 BUGS

 Please report any bugs or feature requests to C<bug-ovirt at rt.cpan.org>, or through
 the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Ovirt>.  I will be notified, and then you'll
 automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

 You can find documentation for this module with the perldoc command.

    perldoc Ovirt


 You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Ovirt>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Ovirt>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Ovirt>

=item * Search CPAN

L<http://search.cpan.org/dist/Ovirt/>

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

1; # End of Ovirt
