#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use Cwd qw(abs_path);

# search for Module in same directory where this script is
# use File::Spec;
# use lib File::Spec->catdir($FindBin::Bin);

use Getopt::Std;
use OcToolkit;

use Data::Dumper;

my $projectDir = abs_path(".")."/";
my $customCallbacksObj;
eval {
    unshift @INC, $projectDir;
    require CustomCallbacks;
    CustomCallbacks->import();
    $customCallbacksObj = CustomCallbacks->new();
};
warn "CustomCallbacks.pm file not found, continuing without it" if $@;

my $help = "Install/uninstall/backup/validate/upgrade instances and they components into/from Openshift/Kubernetes cluster
Put your templates in 'templates_tt' dir located in current dir. Every component should have own dir(10-api,20-solr,...) inside of it.
Write your templates with Template Toolkit(https://template-toolkit.org) templating engine.
Put your config into oc_config.json. Located in current dir.
   'instance_specific_data' : put your instance specific data in this json node, see example belove and in git
   'instance_specific_name' : instance string will be automatically added at the end of every entry, see example belove and in git
   'project': project specifc data
   oc_config.json root data are fix for every instance
   put your secrets into 'secrets' dir, see example from git repo
  
Flags description:
  -A cluster base address, e.g.: 'apps.clusterintern' or 'apps.clusterpublic', used in default route url generation
  -a advance features:
     '-a kubectl'          use Kubernetes 'kubectl' instead of default Openshift 'oc' command
     '-a removeClutter'    remove clutter yaml fields during backup
    Use multiple: -a 'kubectl;removeClutter'
  -b instance name(s), backups specific instance(s) sorted by components e.g.: -b 'dev;test' or -b 'all' to backup whole project(unsorted) 
  -c cluster name e.g.: 'clusterIntern','clusterPublic'... Default is defined in oc_config.json->project->default_cluster. 
     You should be logged in into corresponding cluster
     If cluster label in url should be different then cluster name, use '-A' flag to set custom cluster url label
  -C config file, default: 'oc_config.json'
  -d instanceName(s), deletes instances from logged in project e.g.: '-d test', see -i documentation
  -g instanceName(s), generates 'oc_config.json' template for given instances based on components defined in 'templates_tt' directory
      e.g.: -g 'test;prod'
  -h help, prints this help
  -H host, used in default route url generation
  -i instance name(s) e.g.: installs given instances e.g.: 'test;prod'
  -j set custom 'secrets.json' file name
  -k use(install/delete/validate/upgrade/generate yamls/backup) only specific Openshift/Kubernetes resource kind(s) 
     e.g.: -k 'DeploymentConfig;Service;Route' Default is defined in oc_config.json->project->oc_resource_kinds
  -m component directory names e.g.: 'init-project;init-api;init-gateway;solr;api;gateway;public-ui;admin-ui;swagger;cron-jobs'
     omit flag or use '-m all' to select all defined in oc_config.json->project->component_dirs
  -n openshift project namespace e.g.: 'myNameSpace' 
     if not set, current oc project name or oc_config->project->namespace will be used as default namespace
  -N project name, used in default route url generation
  -o 'init', all directories which name string includes 'init' will be omitted,
           useful if you like to preserve data volumes during install/delete operations
     'oc', only yaml files will be generated
     Use multiple: -o 'init;oc'
  -p url prefix, adds prefix to all route urls, useful when running in Openshift sandbox in oder to avoid network routes conflicts
  -r openshift cluster IP range(first three numbers) e.g.: '112.20.14', last number will be randomly generated
  -s use this flag to change secrets directory. Default is 'secrets'
  -S 'numeric' or 'alphabetic', dirs and files sort type(relevant for running order), default is 'numeric'
  -t set custom 'templates_tt' directory
  -T directoryName, convert '.yaml' files extension into '.tt' extention inside of given directory
  -u instanceName(s), runs validation, creates 'validation_report.txt' und then runs upgrade of components that are modified,
     e.g.: -u test
  -v instanceName(s), validates given instance(s) between template version and Openshift/Kubernetes version in cloud e.g.: -v test, 
     report is written in 'validation_report.txt' file
  -y use(install/delete/validate/upgrade/generate yamls) only for yaml files that includes given substring
  -Y set custom 'templates_yaml' directory
  -x custom flag value: set it in CustomCallbacks::addFlagValuesToConfig and then use it in tt template with [% my_custom_value %]

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
  
  Place instance specific secretes files in e.g.: 
      - secrets/my_secret.txt or
        secrets/instance/test/my_secret.txt or
        secrets/clusterPublic/my_secret.txt or
        secrets/clusterPublic/instance/prod/my_secret.txt
        for corresponding instance and cluster 
        access them by [% secrets.item('my_secret.txt') %] from tt template
      - secrets value from secretes.json file will be automatically selected depending on current instance and cluster,
        they are accessible from tt template by [% secrets_json.someSecret1 %] 
  See example in git repo

  ";
  
sub _loopInstances($$);
sub addFlagValuesToConfig($);
sub componentIsAllowed($$$$);
sub generateUrl($$$$$$);
sub removeClutter($$);

# $projectName; # used in default url generation
my ($clusterBaseAddress, $advanceFeatures, $backupSpecificInstances, $cluster, $ocConfigFile, 
    $generateConfigTemplate, $deleteInstances, $host, $installInstances, $secretsJson, 
    $ocResourceKinds, $componentDirs, $namespace, $projectName, $urlPrefix, $clusterIpRange,
    $secretsDir, $sortType, $templatesTTDir, $yamlToTTconvertDir, $upgradeInstances, $validateInstances, 
    $specificYamlFile, $templatesYamlDir);
my $omit = ""; 

my %opts;
getopts("a:A:b:c:d:H:g:h:i:j;k:m:M:n:N:o:O:p:r:s:S:t:T:u:v:y:Y:x:", \%opts);

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
$generateConfigTemplate  = $opts{g} if defined $opts{g};
$host                    = $opts{H} if defined $opts{H};
$installInstances        = $opts{i} if defined $opts{i};
$secretsJson             = $opts{j} if defined $opts{j};
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

my $flag;
$flag = $deleteInstances         if defined $deleteInstances;
$flag = $installInstances        if defined $installInstances;
$flag = $backupSpecificInstances if defined $backupSpecificInstances;
$flag = $validateInstances       if defined $validateInstances;
$flag = $upgradeInstances        if defined $upgradeInstances;
$flag = $generateConfigTemplate  if defined $generateConfigTemplate;
die("Flags -i -d -b -v -u -g can't be left empty.") if (defined $flag) && (length($flag) eq 2) && ($flag =~ /\-/ ); 

my $clusterText = `oc config current-context`;
if((defined $cluster) && (lc($clusterText) !~ lc($cluster))){
    print "Cluster you entered in -c flag '$cluster' doesn't correspondent to cluster that you are currently logged in.
Press enter if you still want to continue or press ctrl+c to abort.";
    my $continue = <>;
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
    $cluster = "unknown" if not defined $cluster;
    print qx/oc project/;
    print "Deleting $myComponentDirs component(s) in '$deleteInstances' instance in '$cluster' cluster.
    \nPress enter to continue or ctrl+c to abort";
    my $continue = <>;
}

############################################################################
# install/delete/validate/update/backup/create yamls for specific instance #
############################################################################
$ocConfigFile     = $projectDir.$ocConfigFile     if defined $ocConfigFile;
$secretsDir       = $projectDir.$secretsDir       if defined $secretsDir;
$templatesTTDir   = $projectDir.$templatesTTDir   if defined $templatesTTDir;
$templatesYamlDir = $projectDir.$templatesYamlDir if defined $templatesYamlDir;

my $ocObj = OcToolkit->new( advanceFeatures       => $advanceFeatures,
                            clusterBaseAddress    => $clusterBaseAddress,
                            cluster               => $cluster,
                            ocConfigFile          => $ocConfigFile,
                            host                  => $host,
                            secretsJson           => $secretsJson,
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
                            validationReportFile  => $projectDir.'validation_report.txt',
                            projectDir            => $projectDir,
                            componentIsAllowed    => \&componentIsAllowed,
                            generateUrl           => \&generateUrl,
                            removeClutter         => \&removeClutter,
                            removeClutterBackup   => \&removeClutterBackup);

$ocObj->setParams({addFlagValuesToConfig => \&addFlagValuesToConfig}) if defined $opts{x};

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
$ocObj->convertYamlToTTExtention($yamlToTTconvertDir)       if defined $yamlToTTconvertDir;
$ocObj->generateConfigJsonTemplate($generateConfigTemplate) if defined $generateConfigTemplate;


sub _loopInstances($$){
    my ($instancesString, $methodName) = @_;
    
    my @instances =  split(';', $instancesString);
     foreach my $instance (@instances){
        my $methodNameU = ucfirst $methodName;
        print "$methodNameU instance: $instance\n";
        $ocObj->$methodName($instance) if $ocObj->can($methodName); 
    }
}

#####################################################################################
# use this functions to add custom config/logic without need to change OcToolkit.pm # 
#####################################################################################

sub addFlagValuesToConfig($){
    my ($config) = @_;    
    return defined $customCallbacksObj ? $customCallbacksObj->addFlagValuesToConfig($config, \%opts) : undef;
}

sub componentIsAllowed($$$$){
    my ($myTemplateName, $myDir, $myCluster, $myInstance) = @_;
    return defined $customCallbacksObj ? $customCallbacksObj->componentIsAllowed($myTemplateName, $myDir, $myCluster, $myInstance) : undef;
}

sub generateUrl($$$$$$){
    my ($urlPrefix, $projectName, $componentName, $instanceKey, $clusterBaseAddress, $host) = @_;

    if(defined $customCallbacksObj){
        return $customCallbacksObj->generateUrl($urlPrefix, $projectName, $componentName, $instanceKey, $clusterBaseAddress, $host);
    }else{
        return;
    }
}

sub removeClutter($$){
    my ($ocJsonHash, $params) = @_;
    return defined $customCallbacksObj ? $customCallbacksObj->removeClutter($ocJsonHash, $params) : undef;
}

sub removeClutterBackup($$){
    my ($ocJsonHash, $params) = @_;
    return defined $customCallbacksObj ? $customCallbacksObj->removeClutterBackup($ocJsonHash, $params) : undef;
}

1;
