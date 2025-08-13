#!/usr/bin/perl

use strict;
use warnings;

# search for Module in same directory where this script is
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin);

use Getopt::Std;
use OcToolkit;
use Data::Dumper;

my $help = "Install/uninstall/backup/validate/upgrade instances and they components into/from Openshift/Kubernetes cluster
Put your templates in 'templates_tt' dir located in current dir. Every component should have own dir(10-api,20-solr,...) inside of it.
Write your templates with Template Toolkit(https://template-toolkit.org) templating engine.
Put your config into oc_config.json. Located in current dir.
   'instance_specific_data' : put your instance specific data in this json node, see example belove and in git
   'instance_specific_name' : instance string will be automatically added at the end of every entry, see example belove and in git
   'project': project specifc data
   oc_config.json root data are fix for every instance
  
Flags description:
  -A cluster base address, e.g.: 'apps.clusterintern' or 'apps.clusterpublic', used in default route url generation
  -a advance features:
    '-a multipleClusters'  if cluster specific templates are required, put them into nested dir
                           e.g.: templates_tt/50-api/clusterIntern/50-deployment-config-api.tt, 
                           ocToolkit will automatically select corresponding templates
                           (currently this flag is selected by default)
     '-a kubectl'          use Kubernetes 'kubectl' instead of default Openshift 'oc' command
     '-a removeClutter'    remove clutter yaml fields during backup
    Use multiple: -a 'multipleClusters;kubectl;removeClutter'
  -b instance name(s), backups specific instance(s) sorted by components e.g.: -b 'dev;test' or -b all to backup whole project(unsorted) 
     if '-a multipleClusters' and not '-b all' is used then '-c' flag is mandatory
  -c cluster name e.g.: 'clusterIntern','clusterPublic'... Default is defined in oc_config.json->project->default_cluster. 
     You should be logged in into corresponding cluster
     If cluster label in url should be different then cluster name, use '-A' flag to set custom cluster url label
  -C config file, default: 'oc_config.json'
  -d instanceName(s), deletes instances from logged in project e.g.: '-d test', see -i documentation
  -h help, prints this help
  -H host, used in default route url generation
  -i instance name(s) e.g.: installs given instances e.g.: 'test;prod'
  -k use(install/delete/validate/upgrade/generate yamls/backup) only specific Openshift/Kubernetes resource kind(s) 
     e.g.: -k 'DeploymentConfig;Service;Route' Default is defined in oc_config.json->project->oc_resource_kinds
  -m component directory names e.g.: 'init-project;init-api;init-gateway;solr;api;gateway;public-ui;admin-ui;swagger;cron-jobs'
     omit flag or use '-m all' to select all defined in oc_config.json->project->component_dirs
  -n openshift project namespace e.g.: 'myNameSpace' if not set, current oc project name will be used as default namespace
  -N project name, used in default route url generation
  -o 'init', all directories which name string includes 'init' will be omitted,
           useful if you like to preserve data volumes during install/delete operations
     'oc', only yaml files will be generated
  -p url prefix, adds prefix to all route urls, useful when running in Openshift sandbox in oder to avoid network routes conflicts
  -r openshift cluster IP range(first three numbers) e.g.: '112.20.14', last number will be randomly generated
  -s use this flag to change secrets directory. Default is 'secrets'
  -S 'numeric' or 'alphabetic', dirs and files sort type(relevant for running order), default is 'numeric'
  -t set custom 'templates_tt' directory
  -T directoryName, convert '.yaml' files extension into '.tt' extention inside of given directory
  -u instanceName(s), runs validation, creates 'validation_report.txt' und then runs upgrade of components that are modified,
     e.g.: -u test
  -v instanceName(s), validates given instance(s) between template version and Openshift version in cloud e.g.: -v test, 
     report is written in 'validation_report.txt' file
  -y use(install/delete/validate/upgrade/generate yamls) only for yaml files that includes given substring
  -Y set custom 'templates_yaml' directory
  

  see '-a multipleClusters' flag
  oc_config.json magic nodes:
      'instance_specific_data': instance will be automatically selected, e.g.: for json node 'instance_specific_data.api.test.limits.memory'  
                                you can access instance specific data in tt template by 
                                [% oc_config.instance_specific_data.api.limits.memory %] if current instance is 'test' 
      'instance_specific_name': '-instanceName' will be added at the end of each value, e.g.: if you have json node 'instance_specific_name.api'
                                with value 'my-api' then by accessing [% oc_config.instance_specific_name.api %] in tt template, in yaml file will be 
                                written 'my-api-test' if current instance is 'test
  see more examples in git: https://gitlab.com/code7143615/octoolkit/-/tree/master
  
  Examples: 
        # install 'dev' and 'test' instances in 'clusterIntern' cluster
        # you shoud be logged in in same cluster that you specified in '-c' flag
        ocToolkit -c clusterIntern -i 'dev;test' 
        
        # deletes 'api' and 'solr' components on 'test' instance in currently logged in project
        ocToolkit -d test -m 'api;solr'
        
        # backups all components on 'test' instance in logged in project and remove clutter yaml nodes
        ocToolkit -b test -a removeClutter
        
        # validates 'api' and 'solr' components on 'test' instance in logged in project
        # you shoud be logged in in same cluster that you specified in '-c' flag
        ocToolkit -c clusterIntern -v test -m 'api;solr'
        
        # upgrades 'solr' component on 'test' instance in logged in project but all dirs that have 'init' string in its name will me omitted
        # you shoud be logged in in same cluster that you specified in '-c' flag
        ocToolkit -c clusterIntern -u test -m solr -o init
        
        # generate yaml templates(no installing) for oc resourse kinds 'DeploymentConfig' and 'Service' 
        # of 'solr' component for 'test' instance for 'clusterPublic' cluster
        ocToolkit -c clusterPublic -i test -m solr -k 'DeploymentConfig;Service' -o oc
  
  Place instance specific secretes in e.g.: secrets/instance/test/my_secret.txt for 'test' instance and 
  access them by [% secrets.instance_specific.item('my_secret.txt') %] from tt template
  Make sure that oc_config.json->project node values are set correctly.

  ";
  
sub addFlagValuesToConfig($);
sub componentIsAllowed($$$$);
sub generateUrl($$$$$$);
sub removeClutter($$);
sub _loopInstances($$);

my $clusterBaseAddress;
my $advanceFeatures;
my $backupSpecificInstances;
my $cluster = "clusterPublic"; # default
my $ocConfigFile;
my $deleteInstances;
my $host;
my $installInstances;
my $ocResourceKinds;
my $componentDirs;
my $namespace;
my $projectName; # used in default url generation
my $omit   = ""; 
my $urlPrefix;
my $clusterIpRange;
my $secretsDir;
my $sortType;
my $templatesTTDir;
my $yamlToTTconvertDir;
my $upgradeInstances;
my $validateInstances;
my $specificYamlFile;
my $templatesYamlDir;

my %opts;
getopts("a:A:b:c:d:H:h:i:k:m:M:n:N:o:O:p:r:s:S:t:T:u:v:y:Y:", \%opts);

if($opts{h}){
    print $help;
    exit;
}

$clusterBaseAddress      = $opts{A} if defined $opts{A};
$advanceFeatures         = $opts{a} if defined $opts{a};
$backupSpecificInstances = $opts{b} if defined $opts{b};
$cluster                 = $opts{c} if defined $opts{c};
$ocConfigFile            = $opts{C} if defined $opts{C};
$deleteInstances         = $opts{d} if defined $opts{d};
$host                    = $opts{H} if defined $opts{H};
$installInstances        = $opts{i} if defined $opts{i};
$ocResourceKinds         = $opts{k} if defined $opts{k};
$componentDirs           = $opts{m} if (defined $opts{m}) && ($opts{m} ne "all");
$namespace               = $opts{n} if defined $opts{n};
$projectName             = $opts{N} if defined $opts{N};
$omit                    = $opts{o} if defined $opts{o};
$urlPrefix               = $opts{p} if defined $opts{p};
$clusterIpRange          = $opts{r} if defined $opts{r};
$secretsDir              = $opts{s} if defined $opts{s};
$sortType                = $opts{S} if defined $opts{S};
$templatesTTDir          = $opts{t} if defined $opts{t};
$yamlToTTconvertDir      = $opts{T} if defined $opts{T};
$upgradeInstances        = $opts{u} if defined $opts{u};
$validateInstances       = $opts{v} if defined $opts{v};
$specificYamlFile        = $opts{y} if defined $opts{y};
$templatesYamlDir        = $opts{Y} if defined $opts{Y};

if(defined $installInstances){
    die("Please set working cluster with -c flag, e.g.: perl ocToolkit.pl -c clusterPublic -i prod") if not defined $cluster;
}

my $flag;
$flag = $deleteInstances         if defined $deleteInstances;
$flag = $installInstances        if defined $installInstances;
$flag = $backupSpecificInstances if defined $backupSpecificInstances;
$flag = $validateInstances       if defined $validateInstances;
$flag = $upgradeInstances        if defined $upgradeInstances;
die("Flags -i -d -b -v -u can't be left empty.") if (defined $flag) && (length($flag) eq 2) && ($flag =~ /\-/ ); 

if(not defined $clusterBaseAddress){
    my $clusterLc = lc $cluster;
    $clusterBaseAddress = "apps.$clusterLc";
}

if(defined $deleteInstances){
    my $myComponentDirs = $componentDirs;
    if($omit =~ /init/ && (defined $componentDirs)){
        # remove init dirs
        my @componentsDirArray = split(';', $componentDirs);
        @componentsDirArray    = (grep {$_ !~ /init/} @componentsDirArray);
        $myComponentDirs       = join( ';', @componentsDirArray);
    }
    $myComponentDirs = "all" if not defined $myComponentDirs;
    print qx/oc project/;
    print "Deleting $myComponentDirs component(s) in '$deleteInstances' instance in '$cluster' cluster.
    \nPress enter to continue or ctrl+c to abort";
    my $continue = <>;
}

############################################################################
# install/delete/validate/update/backup/create yamls for specific instance #
############################################################################

# set 'multipleClusters' as default
if(not defined $advanceFeatures){
    $advanceFeatures = "multipleClusters";
}else{
    $advanceFeatures .= ";multipleClusters";
}
my $ocObj = OcToolkit->new( advanceFeatures       => $advanceFeatures,
                            clusterBaseAddress    => $clusterBaseAddress,
                            cluster               => $cluster,
                            ocConfigFile          => $ocConfigFile,
                            host                  => $host,
                            ocResourceKinds       => $ocResourceKinds,
                            componentDirs         => $componentDirs,
                            namespace             => $namespace,
                            projectName           => $projectName,
                            omit                  => $omit,
                            urlPrefix             => $urlPrefix,
                            clusterIpRange        => $clusterIpRange,
                            secretsDir            => $secretsDir,
                            sortType              => $sortType,
                            templatesTTDir        => $templatesTTDir,
                            yamlToTTconvertDir    => $yamlToTTconvertDir,
                            specificYamlFile      => $specificYamlFile,
                            templatesYamlDir      => $templatesYamlDir,
                            addFlagValuesToConfig => \&addFlagValuesToConfig,
                            componentIsAllowed    => \&componentIsAllowed,
                            generateUrl           => \&generateUrl,
                            removeClutter         => \&removeClutter,
                            removeClutterBackup   => \&removeClutterBackup);

# $ocObj->setParams({omit => "oc"});
_loopInstances($deleteInstances,         "delete")   if defined $deleteInstances;
_loopInstances($installInstances,        "install")  if defined $installInstances;
_loopInstances($upgradeInstances,        "upgrade")  if defined $upgradeInstances;
_loopInstances($validateInstances,       "validate") if defined $validateInstances;
if(defined $backupSpecificInstances){
    if($backupSpecificInstances eq "all"){
        $ocObj->backupWholeOCProject();
    }else{
        _loopInstances($backupSpecificInstances, "backup");
    }
}
$ocObj->convertYamlToTTExtention($yamlToTTconvertDir) if defined $yamlToTTconvertDir;

#####################################################################################
# use this functions to add custom config/logic without need to change OcToolkit.pm # 
#####################################################################################

# add some script input flag value to config file, access them then in TT Template by [% my_custom_value %]
sub addFlagValuesToConfig($){
    my ($config) = @_;

    $config->{my_custom_value} = "some custom value received from flag";

    return $config;
}

# some specific rules about what components are allowed to be installed on given cluster and instance
# if you need completely different tt template files for specific clusters use '-a multipleClusters' flag
# put tt template file into nested directory, named by your cluster, inside of your tt template component dirs
sub componentIsAllowed($$$$){
    my ($myTemplateName, $myDir, $myCluster, $myInstance) = @_;

#     my $clusterLowerCase = lc $myCluster;
#     if($clusterLowerCase =~ /clusterPublic/){
#         if($myTemplateName =~ /route/){
#             return 0 if $myDir =~ /solr/;
#             return 0 if $myDir =~ /api/;
#             return 0 if $myDir =~ /admin\-ui/;
#         }
#         return 0 if $myDir =~ /swagger/;
#     }

    return 1;
}

# define default routes url pattern
sub generateUrl($$$$$$){
    my ($urlPrefix, $projectName, $componentName, $instanceKey, $clusterBaseAddress, $host) = @_;
    
    if(defined $urlPrefix){
        $urlPrefix .= "-";
    }else{
        $urlPrefix = "";
    }
    if(defined $projectName){
        $projectName .= "-";
    }else{
        $projectName = "";
    }
    if(defined $clusterBaseAddress){
        $clusterBaseAddress .= ".";
    }else{
        $clusterBaseAddress = "";
    }

    return $urlPrefix.$projectName.$componentName."-".$instanceKey.".".$clusterBaseAddress.$host;
}

# ignore some specific fields during validation and upgrade
sub removeClutter($$){
    my ($ocJsonHash, $params) = @_;

    $ocJsonHash = removeClutterBackup($ocJsonHash, $params);
    
    my $dir          = $params->{dir};
    my $templateName = $params->{templateName};
    my $ocKind       = $params->{ocKind};
    my $ocName       = $params->{ocName};

    # some extra fields(in comparison to backup) to be ignored during validation and upgrade
    foreach my $i ((0..7)){
        if($ocKind eq "BuildConfig"){
            if((defined $ocJsonHash->{spec}) &&
               (defined $ocJsonHash->{spec}->{triggers}) &&
               (defined $ocJsonHash->{spec}->{triggers}->[$i]) &&
               (defined $ocJsonHash->{spec}->{triggers}->[$i]->{github}) &&
               (defined $ocJsonHash->{spec}->{triggers}->[$i]->{github}->{secret})
            ){
                delete $ocJsonHash->{spec}->{triggers}->[$i]->{github}->{secret};
            }
            if((defined $ocJsonHash->{spec}) &&
               (defined $ocJsonHash->{spec}->{triggers}) &&
               (defined $ocJsonHash->{spec}->{triggers}->[$i]) &&
               (defined $ocJsonHash->{spec}->{triggers}->[$i]->{generic}) &&
               (defined $ocJsonHash->{spec}->{triggers}->[$i]->{generic}->{secret})
            ){
                delete $ocJsonHash->{spec}->{triggers}->[$i]->{generic}->{secret};
            }
        }
        if($ocKind eq "ImageStream"){
            if((defined $ocJsonHash->{spec}) &&
               (defined $ocJsonHash->{spec}->{tags}) &&
               (defined $ocJsonHash->{spec}->{tags}->[$i]) &&
               (defined $ocJsonHash->{spec}->{tags}->[$i]->{importPolicy})
            ){
                delete $ocJsonHash->{spec}->{tags}->[$i]->{importPolicy};
            }
        }
        if($ocKind eq "DeploymentConfig"){
            if((defined $ocJsonHash->{spec}) &&
               (defined $ocJsonHash->{spec}->{template}) &&
               (defined $ocJsonHash->{spec}->{template}->{spec}) &&
               (defined $ocJsonHash->{spec}->{template}->{spec}->{containers}) &&
               (defined $ocJsonHash->{spec}->{template}->{spec}->{containers}->[$i]) &&
               (defined $ocJsonHash->{spec}->{template}->{spec}->{containers}->[$i]->{resources}) &&
               (not defined $ocJsonHash->{spec}->{template}->{spec}->{containers}->[$i]->{resources}->{limits}) &&
               (not defined $ocJsonHash->{spec}->{template}->{spec}->{containers}->[$i]->{resources}->{requests})
            ){
                $ocJsonHash->{spec}->{template}->{spec}->{containers}->[$i]->{resources} = {};
            }
        }
    }

    delete $ocJsonHash->{spec}->{clusterIPs};
    delete $ocJsonHash->{spec}->{clusterIP};
    delete $ocJsonHash->{spec}->{volumeName} if $ocKind eq "PersistentVolumeClaim";
    
    return $ocJsonHash;
}

# ignore some specific fields during backup of the whole project
sub removeClutterBackup($$){
    my ($ocJsonHash, $params) = @_;

    my $dir          = $params->{dir};
    my $templateName = $params->{templateName};
    my $ocKind       = $params->{ocKind};
    my $ocName       = $params->{ocName};
    
    delete $ocJsonHash->{status};
    
    delete $ocJsonHash->{metadata}->{annotations}->{'openshift.io/generated-by'};
    delete $ocJsonHash->{metadata}->{annotations}->{'openshift.io/restore-server-version'};
    delete $ocJsonHash->{metadata}->{annotations}->{'openshift.io/backup-server-version'};
    delete $ocJsonHash->{metadata}->{annotations}->{'openshift.io/backup-registry-hostname'};
    delete $ocJsonHash->{metadata}->{annotations}->{'openshift.io/migration-registry'};
    delete $ocJsonHash->{metadata}->{annotations}->{'openshift.io/restore-registry-hostname'};
    delete $ocJsonHash->{metadata}->{annotations}->{'openshift.io/image.dockerRepositoryCheck'};
    delete $ocJsonHash->{metadata}->{annotations}->{'kubectl.kubernetes.io/last-applied-configuration'};
    delete $ocJsonHash->{metadata}->{annotations}->{'kubernetes.io/service-account.name'};
    delete $ocJsonHash->{metadata}->{annotations}->{'kubernetes.io/service-account.uid'};
    delete $ocJsonHash->{metadata}->{annotations}->{'openshift.io/token-secret.value'};
    delete $ocJsonHash->{metadata}->{annotations}->{'openshift.io/token-secret.name'};
    delete $ocJsonHash->{metadata}->{annotations}->{'kubernetes.io/created-by'};
    delete $ocJsonHash->{metadata}->{annotations}->{'volume.beta.kubernetes.io/storage-provisioner'};
    delete $ocJsonHash->{metadata}->{annotations}->{'pv.kubernetes.io/bind-completed'};
    delete $ocJsonHash->{metadata}->{annotations}->{'pv.kubernetes.io/bound-by-controller'};
    delete $ocJsonHash->{metadata}->{annotations}->{'volume.kubernetes.io/storage-provisioner'};
    
    delete $ocJsonHash->{metadata}->{labels}->{'migration.openshift.io/migrated-by-migmigration'};
    delete $ocJsonHash->{metadata}->{labels}->{'migration.openshift.io/migrated-by-migplan'};
    delete $ocJsonHash->{metadata}->{labels}->{'velero.io/backup-name'};
    delete $ocJsonHash->{metadata}->{labels}->{'velero.io/restore-name'};
    delete $ocJsonHash->{metadata}->{labels}->{'app.kubernetes.io/component'};
    delete $ocJsonHash->{metadata}->{labels}->{'app.kubernetes.io/instance'};
    
    delete $ocJsonHash->{metadata}->{resourceVersion};
    delete $ocJsonHash->{metadata}->{uid};
    delete $ocJsonHash->{metadata}->{creationTimestamp};
    delete $ocJsonHash->{metadata}->{generation};
    delete $ocJsonHash->{metadata}->{managedFields};
    delete $ocJsonHash->{metadata}->{selfLink};
    delete $ocJsonHash->{metadata}->{deletionTimestamp};
    delete $ocJsonHash->{metadata}->{deletionGracePeriodSeconds};

    foreach my $i ((0..7)){
        if((defined $ocJsonHash->{spec}) &&
           (defined $ocJsonHash->{spec}->{triggers}) &&
           (defined $ocJsonHash->{spec}->{triggers}->[$i]) &&
           (defined $ocJsonHash->{spec}->{triggers}->[$i]->{imageChangeParams}) &&
           (defined $ocJsonHash->{spec}->{triggers}->[$i]->{imageChangeParams}->{lastTriggeredImage})
        ){
            delete $ocJsonHash->{spec}->{triggers}->[$i]->{imageChangeParams}->{lastTriggeredImage};
        }
        
        if((defined $ocJsonHash->{spec}) &&
           (defined $ocJsonHash->{spec}->{tags}) &&
           (defined $ocJsonHash->{spec}->{tags}->[$i]) &&
           (defined $ocJsonHash->{spec}->{tags}->[$i]->{generation})
        ){
            delete $ocJsonHash->{spec}->{tags}->[$i]->{generation};
        }
        
        if((defined $ocJsonHash->{spec}) &&
           (defined $ocJsonHash->{spec}->{template}) &&
           (defined $ocJsonHash->{spec}->{template}->{spec}) &&
           (defined $ocJsonHash->{spec}->{template}->{spec}->{containers}) &&
           (defined $ocJsonHash->{spec}->{template}->{spec}->{containers}->[$i]) &&
           (defined $ocJsonHash->{spec}->{template}->{spec}->{containers}->[$i]->{image})
        ){
            delete $ocJsonHash->{spec}->{template}->{spec}->{containers}->[$i]->{image};
        }
    }

    return $ocJsonHash;
}

sub _loopInstances($$){
    my ($instancesString, $methodName) = @_;
    
    my @instances =  split(';', $instancesString);
     foreach my $instance (@instances){
        my $methodNameU = ucfirst $methodName;
        print "$methodNameU instance: $instance\n";
        $ocObj->$methodName($instance) if $ocObj->can($methodName); 
    }
}

1;
