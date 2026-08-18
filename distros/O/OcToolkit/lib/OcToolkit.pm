# John Summers,  hereby disclaims all copyright interest in the program Open Cloud Toolkit aka "ocToolkit"  written by John Summers
# 
# John Summers, devp2000a@gmail.com 
# 
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

package OcToolkit;

use v5.16; # or newer
use strict;
use warnings;

our $VERSION = "1.19";

use JSON::PP;
use Tie::IxHash;
use Text::Diff;
use Template;
use File::Slurp;
use File::Find::Rule;
use File::Path qw(make_path rmtree);
use MIME::Base64 qw(encode_base64 decode_base64);
use YAML qw(LoadFile);
use YAML::Safe;
use File::Basename qw(basename);
use Storable qw(dclone);

use Data::Dumper;


sub new{
    my $class = shift;
    my $self  = {@_};
    
    $self->{tt}   = Template->new({INTERPOLATE  => 1, ABSOLUTE => 1});
    $self->{json} = JSON::PP->new;
    $self->{json}->convert_blessed();
    
    my $projectDir = $self->{projectDir}; # e.g.: /home/user/myProject/
    
    $self->{secretsDir}           = $projectDir."secrets"               if not defined $self->{secretsDir};
    $self->{secretsJson}          = "secrets.json"                      if not defined $self->{secretsJson};
    $self->{octConfigFile}        = $projectDir."oct_config.json"       if not defined $self->{octConfigFile};
    $self->{templatesTTDir}       = $projectDir."templates_tt"          if not defined $self->{templatesTTDir};
    $self->{templatesYamlDir}     = $projectDir."templates_yaml"        if not defined $self->{templatesYamlDir};
    $self->{validationReportFile} = $projectDir."validation_report.txt" if not defined $self->{validationReportFile};
    $self->{cloudCommand}         = "oc"                                if not defined $self->{cloudCommand};
    if((defined $self->{advanceFeatures}) && ($self->{advanceFeatures} =~ /kubectl/)){
         $self->{cloudCommand} = "kubectl";
    }
    
    if(!-e $self->{octConfigFile}){
        open(my $fh, '>', $self->{octConfigFile}) or die "Could not create '$self->{octConfigFile}': $!";
        print $fh '{}';
        close($fh);
        print "$self->{octConfigFile} is missing. Empty $self->{octConfigFile} is created.\n";
    }

    if(not defined $self->{cluster}){
        my $octConfigFiletext = read_file($self->{octConfigFile});
        my $octConfig = $self->{json}->utf8->decode($octConfigFiletext);
        $self->{cluster} = $octConfig->{project}->{default_cluster};
        $self->{cluster} = "unknown" if not defined $self->{cluster};
    }

    return bless $self, $class;
}

sub backup{
    my ($self, $instance) = @_;

    $self->_initConfSecretsAndYaml($instance);

    $self->_createDir("backups");
    $self->_createDir("backups\/$instance");
    
    $self->_loopDir($self->{config}->{templates_yaml_dir}, "*", "_backupInstance");
    $self->_runPostHook();
    
    return;
}

sub backupWholeOCProject{
    my ($self) = @_;

    $self->_runPreHook();
    $self->_createDir("backups");
    $self->_createDir("backups\/wholeProject");
    $self->_clearDir("backups/wholeProject");
    
    my $octConfigFileText = read_file($self->{octConfigFile});
    my $octConfig = $self->{json}->utf8->decode($octConfigFileText);
    
    my $resourceKindsBackup = $octConfig->{project}->{resource_kinds_backup};
    $resourceKindsBackup = $self->_getDefaultKindsBackup() if not defined $resourceKindsBackup;
    my @resourceKindsBackupArray = split(';', $resourceKindsBackup);
    
    foreach my $octResourceKind (@resourceKindsBackupArray){
        my $resourceKindsBackup = $octResourceKind;
        if($octResourceKind ne "Ingress" &&
           $octResourceKind ne "StorageClass" &&
           $octResourceKind ne "NetworkPolicy"
        ){
            $resourceKindsBackup .= "s";
        }
        print "$resourceKindsBackup:\n";
        my $text = qx/$self->{cloudCommand} get $resourceKindsBackup/;
        my @textArray = split('\n', $text);
        shift @textArray;
        foreach my $line (@textArray){
            my @lineArray = split(" ", $line);
            my $octItem = $lineArray[0];
            print "kind: $octResourceKind  item: $octItem\n";
            $self->_createDir("backups\/wholeProject\/$resourceKindsBackup");
            eval { 
                my $octItemJson = qx/$self->{cloudCommand} get $octResourceKind $octItem -o json/;
                my $octItemHash = $self->{json}->utf8->decode($octItemJson);
                if((defined $self->{advanceFeatures}) && 
                   ($self->{advanceFeatures} =~ /removeClutter/) && 
                   (defined $self->{removeClutterBackup})){
                    my $subParams = {"octKind" => $octResourceKind, "octName" => $octItem};
                    $octItemHash = $self->{removeClutterBackup}->($octItemHash, $subParams);
                }
                my $yamlSaveObj = YAML::Safe->new->boolean("JSON::PP");
                my $yamlText = $yamlSaveObj->Dump($octItemHash);
                $yamlText =~ s/---\n//;
                write_file("$self->{projectDir}backups\/wholeProject\/$resourceKindsBackup/$octItem".".yaml", $yamlText);
            };
            if($@){
                # if error occurred take yaml without calling '->removeClutterBackup()'
                print "Removing clutter has failed, writing yaml file: $resourceKindsBackup/$octItem.yaml without removing clutter.\n";
                my $yamlText = qx/$self->{cloudCommand} get $octResourceKind $octItem -o yaml/;
                write_file("$self->{projectDir}backups\/wholeProject\/$resourceKindsBackup/$octItem".".yaml", $yamlText);
            }
        }
    }
    $self->_runPostHook();
    
    return;
}

sub convertYamlToTTExtention{
    my ($self, $yamlToTTconvertDir) = @_;

    $self->_loopDir($yamlToTTconvertDir, "yaml", "_convertYamlToTTExtention",
                    {_convertYamlToTTExtention => {yamlToTTconvertDir => $yamlToTTconvertDir}});
}

sub delete{
    my ($self, $instance) = @_;
    
    $self->_initConfSecretsAndYaml($instance);

    my $cluster   = $self->{config}->{cluster};
    my $namespace = $self->{config}->{namespace};
    return if ($self->{omit} // '') =~ /cloud/;
    return if not $self->_confirmOperation("Delete", $instance, $cluster, $namespace);
    
    $self->_loopDir($self->{config}->{templates_yaml_dir}, "yaml", "_deleteFromCloud");
    
    if((not $self->{config}->{oct_config}->{project}->{omit_deletion_of_not_defined_resources})  &&
       (defined $self->{advanceFeatures} && $self->{advanceFeatures} =~ /deleteUndefinedInCloud/)
    ){
        $self->_deleteUndefinedResourcesInCloud($instance);
    }

    $self->_gitCommitAndPush();
    $self->_runPostHook();
    
    return;
}

sub generateConfigJsonTemplate{
    my ($self, $instances) = @_;
    
    print "Existing config file: $self->{octConfigFile} will be overwriten do you want to continue?
Press enter to contiue or type: 'skip' and press enter to skip this operation.\n";
    my $continue = <>;
    return if $continue =~ /skip/;
    
    # preserve order in hash
    my $componentFromTemplatesTTDir = $self->_getComponentsFromTemplatesTTDir();
    $componentFromTemplatesTTDir =~ s/\-/_/g;
    my @componentsArr = split(';', $componentFromTemplatesTTDir);
    tie my %configHash, 'Tie::IxHash';
    tie my %instanceSpecificData, 'Tie::IxHash';
    $configHash{instance_specific_data} = \%instanceSpecificData;
    foreach my $component (@componentsArr) {
        tie my %componentHash, 'Tie::IxHash';
        $instanceSpecificData{$component} = \%componentHash;
        my @instancesArr = split(';', $instances);
        foreach my $instance (@instancesArr) {
            $componentHash{$instance} = {};
        }
    }
    $configHash{instance_specific_name} = {};
    $configHash{git_repo} = {};
    
    tie my %gitHash, 'Tie::IxHash';
    $gitHash{auto_commit} = 0;
    $gitHash{auto_push} = 0;
    $gitHash{auto_commit_prompt} = 0;
    $gitHash{auto_push_branch} = "master";
    
    tie my %projectHash, 'Tie::IxHash';
    $projectHash{name} = "";
    $projectHash{namespace} = undef;
    $projectHash{host} = "";
    $projectHash{default_cluster} = undef;
    $projectHash{allowed_clusters} = undef;
    $projectHash{component_dirs} = undef;
    $projectHash{resource_kinds_backup} = undef;
    $projectHash{resource_kinds} = undef;
    $projectHash{git} = \%gitHash;
    $projectHash{url_prefix} = undef;
    $projectHash{prompt_write_operations} = 1;
    $projectHash{default_cloud_write_command} = undef;
    $projectHash{output_log_file} = "output.log";
    $projectHash{omit_deletion_of_not_defined_resources} = undef;
    $projectHash{revert_exemptions} = undef;
    $projectHash{cluster_base_address} = undef;
    $projectHash{cluster_ip_range} = "";
    
    $configHash{project} = \%projectHash;
    
    write_file($self->{octConfigFile}, $self->{json}->pretty->encode(\%configHash));

    return;
}

sub install{
    my ($self, $instance) = @_;

    $self->_initConfSecretsAndYaml($instance);

    my $cluster   = $self->{config}->{cluster};
    my $namespace = $self->{config}->{namespace};    
    return if ($self->{omit} // '') =~ /cloud/;
    return if not $self->_confirmOperation("Install", $instance, $cluster, $namespace);

    # sent custom params
    # $self->_loopDir($self->{config}->{templates_tt_dir}, "tt", "_callCloudCommand", {_callCloudCommand => {param1 => "value1", param2 => "value2"}});
    $self->_loopDir($self->{config}->{templates_yaml_dir}, "yaml", "_callCloudCommand");
    $self->_gitCommitAndPush();
    $self->_runPostHook();
    
    print qq^\n\nTo get build and deployment status run: $self->{cloudCommand} get pods --sort-by=.metadata.creationTimestamp | tac | grep Running\n\n^;
    
    return;
}

sub revert{
    my ($self, $instance) = @_;
     
    # disable range narrowing, revert is meant to be used after 'git revert' or similar operation,
    # whole project should be taken for revert
    delete $self->{resourceKinds};
    delete $self->{components};
    delete $self->{specificYamlFile};
    
    if(defined $self->{gitRevertHash}){
        print "git revert --no-commit $self->{gitRevertHash}..HEAD\n";
        my $gitText = qx/git revert --no-commit $self->{gitRevertHash}..HEAD 2>&1/;
        if($? != 0){
            print "Unable to git revert:\n$gitText\n";
            return;
        }else{
             $self->_writeLog($gitText);
        }
    }
    
    my $skipPostHooks = 1;
    my $skipGitCommit = 1;
    my $atLeastOneUpdated = $self->update($instance, $skipPostHooks, $skipGitCommit);

    my $atLeastOneDeleted = 0; 
    if(not $self->{config}->{oct_config}->{project}->{omit_deletion_of_not_defined_resources}){
        $atLeastOneDeleted = $self->_deleteUndefinedResourcesInCloud($instance);
    }
    $self->_gitCommitAndPush() if $atLeastOneUpdated || $atLeastOneDeleted;
     
    $self->_runPostHook();
     
    return;
}

sub setParams{
    my ($self, $params) = @_;

    if (@_ == 2) {
        $self->{advanceFeatures}       = $params->{advanceFeatures}       if defined $params->{advanceFeatures};
        $self->{clusterBaseAddress}    = $params->{clusterBaseAddress}    if defined $params->{clusterBaseAddress};
        $self->{cluster}               = $params->{cluster}               if defined $params->{cluster};
        $self->{octConfigFile}         = $params->{octConfigFile}         if defined $params->{octConfigFile};
        $self->{gitRevertHash}         = $params->{gitRevertHash}         if defined $params->{gitRevertHash};
        $self->{host}                  = $params->{host}                  if defined $params->{host};
        $self->{resourceKinds}         = $params->{resourceKinds}         if defined $params->{resourceKinds};
        $self->{components}            = $params->{components}            if defined $params->{components};
        $self->{namespace}             = $params->{namespace}             if defined $params->{namespace};
        $self->{projectName}           = $params->{projectName}           if defined $params->{projectName};
        $self->{omit}                  = $params->{omit}                  if defined $params->{omit};
        $self->{urlPrefix}             = $params->{urlPrefix}             if defined $params->{urlPrefix};
        $self->{clusterIpRange}        = $params->{clusterIpRange}        if defined $params->{clusterIpRange};
        $self->{secretsDir}            = $params->{secretsDir}            if defined $params->{secretsDir};
        $self->{sortType}              = $params->{sortType}              if defined $params->{sortType};
        $self->{templatesTTDir}        = $params->{templatesTTDir}        if defined $params->{templatesTTDir};
        $self->{yamlToTTconvertDir}    = $params->{yamlToTTconvertDir}    if defined $params->{yamlToTTconvertDir};
        $self->{specificYamlFile}      = $params->{specificYamlFile}      if defined $params->{specificYamlFile};
        $self->{templatesYamlDir}      = $params->{templatesYamlDir}      if defined $params->{templatesYamlDir};
        $self->{validationReportFile}  = $params->{validationReportFile}  if defined $params->{validationReportFile};
        $self->{projectDir}            = $params->{projectDir}            if defined $params->{projectDir};
        $self->{addFlagValuesToConfig} = $params->{addFlagValuesToConfig} if defined $params->{addFlagValuesToConfig};
        $self->{componentIsAllowed}    = $params->{componentIsAllowed}    if defined $params->{componentIsAllowed};
        $self->{generateUrl}           = $params->{generateUrl}           if defined $params->{generateUrl};
        $self->{removeClutter}         = $params->{removeClutter}         if defined $params->{removeClutter};
        $self->{removeClutterBackup}   = $params->{removeClutterBackup}   if defined $params->{removeClutterBackup};
    }
    return;
}

sub scaleToZero{
     my ($self, $instance) = @_;

     $self->_initConfSecretsAndYaml($instance);

     foreach my $resourceName (keys %{$self->{templateManifests}->{Deployment}}){
         print "$self->{cloudCommand} scale Deployment $resourceName --replicas=0\n";
         qx/$self->{cloudCommand} scale Deployment $resourceName --replicas=0/;
     }
     foreach my $resourceName (keys %{$self->{templateManifests}->{DeploymentConfig}}){
         print "$self->{cloudCommand} scale DeploymentConfig $resourceName --replicas=0\n";
         qx/$self->{cloudCommand} scale DeploymentConfig $resourceName --replicas=0/;
     }
     foreach my $resourceName (keys %{$self->{templateManifests}->{StatefulSet}}){
         print "$self->{cloudCommand} scale StatefulSet $resourceName --replicas=0\n";
         qx/$self->{cloudCommand} scale StatefulSet $resourceName --replicas=0/;
     }

     return;
}

sub update{
    my ($self, $instance, $skipPostHooks, $skipGitCommit) = @_;
        
    $self->validateAgainstCloud($instance, $skipPostHooks);

    if(not $self->{atLeastOneModified}){
        print "No updated needed.\n";
        return;
    }
    
    my $cluster   = $self->{config}->{cluster};
    my $namespace = $self->{config}->{namespace};
    return if ($self->{omit} // '') =~ /cloud/;
    return if not $self->_confirmOperation("Update", $instance, $cluster, $namespace);
    
    my $validationReport      = read_file($self->{validationReportFile});
    my @validationReportLines = split /\n/, $validationReport;
    my $atLeastOneUpdated = 0;
    foreach my $line (@validationReportLines){
        my @items = split /;/, $line;
        if($items[-1] eq "MODIFIED"){
            $atLeastOneUpdated = 1;
            my $pathAndFile = $items[0];
            my $octKind     = $items[1];
            my $octName     = $items[2];
            if($octKind eq "PersistentVolumeClaim"){
                my $text = "You are trying to update PersistentVolumeClaim.
Please make sure that all PODs that use this Persisten Volume are turned down before update.
If update operation start hanging at this step press ctrl+c to abort. \n\n";
                $self->_writeLog($text);
            }
            $self->_writeLog("Updating octKind:$octKind, octName: $octName from $pathAndFile\n");
            my $writeCommand = $self->_getCloudWriteCommand();
            my $outputText = "";
            $outputText = qx/$self->{cloudCommand} delete $octKind $octName 2>&1/ if $writeCommand eq "create";
            $self->_writeLog($outputText);
            my $templatesYamlDir = $self->{config}->{templates_yaml_dir};
            $outputText = qx/$self->{cloudCommand} $writeCommand -f $templatesYamlDir\/$pathAndFile 2>&1/;
            $self->_writeLog($outputText);
        }
    }
    $self->_gitCommitAndPush() if $atLeastOneUpdated && (not $skipGitCommit);
    $self->_runPostHook() if not defined $skipPostHooks;
    
    return $atLeastOneUpdated;
}

sub validateAgainstCloud{
    my ($self, $instance, $skipPostHooks) = @_;

    qx/> $self->{validationReportFile}/; # clear file
    
    $self->_initConfSecretsAndYaml($instance);
    
    $self->_loopDir($self->{config}->{templates_yaml_dir}, "yaml", "_validateAgainstCloud");
    $self->_runPostHook() if not defined $skipPostHooks;
    
    return;
}

sub validateManifests{
    my ($self, $instance, $skipPostHooks) = @_;
    
    $self->_initConfSecretsAndYaml($instance);
    $self->_loopDir($self->{config}->{templates_yaml_dir}, "yaml", "_callCloudCommand", {_callCloudCommand => {dryRun => 1}});
    $self->_runPostHook() if not defined $skipPostHooks;
    
    return;
}

sub _addSecretsToConfigHash{
    my ($self, $config, $dirFileName) = @_;

    my @dirFileNameArr = split('/', $dirFileName); # test, prod etc.
    my $secretText = read_file($dirFileName);
    $config->{secrets}->{$dirFileNameArr[-1]} = $secretText;
  
    my $secretTextBase64 = encode_base64($secretText, "");
    $config->{secrets}->{base64}->{$dirFileNameArr[-1]} = $secretTextBase64;

    return;
}

sub _backupInstance{
    my ($self, $params) = @_;

    my $dir          = $params->{dir};
    my $templateName = $params->{templateName};

    my $instance = $self->{config}->{instance};
    $self->_createDir("backups\/$instance\/$dir");
    my $pathToYamlFile = "$self->{config}->{templates_yaml_dir}/$dir/$templateName".".yaml";
    my $templateData = LoadFile($pathToYamlFile);
    
    my $yamlText;
    if((defined $self->{advanceFeatures}) && 
       ($self->{advanceFeatures} =~ /removeClutter/) && 
       (defined $self->{removeClutterBackup})){
        print "$self->{cloudCommand} get $templateData->{kind} $templateData->{metadata}->{name} -o json\n";
        my $octJson = qx/$self->{cloudCommand} get $templateData->{kind} $templateData->{metadata}->{name} -o json/;
        my $octHash  = $self->{json}->utf8->decode($octJson); 
        my $subParams = {"octKind" => $templateData->{kind}, "octName" => $templateData->{metadata}->{name}};
        $octHash = $self->{removeClutterBackup}->($octHash, $subParams);
        my $yamlSaveObj = YAML::Safe->new->boolean("JSON::PP");
        $yamlText = $yamlSaveObj->Dump($octHash);
        $yamlText =~ s/---\n//;
    }else{
         print "$self->{cloudCommand} get $templateData->{kind} $templateData->{metadata}->{name} -o yaml\n";
         $yamlText = qx/$self->{cloudCommand} get $templateData->{kind} $templateData->{metadata}->{name} -o yaml/;
    }

    write_file("$self->{projectDir}backups\/$instance\/$dir/$templateName".".yaml", $yamlText);     
}

sub _callCloudCommand{
    my ($self, $params) = @_;
    
    my @funcName = split /::/, (caller(0))[3];
    my $dir          = $params->{dir};
    my $templateName = $params->{templateName};
    my $customParams = $params->{params}->{$funcName[-1]};

    return if (defined $self->{componentIsAllowed}) && 
              (not $self->{componentIsAllowed}->($templateName, $dir, $self->{config}->{cluster}, $self->{instance}));

    my $templateNameYaml = $templateName.".yaml";
    my $pathAndFile = $self->{config}->{templates_yaml_dir}."\/$dir\/$templateNameYaml";
    my $yamlData = LoadFile($pathAndFile);

    if(not defined $customParams->{dryRun}){
        my $writeCommand = $self->_getCloudWriteCommand();
        $self->_writeLog("$self->{cloudCommand} $writeCommand -f $pathAndFile\n");
        my $outputText = qx/$self->{cloudCommand} $writeCommand -f $pathAndFile 2>&1/;
        $self->_writeLog($outputText);
    }else{
        my $infoText = "$dir\/$templateNameYaml";
        my $text = qx/$self->{cloudCommand} apply --dry-run=server --validate=true -f $pathAndFile 2>&1/;
        my $isError = $? >> 8;
        if($isError){
            $text = $self->{ignoreManifestValidationErrors}->($text) if defined $self->{ignoreManifestValidationErrors};
            if($text ne ""){
                print "$infoText ERROR\n";
                print "============\n$text\n============\n";
            }else{
                # ignore this error
                print "$infoText OK\n";
            }
        }else{
            print "$infoText;OK\n";
        }
    }
    
    return;
}

sub _clearDir{
    my ($self, $dir) = @_;

    rmtree $dir;
    make_path $dir;
}

sub _confirmOperation{
    my ($self, $type, $instance, $cluster, $namespace) = @_;
 
    return if ($self->{omit} // '') =~ /confirm/;
    
    $self->_writeLog(qx/oc project/);
    
    my $components;
    if(($self->{omit} // '') =~ /init/ ){
        $components = $self->{config}->{standard_component_dirs};
    }else{
        $components = $self->{config}->{component_dirs};
    }
    $components = "all" if not defined $components;
    my $preposition = "for";
    $preposition = "from" if $type eq "Delete";
    my $componentsText = "\nCOMPONENT(S):      '$components' $preposition";
    
    my $confirmOperationText = ""; 
    if(defined $self->{specificYamlFile}){
        $confirmOperationText = "\nFILE NAME CONTAINS:'$self->{specificYamlFile}' in";
    } 
    
    if(defined $self->{resourceKinds}){
        $confirmOperationText .= "\nKIND(s):           '$self->{resourceKinds}' in";
    }
    
    my $continue = "";
    my $infoText = "\n$type $confirmOperationText $componentsText\nINSTANCE:          '$instance' in\nNAMESPACE:         '$namespace' in\nCLUSTER:           '$cluster'\n";
    $self->_writeLog($infoText);
    if(($self->{omit} // '') !~ /cloud/ && $self->{config}->{oct_config}->{project}->{prompt_write_operations}){
        $self->_writeLog("Press enter to continue or type: 'skip' and press enter to skip this operation.\n");
        $continue = <>;
    }
    
    return $continue !~ /skip/;
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

sub _createTemplatesTTDirHash{
    my ($self, $params) = @_;
    
    my $dir          = $params->{dir};
    my $templateName = $params->{templateName};

    # $self->{templatesTTHash}->{"40-api"}->{"40-build-config-api"} = "40-api/clusterIntern/40-build-config-api";
    # $self->{templatesTTHash}->{"40-api"}->{"45-build-config-api"} = "40-api/test/40-build-config-api";
    # $self->{templatesTTHash}->{"40-api"}->{"46-build-config-api"} = "40-api/clusterPublic/instance/prod/40-build-config-api"; 
    if(not -d "$self->{templatesTTDir}/$dir/$templateName"){
        $self->{templatesTTHash}->{$dir}->{$templateName} = "$dir/$templateName";
    }elsif($templateName eq $self->{config}->{cluster}){
        for my $dirFileName (File::Find::Rule
            ->file()
            ->name("*")
            ->maxdepth(1)
            ->in("$self->{templatesTTDir}/$dir/$self->{config}->{cluster}")){
            my @dirFileNameArr = split('/', $dirFileName);
            my $templName = substr($dirFileNameArr[-1], 0, -3);
            $self->{templatesTTHash}->{$dir}->{$templName} = "$dir/$self->{config}->{cluster}/$templName";
        }
        if(-d "$self->{templatesTTDir}/$dir/$self->{config}->{cluster}/instance/$self->{config}->{instance}"){
            for my $dirFileName (File::Find::Rule
                ->file()
                ->name("*")
                ->maxdepth(1)
                ->in("$self->{templatesTTDir}/$dir/$self->{config}->{cluster}/instance/$self->{config}->{instance}")){
                my @dirFileNameArr = split('/', $dirFileName);
                my $templName = substr($dirFileNameArr[-1], 0, -3);
                $self->{templatesTTHash}->{$dir}->{$templName} = 
                    "$dir/$self->{config}->{cluster}/instance/$self->{config}->{instance}/$templName";
            }
        }
    }elsif(($templateName eq "instance") && (-d "$self->{templatesTTDir}/$dir/instance/$self->{config}->{instance}")){
        for my $dirFileName (File::Find::Rule
            ->file()
            ->name("*")
            ->maxdepth(1)
            ->in("$self->{templatesTTDir}/$dir/instance/$self->{config}->{instance}")){
            my @dirFileNameArr = split('/', $dirFileName);
            my $templName = substr($dirFileNameArr[-1], 0, -3);
            $self->{templatesTTHash}->{$dir}->{$templName} = "$dir/instance/$self->{config}->{instance}/$templName";
        }
    }

    return;
}

sub _createDir{
    my ($self, $relativeDirPath) = @_;
    qx/mkdir $self->{projectDir}$relativeDirPath 2>&1/;
    return;
}

sub _deleteFromCloud{
    my ($self, $params) = @_;

    my $dir          = $params->{dir};
    my $templateName = $params->{templateName};

    my $data = LoadFile("$self->{config}->{templates_yaml_dir}/$dir/$templateName".".yaml");
    $self->_writeLog("$self->{cloudCommand} delete $data->{kind} $data->{metadata}->{name}\n");
    my $outputText = qx/$self->{cloudCommand} delete $data->{kind} $data->{metadata}->{name} 2>&1/;
    $self->_writeLog($outputText);
    
    return;
}

sub _deleteUndefinedResourcesInCloud{
    my ($self, $instance) = @_;
    
    # get $self->{templateManifests} for all instances in current cluster
    my $allClusterInstances;
    my $cluster = $self->{config}->{cluster};
    my $confingProject = $self->{config}->{oct_config}->{project};
    if(defined $confingProject->{git}                                              &&
       defined $confingProject->{git}->{revert_multiple_instances_in_same_project} &&
       defined $confingProject->{git}->{revert_multiple_instances_in_same_project}->{$cluster}
      ){
        $allClusterInstances = dclone($confingProject->{git}->{revert_multiple_instances_in_same_project}->{$cluster});
        # remove current instance, it is already processed
        @$allClusterInstances = grep { $_ ne $instance } @$allClusterInstances; 
        
        foreach my $cInstance (@$allClusterInstances){
            $self->{instance} = $cInstance;
            $self->{config} = $self->_getConfig();
            $self->_generateYaml();
        }    
        # bring back current instace to 'template_yaml'
        $self->{instance} = $instance;
        $self->{config} = $self->_getConfig();
        $self->_generateYaml();
    }
    
    my $resourceKinds = $self->{config}->{resource_kinds};
    my @resourceKindsArr = split(';', $resourceKinds);
    
    # get resources from Cloud
    my $cloudVsManifestDiff;
    foreach my $resourceKind (@resourceKindsArr){
        my $text = qx/$self->{cloudCommand} get $resourceKind/;
        my @textArr = split("\n", $text);
        shift @textArr;
        foreach my $textLine (@textArr){
            my ($resourceName) = split /\s+/, $textLine =~ s/^\s+//r; # remove also leading spaces
            $cloudVsManifestDiff->{$resourceKind}->{$resourceName} = 1;
        }
    }

    my @revertExemptionsArr = ();
    my $revertExemptions = $self->{config}->{oct_config}->{project}->{revert_exemptions};
    @revertExemptionsArr = split(';', $revertExemptions) if defined $revertExemptions;
    
    foreach my $resourceKind (keys %{$cloudVsManifestDiff}){
        foreach my $resourceName (keys %{$cloudVsManifestDiff->{$resourceKind}}){
            foreach my $revertExemption (@revertExemptionsArr){
                if($resourceName =~ /$revertExemption/){
                    # don't delete this resource, remove him from template manifests vs cloud resources difference hash
                    delete $cloudVsManifestDiff->{$resourceKind}->{$resourceName};
                }
            }
            if((defined $self->{templateManifests}) && $self->{templateManifests}->{$resourceKind}->{$resourceName}){
                delete $cloudVsManifestDiff->{$resourceKind}->{$resourceName};
            }
        }
    }

    my $cloudVsManifestDiffIsEmpty = 1;
    foreach my $resourceKind (keys %{$cloudVsManifestDiff}){
        foreach my $resourceName (keys %{$cloudVsManifestDiff->{$resourceKind}}){
            if((defined $cloudVsManifestDiff->{$resourceKind}) && $cloudVsManifestDiff->{$resourceKind}->{$resourceName}){
                $cloudVsManifestDiffIsEmpty = 0;
            }
        }
    }
    
    my $atLeastOneDeleted = 0;
    if(not $cloudVsManifestDiffIsEmpty){
        $self->_writeLog("\nThis resources are not defined in Manifests but they are found in Cloud:\n");
        foreach my $resourceKind (keys %{$cloudVsManifestDiff}){
            foreach my $resourceName (keys %{$cloudVsManifestDiff->{$resourceKind}}){
                $self->_writeLog(sprintf "Resource kind: %-25s Resource name: %s\n", $resourceKind, $resourceName);
            }
        }
        my $continue = "";
        if($self->{config}->{oct_config}->{project}->{prompt_write_operations}){
            $self->_writeLog("\nPress enter to delete them or type 'skip' and press enter to keep them:\n");
            $continue = <>;
        }
        if($continue !~ /skip/){
            foreach my $resourceKind (keys %{$cloudVsManifestDiff}){
                foreach my $resourceName (keys %{$cloudVsManifestDiff->{$resourceKind}}){
                    if((defined $cloudVsManifestDiff->{$resourceKind}) && $cloudVsManifestDiff->{$resourceKind}->{$resourceName}){
                        $atLeastOneDeleted = 1;
                        $self->_writeLog("$self->{cloudCommand} delete $resourceKind $resourceName\n");
                        my $outputText = qx/$self->{cloudCommand} delete $resourceKind $resourceName 2>&1/;
                        $self->_writeLog($outputText);
                    }
                }
            }
        }
    }

    return $atLeastOneDeleted;
}

sub _encodeJsonHashToBase64{
    my ($self, $jsonHash) = @_;

    if(ref $jsonHash eq 'HASH'){
        $_ = $self->_encodeJsonHashToBase64($_) for values %$jsonHash;
    }
    elsif(ref $jsonHash eq 'ARRAY'){
        $_ = $self->_encodeJsonHashToBase64($_) for @$jsonHash;
    }
    elsif(defined $jsonHash){
        return encode_base64($jsonHash, "");
    }

    return $jsonHash;
}

sub _generateYaml{
    my ($self) = @_;

    $self->_writeLog("Instance is missing.\n") and return if not defined $self->{instance};

    if(
        ($self->{omit} // '') =~ /init/ || 
        (
          $self->{config}->{oct_config}->{project}->{omit_init} &&
          ($self->{advanceFeatures} // '') !~ /useInit/
        )
      ){
        $self->_removeInitFromComponentDirs();
    }
    $self->_loopDir($self->{config}->{templates_tt_dir}, "*", "_createTemplatesTTDirHash");
    $self->_clearDir($self->{config}->{templates_yaml_dir});
    $self->_writeYamlFiles();
    
    return;
}

sub _getComponentConfigNodes{
    my ($self, $config) = @_;
    
    my @componentConfigNodes;
    my $componentConfigNodesString;
    if((defined $config->{oct_config}) && (defined $config->{oct_config}->{instance_specific_data})){
        foreach my $componentConfigNode (keys %{$config->{oct_config}->{instance_specific_data}}){
            push @componentConfigNodes, $componentConfigNode;
        }
    }

    return \@componentConfigNodes;
}

sub _getComponentsFromTemplatesTTDir{
    my ($self) = @_;

    my $components = "";
    foreach my $dirPath (sort {
                # sort numerically
                my ($an) = basename($a) =~ /^(\d+)/;
                my ($bn) = basename($b) =~ /^(\d+)/;
                ($an // 0) <=> ($bn // 0) || basename($a) cmp basename($b);
            } glob "$self->{templatesTTDir}/*"){
        next if not -d $dirPath;
        my @dirPathArr = split('/', $dirPath);
        my $componentDir = $dirPathArr[-1];
        $componentDir  =~ s/^\d+-//;
        $components .= $componentDir.";";
    }
    chop($components) if $components ne "";

    return $components;
}

sub _getConfig{
    my ($self) = @_;

    my $octConfigJson = read_file($self->{octConfigFile});
    my $config->{oct_config} = $self->{json}->utf8->decode($octConfigJson);

    $self->{config}->{oct_config}->{project}->{git} = {} if not defined $self->{config}->{oct_config}->{project}->{git};
    
    $config = $self->{addFlagValuesToConfig}->($config) if defined $self->{addFlagValuesToConfig};

    # set/generate instance specific names
    foreach my $entry (keys %{$config->{oct_config}->{instance_specific_name}}){
        $config->{oct_config}->{instance_specific_name}->{$entry} .= "-$self->{instance}";
    }

    $config->{allowed_clusters}  = $config->{oct_config}->{project}->{allowed_clusters};
    if(not defined $config->{allowed_clusters}){
        print "INFO: oct_config->project->allowed_clusters json node is empty. Marking 'allowed_clusters' as '$self->{cluster}'\n";
        $config->{allowed_clusters} = $self->{cluster};
    }else{
        print "Warning: Unknown cluster $self->{cluster}\n" if $config->{allowed_clusters} !~ /$self->{cluster}/;
    }

    $config->{cluster_ip_range} = $config->{oct_config}->{project}->{cluster_ip_range};
    $config->{cluster_ip_range} = $self->{clusterIpRange}       if defined $self->{clusterIpRange};
    $config->{project_name}     = $config->{oct_config}->{project}->{name};
    $config->{project_name}     = $self->{projectName}          if defined $self->{projectName};
    $config->{host}             = $config->{oct_config}->{project}->{host};
    $config->{host}             = $self->{host}                 if defined $self->{host};
    $config->{namespace}        = $config->{oct_config}->{project}->{namespace};
    $config->{namespace}        = $self->{namespace}            if defined $self->{namespace};# from -n flag
    $config->{namespace}        = $self->_getCurrentProject()   if not defined $config->{namespace};
    # default component dirs are set here, dirs in 'templates_tt' not set as default will be omitted
    $config->{component_dirs}   = $config->{oct_config}->{project}->{component_dirs};
    $config->{component_dirs}   = $self->{components}           if defined $self->{components};
    $config->{component_dirs}   = $self->_getComponentsFromTemplatesTTDir() if not defined $config->{component_dirs}; 
    # component dirs can contains numbers e.g.: '50-solr' so regexp match is used => 
    # separate 'init' components in order to avoid false matches (e.g.: 20-init-api vs 50-api when 'api' searched)
    my @components                  = split(';', $config->{component_dirs});
    my $standardComponentDirs = "";
    my $initComponentDirs = "";
    foreach my $componentDir (@components){
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
    $config->{resource_kinds_backup}      = $config->{oct_config}->{project}->{resource_kinds_backup};
    $config->{resource_kinds_backup}      = $self->_getDefaultKindsBackup() if not defined $config->{resource_kinds_backup};
    $config->{resource_kinds}             = $config->{oct_config}->{project}->{resource_kinds};
    $config->{resource_kinds}             = $self->{resourceKinds}    if defined $self->{resourceKinds};
    $config->{resource_kinds}             = $self->_getDefaultKinds() if not defined $config->{resource_kinds};
    $config->{templates_yaml_dir}         = $self->{templatesYamlDir};
    $config->{templates_tt_dir}           = $self->{templatesTTDir};
    $config->{cluster}                    = $self->{cluster};
    $config->{instance}                   = $self->{instance};
    $config->{instance_capitalized_first} = ucfirst $config->{instance};
    $config->{url_prefix}                 = $config->{oct_config}->{project}->{url_prefix} if defined $config->{oct_config}->{project}->{url_prefix};
    $config->{url_prefix}                 = $self->{urlPrefix} if defined $self->{urlPrefix};
    $config->{cluster_base_address}       = $self->{clusterBaseAddress} if defined $self->{clusterBaseAddress}; 
    $config->{cluster_base_address}       = $config->{oct_config}->{project}->{cluster_base_address} if not defined $config->{cluster_base_address};
    
    my $componentConfigNodes  = $self->_getComponentConfigNodes($config);
    foreach my $componentConfNode (@$componentConfigNodes){
        # set/generate default urls
        if((defined $config->{oct_config}->{instance_specific_data}->{$componentConfNode}) && 
           (ref($config->{oct_config}->{instance_specific_data}->{$componentConfNode}) eq 'HASH')){
            foreach my $instanceKey (keys %{$config->{oct_config}->{instance_specific_data}->{$componentConfNode}}){
                if(not defined $config->{oct_config}->{instance_specific_data}->{$componentConfNode}->{$instanceKey}->{url}){                    
                    my $componentNameKebab = $componentConfNode;
                    $componentNameKebab    =~ s/_/\-/g;
                    my $lcInstanceKey   = lc $instanceKey;
                    $lcInstanceKey = undef if $componentConfNode =~ /init_/; # don't add instance name to url if in 'init_' component
                    my $url = "";
                    if(defined $self->{generateUrl}){
                        $url = $self->{generateUrl}->($config->{url_prefix}, 
                                                      $config->{project_name},
                                                      $componentNameKebab,
                                                      $lcInstanceKey,
                                                      $config->{cluster_base_address},
                                                      $config->{host});
                    }
                    $config->{oct_config}->{instance_specific_data}->{$componentConfNode}->{$instanceKey}->{url} = $url;  
                }
            }
        }
        # select instance specific data
        if(defined $config->{oct_config}->{instance_specific_data}->{$componentConfNode}->{$self->{instance}}){
            $config->{oct_config}->{instance_specific_data}->{$componentConfNode} = 
                $config->{oct_config}->{instance_specific_data}->{$componentConfNode}->{$self->{instance}};
        }
    }
    # in worse case 36 available IP addresses(see _writeYamlFile), make number smaller if more needed(max is 256)
    $config->{ip_last_number} = int(rand(220));
    
    print "'Info: component_dirs' parameter is missing\n"   if not defined $config->{component_dirs};
    print "'Info: cluster_ip_range' parameter is missing\n" if not defined $config->{cluster_ip_range};
    print "'Info: host' parameter is missing\n"             if not defined $config->{host};

    return $config;
}

sub _getCurrentProject{
    my ($self) = @_; 

    my $projectCmdLine    = qx/$self->{cloudCommand} config current-context/;
    my @projectCmdLineArr = split('/', $projectCmdLine);
    my $project = $projectCmdLineArr[0];
    $project = "unknown" if not defined $project;

    return $project;
}

sub _getDefaultKinds{
    return "PersistentVolumeClaim;ImageStream;BuildConfig;Deployment;DeploymentConfig;Secret;ConfigMap;CronJob;Job;Service;Route";
}

sub _getDefaultKindsBackup{
    return "PersistentVolumeClaim;StorageClass;VolumeSnapshot;ImageStream;BuildConfig;Deployment;DeploymentConfig;StatefulSet;Secret;ConfigMap;CronJob;Job;DaemonSet;ReplicaSet;ReplicationController;HorizontalPodAutoscaler;PodDisruptionBudget;Service;Route;Ingress;NetworkPolicy;ServiceAccount;ClusterRole;RoleBinding;ResourceQuota;LimitRange";
}

sub _getSecrets{
    my ($self, $config) = @_;

    my $secretJsonFileName = $self->{secretsJson};
    # secrets files for all instances and all clusters e.g.: secrets/my-secret.txt
    for my $dirFileName (File::Find::Rule->file()->name("*")->maxdepth(1)->in($self->{secretsDir})) {
        my @dirFileNameArr = split('/', $dirFileName);
        next if $dirFileNameArr[-1] eq $secretJsonFileName;
        $self->_addSecretsToConfigHash($config, $dirFileName);
    }

    # instance specific secrets files and for all clusters e.g.: secrets/instance/test/my-secret.txt
    for my $dirFileName (File::Find::Rule->file()->name("*")->maxdepth(1)->in("$self->{secretsDir}/instance/$self->{instance}")) {
        my @dirFileNameArr = split('/', $dirFileName);
        next if $dirFileNameArr[-1] eq $secretJsonFileName;
        $self->_addSecretsToConfigHash($config, $dirFileName);
    }
    
    my $clusterSpecificSecretsDirExist = 0;
    foreach my $dirPath (glob "$self->{secretsDir}/*"){
        next if not -d $dirPath;
        my @dirPathArr = split('/', $dirPath);
        my $dirName = $dirPathArr[-1];
        next if $dirName eq "instance";
        $clusterSpecificSecretsDirExist = 1 if $dirName eq $self->{config}->{cluster};
    }
    
    # secrets files for all instances and for specific cluster e.g.: secrets/clusterIntern/my_secret.txt
    if($clusterSpecificSecretsDirExist){
        for my $dirFileName (File::Find::Rule->file()->name("*")->maxdepth(1)->in("$self->{secretsDir}/$self->{config}->{cluster}")) {
            my @dirFileNameArr = split('/', $dirFileName);
            next if $dirFileNameArr[-1] eq $secretJsonFileName;
            $self->_addSecretsToConfigHash($config, $dirFileName);
        }
        # secret files for specific instance and specific cluster e.g.: secrets/clusterIntern/instance/prod/my_secret.txt
        for my $dirFileName (File::Find::Rule->file()->name("*")->maxdepth(1)->in("$self->{secretsDir}/$self->{config}->{cluster}/instance/$self->{instance}")) {
            my @dirFileNameArr = split('/', $dirFileName);
            next if $dirFileNameArr[-1] eq $secretJsonFileName;
            $self->_addSecretsToConfigHash($config, $dirFileName);
        }
    }
    # secrets json for all instances and all clusters
    $config->{secrets_json} = {};
    eval {
        my $secretJson = read_file("$self->{secretsDir}/$secretJsonFileName");
        my $secretJsonAllInstancesAllClustersHash = $self->{json}->utf8->decode($secretJson);
        $self->_mergeSecretsJson($config->{secrets_json}, $secretJsonAllInstancesAllClustersHash);
    };
    if($clusterSpecificSecretsDirExist){
        # secrets json for all instances and specific cluster
        my $path = "$self->{secretsDir}/$self->{config}->{cluster}/$secretJsonFileName";
        eval {
            my $secretJsonClusterSpecific = read_file($path);
            my $secretJsonClusterSpecificHash = $self->{json}->utf8->decode($secretJsonClusterSpecific);
            $self->_mergeSecretsJson($config->{secrets_json}, $secretJsonClusterSpecificHash);
        };
        # secrets json for specific instance and specific cluster
        $path = "$self->{secretsDir}/$self->{config}->{cluster}/instance/$self->{instance}/$secretJsonFileName"; 
        eval {
            my $secretJsonClusterSpecificInstanceSpecific = read_file($path);
            my $secretJsonClusterSpecificInstanceSpecificHash = $self->{json}->utf8->decode($secretJsonClusterSpecificInstanceSpecific);
            $self->_mergeSecretsJson($config->{secrets_json}, $secretJsonClusterSpecificInstanceSpecificHash);
        };
    }else{        
        # secrets json for specific instance and all clusters
        my $path = "$self->{secretsDir}/instance/$self->{instance}/$secretJsonFileName"; 
        eval {
            my $secretJsonInstanceSpecific = read_file($path);
            my $secretJsonInstanceSpecificHash = $self->{json}->utf8->decode($secretJsonInstanceSpecific);
            $self->_mergeSecretsJson($config->{secrets_json}, $secretJsonInstanceSpecificHash);
        };
    }

    return;
}

sub _getCloudWriteCommand{
    my ($self) = @_;

    my $writeCommand = "create";
    if(defined $self->{config}->{oct_config}->{project}->{default_cloud_write_command}){
        $writeCommand = $self->{config}->{oct_config}->{project}->{default_cloud_write_command};
    }
    $writeCommand = "create" if defined $self->{advanceFeatures} && $self->{advanceFeatures} =~ /create/;
    $writeCommand = "apply"  if defined $self->{advanceFeatures} && $self->{advanceFeatures} =~ /apply/;
        
    return $writeCommand;
}

sub _gitCommitAndPush{
    my ($self, $instance) = @_;

    if(not $self->{config}->{oct_config}->{project}->{git}->{auto_commit}){
        if($self->{config}->{oct_config}->{project}->{git}->{auto_commit_prompt}){
            $self->_writeLog("\nPress enter to commit(and push if enabled) to Git or type 'skip' and press enter to skip this operation(s).\n");
            my $continue = <>;
            return if $continue =~ /skip/;
        }
        $self->_writeLog("commiting to git...\n");
        my $commitText = "committed on: " . localtime;
        if($self->{config}->{oct_config}->{project}->{git}->{auto_commit_prompt}){
            $self->_writeLog("Write your git commit message or press Enter to use default:\n($commitText)\n");
            my $customMsg = <>;
            $commitText = $customMsg if $customMsg ne "\n";
            $commitText =~ s/\n//g;
        }
        $self->_writeLog("git commit -am \"$commitText\"\n");
        `git commit -am "$commitText"`;
        if($self->{config}->{oct_config}->{project}->{git}->{auto_push}){
            my $branch = $self->{config}->{oct_config}->{project}->{git}->{auto_push_branch} // "master";
            $self->_writeLog("git push origin $branch\n");
            `git push origin $branch`;
        }
    }

    return;
}

sub _initConfSecretsAndYaml{
    my ($self, $instance) = @_;
    
    $self->{instance} = $instance;
    $self->{config} = $self->_getConfig();
    $self->_runPreHook();
    
    my $outputLogFile = "output.log";
    if(defined $self->{config}->{oct_config}->{project}->{output_log_file}){
        $outputLogFile = $self->{config}->{oct_config}->{project}->{output_log_file};
     }
    `touch $outputLogFile`;
    `>$outputLogFile`; # clear file content

    $self->_getSecrets($self->{config});
    $self->_generateYaml();
        
    return;
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
    @dirArray = reverse @dirArray if $injectedSubName eq "_deleteFromCloud";

    foreach my $dir (@dirArray){
        $self->_writeLog("\nComponent: $dir:\n") if $injectedSubName eq "_callCloudCommand";
        
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
        @fileArray = reverse @fileArray if $injectedSubName eq "_deleteFromCloud";
        foreach my $file (@fileArray){
            next if $file eq "dirNumber" || $self->_skipComponent($dir);
            my @fileArr = split('\.', $file);            
            if((not defined $fileArr[1]) && ($self->{config}->{allowed_clusters} !~ /$file/)){
                $self->_writeLog("Warning : Unknown cluster: $file\n") if $file ne "instance";
            }
            my $injectedSub = \&$injectedSubName;
            $injectedSub->($self, {dir => $dir, templateName => $fileArr[0], params => $params});
        }
    }
}

sub _mergeSecretsJson{
    my ($self, $jsonHashOriginal, $jsonHashAddition) = @_;
    
    if(ref($jsonHashAddition) eq 'HASH'){
        foreach my $key (keys %{$jsonHashAddition}){
            $jsonHashOriginal->{$key} = $jsonHashAddition->{$key};
            $jsonHashOriginal->{base64}->{$key} = $self->_encodeJsonHashToBase64(dclone($jsonHashAddition->{$key}));
        }
    }
    
    return;
}

sub _removeInitFromComponentDirs{
    my ($self) = @_;
    
    my @componentsYamlDirArray       = split(';', $self->{config}->{component_dirs});
    @componentsYamlDirArray          = (grep {$_ !~ /init/} @componentsYamlDirArray);
    $self->{config}->{component_dirs} = join( ';', @componentsYamlDirArray);
}

sub _runPreHook{
    my ($self) = @_;
    
    if((($self->{omit} // '') !~ /preHook/) && (defined $self->{preHook})){
        $self->{preHook}->($self->{config});
    }

    return;
}

sub _runPostHook{
    my ($self) = @_;

    if((($self->{omit} // '') !~ /postHook/) && (defined $self->{postHook})){
        $self->{postHook}->($self->{config});
    }

    return;
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

sub _validateAgainstCloud{
    my ($self, $params) = @_;
    
    my @funcName = split /::/, (caller(0))[3];
    my $dir          = $params->{dir};
    my $templateName = $params->{templateName};

    my $templateNameYaml = $templateName.".yaml";
    my $yamlData         = LoadFile("$self->{config}->{templates_yaml_dir}/$dir/$templateNameYaml");
    my $octName          = $yamlData->{metadata}->{name};
    my $octKind          = $yamlData->{kind};
    my $octJson          = qx/$self->{cloudCommand} get $octKind $octName -o json/;
    my $octHash = {};
    eval { 
        $octHash  = $self->{json}->utf8->decode($octJson); 
        if(($octKind eq "Secret") && (ref($octHash->{data}) eq 'HASH')){
            foreach my $key (keys %{$octHash->{data}}){
                my $secret = decode_base64($octHash->{data}->{$key});
                $secret =~ s/\n//g;
                $secret =~ s/\r//g;
                $octHash->{data}->{$key} = $secret;
            }
        }
    };
    $self->_writeLog(Dumper($@)) if $@;
    
    my $templateYamlText = read_file("$self->{config}->{templates_yaml_dir}/$dir/$templateNameYaml");
    my $yamlObj = YAML::Safe->new->boolean("JSON::PP");
    my $templateHash = $yamlObj->Load($templateYamlText);
    my $subParams = {"dir" => $dir, "templateName" => $templateName, "octKind" => $octKind, "octName" => $octName};
    $octHash       = $self->{removeClutter}->($octHash, $subParams)       if defined $self->{removeClutter};
    $templateHash = $self->{removeClutter}->($templateHash, $subParams) if defined $self->{removeClutter};
    
    if($octKind eq "Secret"){
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
    
    $octJson         =  $self->{json}->utf8->pretty->canonical->encode($octHash);
    my $templateJson =  $self->{json}->utf8->pretty->canonical->encode($templateHash);
    my @octJsonArr       = split /\n/, $octJson;
    my @templateJsonArr = split /\n/, $templateJson;
    my $diff = diff \@octJsonArr, \@templateJsonArr, { STYLE => "Table", CONTEXT => 0 };
    if(($octKind eq "Secret") && ($diff ne "")){
        $diff = "+---+-----------------------------------------------------+---+---------------------------------+
*   |           different secret, not displayed           *   | different secret, not displayed |
+---+-----------------------------------------------------+---+---------------------------------+
";
    }
    $diff =~ s/\\ No newline at end of file\s//g;
   
    my $diffStatus;
    if((defined $diff) && ($diff ne "")){
        $diffStatus = "MODIFIED";
        $self->{"atLeastOneModified"} = 1;
    }else{
         $diffStatus = "OK";
    }
    my $line = "$dir/$templateNameYaml;$octKind;$octName;$diffStatus\n";
    $self->_writeLog($line);
    $self->_writeLog($diff) if $diff ne "";
    write_file($self->{validationReportFile}, {append => 1}, $line);
}

# used only during cloud write operations(install/update/delete)
sub _writeLog{
     my ($self, $text) = @_;

     print $text;
     
     my $file = "output.log";
     if(defined $self->{config}->{oct_config}->{project}->{output_log_file}){
        $file = $self->{config}->{oct_config}->{project}->{output_log_file};
     }
     write_file($file, {append => 1}, $text);
     
     return;
}

sub _writeYamlFile{
    my ($self, $params) = @_;

    my $dir          = $params->{dir};
    my $templateName = $params->{templateName};

    # return if $dir =~ /init/ && (($self->{omit} // '') =~ /init/  || $self->{config}->{oct_config}->{project}->{omit_init});
    
    if($dir =~ /init/ && 
       (
         ($self->{omit} // '') =~ /init/  || 
         ($self->{config}->{oct_config}->{project}->{omit_init} && ($self->{advanceFeatures} // '') !~ /useInit/)
       )
      ){
        return;
    }
    
    return if (defined $self->{specificYamlFile}) && ($templateName !~ /$self->{specificYamlFile}/);
    return if (defined $self->{componentIsAllowed}) && 
              (not $self->{componentIsAllowed}->($templateName, $dir, $self->{config}->{cluster}, $self->{instance}));
    
    my $yamlText;
    my $templatesYamlFilePath = "$self->{config}->{templates_yaml_dir}/$dir";
    make_path $templatesYamlFilePath or die("Failed to create path: $templatesYamlFilePath") if !-d $templatesYamlFilePath;

    # $self->{templatesTTHash}->{"40-api"}->{"40-build-config-api"} = "40-api/clusterPublic/40-build-config-api";
    my $templateTTFilePath = "$self->{templatesTTDir}/$self->{templatesTTHash}->{$dir}->{$templateName}";
    $templateTTFilePath = $templateTTFilePath.".tt";

    eval { $self->{tt}->process($templateTTFilePath, $self->{config}, \$yamlText); };
    if($@){
        $self->_writeLog("Error occurred during generating yaml in: $dir  $templateName\n".Dumper($@)."\n");
        return;
    }

    my $yamlHash;
    eval { $yamlHash = Load($yamlText);};
    if($@){
        $self->_writeLog("Error occurred during conversion to yaml in: $dir  $templateName\n".Dumper($@)."\n");
        return;
    }

    $self->{templateManifests}->{$yamlHash->{kind}}->{$yamlHash->{metadata}->{name}} = 1;
  
    my $allowedResourceKinds = $self->{config}->{resource_kinds};
    return if (defined $allowedResourceKinds) && ($allowedResourceKinds !~ /$yamlHash->{kind}/);

    write_file("$templatesYamlFilePath/$templateName\.yaml", $yamlText);
    $self->{config}->{ip_last_number}++ if $yamlHash->{kind} eq "Service";
}

sub _writeYamlFiles{
    my ($self) = @_;

    # $self->{templatesTTHash}->{"40-api"}->{"40-build-config-api"} = "40-api/clusterPublic/40-build-config-api.tt";
    my $dirs = $self->{templatesTTHash};
    if((defined $self->{sortType}) && ($self->{sortType}) eq "alphabetic"){
        # alphabetic
        foreach my $dir (sort {lc($a) cmp lc($b)} keys %{$dirs}){
            my $files = $dirs->{$dir};
            foreach my $templateName (sort {lc($a) cmp lc($b)} keys %{$files}){
                $self->_writeYamlFile({dir => $dir, templateName => $templateName});
            }
        }
    }else{
        # numeric
        no warnings 'numeric';
        foreach my $dir (sort {lc($a) <=> lc($b)} keys %{$dirs}){
            my $files = $dirs->{$dir};
            foreach my $templateName (sort {lc($a) <=> lc($b)} keys %{$files}){
                $self->_writeYamlFile({dir => $dir, templateName => $templateName});
            }
        }
    }

    return;
}

1;

__END__

=encoding utf-8

=head1 NAME

OcToolkit - Open Cloud Toolkit -  Module for managing Openshift and Kubernetes projects

=head1 SYNOPSIS

    use OcToolkit;
    
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
                            addFlagValuesToConfig => \&addFlagValuesToConfig,
                            componentIsAllowed    => \&componentIsAllowed,
                            generateUrl           => \&generateUrl,
                            removeClutter         => \&removeClutter,
                            removeClutterBackup   => \&removeClutterBackup);

=head1 DESCRIPTION

Library for Openshift and Kubernetes with multi cluster support. Wrapper for 'oc/kubectl' command line tool powered by 'Template Toolkit' templating engine.
See https://gitlab.com/code7143615/octoolkit/-/blob/master/README.md for 'ocToolkit' command line tool.
Feedback Page: https://gitlab.com/code7143615/octoolkit/-/issues/1

=head1 LICENSE

Copyright (C) John Summers.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 OVERVIEW

OcToolkit (short for Open Cloud Toolkit) is a Perl module designed for managing Openshift (and Kubernetes) projects, with added support for multi-cluster workflows. It includes Buids/BuildConfigs so you can use one tool for uploading your whole project to the Cloud. 

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

=item * B<update(instance)>

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
    $ocObj->update('testInstance');
    $ocObj->backup('production');
    $ocObj->delete('devInstance');

=head1 SUMMARY

=over 4

=item * B<Template-driven management>

Converts templates into YAML and applies them via C<oc> commands.

=item * B<Full lifecycle support>

Can install, validate, update, backup, and delete Openshift/Kubernetes resources.

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

This library powers 'ocToolkit' command line tool(see description). 
'ocToolkit' aims to simplify CI/CD and reduce related overhead. Could be usefull for small teams and start-ups.
Edit this library if you like to extend 'ocToolkit' features or use it for your own Perl based CI/CD pipeline. 

=cut

=head1 AUTHOR(S)

Open Cloud Toolkit(ocToolkit) team E<lt>devp2000a@gmail.comE<gt>

=cut
