package Solstice::Server;

=head1 NAME

Solstice::Server - An interface between applications and the system solstice is running on.

=head2 Export

None by default.

=head2 Methods

=cut

use strict;
use warnings;
use 5.006_000;

use base qw(Solstice);

use CGI;
use Solstice::CGI::Upload;

use constant TRUE => 1;
use constant FALSE => 0;


sub solsticeStartup {
   eval {
       my $config = Solstice::Configure->new();
   
       require Solstice;
       require Solstice::Dispatch;
       require Solstice::Service::Debug;
       require Solstice::Database;
       require Solstice::Configure;
       require Solstice::State::Machine;
       require Solstice::NamespaceService;
       require Solstice::ButtonService;
       require Solstice::ErrorHandler;
       require Solstice::Controller::Application::Main;
       require Solstice::Controller::Application::REST;
       require Solstice::Controller::Application::Auth;
       require Solstice::Session;
       require Solstice::Service;
       require Solstice::ContentTypeService;
       require Solstice::LangService;
       require Solstice::LogService;
       require Solstice::Controller::Remote;
       require Solstice::UserService;
       require Solstice::CGI;
       require Time::HiRes;
   
       Solstice::State::Machine->initialize($config->getStateFiles());
   
       for my $startup_script (@{$config->getStartupFiles()}){
           eval{
               require $startup_script;
           };
           die "Startup script $startup_script failed: $@\n" if $@;
       }
   
       foreach my $app (keys %{$config->getRemoteDefs()}){
           my $remote_defs = $config->getRemoteDefs()->{$app};
           foreach my $key (keys %$remote_defs ){
               Solstice->new()->loadModule($config->getRemoteDefs()->{$app}{$key});
           }
       }
   
   # load the solstice lang keys
       eval {
           my $lang_service = Solstice::LangService->new('Solstice');
           $lang_service->_initialize();
       };
       die "Couldn't initialize Solstice::LangService for global namespace: $@\n" if $@;
   # load the app lang keys
       foreach my $app (@{$config->getNamespaces()}) {
           eval {
               my $lang_service = Solstice::LangService->new($app);
               $lang_service->_initialize();
           };
           die "Couldn't initialize Solstice::LangService for $app: $@\n" if $@;
       }
   
   #in order to avoid using cached copies of compiled views or static file concats, we clear the cache
       if( my $compiled_template_dir = $config->getCompiledViewPath() ){
           opendir(my $compiled_template_dir_handle, $compiled_template_dir);
           foreach my $compiled_template (readdir $compiled_template_dir_handle){
               next unless $compiled_template =~ /\.cmpl$/;
               unlink $compiled_template_dir .'/'. $compiled_template;
           }
           close $compiled_template_dir_handle;
       }
   
       if( my $static_concat_dir = $config->getDataRoot() .'/static_file_concat_cache/' ){
           opendir(my $static_concat_dir_handle, $static_concat_dir);
           foreach my $static_concat (readdir $static_concat_dir_handle){
               unlink $static_concat_dir .'/'. $static_concat;
           }
           close $static_concat_dir_handle;
       }
   
   };

    if($@){
        warn "Solstice failed to start: $@";
        Solstice::Server->setStartupError($@);
    }
}

# Package variable instead of memory service, so it will work properly in dev mode.
my $startup_error;

# Tracks an object that interfaces with the specific type of server.
my $server_implementation;

sub new {
    my $obj = shift;
    my $self = $obj->SUPER::new(@_);

    if (!defined $Solstice::Server::server_implementation && (ref $self ne "Solstice::Server")) {
        $self->solsticeStartup();
        $Solstice::Server::server_implementation = $self;
    }

    return $self;
}

sub getServerInterface {
    return $Solstice::Server::server_implementation;
}

sub getStartupError {
    my $self = shift;
    return $Solstice::Server::startup_error;
}

sub setStartupError {
    my $self = shift;
    my $error = shift;
    $Solstice::Server::startup_error = $error;
}

sub getIsSSL {
    my $self = shift;
    return $self->getServerInterface()->_getIsSSL();
}

sub getURI {
    my $self = shift;
    return $self->getServerInterface()->_getURI();
}

sub setPostMax {
    my $self = shift;
    return $self->getServerInterface()->_setPostMax(shift);
}

sub setContentLength {
    my $self = shift;
    return $self->getServerInterface()->_setContentLength(shift);
}

sub setContentDisposition {
    my $self = shift;
    return $self->getServerInterface()->_setContentDisposition(shift);
}

sub setContentType {
    my $self = shift;
    return $self->getServerInterface()->_setContentType(shift);
}

sub getContentType {
    my $self = shift;
    return $self->getServerInterface()->_getContentType();
}

sub setStatus {
    my $self = shift;
    return $self->getServerInterface()->_setStatus(shift);
}

sub getStatus {
    my $self = shift;
    return $self->getServerInterface()->_getStatus();
}

sub getMeetsConditions {
    my $self = shift;
    return $self->getServerInterface()->_getMeetsConditions(shift);
}

sub sendFileByPath {
    my $self = shift;
    return $self->getServerInterface()->_sendFileByPath(shift);
}

sub addHeader {
    my $self = shift;
    return $self->getServerInterface()->_addHeader(shift, shift);
}

sub getHeaderIn {
    my $self = shift;
    return $self->getServerInterface()->_getHeaderIn(shift);
}

sub getMethod {
    my $self = shift;
    return $self->getServerInterface()->_getMethod();
}

sub printHeaders {
    my $self = shift;
    return $self->getServerInterface()->_printHeaders();
}

sub getRequestBody {
    my $self = shift;
    return $self->getServerInterface()->_getRequestBody();
}

sub getCookie {
    my $self = shift;
    return $self->getServerInterface()->_getCookie(shift, shift);
}

sub sendCookie {
    my $self = shift;
    return $self->getServerInterface()->_sendCookie(shift);
}

sub param {
    my $self = shift;
    if(@_){
        return CGI::param(@_);
    }elsif(wantarray){
        return CGI::param();
    }else{
        my $params;
        for my $name ( CGI::param() ){
            $params->{$name} = CGI::param($name);
        }
        return $params;
    }
}

sub getUploadSuccessful {
    my $self = shift;
    return TRUE;
}


sub getUpload {
    my $self = shift;
    my $interface = $self->getServerInterface();

    my $data = $interface->_getUploadData(shift);

    my $upload = Solstice::CGI::Upload->new();
    $upload->setSize($data->{'size'});
    $upload->setContentType($data->{'type'});
    $upload->setName($data->{'name'});
    $upload->setFileHandle($data->{'handle'});
    return $upload;
}

# XXX - add a useful message here about what they should do?

sub _getURI {
    die "_getURI not implemented in server subclass ".ref($_[0])."\n";
}

sub _printHeaders {
    die "_printHeaders not implemented in server subclass ".ref($_[0])."\n";
}

sub _setPostMax {
    die "_setPostMax not implemented in server subclass ".ref($_[0])."\n";
}

sub _setContentLength {
    die "_setContentLength not implemented in server subclass ".ref($_[0])."\n";
}

sub _setContentDisposition {
    die "_setContentDisposition not implemented in server subclass ".ref($_[0])."\n";
}

sub _setContentType {
    die "_setContentType not implemented in server subclass ".ref($_[0])."\n";
}

sub _getContentType {
    die "_getContentType not implemented in server subclass ".ref($_[0])."\n";
}

sub _setStatus {
    die "_setStatus not implemented in server subclass ".ref($_[0])."\n";
}

sub _getStatus {
    die "_getStatus not implemented in server subclass ".ref($_[0])."\n";
}

sub _getMeetsConditions {
    die "_getMeetsConditions not implemented in server subclass ".ref($_[0])."\n";
}

sub _addHeader {
    die "_addHeader not implemented in server subclass ".ref($_[0])."\n";
}

sub _getHeaderIn {
    die "_getHeaderIn not implemented in server subclass ".ref($_[0])."\n";
}

sub _sendFileByPath {
    die "_sendFileByPath not implemented in server subclass ".ref($_[0])."\n";
}

sub _getMethod {
    die "_getMethod not implemented in server subclass ".ref($_[0])."\n";
}

sub _getRequestBody {
    die "_getRequestBody not implemented in server subclass ".ref($_[0])."\n";
}

1;

=head1 COPYRIGHT

Copyright 1998-2007 Office of Learning Technologies, University of Washington

Licensed under the Educational Community License, Version 1.0 (the "License");
you may not use this file except in compliance with the License. You may obtain
a copy of the License at: http://www.opensource.org/licenses/ecl1.php

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

=cut
