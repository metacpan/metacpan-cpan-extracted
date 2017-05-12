package Solstice::Configure;

# $Id: Configure.pm 3374 2006-05-09 17:10:39Z pmichaud $

=head1 NAME

Solstice::Configure - Provides configuration info to the Solstice Framework

=head1 SYNOPSIS

  use Solstice::Configure;
  
  my $config = Solstice::Configure->new();
  
  # This creates a new configation object.  The first time this happens,
  # Solstice::Configure attempts to locate the central Solstice configuration file,
  # and then to locate the config files for all installed applications.  This
  # happens automatically when Solstice is used as an Apache handler, but when
  # writing scripts, you may notice a delay as modules are loaded to parse and
  # handle all the application config files.
  
  my $config = Solstice::Configure->new('WebQ');
  $config->setSection('RRef');
  
  # Normally, access is given only to the central config keys, but when
  # Solstice::Configure is given an application name (namespace) the keys defined
  # in that app's config file are availble. This can be done either at the
  # constructor or with setSection().
  
  my $value = $config->get('KEY');
  
  # This retrieves the key specified in the config file.  If no namespace was
  # provided, it only searches the central config file.  otherwise it searches
  # the app-specfic config first and then the central one.
  
  # Required configuration directives are offered via accessor:
  
  # Central Solstice configuration:
  $value = $config->getRoot();                #solstice filesystem root
  $value = $config->getVirtualRoot();            #Solstice URL root
  $value = $config->getURL();                    #synonmy for getVirtualRoot()
  $value = $config->getServerString();        #A string identfying the server
  $value = $config->getAdminEmail();            #backend email - not shown to user
  $value = $config->getSupportEmail();        #public email - shown to user
  $value = $config->getDBName();              #Database Name
  $value = $config->getDBHost();                #Database Host
  $value = $config->getDBPort();                #database port
  $value = $config->getDBUser();                #Database login user
  $value = $config->getDBPassword();            #Database password
  $value = $config->getEncryptionKey();        #Key to use for encryption
  $value = $config->getBoilerplateView();        #View module to use to paint boilerplate
  $value = $config->getAppDirs();                #List of paths where apps may live
  $value = $config->getNamespaces();            #List of all the app namespaces that were loaded
  
  # Shared directives - legal in both Solstice and application configs
  $value = $config->getCSSFiles();            #List of css files to include 
  $value = $config->getJSFiles();                #List of js files to include
  $value = $config->getStaticDirs();            #List of image/static content dirs to allow
  $value = $config->getCGIUrls();                #list of non-framework cgis to allow
  
  # Application-only directives
  $value = $config->getAppRoot();                #filesystem location of app
  $value = $config->getAppVirtualRoot();        #URL of app, relative to solstice virtual root
  $value = $config->getAppURL();                #synonym for getAppVirtualRoot
  $value = $config->getAppUrls();                #URLS handled by this app, relative to app URL
  $value = $config->getStartupFiles();        #List of startup files to run
  $value = $config->getErrorHandler();        #class used to handle errors in the app


=head1 DESCRIPTION

Solstice::Configure is used to provide configuration data to applications, and
the solstice framework as a whole.

The central Solstice configuation file must be named "solstice_config.xml" and
should be located either in the directory specified in the environment variable
SOLSTICE_CONFIG_PATH, in the root of the solstice install, or in the /conf/
directory within the solstice install.  If the ENV variable is not set, the
Solstice /functions/ dir must be in Perl's @INC list for the config file to be
found.

Application config files must be named "config.xml" and must be placed at the
root of the application folder, as specified in the application layout.

An example Solstice config file and an example application config file can be
found in the Solstice /conf/ directory.

=over 4

=cut

use strict;
use warnings;
use 5.006_000;

our ($VERSION) = ('$Revision: 3374 $' =~ /^\$Revision:\s*([\d.]*)/);
use base qw(Solstice::Service::Memory);

use File::stat;
use XML::LibXML;
use Solstice::Service::Debug;
use Solstice::Model::Config::Solstice;
use Solstice::Model::Config::App;

use constant CONFIG_FILE_ENV_KEY => 'SOLSTICE_CONFIG_PATH';
use constant GLOBAL_CONFIG       => 'STANDARD';
use constant ELEMENT_TYPE        => 1;
use constant COMPILED_VIEW_DIR_NAME => 'solstice_compiled_views';
use constant REST_ROOT_DEFAULT => 'rest/';


use constant TRUE  => 1;
use constant FALSE => 0;

our $group_tags = {
    keys        => 'key',
    statics     => 'static',
    remotes     => 'remote',
    webservices    => 'resource',
    js_files    => 'js_file',
    css_files   => 'css_file',
    app_dirs    => 'app_dir',
    urls        => 'url',
    cgis        => 'cgi',
    log_modules => 'module',
    memcached_servers=> 'server',
    db_hosts    => 'host',
};


sub new {
    my $pkg     = shift;
    my $section = shift;
    my $self    = $pkg->SUPER::new(@_);

    $self->setSection(undef);

    $self->{'_url_collision_detector'} = {};
    $self->{'_namespace_collision_detector'} = {};
    $self->_initialize();

    $self->setSection($section);

    return $self;
}

sub _initialize {
    my $self = shift;

    my $been_initialized = $self->getValue('config_initialized');
    return TRUE if (defined $been_initialized && ! $self->getDevelopmentMode());

    #grab the main configuration
    $self->_parseSolsticeConfig();

    #and the app-specific ones
    for my $config_file ($self->_getAppConfigFiles()) {
        $self->_parseAppConfig($config_file);
    }

    #now that all of our app libs are in @INC we may load up all application files
    for my $namespace ($self->getNamespaces()) {
        $self->_initApplicationObject($namespace);
    }

    $self->setValue('config_initialized', TRUE);
    return TRUE;
}

sub _parseSolsticeConfig {
    my $self = shift;

    my $config_file = $self->_locateConfigFile();
    my $schema_file = $self->_locateSchemaPath().'/solstice_config.xsd';

    if (!defined $config_file) {
        $self->_generateDefaultSolsticeConfigValues();
        return TRUE;
    }else{
        $self->setValue(GLOBAL_CONFIG . '__solstice__NO_CONFIG', FALSE);
    }
    
    return TRUE unless $self->_requiresParsing($config_file);

    my $config = Solstice::Model::Config::Solstice->new($config_file, $schema_file);
    
    $self->_addConfigurationKeys(GLOBAL_CONFIG, $config->getKeys());
    $self->_addRemoteDefinitions('Solstice', $config->getRemotes());
    $self->_addDBHosts(GLOBAL_CONFIG, $config->getDBHosts());

    #This sets up the reserved values for our accessors
    $self->setValue(GLOBAL_CONFIG . '__solstice__app_dirs', $config->getAppDirs());
    $self->setValue(GLOBAL_CONFIG . '__solstice__log_modules', $config->getLogModules());
    $self->setValue(GLOBAL_CONFIG . '__solstice__js_files', $config->getJSFiles());
    $self->setValue(GLOBAL_CONFIG . '__solstice__css_files', $config->getCSSFiles());
    $self->setValue(GLOBAL_CONFIG . '__solstice__memcached_servers', $config->getMemcachedServers());
    $self->setValue(GLOBAL_CONFIG . '__solstice__VIRTUAL_ROOT',      $config->getVirtualRoot());
    $self->setValue(GLOBAL_CONFIG . '__solstice__WEBSERVICE_REST_ROOT',$config->getWebserviceRestRoot());
    $self->setValue(GLOBAL_CONFIG . '__solstice__SERVER_STRING',     $config->getServerString());
    $self->setValue(GLOBAL_CONFIG . '__solstice__ADMIN_EMAIL',       $config->getAdminEmail());
    $self->setValue(GLOBAL_CONFIG . '__solstice__SUPPORT_EMAIL',     $config->getSupportEmail());
    $self->setValue(GLOBAL_CONFIG . '__solstice__LANG',              $config->getLang());
    $self->setValue(GLOBAL_CONFIG . '__solstice__DEBUG_LEVEL',       $config->getDebugLevel());
    $self->setValue(GLOBAL_CONFIG . '__solstice__ENCRYPTION_KEY',    $config->getEncryptionKey());
    $self->setValue(GLOBAL_CONFIG . '__solstice__BOILER_VIEW',       $config->getBoilerplateView());
    $self->setValue(GLOBAL_CONFIG . '__solstice__DATA_ROOT',         $config->getDataRoot());
    $self->setValue(GLOBAL_CONFIG . '__solstice__ERROR_HTML',        $config->getErrorHTML());
    $self->setValue(GLOBAL_CONFIG . '__solstice__SESSION_BACKEND',    $config->getSessionBackend());
    $self->setValue(GLOBAL_CONFIG . '__solstice__SESSION_DB',         $config->getSessionDB());
    $self->setValue(GLOBAL_CONFIG . '__solstice__SESSION_COOKIE',     $config->getSessionCookie());
    $self->setValue(GLOBAL_CONFIG . '__solstice__SMTP_SERVER',        $config->getSMTPServer());
    $self->setValue(GLOBAL_CONFIG . '__solstice__MAILNAME',           $config->getSMTPMailname());
    $self->setValue(GLOBAL_CONFIG . '__solstice__MAIL_DELAY',         $config->getSMTPMessageWait());

    if( defined $config->getSMTPUseQueue() && $config->getSMTPUseQueue() !~ /^(always|optional|never)$/){
        die "The <smtp_use_queue> option may only be 'optional', 'always', or 'never'.  Please check your solstice_config.xml file.\n";
    }
    $self->setValue(GLOBAL_CONFIG . '__solstice__USE_QUEUE',          $config->getSMTPUseQueue());
    $self->setValue(GLOBAL_CONFIG . '__solstice__COMP_VIEW_PATH',     $config->getCompiledViewPath());
    $self->setValue(GLOBAL_CONFIG . '__solstice__DEVELOPMENT_MODE',   $config->getDevelopmentMode());
    $self->setValue(GLOBAL_CONFIG . '__solstice__require_ssl',        $config->getRequireSsl());
    $self->setValue(GLOBAL_CONFIG . '__solstice__SLOW_QUERY_TIME',    $config->getSlowQueryTime());

    #get the cgis and static content dirs into the virtual url map
    $self->_virtualPathExtractor({'statics' => $config->getStaticDirs()}, 'statics', 'static_dirs', $self->getRoot(), 'main solstice_config.xml');
    $self->_virtualPathExtractor({cgis => $config->getCGIs()}, 'cgis',    'cgis',        $self->getRoot(), 'main solstice_config.xml', 'Solstice');

    $self->_configParsed($config_file);
}

=item _generateDefaultSolsticeConfigValues()

This is used when the example_solstice_config hasn't been copied to the solstice_config yet... this 
creates enough values for the screens to get up and running.

=cut

sub _generateDefaultSolsticeConfigValues {
    my $self = shift;

    my $root = $self->getRoot();
    
    $self->setValue(GLOBAL_CONFIG . '__solstice__ROOT', $root);
    $self->setValue(GLOBAL_CONFIG . '__solstice__remote_defs', {}); 
    $self->setValue(GLOBAL_CONFIG . '__solstice__LANG', 'en');
    $self->setValue(GLOBAL_CONFIG . '__solstice__NO_CONFIG', TRUE);
}

sub _parseAppConfig {
    my ($self, $filename) = @_;

    return TRUE unless $self->_requiresParsing($filename);

    my $schema_file = $self->_locateSchemaPath() .'/app_config.xsd';

    my $config = Solstice::Model::Config::App->new($filename, $schema_file);
    
    my $namespace = $config->getConfigNamespace();
    die "<config_namespace>KEY</config_namespace> required in app conf file $filename\n" unless $namespace;
    $self->addNamespace($namespace);
    die "Namespace $namespace used by multiple applications!\n" if $self->{'_namespace_collision_detector'}{$namespace};
    $self->{'_namespace_collision_detector'}{$namespace} = TRUE;


    $self->_addConfigurationKeys($namespace, $config->getKeys());
    $self->_addRemoteDefinitions($namespace, $config->getRemotes());

    my $app_root = $filename;
    $app_root =~ s/config\.xml$//;

    unshift @INC, $app_root.'lib';

    $self->_virtualPathExtractor({ urls => $config->getURLs()}, 'urls', 'app_urls', $app_root, $app_root . '/config.xml', $namespace, $config->getApplicationURL());
    $self->_virtualPathExtractor({ statics => $config->getStaticDirs()}, 'statics', 'static_dirs', $app_root, $app_root . '/config.xml', undef, $config->getApplicationURL());
    $self->_virtualPathExtractor({ cgis => $config->getCGIs()}, 'cgis',    'cgis',        $app_root, $app_root . '/config.xml', $namespace, $config->getApplicationURL());
    $self->_virtualPathExtractor({ webservices => $config->getWebservices()}, 'webservices',    'webservices',        $app_root, $app_root . '/config.xml', $namespace, $config->getApplicationURL());

    $self->setValue($namespace . '__solstice__app_root', $app_root);
    $self->setValue($namespace . '__solstice__app_url',  $config->getApplicationURL());
    $self->setValue($namespace . '__solstice__js_files', $config->getJSFiles());
    $self->setValue($namespace . '__solstice__css_files', $config->getCSSFiles());
    $self->setValue($namespace . '__solstice__error_handler',          $config->getErrorHandler);
    $self->setValue($namespace . '__solstice__db_name',  $config->getDBName());
    
    # Pageflow xml file?
    # TODO: it might be better to remove this section (and the associated
    # getStateFiles() method) and let Solstice::State::Machine::initialize
    # handle its own discovery, but right now we don't really have a clean
    # way to get all installed namespaces/app_roots.
    my $state_file_path = $app_root . 'pageflow.xml';
    if (-f $state_file_path) {
        my $memory_key = GLOBAL_CONFIG . '__solstice__state_files';
        my $state_files = $self->getValue($memory_key) || {};
        $state_files->{$namespace} = $state_file_path;
        $self->setValue($memory_key, $state_files);
    }

    # Startup file?
    my $startup_file_path = $app_root . 'startup.pl';
    if (-f $startup_file_path) {
        my $startup_files = $self->getValue(GLOBAL_CONFIG . '__solstice__startup_files') || [];
        push @$startup_files, $startup_file_path; 
        $self->setValue(GLOBAL_CONFIG . '__solstice__startup_files', $startup_files);
    }
    
    $self->_configParsed($filename);
}

sub _initApplicationObject {
    my $self = shift;
    my $namespace = shift;
 
    return TRUE if $self->_hasLoadedApplication($namespace);

    #load Application object if present
    for my $lib_dir (@INC){
        if( -f "$lib_dir/$namespace/Application.pm" ){
            $self->loadModule($namespace.'::Application');
        }
    }
    
    $self->_setHasLoadedApplication($namespace);
}

sub _hasLoadedApplication {
    my $self = shift;
    my $namespace = shift;
    return $self->getValue(GLOBAL_CONFIG. '__solstice_ns_loaded__'.$namespace);
}

sub _setHasLoadedApplication {
    my $self = shift;
    my $namespace= shift;
    $self->setValue(GLOBAL_CONFIG.'__solstice_ns_loaded__'.$namespace,TRUE);
}
# AKA _virtualPathTracker
# AKA _virtualPathMan
sub _virtualPathExtractor {
    my $self            = shift;
    my $config          = shift;
    my $key             = shift;
    my $destination     = shift;
    my $app_root        = shift;
    my $source          = shift;
    my $namespace       = shift;
    my $application_url = shift;


    # Add to our app hash.  It's up to the handler to determine how this relates to the root of the solstice install.
    my $app_urls = $self->getValue(GLOBAL_CONFIG . '__solstice__' . $destination) || {};
    if ($config->{$key} && ref $config->{$key} eq 'ARRAY') {
        foreach my $url (@{$config->{$key}}) {

            my $virtual_url = defined $application_url ? $application_url . '/' . $url->{virtual_path} : $url->{virtual_path};
            $virtual_url = "/".$self->getWebServiceRestRoot(). "/$virtual_url" if $key eq 'webservices';
            $virtual_url = "/" . $self->getVirtualRoot() . "/$virtual_url/";
            $virtual_url =~ s/\/+/\//g;
            $virtual_url =~ s/\/*$//g if $key eq 'cgis';
            my $detector_hash    = $self->{_url_collision_detector};
            my $type             = $key eq "statics" ? "static directory" : "URL";
            my $collision_string = "$type $virtual_url from $source";

            if (defined $detector_hash->{$virtual_url}) {
                die $detector_hash->{$virtual_url} . " collides with " . $collision_string ."\n";
            } else {
                $detector_hash->{$virtual_url} = $collision_string;

                #add the full path if neccessary
                if (!defined $url->{'filesys_path'}) {
                    $url->{'filesys_path'} = '';
                }
                $url->{'filesys_path'} = $app_root . '/' . $url->{'filesys_path'};

                $url->{'config_namespace'} = $namespace if defined $namespace;
                $app_urls->{$virtual_url} = $url;
            }
        }
    }
    $self->setValue(GLOBAL_CONFIG . '__solstice__' . $destination, $app_urls);
}

sub _getAppConfigFiles {
    my $self = shift;

    return @{$self->getValue('__solstice_app_config_files')} if ($self->getValue('__solstice_app_config_files') && ! $self->getDevelopmentMode());

    my @app_config_files;

    for my $app_dir (@{$self->getAppDirs()}) {
        opendir(my $dir_handle, $app_dir);
        for my $entry (grep {!/^\./ && -d "$app_dir/$_"} readdir($dir_handle)) {
            my $filename = "$app_dir/$entry/config.xml";
            if (-f $filename) {
                push @app_config_files, $filename;
            }
        }
    }

    $self->setValue('__solstice_app_config_files', \@app_config_files);
    return @app_config_files;
}

=item _configParsed(PATH_TO_CONFIG)

Marks a configuration file as having been parsed, at the current time.  This time is checked
against the modification date of the config file during processing by _requiresParsing(PATH_TO_CONFIG) 

=cut

sub _configParsed {
    my $self           = shift;
    my $path_to_config = shift;
    return FALSE unless defined $path_to_config;

    $self->setValue('__parsed_config_timestamp__' . $path_to_config, time);
    return TRUE;
}

=item _requiresParsing(PATH_TO_CONFIG)

This is the gatekeeper for each config file's parsing.  If the file hasn't been parsed yet, 
or if the file has been modified since the last time it was parsed, this will let a new 
parsing run happen.  Otherwise, this will return false, preventing an unneccesary parse.

=cut

sub _requiresParsing {
    my $self           = shift;
    my $path_to_config = shift;

    return FALSE unless defined $path_to_config;

    my $last_parsed = $self->getValue('__parsed_config_timestamp__' . $path_to_config);
    if (!defined $last_parsed) {
        return TRUE;
    }

    my $file_info = stat($path_to_config);
    return TRUE unless $file_info;
    if ($file_info->mtime > $last_parsed) {
        return TRUE;
    }
    return FALSE;
}

sub addNamespace {
    my $self = shift;
    my $namespaces_ref = $self->getValue(GLOBAL_CONFIG . "__solstice__NAMESPACES") || [];
    push @$namespaces_ref, shift;
    $self->setValue(GLOBAL_CONFIG . "__solstice__NAMESPACES", $namespaces_ref);
}

sub getNamespaces {
    my $self = shift;
    return $self->getValue(GLOBAL_CONFIG . "__solstice__NAMESPACES") || [];
}

sub getWebServiceRestRoot {
    my $self = shift;
    return $self->getValue(GLOBAL_CONFIG . '__solstice__WEBSERVICE_REST_ROOT') || REST_ROOT_DEFAULT;
}

sub getURL {
    my $self = shift;
    return $self->getValue(GLOBAL_CONFIG . '__solstice__VIRTUAL_ROOT') || '';
}

sub getDataRoot {
    my $self = shift;
    return $self->getValue(GLOBAL_CONFIG . '__solstice__DATA_ROOT') || '';
}

sub getVirtualRoot {    #alias
    my $self = shift;
    return $self->getURL();
}

sub getServerString {
    my $self = shift;
    return $self->getValue(GLOBAL_CONFIG . '__solstice__SERVER_STRING') || '';
}

sub getAdminEmail {
    my $self = shift;
    return $self->getValue(GLOBAL_CONFIG . '__solstice__ADMIN_EMAIL') || '';
}

sub getSupportEmail {
    my $self = shift;
    return $self->getValue(GLOBAL_CONFIG . '__solstice__SUPPORT_EMAIL') || '';
}

sub getDBSlaves {
    my $self = shift;
    return $self->getValue(GLOBAL_CONFIG . '__solstice__DB_SLAVES') || [];
}
=item getDBSlave

Returns a hash that contains all the information about a database slave (returns this at random)

=cut

sub getDBSlave {
    my $self = shift;
    my $slaves = $self->getDBSlaves();
    return undef unless scalar @$slaves;

    return $slaves->[int(rand(scalar @$slaves))];
}

sub getDBHost {
    my $self = shift;
    return $self->getValue(GLOBAL_CONFIG . '__solstice__DB_HOST') || '';
}

sub getDBPort {
    my $self = shift;
    return $self->getValue(GLOBAL_CONFIG . '__solstice__DB_PORT') || '';
}

sub getDBUser {
    my $self = shift;
    return $self->getValue(GLOBAL_CONFIG . '__solstice__DB_USER') || '';
}

sub getCentralDebugLevel {
    my $self = shift;
    return $self->getValue(GLOBAL_CONFIG . '__solstice__DEBUG_LEVEL') || '';
}

sub getDBPassword {
    my $self = shift;
    return $self->getValue(GLOBAL_CONFIG . '__solstice__DB_PASSWORD') || '';
}

sub getDBName {
    my $self = shift;
    return $self->getValue(GLOBAL_CONFIG . '__solstice__DB_NAME') || '';
}

sub getEncryptionKey {
    my $self = shift;
    return $self->getValue(GLOBAL_CONFIG . '__solstice__ENCRYPTION_KEY') || '';
}

sub getLang {
    my $self = shift;
    return $self->getValue(GLOBAL_CONFIG . '__solstice__LANG');
}

sub getBoilerplateView {
    my $self = shift;
    return $self->getValue(GLOBAL_CONFIG . '__solstice__BOILER_VIEW') || '';
}

sub getErrorHTML {
    my $self = shift;
    return $self->getValue(GLOBAL_CONFIG . '__solstice__ERROR_HTML');
}

sub getAppDirs {
    my $self = shift;
    return $self->getValue(GLOBAL_CONFIG . '__solstice__app_dirs') || [];
}

sub getCSSFiles {
    my $self = shift;
    return $self->getValue($self->_getSection() . '__solstice__css_files') || [];
}

sub getJSFiles {
    my $self = shift;
    return $self->getValue($self->_getSection() . '__solstice__js_files') || [];
}

sub getLogModules {
    my $self = shift;
    return $self->getValue(GLOBAL_CONFIG . '__solstice__log_modules') || [];
}

sub getStaticDirs {
    my $self = shift;
    return $self->getValue(GLOBAL_CONFIG . '__solstice__static_dirs') || {};
}

sub getCGIUrls {
    my $self = shift;
    return $self->getValue(GLOBAL_CONFIG . '__solstice__cgis') || {};
}

sub getAppUrls {
    my $self = shift;
    return $self->getValue(GLOBAL_CONFIG . '__solstice__app_urls') || {};
}

sub getWebserviceUrls {
    my $self = shift;
    return $self->getValue(GLOBAL_CONFIG . '__solstice__webservices') || {};
}

sub getStartupFiles {
    my $self = shift;
    return $self->getValue(GLOBAL_CONFIG . '__solstice__startup_files') || [];
}

sub getStateFiles {
    my $self = shift;
    return $self->getValue(GLOBAL_CONFIG . '__solstice__state_files') || {};
}

sub getAppVirtualRoot {    #alias
    my $self = shift;
    return $self->getAppURL();
}

sub getAppURL {
    my $self = shift;
    return $self->getValue($self->_getSection() . '__solstice__app_url');
}

sub getAppRoot {
    my $self = shift;
    return $self->getValue($self->_getSection() . '__solstice__app_root');
}

sub getAppLibraryPath {
    my $self = shift;
    return $self->getAppRoot().'lib';
}

sub getAppTemplatePath {
    my $self = shift;
    return $self->getAppRoot().'templates';
}

sub getAppDBName {
    my $self = shift;
    return $self->getValue($self->_getSection() . '__solstice__db_name') || '';
}

sub getErrorHandler {
    my $self = shift;
    return $self->getValue($self->_getSection() . '__solstice__error_handler');
}

sub getRemoteDefs {
    my $self = shift;
    return $self->getValue(GLOBAL_CONFIG . '__solstice__remote_defs');
}


sub getSessionBackend {
    my $self = shift;
    return $self->getValue(GLOBAL_CONFIG . '__solstice__SESSION_BACKEND') || 'MySQL';
}

sub getSessionDB {
    my $self = shift;
    return $self->getValue(GLOBAL_CONFIG . '__solstice__SESSION_DB') || '';
}

sub getSessionCookie {
    my $self = shift;
    return $self->getValue(GLOBAL_CONFIG . '__solstice__SESSION_COOKIE') || '';
}

sub getSMTPServer {
    my $self = shift;
    return $self->getValue(GLOBAL_CONFIG . '__solstice__SMTP_SERVER') || '';
}

sub getSMTPMailname {
    my $self = shift;
    return $self->getValue(GLOBAL_CONFIG . '__solstice__MAILNAME') || '';
}

sub getSMTPMessageWait {
    my $self = shift;
    return $self->getValue(GLOBAL_CONFIG . '__solstice__MAIL_DELAY') || 0.5;
}

sub getSMTPUseQueue {
    my $self = shift;
    return $self->getValue(GLOBAL_CONFIG . '__solstice__USE_QUEUE') || 'optional';
}

sub getCompiledViewPath {
    my $self = shift;
    my $path = $self->getDataRoot() ? $self->getDataRoot() : '/tmp/';
    $path = $path.'/'. COMPILED_VIEW_DIR_NAME;
    $path =~ s/\/+/\//g;
    return $path;
}

sub getDevelopmentMode {
    my $self = shift;
    return $self->getValue(GLOBAL_CONFIG . '__solstice__DEVELOPMENT_MODE') || '';
}

sub getRequireSSL {
    my $self = shift;
    return $self->getValue(GLOBAL_CONFIG . '__solstice__require_ssl') || FALSE;
}

sub getMemcachedServers {
    my $self = shift;
    return $self->getValue(GLOBAL_CONFIG .'__solstice__memcached_servers');
}

=item setDevelopmentMode()

This should only be called from tests, where development modes need to be tested programatically instead of being read from a config file.

=cut

sub setDevelopmentMode {
    my $self = shift;
    $self->setValue(GLOBAL_CONFIG . '__solstice__DEVELOPMENT_MODE', shift);
}

sub getSlowQueryTime {
    my $self = shift;
    return $self->getValue(GLOBAL_CONFIG . '__solstice__SLOW_QUERY_TIME') || '';
}

sub getNoConfig {
    my $self = shift;
    return $self->getValue(GLOBAL_CONFIG . '__solstice__NO_CONFIG') || FALSE;
}

=item _addDBHosts($namespace_tag, $array_of_hashrefs)

=cut

sub _addDBHosts {
    my ($self, $namespace, $config) = @_;


    my $slaves;
    for my $hash ( @{$config}) {
        if(($hash->{'type'} && $hash->{'type'} eq 'master') || scalar @{$config} ==1){
            $self->setValue(GLOBAL_CONFIG . '__solstice__DB_HOST',           $hash->{'host_name'});
            $self->setValue(GLOBAL_CONFIG . '__solstice__DB_PORT',           $hash->{'port'});
            $self->setValue(GLOBAL_CONFIG . '__solstice__DB_USER',           $hash->{'user'});
            $self->setValue(GLOBAL_CONFIG . '__solstice__DB_PASSWORD',       $hash->{'password'});
            $self->setValue(GLOBAL_CONFIG . '__solstice__DB_NAME',           $hash->{'database_name'});
        }else{
            next unless defined $hash && defined $hash->{'host_name'};

            #set some defaults unless the slave specified them already
            #XXX this will work great as long as we've already seen the master
            # what if the master isn't the first db specified?
            $hash->{'port'} = $self->getDBPort() unless defined $hash->{'port'};
            $hash->{'user'} = $self->getDBUser() unless defined $hash->{'user'};
            $hash->{'password'} = $self->getDBPassword() unless defined $hash->{'password'};
            $hash->{'database_name'} = $self->getDBName() unless defined $hash->{'database_name'};

            push @$slaves, $hash;
        }
    }
    $self->setValue(GLOBAL_CONFIG . '__solstice__DB_SLAVES', $slaves);
}


=item _addConfigurationKeys($namespace_tag, $hashref_of_keys)

=cut

sub _addConfigurationKeys {
    my ($self, $namespace, $config) = @_;

    for my $key (keys %{$config}) {
        $self->setValue($namespace . '__' . $key, $config->{$key});#{'content'});
    }
}

=item _addRemoteDefinitions($namespace_tag, $hashref_of_keys)

=cut

sub _addRemoteDefinitions {
    my ($self, $namespace, $config) = @_;

    my $remote_defs = $self->getValue(GLOBAL_CONFIG . '__solstice__remote_defs');

    unless (defined $remote_defs) {
        $remote_defs = {};
        $self->setValue(GLOBAL_CONFIG . '__solstice__remote_defs', $remote_defs);
    }

    for my $key (keys %{$config}) {
        $remote_defs->{$namespace}{$key} = $config->{$key};#{'content'};
    }
}

sub _getCGIProfile {
    my $self         = shift;
    my $url          = shift;

    my $url_registry = $self->getCGIUrls();
    return $self->_lookupURLProfileFromRegistry($url, $url_registry);
}

sub _getWebserviceProfile {
    my $self = shift;
    my $url = shift;

    my $url_registry = $self->getWebserviceUrls();
    return $self->_lookupURLProfileFromRegistry($url, $url_registry);
}


sub _getURLProfile {
    my $self = shift;
    my $url  = shift;

    my $url_registry = $self->getAppUrls();
    return $self->_lookupURLProfileFromRegistry($url, $url_registry);
}


sub _lookupURLProfileFromRegistry {
    my $self = shift;
        my $url = shift;
        my $url_registry = shift;

    my $url_with_slash;
    my $url_wo_slash;
    if ($url =~ /\/$/) {
        $url_with_slash = $url;
        $url_wo_slash   = $url;
        $url_wo_slash =~ s/\/$//;
    } else {
        $url_wo_slash   = $url;
        $url_with_slash = $url . '/';
    }

    $url_with_slash =~ s/\/+/\//g;
    $url_wo_slash   =~ s/\/+/\//g;


    #first see if we have any extact matches
    if (defined $url_registry->{$url_with_slash} or defined $url_registry->{$url_wo_slash}) {
        return $url_registry->{$url_with_slash} || $url_registry->{$url_wo_slash};
    }

    #then see if there are any prefixes to match  
    #check them in order of longest to shortest, so we get the best match possible
    my @keys = keys %$url_registry;
    @keys = sort{ 
        my $a_count = () = $a =~ /\//g;
        my $b_count = () = $b =~ /\//g;
        return $b_count <=> $a_count;
    } @keys;

    for my $url_original (@keys){
        next unless $url_registry->{$url_original}{'url_is_prefix'};

        my $url_regex = $url_original;

        #pull out the param names from the url and construct our regex
        my @url_param_names = $url_regex =~ /\{(\w+?)\}/g;
        $url_regex =~ s/(\{\w+?\})/(\[^\/]+?)/g;

        if($url_with_slash =~ /^$url_regex/){

            my @params; 
            #Fill our named params if our url included any
            if( @url_param_names ){
                @params = $url_with_slash =~ /^$url_regex/;

                # make the named param hash from the values and names we grabbed above
                my %named_params;
                for(my $i = 0; $i < scalar @url_param_names; $i ++ ){
                    $named_params{$url_param_names[$i]} = $params[$i];
                }

                #add the named params to CGI
                Solstice::CGI->_setNamedURLParams(\%named_params);
            }else{
                Solstice::CGI->_setNamedURLParams({});
            }

            #slice off everything we matched 
            $url_with_slash =~ s/$url_regex//;

            #add any named AND remaining url portions to the array version
            # Remove any leading slashes - CGIs don't have a / appended to the end, so the match above doesn't remove the leading slash for us.
            $url_with_slash =~ s'^/*'';
            push @params, split(/\//, $url_with_slash);
            Solstice::CGI->_setURLParams(\@params);

            return $url_registry->{$url_original};
        }
    }


    return undef;
}


sub _getStaticContent {
    my $self = shift;
    my $url  = shift;

    my $static_registry = $self->getStaticDirs();
    my $candidate_url   = $url;
    $candidate_url =~ s/\s+$//g; #I wonder if this is safe?  but if the url ends in url-enocded whitespace we infinte loop

    # The registry doesn't have multi-slash entries.  We need to stash this new version away, so we can run the regex to get the
    # filename off the url against a url that looks like the candidate, rather than the input.
    $candidate_url =~ s/\/+/\//g;
    my $processed_url = $candidate_url;

    while ($candidate_url) {
        if (defined $static_registry->{$candidate_url}) {
            my $dir_path = $static_registry->{$candidate_url}{'filesys_path'};
            $processed_url =~ /$candidate_url(.*)/;
            my $file_path = $1;
            my $file      = $dir_path . '/' . $file_path;

            return $file;
        }

        if ($candidate_url =~ /\/$/) {
            $candidate_url =~ s/\/$//;
        } else {
            $candidate_url =~ s/([^\/]*?)$//;
        }
    }
    return undef;
}

=item setSection($section)

Set the header in the config file we will be reading from, besides STANDARD.

=cut

sub setSection {
    my $self = shift;
    $self->{'_section'} = shift;
    $self->{'_section'} = GLOBAL_CONFIG unless defined $self->{'_section'};
}

sub _getSection {
    my $self = shift;
    return $self->{'_section'};
}

sub _get {
    my $self         = shift;
    my $key          = shift;
    my $section      = $self->_getSection();
    my $orig_section = $section;

    if (!defined $section) {
        $section = GLOBAL_CONFIG;
    }
    my $value = $self->SUPER::get($section . '__' . $key);
    if (defined $value) {
        return $value;
    }
    $section = GLOBAL_CONFIG;
    $value   = $self->SUPER::get($section . '__' . $key);
    if (defined $value) {
        return $value;
    }
    return undef;
}

sub defined {
    my $self = shift;
    my $key  = shift;

    return defined $self->_get($key) ? TRUE : FALSE;
}

sub get {
    my $self = shift;
    my $key  = shift;

    return $self->_get($key) if defined $self->_get($key);

    my $section = $self->_getSection();
    die "Invalid configuration key: $section -> $key requested from " . join(" ", caller)."\n";
}

=item getRoot ()

Finds the directory that holds the site's Solstice install.

=cut

sub getRoot {
    my $self = shift;

    if( my $cached = $self->getValue(GLOBAL_CONFIG . '__solstice__ROOT')){
        return $cached;
    }

    my $root;

    #check each one for a custom solstice install or a CPAN-style install
    for my $lib_dir (@INC) {
        if (-e "$lib_dir/Solstice.pm" && -d "$lib_dir/../conf/schemas"){
            $root = "$lib_dir/../";

        }elsif (-d "$lib_dir/auto/Solstice/conf/schemas"){
            $root = "$lib_dir/auto/Solstice/";
        }
    }

    if($root){
        $self->setValue(GLOBAL_CONFIG . '__solstice__ROOT', $root);
        return $root;
    }else{
        die "Could not locate a Solstice installation.";
    }
}

sub _locateSchemaPath {
    my $self = shift;
    return $self->getRoot() ."/conf/schemas";
}

sub _locateConfigFile {
    my $self = shift;
    my $file;

    return $self->getValue('__solstice_config_path__') if $self->getValue('__solstice_config_path__');

    my $env_key = CONFIG_FILE_ENV_KEY;
    my $solstice_root = $self->getRoot();

    if (defined $ENV{$env_key} && $ENV{$env_key}) {
        $file = $ENV{$env_key};

    }elsif( -f "/etc/solstice_config.xml" ) {
        $file = "/etc/solstice_config.xml";

    }elsif( -f "$solstice_root/solstice_config.xml") {
        $file = "$solstice_root/solstice_config.xml";

    }elsif (-f "$solstice_root/conf/solstice_config.xml") {
        $file = "$solstice_root/conf/solstice_config.xml";
    }

    if (defined $file) {    
        $self->setValue('__solstice_config_path__', $file);
        return $file;
    }
    else {
        warn "No Solstice config file found.  Setup wizard will be available at 'http://your-host.com/solstice/'\n";
        return undef;
    }
}


=item _getClassName()

Return the class name. Overridden to avoid a ref() in the superclass.

=cut

sub _getClassName {
    return 'Solstice::Configure';
}

1;

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
