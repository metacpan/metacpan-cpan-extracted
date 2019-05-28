package MySQL::Admin::Actions;
use strict;
use warnings;
use utf8;
require Exporter;
use vars qw($m_hrActions $DefaultClass @EXPORT  @ISA $defaultconfig);
@MySQL::Admin::Actions::EXPORT = qw(loadActions saveActions $m_hrActions);
use MySQL::Admin::Config;
@MySQL::Admin::Actions::ISA     = qw( Exporter MySQL::Admin::Config);
$MySQL::Admin::Actions::VERSION = '1.18';
$DefaultClass                   = 'MySQL::Admin::Actions' unless defined $MySQL::Admin::Actions::DefaultClass;
$defaultconfig                  = '%CONFIG%';

=head1 NAME

MySQL::Admin::Actions - actions for Mysql::Admin

=head1 SYNOPSIS

        use vars qw($m_hrActions);

        *actions = \$MySQL::Admin::Actions::actions;

        $m_hrActions = {

                welcome => {

                        sub => 'main',

                        file => 'content.pl',

                        title => 'Welcome',

                        whatever => 'storeyour own Stuff'

                        },
        };
        saveActions();

actions

=head1 DESCRIPTION

Actions for MySQL::Admin.

=head2 EXPORT

loadActions() saveActions() $m_hrActions

=head1 Public

=head2 new

=cut

sub new {
    my ( $class, @initializer ) = @_;
    my $self = {};
    bless $self, ref $class || $class || $DefaultClass;
    return $self;
} ## end sub new

=head2 loadActions

=cut

sub loadActions {
    my ( $self, @p ) = getSelf(@_);
    my $do = ( defined $p[0] ) ? $p[0] : $defaultconfig;
    if ( -e $do ) { do $do; }
} ## end sub loadActions

=head2 saveActions

=cut

sub saveActions {
    my ( $self, @p ) = getSelf(@_);
    $self->SUPER::saveConfig( @p, $m_hrActions, 'actions' );
} ## end sub saveActions

=head1 Private

=head2 getSelf

=cut

sub getSelf {
    return @_ if defined( $_[0] ) && ( !ref( $_[0] ) ) && ( $_[0] eq 'MySQL::Admin::Actions' );
    return (
        defined( $_[0] ) && ( ref( $_[0] ) eq 'MySQL::Admin::Actions'
            || UNIVERSAL::isa( $_[0], 'MySQL::Admin::Actions' ) )
      )
      ? @_
      : ( $MySQL::Admin::Actions::DefaultClass->new, @_ );
} ## end sub getSelf

=head2 see Also

L<MySQL::Admin> L<MySQL::GUI> L<MySQL::Admin::Actions> L<MySQL::Admin::Translate> L<MySQL::Admin::Settings> L<MySQL::Admin::Config>

=head1 AUTHOR

Dirk Lindner <lze@cpan.org>

=head1 LICENSE

Copyright (C) 2005-2015 by Hr. Dirk Lindner

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public License
as published by the Free Software Foundation;
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

=cut
1;
