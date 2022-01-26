package Perl::Critic::Policy::PreferredModules;

use strict;
use warnings;

use parent 'Perl::Critic::Policy';

use Perl::Critic::Utils qw{ :severities :classification :ppi $SEVERITY_MEDIUM $TRUE $FALSE };

use Perl::Critic::Exception::AggregateConfiguration ();
use Perl::Critic::Exception::Configuration::Generic ();

use Config::INI::Reader ();

sub supported_parameters {
    return (
        {
            name        => 'config',
            description => 'Config::INI file listing recommendations.',
            behavior    => 'string',
        },
    );
}

use constant default_severity => $SEVERITY_MEDIUM;
use constant applies_to       => 'PPI::Statement::Include';

use constant optional_config_attributes => qw{ prefer reason };

our $VERSION = '0.004'; # VERSION
# ABSTRACT: Provide custom package recommendations

sub initialize_if_enabled {
    my ( $self, $config ) = @_;

    my $cfg_file = $config->get('config') // '';
    $cfg_file =~ s{^~}{$ENV{HOME}};

    $self->{_is_enabled} = !! $self->_parse_config($cfg_file);

    return $TRUE;
}

sub _add_exception {
    my ( $self, $msg ) = @_;

    $msg //= q[Unknown Error];

    $msg = __PACKAGE__ . ' ' . $msg;

    my $errors = Perl::Critic::Exception::AggregateConfiguration->new();

    $errors->add_exception( Perl::Critic::Exception::Configuration::Generic->throw( message => $msg ) );

    return;
}

sub _parse_config {
    my ( $self, $cfg_file ) = @_;

    if ( !length $cfg_file ) {
        return;
    }

    if ( !-e $cfg_file ) {
        return $self->_add_exception(qq[config file '$cfg_file' does not exist.]);
    }

    return unless $cfg_file && -e $cfg_file;

    # slurp the file rather than using `read_file` for compat with Test::MockFile
    my $content;
    {
        local $/;
        open my $fh, '<', $cfg_file or return;
        $content = <$fh>;
    }

    my $preferred_cfg;
    eval { $preferred_cfg = Config::INI::Reader->read_string($content); 1 } or do {
        return $self->_add_exception(qq[Invalid configuration file $cfg_file]);
    };

    my %valid_opts    = map { $_ => 1 } optional_config_attributes();

    foreach my $pkg ( keys %$preferred_cfg ) {
        my $setup = $preferred_cfg->{$pkg};

        my @has_opts = keys %$setup;
        foreach my $opt (@has_opts) {
            next if $valid_opts{$opt};
            $self->_add_exception("Invalid configuration - Package '$pkg' is using an unknown setting '$opt'");
        }
    }

    $self->{_cfg_preferred_modules} = $preferred_cfg;

    return 1;
}

sub violates {
    my ( $self, $elem ) = @_;

    return () unless $self->{_is_enabled};
    return () unless $elem;

    my $module = $elem->module;

    return () unless defined $module;
    return () unless my $setup = $self->{_cfg_preferred_modules}->{$module};

    my $desc = qq[Using module $module is not recommended];
    my $expl = $setup->{reason} // $desc;

    if ( my $prefer = $setup->{prefer} ) {
        $desc = "Prefer using module module $prefer over $module";
    }

    return $self->violation( $desc, $expl, $elem );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::PreferredModules - Provide custom package recommendations

=head1 VERSION

version 0.004

=head1 DESCRIPTION

Every project has its own rules for preferring specific packages over others.

This Policy tries to be `un-opinionated` and let the user provide a module
preferences with an explanation and/or suggested alternative.

=head1 MODULES

=head1 CONFIGURATION

To use L<Perl::Critic::Policy::PreferredModules> you have first to enable it in your
 F<.perlcriticrc> file by providing a F<preferred_modules.ini> configuration file:

    [PreferredModules]
    config = /path/to/preferred_modules.ini
    # you can also use '~' in the path for $HOME
    #config = ~/.preferred_modules

The  F<preferred_modules.ini> file is using the L<Config::INI> format and can looks like this

    [Do::Not::Use]
    prefer = Another::Package
    reason = "Please use Another::Package rather than Do::Not::Use"

    [Avoid::Using::This]
    [And::Also::That]

    [No:Reason]
    prefer=A::Better:Module
    
    [Only::Reason]
    reason="If you use this module, a puppy might die."

=head1 SEE ALSO

L<Perl::Critic>

=head1 AUTHOR

Nicolas R <atoomic@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by cPanel, L.L.C.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
