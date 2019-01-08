# ABSTRACT: Zanata (http://zanata.org/) synchronization plugin for Serge

package Serge::Sync::Plugin::TranslationService::zanata;

use parent Serge::Sync::Plugin::Base::TranslationService, Serge::Interface::SysCmdRunner;

use strict;

use Serge::Util qw(subst_macros);
use version;

our $VERSION = qv('0.905.7');

sub name {
    return 'Zanata translation server (http://zanata.org/) synchronization plugin';
}

sub init {
    my $self = shift;

    $self->SUPER::init(@_);

    $self->{optimizations} = 1;

    $self->merge_schema({
        # Project configuration file, eg zanata.xml
        project_config   => 'STRING',
        # User configuration, eg /home/user/.config/zanata.ini
        user_config      => 'STRING',
        # Type of push to perform on the server:
        #   'source' pushes source documents only
        #   'both' (default) pushes both source and translation documents
        push_type        => 'STRING',
        # The base directory for storing zanata cache files. Default is current directory.
        cache_dir        => 'STRING',
        # Whether to use an Entity cache when fetching documents.
        use_cache        => 'BOOLEAN',
        # Whether to purge the cache before performing the pull operation
        purge_cache      => 'BOOLEAN',
        # File types to locate and transmit to the server when using project type 'file'
        file_types       => 'ARRAY',
        # Whether to enable debug logging. Default is false.
        debug            => 'BOOLEAN',
        # Whether to output full execution error messages (stacktraces). Default is false.
        errors           => 'BOOLEAN',
        # Whether verification of SSL certificates should be disabled. Default is false.
        disable_ssl_cert => 'BOOLEAN',
        #  Dry run: don't change any data, on the server or on the filesystem. Default is false.
        dry_run          => 'BOOLEAN'
    });
}

sub validate_data {
    my ($self) = @_;

    $self->SUPER::validate_data;

    $self->{data}->{project_config} = subst_macros($self->{data}->{project_config});
    $self->{data}->{user_config} = subst_macros($self->{data}->{user_config});
    $self->{data}->{push_type} = subst_macros($self->{data}->{push_type});
    $self->{data}->{cache_dir} = subst_macros($self->{data}->{cache_dir});
    $self->{data}->{use_cache} = subst_macros($self->{data}->{use_cache});
    $self->{data}->{purge_cache} = subst_macros($self->{data}->{purge_cache});
    $self->{data}->{file_types} = subst_macros($self->{data}->{file_types});
    $self->{data}->{debug} = subst_macros($self->{data}->{debug});
    $self->{data}->{errors} = subst_macros($self->{data}->{errors});
    $self->{data}->{disable_ssl_cert} = subst_macros($self->{data}->{disable_ssl_cert});
    $self->{data}->{dry_run} = subst_macros($self->{data}->{dry_run});

    die "'project_config' not defined" unless defined $self->{data}->{project_config};
    die "'project_config', which is set to '$self->{data}->{project_config}', does not point to a valid file.\n" unless -f $self->{data}->{project_config};

    if (defined $self->{data}->{cache_dir}) {
        die "'cache_dir', which is set to '$self->{data}->{cache_dir}', does not point to a valid dir.\n" unless -d $self->{data}->{cache_dir};
    }

    if (defined $self->{data}->{user_config}) {
        die "'user_config', which is set to '$self->{data}->{user_config}', does not point to a valid file.\n" unless -f $self->{data}->{user_config};
    }

    if (!(defined $self->{data}->{push_type})) {
        $self->{data}->{push_type} = 'both';
    }

    if (($self->{data}->{push_type} ne 'both') and ($self->{data}->{push_type} ne 'source')) {
        die "'push_type', which is set to $self->{data}->{push_type}, is not one of the valid options: 'source' or 'both'";
    }
}

sub run_zanata_cli {
    my ($self, $action, $langs, $capture) = @_;

    my $command = '--batch-mode '.$action;

    $command .= ' --project-config '.$self->{data}->{project_config};

    if (defined $self->{data}->{user_config}) {
        $command .= ' --user-config '.$self->{data}->{user_config};
    }

    if ($langs) {
        my @locales = map {$self->get_zanata_locale($_)} @$langs;

        my $locales_as_string = join(',', @locales);

        $command .= ' --locales '.$locales_as_string;
    }

    if (defined $self->{data}->{debug} && $self->{data}->{debug}) {
        $command .= ' --debug';
    }

    if (defined $self->{data}->{errors} && $self->{data}->{errors}) {
        $command .= ' --errors';
    }

    if (defined $self->{data}->{disable_ssl_cert} && $self->{data}->{disable_ssl_cert}) {
        $command .= ' --disable-ssl-cert';
    }

    if (defined $self->{data}->{dry_run} && $self->{data}->{dry_run}) {
        $command .= ' --dry-run';
    }

    $command = 'zanata-cli '.$command;

    print "Running '$command'...\n";
    return $self->run_cmd($command, $capture);
}

sub get_zanata_locale {
    my ($self, $lang) = @_;

    $lang =~ s/-(\w+)$/'-'.uc($1)/e; # convert e.g. 'pt-br' to 'pt-BR'

    return $lang;
}

sub pull_ts {
    my ($self, $langs) = @_;

    my $action = 'pull';

    if (defined $self->{data}->{cache_dir}) {
        $action .= ' --cache-dir '.$self->{data}->{cache_dir};
    }

    if (defined $self->{data}->{use_cache} && $self->{data}->{use_cache}) {
        $action .= ' --use-cache';
    }

    if (defined $self->{data}->{purge_cache} && $self->{data}->{purge_cache}) {
        $action .= ' --purge-cache';
    }

    return $self->run_zanata_cli($action, $langs);
}

sub push_ts {
    my ($self, $langs) = @_;

    my $action = "push --push-type $self->{data}->{push_type}";

    if (defined $self->{data}->{file_types}) {
        my $file_types = $self->{data}->{file_types};

        my $joined_file_types = join(',', @$file_types);

        $action .= ' --file-types '.$joined_file_types;
    }

    $self->run_zanata_cli($action, $langs);
}

1;