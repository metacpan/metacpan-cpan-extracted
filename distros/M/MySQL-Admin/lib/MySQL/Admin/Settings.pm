package MySQL::Admin::Settings;
use strict;
use warnings;
use utf8;
require Exporter;
use vars qw($m_hrSettings $DefaultClass @EXPORT  @ISA $defaultconfig);
@MySQL::Admin::Settings::EXPORT = qw(loadSettings saveSettings $m_hrSettings);
use MySQL::Admin::Config;
@ISA                             = qw(Exporter MySQL::Admin::Config);
$MySQL::Admin::Settings::VERSION = '1.17';
$DefaultClass                    = 'MySQL::Admin::Settings' unless defined $MySQL::Admin::Settings::DefaultClass;
$defaultconfig                   = '%CONFIG%';

=head1 NAME

MySQL::Admin::Settings - manage MySQL::Admin properties

=head1 SYNOPSIS

        use MySQL::Admin::Settings;

        use vars qw($m_hrSettings);

        *m_hrSettings = \$MySQL::Admin::Settings::m_hrSettings;

        loadSettings('./config.pl');

        print $m_hrSettings->{key};

        $m_hrSettings->{key} = 'value';

        saveSettings("./config.pl");


=head1 DESCRIPTION

settings for MySQL::Admin.

=head2 EXPORT

loadSettings() saveSettings() $m_hrSettings

=head1 Public

=head2 new()

=cut

sub new {
    my ( $class, @initializer ) = @_;
    my $self = {};
    bless $self, ref $class || $class || $DefaultClass;
    return $self;
} ## end sub new

=head2 loadSettings()

=cut

sub loadSettings {
    my ( $self, @p ) = getSelf(@_);
    my $do = ( defined $p[0] ) ? $p[0] : $defaultconfig;
    if ( -e $do ) { do $do; }
} ## end sub loadSettings

=head2 saveSettings()

=cut

sub saveSettings {
    my ( $self, @p ) = getSelf(@_);
    my $l = defined $p[0] ? $p[0] : $defaultconfig;
    $self->SUPER::saveConfig( $l, $m_hrSettings, 'm_hrSettings' );
} ## end sub saveSettings

=head1 Private

=head2 getSelf()

=cut

sub getSelf {
    return @_ if defined( $_[0] ) && ( !ref( $_[0] ) ) && ( $_[0] eq 'MySQL::Admin::Settings' );
    return (
        defined( $_[0] ) && ( ref( $_[0] ) eq 'MySQL::Admin::Settings'
            || UNIVERSAL::isa( $_[0], 'MySQL::Admin::Settings' ) )
      )
      ? @_
      : ( $MySQL::Admin::Settings::DefaultClass->new, @_ );
} ## end sub getSelf

=head2 see Also

L<MySQL::Admin> L<MySQL::GUI> L<MySQL::Admin::Actions> L<MySQL::Admin::Translate> L<MySQL::Admin::Settings> L<MySQL::Admin::Config>

=head1 AUTHOR

Dirk Lindner <lze@cpan.org>

=head1 LICENSE

Copyright (C) 2005-2009 by Hr. Dirk Lindner

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public License
as published by the Free Software Foundation;
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

=cut
1;
