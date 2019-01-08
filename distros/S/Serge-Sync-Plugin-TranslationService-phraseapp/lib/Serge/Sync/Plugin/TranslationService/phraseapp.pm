# ABSTRACT: PhraseApp (https://phraseapp.com) synchronization plugin for Serge

package Serge::Sync::Plugin::TranslationService::phraseapp;
use parent Serge::Sync::Plugin::Base::TranslationService, Serge::Interface::SysCmdRunner;

use strict;

use Serge::Util qw(subst_macros);
use version;

our $VERSION = qv('0.900.6');

sub name {
    return 'PhraseApp translation software (https://phraseapp.com) synchronization plugin';
}

sub init {
    my $self = shift;

    $self->SUPER::init(@_);

    $self->{optimizations} = 1; # set to undef to disable optimizations

    $self->merge_schema({
        config_file      => 'STRING',
        wait_for_uploads => 'BOOLEAN',
        verbose          => 'BOOLEAN'
    });
}

sub validate_data {
    my ($self) = @_;

    $self->SUPER::validate_data;

    $self->{data}->{config_file} = subst_macros($self->{data}->{config_file});
    $self->{data}->{wait_for_uploads} = subst_macros($self->{data}->{wait_for_uploads});
    $self->{data}->{verbose} = subst_macros($self->{data}->{verbose});

    die "'config_file' not defined" unless defined $self->{data}->{config_file};
    die "'config_file', which is set to '$self->{data}->{config_file}', does not point to a valid file.\n" unless -f $self->{data}->{config_file};

    $self->{data}->{wait_for_uploads} = 1 unless defined $self->{data}->{wait_for_uploads};
    $self->{data}->{verbose} = 0 unless defined $self->{data}->{verbose};
}

sub run_phraseapp_cli {
    my ($self, $action, $langs, $capture) = @_;

    $ENV{'PHRASEAPP_CONFIG'} = $self->{data}->{config_file};

    my $command = $action;

    $command = 'phraseapp '.$command;

    if ($self->{data}->{verbose}) {
        $command .= ' --verbose ';
    }

    print "Running '$command'...\n";
    return $self->run_cmd($command, $capture);
}

sub pull_ts {
    my ($self, $langs) = @_;

    return $self->run_phraseapp_cli('pull', $langs);
}

sub push_ts {
    my ($self, $langs) = @_;

    my $action = 'push';

    if ($self->{data}->{wait_for_uploads}) {
        $action = $action.' --wait';
    }

    $self->run_phraseapp_cli($action, $langs);
}

1;