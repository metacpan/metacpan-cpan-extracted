package Solstice::Dispatch;

=head1 NAME

Solstice::Dispatch - Dispatches the current request to the appropriate application.

=head2 Export

None by default.

=head2 Methods

=over 4

=cut

use strict;
use warnings;
use 5.006_000;

use base qw(Solstice);

use Solstice::Server;
use Solstice::Session;
use Solstice::Controller::Application::Auth;
use Solstice::Controller::Application::Main;
use Solstice::Controller::Remote;
use Solstice::Configure;
use Solstice::Service::Debug;
use Solstice::ButtonService;
use Solstice::LangService;
use Solstice::NamespaceService;
use Solstice::PositionService;
use Solstice::UserService;
use Solstice::ErrorHandler;
use Solstice::View::Application;
use Solstice::View::Redirect;
use Time::HiRes qw(gettimeofday tv_interval);
use File::stat;

use constant TRUE => 1;
use constant FALSE => 0;
use constant CONFIG_FILE_KEY => 'SOLSTICE_CONFIG_FILE';

my %CGIS = ();

sub dispatch {
    my $start_time = [gettimeofday];

    my $server = Solstice::Server->new();
    my $startup_error = $server->getStartupError();

    die "Solstice failed to start: $startup_error" if $startup_error;

    #pre-click cleanup - make sure there is nothing left in services
    $Solstice::Service::data_store = {};

    my $url = $server->getURI();
    my $config = Solstice::Configure->new();


    my $run_cleanup = FALSE;
    Solstice::Service::Debug->new( $config->getCentralDebugLevel() );
    if($config->getDevelopmentMode()){
        require Module::Reload;
        Module::Reload->check();
    }

    my $screen = '';

    #sorry, this sucks, but we need this here too to match
    #the image/static content stuff as well as in the
    #_getCGI/URLProfile functions
    $url =~ s/\/+/\//g;

    eval{
        # Start by making sure we're ssl if we need to be...
        if ($config->getRequireSSL() && !$server->getIsSSL()) {
            my $ssl_url = ($server->getServerURL().'/'.$url);
            $ssl_url =~ s/([^:])\/+/$1\//g;
            redirectToSSL($ssl_url, \$screen);

            #Is it a remote xmlhttp call?
        } elsif ( $url =~ /solstice_remote_call_url/ ){
            $run_cleanup = TRUE; #we'll need to clean up services/etc

            my $controller = Solstice::Controller::Remote->new();
            $controller->runApp(\$screen);

            #is it a webservice resource?
        }elsif( my $resource_profile = $config->_getWebserviceProfile($url)){
            $run_cleanup = TRUE; #we'll need to clean up services/etc


            runWebserviceURL($resource_profile, \$screen, $start_time);


            #is it perhaps a legacy CGI?
        }elsif( my $cgi_profile = $config->_getCGIProfile($url)){
            $run_cleanup = TRUE; #we'll need to clean up services/etc

            if($cgi_profile->{'requires_auth'}){
                return if (Solstice::Controller::Application::Auth->new()->requiresUserLogin());
            }

            runCGIURL($cgi_profile); 


            #Now, let's see if we can locate a static content dir
        }elsif( my $file = $config->_getStaticContent($url)){
            if (!serveStaticContent($file)) {
                show404($url, \$screen);
                $run_cleanup = TRUE;
            }

            #Is the URL an App url?
        }elsif( my $profile = $config->_getURLProfile($url)){
            $run_cleanup = TRUE; #we'll need to clean up services/etc

            #run the application code
            runAppURL($profile, \$screen, $start_time);


            #if there is nothing installed
        }elsif( 0 == scalar keys %{$config->getAppUrls()} ){
            showWelcomeScreen($url, \$screen);


            #then there's no pleasing you
        }else{
            # Show a 404
            show404($url, \$screen);
            $run_cleanup = TRUE;
        }
    };

    #If we crashed
    if($@){
        my $captured_error = $@;
        eval { #can't let a crash here prevent data_store cleanup
            handleError($captured_error, $url);
        };
    }

    #cleanup stateful info
    if($run_cleanup){ #these are only needed if we ran certain subs above
        eval {
            Solstice::ButtonService->new()->commit();
            my $session = Solstice::Session->new();
            $session->store();
        }; #can't let a crash here prevent data_store cleanup
    }

    utf8::downgrade($screen);
    if($server->getContentType() && $server->getContentType() =~ /html/){
        my $time = tv_interval($start_time, [gettimeofday]);
        $screen =~ s/___SOLSTICE_PAGE_LOAD_TIME___/$time/;

        if ($config->getDevelopmentMode()) {
            # Grab these service values before clearing the service data
            my $pos_service = Solstice::PositionService->new();
            my $read_count  = $pos_service->getQueueSize('db_read_count');
            my $write_count = $pos_service->getQueueSize('db_write_count');
            
            $screen =~ s/___SOLSTICE_DB_READ_COUNT___/$read_count/;
            $screen =~ s/___SOLSTICE_DB_WRITE_COUNT___/$write_count/;
        }
    }

    #if screen content was printed, fire off any headers and show it
    if($screen){
        $server->printHeaders();
        print $screen;
    }

    #always needed
    $Solstice::Service::data_store = {};


    return TRUE;
}

=item runWebserviceURL

loads the overarching REST controller and steps it through providing the requested resource

=cut

sub runWebserviceURL {
    my ($profile, $screen, $start_time) = @_;


    my $ns_service = Solstice::NamespaceService->new();
    $ns_service->_setAppNamespace($profile->{'config_namespace'});

    my $controller = Solstice::Controller::Application::REST->new($profile->{'controller'});

    if( $profile->{'requires_auth'} ){
        if( $controller->handleAuth() ){
            unless( $controller->runWebservice($screen) ){
                $controller->showError($screen);
            }
        }else{
            $controller->showError($screen);
        }
    }else{
        unless( $controller->runWebservice($screen) ){
            $controller->showError($screen);
        }
    }


    Solstice::LogService->new()->log({
            namespace   => 'Solstice',
            log_file    => 'webservice_log',
            content     => 
            Solstice::Server->new()->getMethod() .
            " on ".
            $profile->{'controller'}.
            ", Time: ". tv_interval($start_time, [gettimeofday])
        });
}


=item runAppURL

if an installed solstice app handles a given url, this primes the controller and pulls the trigger

=cut

sub runAppURL {
    my ($profile, $screen, $start_time) = @_;

    Solstice::Service::Debug->new( $profile->{'debug_level'} );

    my $ns_service = Solstice::NamespaceService->new();
    $ns_service->_setAppNamespace($profile->{'config_namespace'});
    
    Solstice::Server->new()->setPostMax($profile->{'post_max'});

    my $controller = Solstice::Controller::Application::Main->new();

    $controller->setEscapeFrames( $profile->{'escape_frames'} );
    $controller->setDisableBackButton( $profile->{'disable_back_button'} );
    $controller->setViewTopNav( $profile->{'view_top_nav'} );
    $controller->setInitialState( $profile->{'initial_state'} );
    $controller->setDocumentTitle( $profile->{'title'} );
    $controller->setBoilerplateView( $profile->{'boilerplate_view'} );
    $controller->setPageFlow( $profile->{'pageflow'} );
    $controller->setRequireSession( defined $profile->{'require_session'} ? $profile->{'require_session'} : TRUE );
    $controller->setRequiresAuth( defined $profile->{'requires_auth'} ? $profile->{'requires_auth'} : TRUE );


    $controller->runApp($screen);

    my $user_service = Solstice::UserService->new();
    my $orig_user = $user_service->getOriginalUser() ? $user_service->getOriginalUser()->getLoginName(): '-';
    my $user = $user_service->getUser() ? $user_service->getUser()->getLoginName() : '-';

    Solstice::LogService->new()->log({
            namespace   => 'Solstice',
            log_file    => 'app_url_log',
            content     => 
            "Acting as: ". ($user eq $orig_user ? '-' : $user).
            ", PostClick: ". ($controller->getPostClickState() || '-') .
            ", Action: ". ($controller->getAction() || '-') .
            ", PreClick: ". ($controller->getPreClickState() || '-') .
            ", Time: ".  tv_interval($start_time, [gettimeofday])
        });

    return;
}


=item runCGIURL 

if the URL is handled by a simple CGI, fire it up.

=cut

sub runCGIURL {
    my ($cgi_profile) = @_;

    my $script_loaded = $CGIS{$cgi_profile->{'filesys_path'}};
    my $file_info = stat($cgi_profile->{'filesys_path'});
    my $file_modified = $file_info->mtime;

    # Create a namespace for each cgi... this is a bit ugly... tried to make it so this could be cross platform
    my $package = "Solstice::Handler::$cgi_profile->{'filesys_path'}";
    $package =~ s/\./__/g;
    $package =~ s'/|\\'::'g;
    $package =~ s/::([:]+)/::/g;

    if (!defined $script_loaded or ($script_loaded < $file_modified)) {
        local($/, undef);
        open(my $FILE, "<", $cgi_profile->{'filesys_path'}) or die "Unable to open: $cgi_profile->{'filesys_path'}\n";
        my $script = "package $package; sub handler {".join("\n",<$FILE>)."}";
        close($FILE);

        eval $script; ## no critic
        if ($@) {
            die 'Unable to load '.$cgi_profile->{'filesys_path'}." : $@\n";
        }
        else {
            $CGIS{$cgi_profile->{'filesys_path'}} = time;
        }
    }
    { ## no critic
        no strict 'refs';
        eval { &{"${package}::handler"}() };
        if ($@) {
            delete $CGIS{$cgi_profile->{'filesys_path'}};
            die "Error in ".$cgi_profile->{'filesys_path'}." : $@\n";
        }
        return;
    }
}


=item serveStaticContent($filename)

find and serve a static file 

=cut

sub serveStaticContent {
    my ($filename) = @_;

    return FALSE unless (-f $filename);

    my $server = Solstice::Server->new();
    if( $server->getMeetsConditions($filename) ) {
        my $type_service = Solstice::ContentTypeService->new();
        if( my $type = $type_service->getContentTypeByFilename($filename) ){
            if( $type_service->isTextType($type) && !$type_service->includesCharset($type) ){
                $type .= '; charset=UTF-8';
            }
            $server->setContentType($type);
        }else{
            $server->setContentType($type_service->getDownloadContentType());
        }
        $server->printHeaders();

        if( open(my $fh, '<', $filename) ){
            while(<$fh>){
                print $_;
            }
            close $fh;
        }
    }
    return TRUE;
}


=item handleError 

if our eval fails, we run this to try and recover

=cut

sub handleError {
    my ($error, $url, $r) = @_;

    my $server = Solstice::Server->new();
    $@ = undef; #clear this out, we have some evals to do 

    # Avoid specific nuisance 500s
    # http://httpd.apache.org/docs/1.3/misc/FAQ.html#peerreset
    return if ($error =~ /Connection reset by peer/);
    return if ($error =~ /^Apache2::RequestIO::sendfile:/);

    # There are some errors that we know about, and while they need to halt execution, they shouldn't send us email.
    # An example of this is a user with no session making remote calls.
    return if ($error =~ /^Solstice Exception: /);

    #Print an error to the logs
    my $err;

    #gather some useful info
    $err .= "URL: $url\n";
    $err .= "Remote User: ". $ENV{'REMOTE_USER'} ."\n" if $ENV{'REMOTE_USER'};

    my $sess_user = eval{ return Solstice::UserService->new()->getUser()->getLoginName();};
    if(!$@ && $sess_user){
        $err .="Session User: $sess_user\n";
    }

    $@ = undef;
    my $orig_user = eval{ return Solstice::UserService->new()->getOriginalUser()->getLoginName();};
    if(!$@ && $orig_user){
        $err .="Original User: $orig_user\n";
    }


    chomp $error;
    $err .=  "$error\n";
    print STDERR "==== Solstice Application Error ====\n$err====================================\n";

    if(Solstice::Configure->new()->getDevelopmentMode()){
        if(!$server->getContentType()){
            $server->setContentType('text/html');
        }
        $err =~ s/\n/<br>\n/g;
        $server->printHeaders();
        print "<html><body><span style='color:red;'>Solstice Application Error</span><br/><code>$err</code></body></html>";
    }else{


        my $run_default_error = TRUE;
        #First, try to run the app-defined error handler
        $@ = undef;
        eval{
            die "500 on home screen\n" if Solstice::CGI::param('solstice_err');
            my $ns_service = Solstice::NamespaceService->new();
            my $app_config = Solstice::Configure->new($ns_service->getAppNamespace());

            if(defined $app_config->getErrorHandler() && $app_config->getErrorHandler()){

                my $handler = $app_config->getErrorHandler();
                Solstice->new()->loadModule($handler);
                eval {
                    $handler->new($error)->handleError();
                }; die "$handler->handleError(): $@\n" if $@;
                $run_default_error = FALSE;
            }
        };
        print STDERR "==== Solstice Application Error ====\nErrorHandler for URI $url failed:\n$@\n========================\n" if $@;

        #Otherwise, run something generic
        if($run_default_error){

            #send some email
            Solstice::ErrorHandler->new($error)->sendAlert();

            #print a message
            if(!$server->getContentType()){
                $server->setContentType('text/html');
            }
            my $error_html = Solstice::Configure->new()->getErrorHTML();
            $server->printHeaders();
            print $error_html || 'Solstice has experienced an error.';
        }
    }
}

=item show404($url, $screen)

=cut

sub show404 {
    my ($url, $screen) = @_;

    print STDERR "Solstice 404: $url not handled!\n";

    my $server = Solstice::Server->new();
    $server->setStatus(404);
    $server->setContentType('text/html');

    my $config = Solstice::Configure->new(); 

    my $boiler_pkg = $config->getBoilerplateView() || 'Solstice::View::Boilerplate';
    Solstice->new()->loadModule($boiler_pkg);
    my $boiler_view = $boiler_pkg->new();

    my $title = Solstice::LangService->new()->getString('404_title');
    if ($config->defined('404_view') && $config->get('404_view') ){ 
        my $error_pkg = $config->get('404_view');
        Solstice->new()->loadModule($error_pkg);
        my $error_view = $error_pkg->new($url);
        $boiler_view->addChildView('content', $error_view);
    } else {
        $boiler_view->setParam('content', "<h1>$title</h1>"); 
    }

    my $app_view = Solstice::View::Application->new();  
    $app_view->setDocumentTitle($title);
    $app_view->addChildView('boilerplate', $boiler_view);
    $app_view->paint($screen);
}

=item redirectToSSL()

=cut

sub redirectToSSL {
    my $url = shift;
    my $screen = shift;

    my $view = Solstice::View::Redirect->new($url);
    $view->sendHeaders();
    $view->printData();
}

=item showWelcomeScreen($url)

This shows a message to people who have just installed Solstice, but no applications.

=cut

sub showWelcomeScreen {
    my ($url, $screen) = @_;

    my $usable_url = $url;
    $usable_url =~ s/\/+$//; #chop any trailing slashes

    my $config = Solstice::Configure->new();
    if($url =~ /installer\/$/ && $config->getNoConfig() ){
        #create a custom cgi profile that specifies the installer
        runCGIURL({
                filesys_path => $config->getRoot(). '/cgis/configure_solstice.pl', 
                requires_auth => 0
            });
    }else{
        Solstice::Server->new()->setContentType('text/html');
        my $lang_service = Solstice::LangService->new();
        if($config->getNoConfig()){
            $$screen = $lang_service->getString('welcome_to_solstice', {
                    installer_info => $lang_service->getString('solstice_installer_info', {
                            url => $usable_url,
                        }),
                });
        }else{
            $$screen = $lang_service->getString('welcome_to_solstice');
        }
    }
}

1;

__END__

=back

=cut

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
