
# NAME

OcToolkit - Open Cloud Toolkit

# SYNOPSIS

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

# DESCRIPTION

Helm like tool for Openshift and Kubernetes with multi cluster support.
See https://gitlab.com/code7143615/octoolkit/-/blob/master/README.md how to use this library in ocToolkit.pl script
and use it as 'Helm-like' command line tool
Feedback Page: https://gitlab.com/code7143615/octoolkit/-/issues/1

# LICENSE

Copyright (C) John Summers.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

John Summers <devp2000a@gmail.com>
