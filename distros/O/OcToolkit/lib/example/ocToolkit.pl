#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use Cwd qw(abs_path);

# search for Module in same directory where this script is
# use File::Spec;
# use lib File::Spec->catdir($FindBin::Bin);

use Getopt::Long qw(GetOptions);
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

my $help = "Install/uninstall/backup/validate/update instance(s) and they components into/from Openshift/Kubernetes cluster
Put your templates in 'templates_tt' dir located in current dir. Every component should have own dir(10-api,20-solr,...) inside of it.
Write your templates with Template Toolkit(https://template-toolkit.org) templating engine.
Put your config into oct_config.json. Located in current dir.
   'instance_specific_data' : put your instance specific data in this json node, see example belove and in git
   'instance_specific_name' : instance string will be automatically added at the end of every entry, see example belove and in git
   'project': project specifc data
   oct_config.json root data are fix for every instance
   put your secrets into 'secrets' dir, see example from git repo
  
Flags description:
  -A|--cluster-base-address e.g.: 'apps.clusterintern' or 'apps.clusterpublic', used in default route url generation
  -a|--advance-features :
     '-a kubectl'        use Kubernetes 'kubectl' instead of default Openshift 'oc' command
     '-a removeClutter'  remove clutter yaml fields during backup
     '-a apply'          command to be used for writing: 'create' or 'apply'.See oct_config->project->default_cloud_command 
     '-a deleteUndefinedInCloud'  when using -d flag use this to delete Resources in Cloud that are not defined in Manifests
     '-a useInit'  if 'omit_init': 1, set in oct_config.json, use this flag to override this settings
    Use multiple: -a 'kubectl;removeClutter'
  -b|--backup instance name(s), backups specific instance(s) sorted by components e.g.: -b 'dev;test' or -b 'all' to backup whole project(unsorted) 
  -c|--cluster cluster name e.g.: 'clusterIntern','clusterPublic'... Default is defined in oct_config.json->project->default_cluster. 
     You should be logged in into corresponding cluster
     If cluster label in url should be different then cluster name, use '-A' flag to set custom cluster url label
  -C|--config config file, default: 'oct_config.json'
  -d|--delete instanceName(s), deletes instance(s) from logged in project e.g.: -d test
  -g|--git-revert-hash git revert hash, when using the -r flag, use this flag to specify the Git revert hash to which the changes should be automatically reverted, e.g.: -g b18c981
  -G|--generate-config instanceName(s), generates 'oct_config.json' template for given instance(s) based on components defined in 'templates_tt' directory
      e.g.: -g 'test;prod'
  -h|--help help, prints this help
  -H|--host myHost, used in default route url generation
  -i|--install instance name(s) e.g.: installs given instance(s) e.g.: 'test;prod'
  -j|--secrets-json set custom 'secrets.json' file name
  -k|--resource-kinds use(install/delete/validate/update/generate yamls/backup) only specific Openshift/Kubernetes resource kind(s) 
     e.g.: -k 'DeploymentConfig;Service;Route' Default is defined in oct_config.json->project->oct_resource_kinds
  -m|--components components directory names e.g.: 'init-project;init-api;init-gateway;solr;api;gateway;public-ui;admin-ui;swagger;cron-jobs'
     omit flag or use '-m all' to select all defined in oct_config.json->project->component_dirs
  -n|--namespace openshift project namespace e.g.: 'myNameSpace' 
     if not set, current oc project name or oct_config->project->namespace will be used as default namespace
  -N|--project-name project name, used in default route url generation
  -o|--omit 'init', all directories which name string includes 'init' will be omitted,
                  useful if you like to preserve data volumes during install/delete operations
            'cloud', only yaml files will be generated, no 'oc' or 'kubectl' will be called
            'preHook'  omit 'preHook' defined in CustomCallbacks.pm
            'postHook' omit 'postHook' defined in CustomCallbacks.pm
            'confirm' omit confirmation prompts
     Use multiple: -o 'init;cloud'
  -p|--url-prefix url prefix, adds prefix to all route urls, useful when running in Openshift sandbox in oder to avoid network routes conflicts
  -r|--revert instance name(s), reverts instance(s) in cloud to state defined in manifests(installs/updates and deletes not defined resources in cloud) e.g.: 'dev;test',
  -R|--cluster-ip-range openshift cluster IP range(first three numbers) e.g.: '112.20.14', last number will be randomly generated
  -s|--secrets-dir use this flag to change secrets directory. Default is 'secrets'
  -S|--sort-type 'numeric' or 'alphabetic', dirs and files sort type(relevant for running order), default is 'numeric'
  -t|--templates-tt-dir set custom 'templates_tt' directory
  -T|--yaml-to-tt-dir directoryName, convert '.yaml' files extension into '.tt' extention inside of given directory
  -u|--update instanceName(s), runs validation, creates 'validation_report.txt' und then runs update of components that are modified,
     e.g.: -u test
  -v|--validate-against-cloud instanceName(s), compares given instance(s) template version(manifests) and Openshift/Kubernetes resources in cloud e.g.: -v test, 
     report is written in 'validation_report.txt' file
  -V|--validate-manifests instanceName(s), validetes if given instance(s) has valid yaml files(manifests) for logged in cluster e.g.: -V test
  -y|--specific-yaml use(install/delete/validate/update/generate yamls) only for yaml files that includes given substring
  -Y|--templates-yaml-dir set custom 'templates_yaml' directory
  -x|--custom custom flag value: set it in CustomCallbacks::addFlagValuesToConfig and then use it in tt template with [% my_custom_value %]
  -X|--custom-second second custom flag value: set it in CustomCallbacks::addFlagValuesToConfig and then use it in tt template with [% my_custom_value2 %]
  -Z|--scale-to-zero instanceName(s), scale the workloads(Pods) to zero for given instance(s) e.g.: -Z 'dev;test'

  oct_config.json magic nodes:
      'instance_specific_data': instance will be automatically selected, e.g.: for json node 'instance_specific_data.api.test.limits.memory' 
                                you can access instance specific data in tt template by 
                                [% oct_config.instance_specific_data.api.limits.memory %] if current instance is 'test' 
      'instance_specific_name': '-instanceName' will be added at the end of each value, e.g.: if you have json node 'instance_specific_name.api'
                                with value 'my-api' then by accessing [% oct_config.instance_specific_name.api %] in tt template, in yaml file will be 
                                written 'my-api-test' if current instance is 'test
  see more examples in git: https://gitlab.com/code7143615/octoolkit/-/tree/master
  
  Examples: 
        # install 'dev' and 'test'(see CustomCallbacks.pm 'preHook' example)
        ocToolkit -i 'dev;test' 
        
        # deletes 'api' and 'solr' components on 'test' instance in currently logged in project
        ocToolkit -d test -m 'api;solr'
        
        # backups all components on 'test' instance in logged in project and remove clutter yaml nodes
        ocToolkit -b test -a removeClutter
        
        # validates against cloud 'api' and 'solr' components on 'test' instance in logged in project
        # you shoud be logged in in same cluster that you specified in '-c' flag
        ocToolkit -c clusterPublic -v test -m 'api;solr'
        
        # validates manifests on 'test' instance
        ocToolkit -V test
        
        # compares given instance(s) template version(manifests) and Openshift/Kubernetes resources in cloud
        ocToolkit -v test
        
        # updates 'solr' component on 'test' instance in logged in project but all dirs that have 'init' string in its name will me omitted
        # you shoud be logged in in same cluster that you specified in '-c' flag
        ocToolkit -c clusterIntern -u test -m solr -o init
        
        # generate yaml templates(no installing) for oc resourse kinds 'DeploymentConfig' and 'Service' 
        # of 'solr' component for 'test' instance for 'clusterPublic' cluster
        ocToolkit -c clusterPublic -i test -m solr -k 'DeploymentConfig;Service' -o cloud
  
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
sub preHook($);
sub postHook($);
sub removeClutter($$);
sub removeClutterBackup($$);

# $projectName; # used in default url generation
my ($clusterBaseAddress, $advanceFeatures, $backupSpecificInstances, $cluster, $octConfigFile, $gitRevertHash,
    $generateConfigTemplate, $deleteInstances, $scaleToZero, $host, $installInstances, $secretsJson, 
    $resourceKinds, $components, $namespace, $projectName, $urlPrefix, $revertInstances, $clusterIpRange,
    $secretsDir, $sortType, $templatesTTDir, $yamlToTTconvertDir, $updateInstances, 
    $validateAgainstCloudInstances, $validateManifestsInstances,$specificYamlFile, $templatesYamlDir);
my $omit = ""; 

my %opts;

GetOptions(
    'a|advance-features=s'       => \$opts{a},
    'A|cluster-base-address=s'   => \$opts{A},
    'b|backup=s'                 => \$opts{b},
    'c|cluster=s'                => \$opts{c},
    'C|config=s'                 => \$opts{C},
    'd|delete=s'                 => \$opts{d},
    'g|git-revert-hash=s'        => \$opts{g},
    'G|generate-config=s'        => \$opts{G},
    'h|help'                     => \$opts{h},
    'H|host=s'                   => \$opts{H},
    'i|install=s'                => \$opts{i},
    'j|secrets-json=s'           => \$opts{j},
    'k|resource-kinds=s'         => \$opts{k},
    'm|components=s'             => \$opts{m},
    'n|namespace=s'              => \$opts{n},
    'N|project-name=s'           => \$opts{N},
    'o|omit=s'                   => \$opts{o},
    'p|url-prefix=s'             => \$opts{p},
    'r|revert=s'                 => \$opts{r},
    'R|cluster-ip-range=s'       => \$opts{R},
    's|secrets-dir=s'            => \$opts{s},
    'S|sort-type=s'              => \$opts{S},
    't|templates-tt-dir=s'       => \$opts{t},
    'T|yaml-to-tt-dir=s'         => \$opts{T},
    'u|update=s'                 => \$opts{u},
    'v|validate-against-cloud=s' => \$opts{v},
    'V|validate-manifests=s'     => \$opts{V},
    'y|specific-yaml=s'          => \$opts{y},
    'Y|templates-yaml-dir=s'     => \$opts{Y},
    'x|custom=s'                 => \$opts{x},
    'X|custom2=s'                => \$opts{X},
    'Z|scale-to-zero=s'          => \$opts{Z},
) or die "Invalid command line arguments\n";

if($opts{h}){
    print $help;
    exit;
}


$clusterBaseAddress            = $opts{A} if defined $opts{A};
$advanceFeatures               = $opts{a} if defined $opts{a};
$backupSpecificInstances       = $opts{b} if defined $opts{b};
$cluster                       = $opts{c} if defined $opts{c};
$octConfigFile                 = $opts{C} if defined $opts{C};
$deleteInstances               = $opts{d} if defined $opts{d};
$gitRevertHash                 = $opts{g} if defined $opts{g};
$generateConfigTemplate        = $opts{G} if defined $opts{G};
$host                          = $opts{H} if defined $opts{H};
$installInstances              = $opts{i} if defined $opts{i};
$secretsJson                   = $opts{j} if defined $opts{j};
$resourceKinds                 = $opts{k} if defined $opts{k};
$components                    = $opts{m} if (defined $opts{m}) && ($opts{m} ne "all");
$namespace                     = $opts{n} if defined $opts{n};
$projectName                   = $opts{N} if defined $opts{N};
$omit                          = $opts{o} if defined $opts{o};
$urlPrefix                     = $opts{p} if defined $opts{p};
$revertInstances               = $opts{r} if defined $opts{r};
$clusterIpRange                = $opts{R} if defined $opts{R};
$secretsDir                    = $opts{s} if defined $opts{s};
$sortType                      = $opts{S} if defined $opts{S};
$templatesTTDir                = $opts{t} if defined $opts{t};
$yamlToTTconvertDir            = $opts{T} if defined $opts{T};
$updateInstances               = $opts{u} if defined $opts{u};
$validateAgainstCloudInstances = $opts{v} if defined $opts{v};
$validateManifestsInstances    = $opts{V} if defined $opts{V};
$specificYamlFile              = $opts{y} if defined $opts{y};
$templatesYamlDir              = $opts{Y} if defined $opts{Y};
$scaleToZero                   = $opts{Z} if defined $opts{Z};


my $flag;
$flag = $deleteInstances               if defined $deleteInstances;
$flag = $installInstances              if defined $installInstances;
$flag = $backupSpecificInstances       if defined $backupSpecificInstances;
$flag = $revertInstances               if defined $revertInstances;
$flag = $scaleToZero                   if defined $scaleToZero;
$flag = $validateAgainstCloudInstances if defined $validateAgainstCloudInstances;
$flag = $validateManifestsInstances    if defined $validateManifestsInstances;
$flag = $updateInstances               if defined $updateInstances;
$flag = $generateConfigTemplate        if defined $generateConfigTemplate;
die("Flags -i -d -D -b -v -V -u -r -g can't be left empty.") if (defined $flag) && (length($flag) eq 2) && ($flag =~ /\-/ ); 

my $command = "oc";
$command = "kubectl" if defined $advanceFeatures && $advanceFeatures =~ /kubectl/;
my $clusterText = `$command config current-context`;
$clusterText =~ s/\n//g;
my $clusterTextCmp = $clusterText;
$clusterTextCmp =~ s/[^A-Za-z0-9]//g;
if((defined $cluster) && (lc($clusterTextCmp) !~ lc($cluster))){
    print "Warning: Cluster you entered in -c flag '$cluster' doesn't correspondent to the cluster\n$clusterText\nthat you are currently logged in.\nPress enter if you still want to continue or press ctrl+c to abort.";
    my $continue = <>;
}

############################################################################
# install/delete/validate/update/backup/create yamls for specific instance #
############################################################################
$octConfigFile    = $projectDir.$octConfigFile    if defined $octConfigFile;
$secretsDir       = $projectDir.$secretsDir       if defined $secretsDir;
$templatesTTDir   = $projectDir.$templatesTTDir   if defined $templatesTTDir;
$templatesYamlDir = $projectDir.$templatesYamlDir if defined $templatesYamlDir;

my $ocObj = OcToolkit->new( advanceFeatures                => $advanceFeatures,
                            clusterBaseAddress             => $clusterBaseAddress,
                            cluster                        => $cluster,
                            octConfigFile                  => $octConfigFile,
                            gitRevertHash                  => $gitRevertHash,
                            host                           => $host,
                            secretsJson                    => $secretsJson,
                            resourceKinds                  => $resourceKinds,
                            components                     => $components,
                            namespace                      => $namespace,
                            projectName                    => $projectName,
                            omit                           => $omit,
                            urlPrefix                      => $urlPrefix,
                            clusterIpRange                 => $clusterIpRange,
                            secretsDir                     => $secretsDir,
                            sortType                       => $sortType,
                            templatesTTDir                 => $templatesTTDir,
                            yamlToTTconvertDir             => $yamlToTTconvertDir,
                            specificYamlFile               => $specificYamlFile,
                            templatesYamlDir               => $templatesYamlDir,
                            validationReportFile           => $projectDir.'validation_report.txt',
                            projectDir                     => $projectDir,
                            componentIsAllowed             => \&componentIsAllowed,
                            generateUrl                    => \&generateUrl,
                            ignoreManifestValidationErrors => \&ignoreManifestValidationErrors,
                            removeClutter                  => \&removeClutter,
                            removeClutterBackup            => \&removeClutterBackup,
                            preHook                        => \&preHook,
                            postHook                       => \&postHook);

$ocObj->setParams({addFlagValuesToConfig => \&addFlagValuesToConfig}) if defined $opts{x};

# $ocObj->setParams({omit => "cloud"});
_loopInstances($deleteInstances,               "delete")               if defined $deleteInstances;
_loopInstances($installInstances,              "install")              if defined $installInstances;
_loopInstances($revertInstances,               "revert")               if defined $revertInstances;
_loopInstances($scaleToZero,                   "scaleToZero")          if defined $scaleToZero;
_loopInstances($updateInstances,               "update")               if defined $updateInstances;
_loopInstances($validateAgainstCloudInstances, "validateAgainstCloud") if defined $validateAgainstCloudInstances;
_loopInstances($validateManifestsInstances,    "validateManifests")    if defined $validateManifestsInstances;
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

sub ignoreManifestValidationErrors($){
    my ($text) = @_;
    return defined $customCallbacksObj ? $customCallbacksObj->ignoreManifestValidationErrors($text) : undef;
}

sub preHook($){
    my ($config) = @_;
    return defined $customCallbacksObj ? $customCallbacksObj->preHook($config) : undef;
}

sub postHook($){
    my ($config) = @_;
    return defined $customCallbacksObj ? $customCallbacksObj->postHook($config) : undef;
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
