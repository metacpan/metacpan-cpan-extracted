
# NAME

OcToolkit - Open Cloud Toolkit -  A Helm-like Perl module for managing Openshift and Kubernetes projects

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

Helm-like tool for Openshift and Kubernetes with multi cluster support.
See https://gitlab.com/code7143615/octoolkit/-/blob/master/README.md how to use this library in ocToolkit.pl script
and use it as 'Helm-like' command line tool.
Feedback Page: https://gitlab.com/code7143615/octoolkit/-/issues/1

# LICENSE

Copyright (C) John Summers.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# OVERVIEW

OcToolkit (short for Open Cloud Toolkit) is a Perl module designed as a Helm-like toolkit for managing Openshift (and Kubernetes) projects, with added support for multi-cluster workflows.

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

OcToolkit is a robust and flexible Perl-based alternative to Helm, offering templated deployment workflows with validation, backups, and multi-cluster capabilities.

If you're familiar with Helm but prefer a Perl-centric, highly customizable tool, this could be a great fit.

# AUTHOR

John Summers <devp2000a@gmail.com>
