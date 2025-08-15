package OcToolkit;

use v5.16; # or newer
use strict;
use warnings;

our $VERSION = "1.07";

use JSON::PP;
use Text::Diff;
use Template;
use File::Slurp;
use File::Find::Rule;
use File::Path qw(make_path rmtree);
use MIME::Base64 qw(encode_base64 decode_base64);
use YAML qw(LoadFile);
use YAML::Safe;

use Data::Dumper;

sub new {
    my $class = shift;
    my $self  = {@_};
    
    $self->{tt}   = Template->new({INTERPOLATE  => 1});
    $self->{json} = JSON::PP->new;
    $self->{json}->convert_blessed();
    
    $self->{secretsDir}           = "secrets"               if not defined $self->{secretsDir};
    $self->{ocConfigFile}         = "oc_config.json"        if not defined $self->{ocConfigFile};
    $self->{templatesTTDir}       = "templates_tt"          if not defined $self->{templatesTTDir};
    $self->{templatesYamlDir}     = "templates_yaml"        if not defined $self->{templatesYamlDir};
    $self->{validationReportFile} = "validation_report.txt" if not defined $self->{validationReportFile};
    $self->{cliCommand}           = "oc"                    if not defined $self->{cloudCommand};;
    if((defined $self->{advanceFeatures}) && ($self->{advanceFeatures} =~ /kubectl/)){
         $self->{cliCommand} = "kubectl";
    }

    qx/mkdir tmp 2>&1/;
    qx/mkdir tmp\/$self->{secretsDir}  2>&1/;
    qx/mkdir tmp\/$self->{templatesTTDir} 2>&1/;
    
    if(not defined $self->{cluster}){
        my $ocConfigFiletext = read_file($self->{ocConfigFile});
        my $oCconfig = $self->{json}->utf8->decode($ocConfigFiletext);
        $self->{cluster} = $oCconfig->{project}->{default_cluster};
        $self->{cluster} = "unknown" if not defined $self->{cluster};
    }
    
    return bless $self, $class;
}

sub backup{
    my ($self, $instance) = @_;

    $self->{instance} = $instance;
    return if not defined $self->generateYaml();
    
    qx/mkdir backups 2>&1/;
    qx/mkdir backups\/$instance 2>&1/;
    
    $self->_loopDir($self->{config}->{templates_yaml_dir}, "*", "_backupInstance");
}

sub backupWholeOCProject{
    my ($self) = @_;

    qx/mkdir backups 2>&1/;
    qx/mkdir backups\/wholeProject 2>&1/;
    $self->_clearDir("backups/wholeProject");
    
    my $ocConfigFileText = read_file($self->{ocConfigFile});
    my $ocConfig = $self->{json}->utf8->decode($ocConfigFileText);
    
    my $ocResourceKinds = $ocConfig->{project}->{oc_resource_kinds};
    $ocResourceKinds = $self->{ocResourceKinds} if defined $self->{ocResourceKinds};
    my @ocResourceKindsArray = split(';', $ocResourceKinds);
    
    foreach my $ocResourceKind (@ocResourceKindsArray){
        my $ocResourceKinds = $ocResourceKind;
        if($ocResourceKind ne "Ingress" &&
           $ocResourceKind ne "StorageClass" &&
           $ocResourceKind ne "NetworkPolicy"
        ){
            $ocResourceKinds .= "s";
        }
        print "$ocResourceKinds:\n";
        my $text = qx/$self->{cliCommand} get $ocResourceKinds/;
        my @textArray = split('\n', $text);
        shift @textArray;
        foreach my $line (@textArray){
            my @lineArray = split(" ", $line);
            my $ocItem = $lineArray[0];
            print "kind: $ocResourceKind  item: $ocItem\n";
            qx/mkdir backups\/wholeProject\/$ocResourceKinds 2>&1/;
            eval { 
                my $ocItemJson = qx/$self->{cliCommand} get $ocResourceKind $ocItem -o json/;
                my $ocItemHash = $self->{json}->utf8->decode($ocItemJson);
                if((defined $self->{advanceFeatures}) && 
                   ($self->{advanceFeatures} =~ /removeClutter/) && 
                   (defined $self->{removeClutterBackup})){
                    my $subParams = {"ocKind" => $ocResourceKind, "ocName" => $ocItem};
                    $ocItemHash = $self->{removeClutterBackup}->($ocItemHash, $subParams);
                }
                my $yamlSaveObj = YAML::Safe->new->boolean("JSON::PP");
                my $yamlText = $yamlSaveObj->Dump($ocItemHash);
                $yamlText =~ s/---\n//;
                write_file("backups\/wholeProject\/$ocResourceKinds/$ocItem".".yaml", $yamlText);
            };
            if($@){
                # if error occured take yaml without calling '->removeClutterBackup()'
                print "Removing clutter has failed, writing yaml file: $ocResourceKinds/$ocItem.yaml without removing clutter.\n";
                my $yamlText = qx/$self->{cliCommand} get $ocResourceKind $ocItem -o yaml/;
                write_file("backups\/wholeProject\/$ocResourceKinds/$ocItem".".yaml", $yamlText);
            }
        }
    }
}

sub convertYamlToTTExtention{
    my ($self, $yamlToTTconvertDir) = @_;

    $self->_loopDir($yamlToTTconvertDir, "yaml", "_convertYamlToTTExtention",
                    {_convertYamlToTTExtention => {yamlToTTconvertDir => $yamlToTTconvertDir}});
}

sub delete{
    my ($self, $instance) = @_;
    
    $self->{instance} = $instance;
    return if not defined $self->generateYaml();

    my $cluster   = $self->{config}->{cluster};
    my $namespace = $self->{config}->{namespace};
    print "\nDeleting Openshift components from instance: '$instance' in cluster: '$cluster' in namespace: '$namespace'\n";
    $self->_loopDir($self->{config}->{templates_yaml_dir}, "yaml", "_deleteOc");
    
    return;
}

sub generateYaml{
    my ($self) = @_;

    print "Instance is missing.\n" and return if not defined $self->{instance};

    $self->_selectInstanceSpecificSecrets();
    $self->{config} = $self->_generateConfig();
    $self->_removeInitFromComponentDirs() if $self->{omit} =~ /init/;
    $self->_loopDir($self->{config}->{templates_tt_dir}, "*", "_selectClusterSpecificTemplates");
    $self->_clearDir($self->{config}->{templates_yaml_dir});
    $self->_loopDir($self->{config}->{templates_tt_dir}, "tt", "_generateYaml");
    $self->_loopDir($self->{config}->{templates_tt_dir}, "*", "_removeClusterSpecificTemplates");   
    $self->_removeInstanceSpecificSecrets();
    
    return 1;
}

sub install{
    my ($self, $instance) = @_;

    $self->{instance} = $instance;
    return if not defined $self->generateYaml();

    my $cluster   = $self->{config}->{cluster};
    my $namespace = $self->{config}->{namespace};
    print "\nInstalling Openshift components for instance: '$instance' in cluster: '$cluster' in namespace: '$namespace'\n";
    # sent custom params
    # $self->_loopDir($self->{config}->{templates_tt_dir}, "tt", "_callOc", {_callOc => {{param1 : "value1"}, {param2 : "value2"} }});
    $self->_loopDir($self->{config}->{templates_yaml_dir}, "yaml", "_callOc") if $self->{omit} !~ /oc/;
    
    print qq^\n\nTo get build and deployment status run: $self->{cliCommand} get pods | grep Running | grep 'build\|deploy'\n\n^;
    
    return;
}

sub setParams{
    my ($self, $params) = @_;

    if (@_ == 2) {
        $self->{advanceFeatures}        = $params->{advanceFeatures}      if defined $params->{advanceFeatures};
        $self->{clusterBaseAddress}     = $params->{clusterBaseAddress}   if defined $params->{clusterBaseAddress};
        $self->{cluster}                = $params->{cluster}              if defined $params->{cluster};
        $self->{ocConfigFile}           = $params->{ocConfigFile}         if defined $params->{ocConfigFile};
        $self->{host}                   = $params->{host}                 if defined $params->{host};
        $self->{ocResourceKinds}        = $params->{ocResourceKinds}      if defined $params->{ocResourceKinds};
        $self->{componentDirs}          = $params->{componentDirs}        if defined $params->{componentDirs};
        $self->{namespace}              = $params->{namespace}            if defined $params->{namespace};
        $self->{projectName}            = $params->{projectName}          if defined $params->{projectName};
        $self->{omit}                   = $params->{omit}                 if defined $params->{omit};
        $self->{urlPrefix}              = $params->{urlPrefix}            if defined $params->{urlPrefix};
        $self->{clusterIpRange}         = $params->{clusterIpRange}       if defined $params->{clusterIpRange};
        $self->{secretsDir}             = $params->{secretsDir}           if defined $params->{secretsDir};
        $self->{sortType}               = $params->{sortType}             if defined $params->{sortType};
        $self->{templatesTTDir}         = $params->{templatesTTDir}       if defined $params->{templatesTTDir};
        $self->{yamlToTTconvertDir}     = $params->{yamlToTTconvertDir}   if defined $params->{yamlToTTconvertDir};
        $self->{specificYamlFile}       = $params->{specificYamlFile}     if defined $params->{specificYamlFile};
        $self->{templatesYamlDir}       = $params->{templatesYamlDir}     if defined $params->{templatesYamlDir};
        $self->{validationReportFile}   = $params->{validationReportFile} if defined $params->{validationReportFile};
    }
    return;
}

sub upgrade{
    my ($self, $instance) = @_;
    
    $self->validate($instance);
    
    my $validationReport      = read_file($self->{validationReportFile});
    my @validationReportLines = split /\n/, $validationReport;
    foreach my $line (@validationReportLines){
        my @items = split /;/, $line;
        if($items[-1] eq "MODIFIED"){
            my $pathAndFile = $items[0];
            my $ocKind      = $items[1];
            my $ocName      = $items[2];
            if($ocKind eq "PersistentVolumeClaim"){
                print "You are trying to update PersistentVolumeClaim.
Please make sure that all PODs that use this Persisten Volume are turned down before update.
If update operation start hanging at this step press ctrl+c to abort. \n\n";
            }
            print "Upgrading ocKind:$ocKind, ocName: $ocName from $pathAndFile\n";
            qx/$self->{cliCommand} delete $ocKind $ocName/;
            qx/$self->{cliCommand} create -f .\/$self->{config}->{templates_yaml_dir}\/$pathAndFile/;
        }
    }
}

sub validate{
    my ($self, $instance) = @_;

    qx/> $self->{validationReportFile}/; # clear file
    $self->{instance} = $instance;
    return if not defined $self->generateYaml();
    
    my $cluster   = $self->{config}->{cluster};
    my $namespace = $self->{config}->{namespace};
    print "\nValidating Openshift components for instance: '$instance' in cluster: '$cluster' in namespace: '$namespace'\n";
    $self->_loopDir($self->{config}->{templates_yaml_dir}, "yaml", "_validateInstance");
}

sub _backupInstance{
    my ($self, $params) = @_;

    my $dir          = $params->{dir};
    my $templateName = $params->{templateName};

    my $instance = $self->{config}->{instance};
    qx/mkdir backups\/$instance\/$dir 2>&1/;
    my $pathToYamlFile = "$self->{config}->{templates_yaml_dir}/$dir/$templateName".".yaml";
    my $templateData = LoadFile($pathToYamlFile);
    
    my $yamlText;
    if((defined $self->{advanceFeatures}) && 
       ($self->{advanceFeatures} =~ /removeClutter/) && 
       (defined $self->{removeClutterBackup})){
        print "$self->{cliCommand} get $templateData->{kind} $templateData->{metadata}->{name} -o json\n";
        my $ocJson = qx/$self->{cliCommand} get $templateData->{kind} $templateData->{metadata}->{name} -o json/;
        my $ocHash  = $self->{json}->utf8->decode($ocJson); 
        my $subParams = {"ocKind" => $templateData->{kind}, "ocName" => $templateData->{metadata}->{name}};
        $ocHash = $self->{removeClutterBackup}->($ocHash, $subParams);
        my $yamlSaveObj = YAML::Safe->new->boolean("JSON::PP");
        $yamlText = $yamlSaveObj->Dump($ocHash);
        $yamlText =~ s/---\n//;
    }else{
         print "$self->{cliCommand} get $templateData->{kind} $templateData->{metadata}->{name} -o yaml\n";
         $yamlText = qx/$self->{cliCommand} get $templateData->{kind} $templateData->{metadata}->{name} -o yaml/;
    }

    write_file("backups\/$instance\/$dir/$templateName".".yaml", $yamlText);     
}

sub _callOc{
    my ($self, $params) = @_;
    
    my @funcName = split /::/, (caller(0))[3];
    my $dir          = $params->{dir};
    my $templateName = $params->{templateName};
    my $customParams = $params->{params}->{$funcName[-1]};

    return if (defined $self->{componentIsAllowed}) && 
              (not $self->{componentIsAllowed}->($templateName, $dir, $self->{cluster}, $self->{instance}));

    my $templateNameYaml = $templateName.".yaml";
    
    my $yamlData = LoadFile("$self->{config}->{templates_yaml_dir}/$dir/$templateNameYaml");
    if($yamlData->{kind} eq "CronJob"){
        print "$self->{cliCommand} apply -f templates_yaml/$dir/$templateNameYaml\n";
        qx/$self->{cliCommand} apply -f .\/$self->{config}->{templates_yaml_dir}\/$dir\/$templateNameYaml/;
    }else{
        print "$self->{cliCommand} create -f templates_yaml/$dir/$templateNameYaml\n";
        qx/$self->{cliCommand} create -f .\/$self->{config}->{templates_yaml_dir}\/$dir\/$templateNameYaml/;
    }
}

sub _clusterDirExist{
    my ($self, $templateName) = @_;

    my @allowedClustersArr = split(';', $self->{config}->{allowed_clusters});
    foreach my $myCluster (@allowedClustersArr){
        return 1 if ($templateName eq $myCluster) && ($self->{cluster} eq $myCluster);       
    }
    return 0;
}

sub _clearDir{
    my ($self, $dir) = @_;

    rmtree $dir;
    make_path $dir;
}

sub _convertYamlToTTExtention{
    my ($self, $params) = @_;

    my @funcName           = split /::/, (caller(0))[3];
    my $dir                = $params->{dir};
    my $templateName       = $params->{templateName};
    my $customParams       = $params->{params}->{$funcName[-1]};
    my $yamlToTTconvertDir = $customParams->{yamlToTTconvertDir};
    
    my $path = "$yamlToTTconvertDir/$dir";
    qx/mv $path\/$templateName\.yaml $path\/$templateName\.tt 2>&1/;
}

sub _deleteOc{
    my ($self, $params) = @_;

    my $dir          = $params->{dir};
    my $templateName = $params->{templateName};

    my $data = LoadFile("$self->{config}->{templates_yaml_dir}/$dir/$templateName".".yaml");
    print "$self->{cliCommand} delete $data->{kind} $data->{metadata}->{name}\n";
    qx/$self->{cliCommand} delete $data->{kind} $data->{metadata}->{name}/;
}

sub _generateYaml{
    my ($self, $params) = @_;

    my @funcName = split /::/, (caller(0))[3];
    my $dir          = $params->{dir};
    my $templateName = $params->{templateName};
    my $customParams = $params->{params}->{$funcName[-1]};

    return if $dir =~ /init/ && $self->{omit} =~ /init/;
    return if (defined $self->{specificYamlFile}) && ($templateName !~ $self->{specificYamlFile});
    return if (defined $self->{componentIsAllowed}) && 
              (not $self->{componentIsAllowed}->($templateName, $dir, $self->{cluster}, $self->{instance}));
    
    my $yamlText;
    my $templatesYamlPath = "$self->{config}->{templates_yaml_dir}/$dir";
    my $templatesTTPath   = "$self->{config}->{templates_tt_dir}/$dir";
    make_path $templatesYamlPath or die("Failed to create path: $templatesYamlPath") if !-d $templatesYamlPath;
    $self->{tt}->process("$templatesTTPath/$templateName\.tt", $self->{config}, \$yamlText);    
    
    my $yamlHash;
    eval { $yamlHash = Load($yamlText);};
    if($@){
        print "Error occured during conversion to yaml in: $dir  $templateName\n", Dumper($@), "\n";
        return;
    }
    
    return if (defined $self->{ocResourceKinds}) && ($self->{ocResourceKinds} !~ $yamlHash->{kind});

    write_file("$templatesYamlPath/$templateName\.yaml", $yamlText);
    $self->{config}->{ip_last_number}++ if $yamlHash->{kind} eq "Service";
}

sub _generateConfig{
    my ($self) = @_;

    my $ocConfigJson = read_file($self->{ocConfigFile});
    my $config->{oc_config} = $self->{json}->utf8->decode($ocConfigJson);

    $config = $self->{addFlagValuesToConfig}->($config) if defined $self->{addFlagValuesToConfig};
    
    # set/generate instance specific names
    foreach my $entry (keys %{$config->{oc_config}->{instance_specific_name}}){
        $config->{oc_config}->{instance_specific_name}->{$entry} .= "-$self->{instance}";
    }

    $config->{allowed_clusters}  = $config->{oc_config}->{project}->{allowed_clusters};
    if(not defined $config->{allowed_clusters}){
        print "Warning: oc_config->project->allowed_clusters json node is empty. Marking 'allowed_clusters' as '$self->{cluster}'\n";
        $config->{allowed_clusters} = $self->{cluster};
    }else{
        print "Warning: Unknown cluster $self->{cluster}\n" if $config->{allowed_clusters} !~ $self->{cluster};
    }
    
    $config->{cluster_ip_range} = $config->{oc_config}->{project}->{cluster_ip_range};
    $config->{cluster_ip_range} = $self->{clusterIpRange}       if defined $self->{clusterIpRange};
    $config->{project_name}     = $config->{oc_config}->{project}->{name};
    $config->{project_name}     = $self->{projectName}          if defined $self->{projectName};
    $config->{host}             = $config->{oc_config}->{project}->{host};
    $config->{host}             = $self->{host}                 if defined $self->{host};
    $config->{namespace}        = $self->_getCurrentProject();
    $config->{namespace}        = $self->{namespace}            if defined $self->{namespace};
    # default component dirs are set here, dirs in 'templates_tt' not set as default will be omitted
    $config->{component_dirs}   = $config->{oc_config}->{project}->{component_dirs};
    $config->{component_dirs}   = $self->{componentDirs}        if defined $self->{componentDirs};
    # component dirs can contains numbers e.g.: '50-solr' so regexp match is used => 
    # separate 'init' components in order to avoid false matches (e.g.: 20-init-api vs 50-api when 'api' searched)
    my @componentDirs                  = split(';', $config->{component_dirs});
    my $standardComponentDirs = "";
    my $initComponentDirs = "";
    foreach my $componentDir (@componentDirs){
        if($componentDir =~ /init/){
            $initComponentDirs     .= $componentDir.";";
        }else{
            $standardComponentDirs .= $componentDir.";";
        }
    }
    chop($initComponentDirs);
    chop($standardComponentDirs); 
    $config->{init_component_dirs}        = $initComponentDirs;
    $config->{standard_component_dirs}    = $standardComponentDirs;
    $config->{oc_resource_kinds}          = $config->{oc_config}->{project}->{oc_resource_kinds};
    $config->{oc_resource_kinds}          = $self->{ocResourceKinds} if defined $self->{ocResourceKinds};
    $config->{templates_yaml_dir}         = $self->{templatesYamlDir};
    $config->{templates_tt_dir}           = $self->{templatesTTDir};
    $config->{cluster_camelcase}          = $self->{cluster};
    $config->{cluster}                    = lc $self->{cluster};
    $config->{instance}                   = lc $self->{instance};
    $config->{instance_capitalized_first} = ucfirst $config->{instance};
    $config->{url_prefix}                 = $self->{urlPrefix} if defined $self->{urlPrefix};
    $config->{cluster_base_address}       = $self->{clusterBaseAddress} if defined $self->{clusterBaseAddress}; 
    
    my $componentConfigNodes  = $self->_getComponentConfigNodes($config);
    foreach my $componentConfNode (@$componentConfigNodes){
        # set/generate default urls
        if((defined $config->{oc_config}->{instance_specific_data}->{$componentConfNode}) && 
           (ref($config->{oc_config}->{instance_specific_data}->{$componentConfNode}) eq 'HASH')){
            foreach my $instanceKey (keys %{$config->{oc_config}->{instance_specific_data}->{$componentConfNode}}){
                if(not defined $config->{oc_config}->{instance_specific_data}->{$componentConfNode}->{$instanceKey}->{url}){                    
                    my $componentNameKebab = $componentConfNode;
                    $componentNameKebab    =~ s/_/\-/;
                    my $lcInstanceKey   = lc $instanceKey;
                    my $url = "";
                    if(defined $self->{generateUrl}){
                        $url = $self->{generateUrl}->($config->{url_prefix}, 
                                                      $config->{project_name},
                                                      $componentNameKebab,
                                                      $lcInstanceKey,
                                                      $config->{cluster_base_address},
                                                      $config->{host});
                    }
                    $config->{oc_config}->{instance_specific_data}->{$componentConfNode}->{$instanceKey}->{url} = $url;  
                }
            }
        }
        # select instance specific data
        if(defined $config->{oc_config}->{instance_specific_data}->{$componentConfNode}->{$self->{instance}}){
            $config->{oc_config}->{instance_specific_data}->{$componentConfNode} = 
                $config->{oc_config}->{instance_specific_data}->{$componentConfNode}->{$self->{instance}};
        }
    }
    # in worse case 36 available IP addresses(see _generateYaml), make number smaller if more needed(max is 256)
    $config->{ip_last_number} = int(rand(220));
    
    print "'Info: component_dirs' parameter is missing\n"   if not defined $config->{component_dirs};
    print "'Info: cluster_ip_range' parameter is missing\n" if not defined $config->{cluster_ip_range};
    print "'Info: host' parameter is missing\n"             if not defined $config->{host};

    $self->_getSecrets($config);
    
    return $config;
}


sub _getSecrets{
    my ($self, $config) = @_;

    for my $dirFileName (File::Find::Rule->file()->name("*")->in($self->{secretsDir})) {
        my @dirFileNameArr = split('/', $dirFileName);
        if(scalar @dirFileNameArr == 2){
            my $secretText = read_file($dirFileName);
            $secretText =~ s/\n//g;
            $secretText =~ s/\r//g;
            my $secretTextBase64 = encode_base64($secretText);
            $secretTextBase64 =~ s/\n//g;
            $secretTextBase64 =~ s/\r//g;
            $config->{secrets}->{$dirFileNameArr[1]} = $secretTextBase64;
        }
    }
    # instance specific secrets e.g.: secrets/instance/test/my-secret.txt
    for my $dirFileName (File::Find::Rule->file()->name("*")->in("$self->{secretsDir}/instance/$self->{instance}")) {
        my @dirFileNameArr = split('/', $dirFileName);
        if(scalar @dirFileNameArr == 4){
            my $secretText = read_file($dirFileName);
            $secretText =~ s/\n//g;
            $secretText =~ s/\r//g;
            my $secretTextBase64 = encode_base64($secretText);
            $secretTextBase64 =~ s/\n//g;
            $secretTextBase64 =~ s/\r//g;
            $config->{secrets}->{instance_specific}->{$dirFileNameArr[3]} = $secretTextBase64;
        }
    }
}

sub _getComponentConfigNodes{
    my ($self, $config) = @_;
    
    my @componentConfigNodes;
    my $componentConfigNodesString;
    if((defined $config->{oc_config}) && (defined $config->{oc_config}->{instance_specific_data})){
        foreach my $componentConfigNode (keys %{$config->{oc_config}->{instance_specific_data}}){
            push @componentConfigNodes, $componentConfigNode;
        }
    }

    return \@componentConfigNodes;
}

sub _getCurrentProject{
    my ($self) = @_; 

    my $projectCmdLine    = qx/$self->{cliCommand} config current-context/;
    my @projectCmdLineArr = split('/', $projectCmdLine);
    my $project = $projectCmdLineArr[0];
    $project = "unknown" if not defined $project;

    return $project;
}

sub _loopDir {
    my ($self, $dirToLoop, $extention, $injectedSubName, $params) = @_;  

    my $templates = {};
    for my $dirFileName (File::Find::Rule->file()->name("*.$extention")->in($dirToLoop)) {
        $dirFileName =~ s/$dirToLoop\///;
        my @dirFile  = split('\/', $dirFileName);
        my @dir      = split('\-', $dirFile[0]);
        my @file     = split('\-', $dirFile[1]);
        # e.g: $templates->{30-solr}->{dirNumber}               = 30 # in order so sort as integer
        #                           ->{20-build-config-solr.tt} = 20
        $templates->{$dirFile[0]}->{dirNumber}   = $dir[0];
        $templates->{$dirFile[0]}->{$dirFile[1]} = $file[0];
    }

    my @dirArray;
    if((defined $self->{sortType}) && ($self->{sortType}) eq "alphabetic"){
        foreach my $dir (sort { lc $templates->{$a}->{dirNumber} cmp lc $templates->{$b}->{dirNumber} } keys %{$templates}){
            push @dirArray, $dir;
        }
    }else{
        # numeric
        no warnings 'numeric';
        foreach my $dir (sort { $templates->{$a}->{dirNumber} <=> $templates->{$b}->{dirNumber} } keys %{$templates}){
            push @dirArray, $dir;
        }
    }
    @dirArray = reverse @dirArray if $injectedSubName eq "_deleteOc";

    foreach my $dir (@dirArray){
        print "\nInstalling components from: $dir:\n" if $injectedSubName eq "_callOc";
        
        my @fileArray;
        if((defined $self->{sortType}) && ($self->{sortType}) eq "alphabetic"){
            foreach my $file (sort { lc $templates->{$dir}->{$a} cmp  lc $templates->{$dir}->{$b} } keys %{$templates->{$dir}}){
                push @fileArray, $file;
            }
        }else{
            # numeric
            no warnings 'numeric';
            foreach my $file (sort { $templates->{$dir}->{$a} <=> $templates->{$dir}->{$b} } keys %{$templates->{$dir}}){
                push @fileArray, $file;
            }
        }
        @fileArray = reverse @fileArray if $injectedSubName eq "_deleteOc";

        foreach my $file (@fileArray){
            # when calling '_generateYaml' skip cluster directories defined in oc_project.json->project->allowed_clusters,
            # cluster specific tt files are already copied to the component directory
            if((($injectedSubName eq "_generateYaml") && ($self->{config}->{allowed_clusters} =~ /$file/)) ||
                 $file eq "dirNumber"                                                                      || 
                 $self->_skipComponent($dir)) {
                next;
            }
            my @fileArr = split('\.', $file);            
            if(($injectedSubName eq "_generateYaml") && 
               (not defined $fileArr[1]) && 
               ($self->{config}->{allowed_clusters} !~ /$file/)){
                print "Warning : Unknown cluster: $file\n";
            }
            my $injectedSub = \&$injectedSubName;
            $injectedSub->($self, {dir => $dir, templateName => $fileArr[0], params => $params});
        }
    }
}

sub _removeClusterSpecificTemplates{
    my ($self, $params) = @_;

    return if (not defined $self->{advanceFeatures}) || ($self->{advanceFeatures} !~ /multipleClusters/);

    my $dir          = $params->{dir};
    my $templateName = $params->{templateName};
    
    if($self->_clusterDirExist($templateName)){
        qx/rm templates_tt\/$dir\/*.tt 2>&1/;
        qx/cp tmp\/templates_tt\/*.tt templates_tt\/$dir\/ 2>&1/;
        qx/rm tmp\/templates_tt\/*.tt  2>&1/;
    }
}

sub _removeInitFromComponentDirs{
    my ($self) = @_;
    
    my @componentsYamlDirArray       = split(';', $self->{config}->{component_dirs});
    @componentsYamlDirArray          = (grep {$_ !~ /init/} @componentsYamlDirArray);
    $self->{config}->{component_dirs} = join( ';', @componentsYamlDirArray);
}

sub _removeInstanceSpecificSecrets{
    my ($self) = @_;  
    
    return if (not defined $self->{advanceFeatures}) || ($self->{advanceFeatures} !~ /multipleClusters/);
    
    qx/rm $self->{secretsDir}\/* 2>&1/;
    qx/cp tmp\/$self->{secretsDir}\/* $self->{secretsDir}\/ 2>&1/;
    qx/rm tmp\/$self->{secretsDir}\/* 2>&1/;
}

sub _selectClusterSpecificTemplates{
    my ($self, $params) = @_;

    return if (not defined $self->{advanceFeatures}) || ($self->{advanceFeatures} !~ /multipleClusters/);
    
    my $dir          = $params->{dir};
    my $templateName = $params->{templateName};
    
    if($self->_clusterDirExist($templateName)){
        qx/cp templates_tt\/$dir\/*.tt tmp\/templates_tt\/ 2>&1/;
        qx/cp templates_tt\/$dir\/$self->{cluster}\/*.tt templates_tt\/$dir\//;
    }
}

sub _selectInstanceSpecificSecrets{
    my ($self) = @_;  
    
    return if (not defined $self->{advanceFeatures}) || ($self->{advanceFeatures} !~ /multipleClusters/);
    
    qx/cp $self->{secretsDir}\/* tmp\/$self->{secretsDir}\/ 2>&1/;
    qx/cp $self->{secretsDir}\/$self->{cluster}\/* $self->{secretsDir}\/ 2>&1/;
}

sub _skipComponent{
    my ($self, $dir) = @_;

    # ignore skiping if called by this flag
    return 0 if defined $self->{yamlToTTconvertDir};
    
    my @installComponents = [];
    if($dir =~ /init/){
        if(defined $self->{config}->{init_component_dirs}){
            @installComponents = split(';', $self->{config}->{init_component_dirs});
        }
        foreach my $installComponent (@installComponents){
            return 0 if $dir =~ /$installComponent/;
        }  
    }else{
        if(defined $self->{config}->{standard_component_dirs}){
            @installComponents = split(';', $self->{config}->{standard_component_dirs});
        }
        foreach my $installComponent (@installComponents){
            return 0 if $dir =~ /$installComponent/;
        }    
    }

    return 1;
}

sub _validateInstance{
    my ($self, $params) = @_;
    
    my @funcName = split /::/, (caller(0))[3];
    my $dir          = $params->{dir};
    my $templateName = $params->{templateName};
    
    my $templateNameYaml = $templateName.".yaml";
    my $yamlData         = LoadFile("$self->{config}->{templates_yaml_dir}/$dir/$templateNameYaml");
    my $ocName           = $yamlData->{metadata}->{name};
    my $ocKind           = $yamlData->{kind};
    my $ocJson           = qx/$self->{cliCommand} get $ocKind $ocName -o json/;
    my $ocHash = {};
    eval { 
        $ocHash  = $self->{json}->utf8->decode($ocJson); 
        if(($ocKind eq "Secret") && (ref($ocHash->{data}) eq 'HASH')){
            foreach my $key (keys %{$ocHash->{data}}){
                my $secret = decode_base64($ocHash->{data}->{$key});
                $secret =~ s/\n//g;
                $secret =~ s/\r//g;
                $ocHash->{data}->{$key} = $secret;
            }
        }
    };
    print Dumper($@) if $@;
    
    my $templateYamlText = read_file("$self->{config}->{templates_yaml_dir}/$dir/$templateNameYaml");
    my $yamlObj = YAML::Safe->new->boolean("JSON::PP");
    my $templateHash = $yamlObj->Load($templateYamlText);

    my $subParams = {"dir" => $dir, "templateName" => $templateName, "ocKind" => $ocKind, "ocName" => $ocName};
    $ocHash       = $self->{removeClutter}->($ocHash, $subParams)       if defined $self->{removeClutter};
    $templateHash = $self->{removeClutter}->($templateHash, $subParams) if defined $self->{removeClutter};
    
    if($ocKind eq "Secret"){
        if((defined $templateHash->{data}) && (ref($templateHash->{data}) eq 'HASH')){
            foreach my $key (keys %{$templateHash->{data}}){
                my $dataBase64Encoded = $templateHash->{data}->{$key};
                my $dataBase64Decoded = decode_base64($dataBase64Encoded);
                $dataBase64Decoded =~ s/\n//g;
                $dataBase64Decoded =~ s/\r//g;
                $templateHash->{data}->{$key} = $dataBase64Decoded;
            }
        }
    }
    
    $ocJson          =  $self->{json}->utf8->pretty->canonical->encode($ocHash);
    my $templateJson =  $self->{json}->utf8->pretty->canonical->encode($templateHash);
    my @ocJsonArr       = split /\n/, $ocJson;
    my @templateJsonArr = split /\n/, $templateJson;
    my $diff = diff \@ocJsonArr, \@templateJsonArr, { STYLE => "Table", CONTEXT => 0 };
    if(($ocKind eq "Secret") && ($diff ne "")){
        $diff = "+---+-----------------------------------------------------+---+---------------------------------+
*   |           different secret, not displayed           *   | different secret, not displayed |
+---+-----------------------------------------------------+---+---------------------------------+
";
    }
    $diff =~ s/\\ No newline at end of file\s//g;
   
    my $diffStatus;
    if((defined $diff) && ($diff ne "")){
        $diffStatus = "MODIFIED";
    }else{
         $diffStatus = "OK";
    }
    my $line = "$dir/$templateNameYaml;$ocKind;$ocName;$diffStatus\n";
    print $line;
    print $diff if $diff ne "";
    write_file($self->{validationReportFile}, {append => 1}, $line);
}

1;

__END__

=encoding utf-8

=head1 NAME

OcToolkit - Open Cloud Toolkit -  A Helm-like Perl module for managing Openshift and Kubernetes projects

=head1 SYNOPSIS

    use OcToolkit;
    
    my $ocObj = OcToolkit->new( 
                            advanceFeatures       => $advanceFeatures,
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
    $ocObj->install('test');
    $ocObj->validate('test');
    $ocObj->update('test');
    $ocObj->backup('prod');
    $ocObj->delete('dev');

=head1 DESCRIPTION

Helm-like tool for Openshift and Kubernetes with multi cluster support.
See https://gitlab.com/code7143615/octoolkit/-/blob/master/README.md how to use this library in ocToolkit.pl script
and use it as 'Helm-like' command line tool.
Feedback Page: https://gitlab.com/code7143615/octoolkit/-/issues/1

=head1 LICENSE

Copyright (C) John Summers.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 OVERVIEW

OcToolkit (short for Open Cloud Toolkit) is a Perl module designed as a Helm-like toolkit for managing Openshift (and Kubernetes) projects, with added support for multi-cluster workflows.

=head1 KEY FEATURES AND FUNCTIONALITY

=head2 Initialization

Creates a Perl object that wraps tools needed for templating (Template), JSON processing (JSON::PP), file handling, YAML parsing, and more.

Default values for directories and commands (e.g., C<oc> or, in advanced mode, C<kubectl>) are configured in the constructor.

=head2 Core Operations

=over 4

=item * B<install(instance)>

Generates YAML manifests from templates and applies them via C<oc create> or C<oc apply> commands.

=item * B<validate(instance)>

Compares live cluster resources to offline templates using C<oc get>, computes diffs, and logs the status C<OK> or C<MODIFIED>.

=item * B<upgrade(instance)>

Deletes and recreates modified resources, handling some types like PersistentVolumeClaims cautiously.

=item * B<backup(instance)> / B<backupWholeOCProject()>

Backs up live cluster resources into YAML files, with optional clutter removal filters.

=item * B<delete(instance)>

Deletes resources based on generated YAML templates using C<oc delete>.

=back

=head2 Templating Engine

Accepts Template Toolkit files (C<.tt>) and data configuration to generate deployment and other YAMLs.

Organizes templates by directory (often prefixed numerically for order) and processes directories in sequence.

=head2 Configurable Parameters & Extensibility

Accepts a wide range of options such as:

=over 4

=item *

C<namespace>

=item *

C<cluster>

=item *

C<componentDirs>

=item *

C<secretsDir>

=item *

C<urlPrefix>

=item *

... and others.

=back

Supports custom callback functions for:

=over 4

=item * B<removeClutter> / B<removeClutterBackup> - clean up resource output before diffing/backups

=item * B<generateUrl> - dynamically generate service URLs

=item * B<componentIsAllowed> - include/exclude components conditionally

=item * B<addFlagValuesToConfig> - augment configuration data during processing

=back

=head2 Secrets Management

Reads secrets from a C<secretsDir>, encodes them in base64, and embeds them into resource configurations.

=head1 USAGE EXAMPLE

Here's the typical flow from the module's documentation:

    use OcToolkit;

    my $ocObj = OcToolkit->new(
        cluster            => $cluster,
        ocConfigFile       => $ocConfigFile,
        templatesTTDir     => "templates_tt",
        templatesYamlDir   => "templates_yaml",
        secretsDir         => "secrets",
        # ... plus any advanced callbacks or settings
    );

    $ocObj->install('testInstance');
    $ocObj->validate('testInstance');
    $ocObj->upgrade('testInstance');
    $ocObj->backup('production');
    $ocObj->delete('devInstance');

=head1 SUMMARY

=over 4

=item * B<Template-driven management>

Converts templates into YAML and applies them via C<oc> commands.

=item * B<Full lifecycle support>

Can install, validate, upgrade, backup, and delete Openshift/Kubernetes resources.

=item * B<Multi-cluster aware>

Customizable per cluster and instance, with filtering support.

=item * B<Extensible hooks and customization>

Allows user-supplied callbacks for secret handling, URL generation, cleanup, and more.

=item * B<Secret handling built in>

Encodes and injects secrets at runtime securely.

=back

=head1 NOTE

If you are intrested in 'ocToolkit' command line tool only as an end user, see link to Gitlab in Description

=head1 CONCLUSION

OcToolkit is a robust and flexible Perl-based alternative to Helm, offering templated deployment workflows with validation, backups, and multi-cluster capabilities.

If you're familiar with Helm but prefer a Perl-centric, highly customizable tool, this could be a great fit.

=cut

=head1 AUTHOR

John Summers E<lt>devp2000a@gmail.comE<gt>

=cut
