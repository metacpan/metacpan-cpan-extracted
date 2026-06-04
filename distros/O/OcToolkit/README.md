
# NAME

OcToolkit - Open Cloud Toolkit -  Module for managing Openshift and Kubernetes projects

# SYNOPSIS

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

# DESCRIPTION

Library for Openshift and Kubernetes with multi cluster support. Wrapper for 'oc/kubectl' command line tool powered by 'Template Toolkit' templating engine.
See https://gitlab.com/code7143615/octoolkit/-/blob/master/README.md for 'ocToolkit' command line tool.
Feedback Page: https://gitlab.com/code7143615/octoolkit/-/issues/1

# LICENSE

Copyright (C) John Summers.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# OVERVIEW

OcToolkit (short for Open Cloud Toolkit) is a Perl module designed for managing Openshift (and Kubernetes) projects, with added support for multi-cluster workflows. It incudes Buids/BuildConfigs so you can use one tool for uploading your project to the Cloud.  

# KEY FEATURES AND FUNCTIONALITY

## Initialization

Creates a Perl object that wraps tools needed for templating (Template), JSON processing (JSON::PP), file handling, YAML parsing, and more.

Default values for directories and commands (e.g., `oc` or, in advanced mode, `kubectl`) are configured in the constructor.

## Core Operations

- **install(instance)**

    Generates YAML manifests from templates and applies them via `oc create` or `oc apply` commands.

- **validate(instance)**

    Compares live cluster resources to offline templates using `oc get`, computes diffs, and logs the status `OK` or `MODIFIED`.

- **upgrade(instance)**

    Deletes and recreates modified resources, handling some types like PersistentVolumeClaims cautiously.

- **backup(instance)** / **backupWholeOCProject()**

    Backs up live cluster resources into YAML files, with optional clutter removal filters.

- **delete(instance)**

    Deletes resources based on generated YAML templates using `oc delete`.

## Templating Engine

Accepts Template Toolkit files (`.tt`) and data configuration to generate deployment and other YAMLs.

Organizes templates by directory (often prefixed numerically for order) and processes directories in sequence.

## Configurable Parameters & Extensibility

Accepts a wide range of options such as:

- `namespace`
- `cluster`
- `componentDirs`
- `secretsDir`
- `urlPrefix`
- ... and others.

Supports custom callback functions for:

- **removeClutter** / **removeClutterBackup** - clean up resource output before diffing/backups
- **generateUrl** - dynamically generate service URLs
- **componentIsAllowed** - include/exclude components conditionally
- **addFlagValuesToConfig** - augment configuration data during processing

## Secrets Management

Reads secrets from a `secretsDir`, encodes them in base64, and embeds them into resource configurations.

# USAGE EXAMPLE

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

# SUMMARY

- **Template-driven management**

    Converts templates into YAML and applies them via `oc` commands.

- **Full lifecycle support**

    Can install, validate, upgrade, backup, and delete Openshift/Kubernetes resources.

- **Multi-cluster aware**

    Customizable per cluster and instance, with filtering support.

- **Extensible hooks and customization**

    Allows user-supplied callbacks for secret handling, URL generation, cleanup, and more.

- **Secret handling built in**

    Encodes and injects secrets at runtime securely.

# NOTE

If you are intrested in 'ocToolkit' command line tool only as an end user, see link to Gitlab in Description

# CONCLUSION

This library powers 'ocToolkit' command line tool(see description). 
'ocToolkit' aims to simplify CI/CD and reduce related overhead. Could be usefull for small teams and start-ups.
Edit this library if you like to extend 'ocToolkit' features or use it for your own Perl based CI/CD pipeline. 

# AUTHOR(S)

Open Cloud Toolkit(ocToolkit) team <devp2000a@gmail.com>
