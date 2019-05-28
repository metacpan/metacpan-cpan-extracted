package MySQL::Admin::Session;
use strict;
use warnings;
use utf8;
require Exporter;
use vars qw( $session $DefaultClass @EXPORT  @ISA $defaultconfig);
@MySQL::Admin::Session::EXPORT = qw(loadSession saveSession $session);
use MySQL::Admin::Config;
@MySQL::Admin::Session::ISA     = qw(Exporter MySQL::Admin::Config);
$MySQL::Admin::Session::VERSION = '1.18';
$DefaultClass                   = 'MySQL::Admin::Session' unless defined $MySQL::Admin::Session::DefaultClass;
$defaultconfig                  = '%CONFIG%';

=head1 NAME

MySQL::Admin::Session - store the sessions for MySQL::Admin

=head1 SYNOPSIS

see l<MySQL::Admin::Config>

=head1 DESCRIPTION

session for MySQL::Admin.

=head2 EXPORT

loadConfig() saveSession() $session

=head1 Public

=head2 new

=cut

sub new {
    my ( $class, @initializer ) = @_;
    my $self = {};
    bless $self, ref $class || $class || $DefaultClass;
    return $self;
} ## end sub new

=head2 loadSession

load session via do from disk.

=cut

sub loadSession {
    my ( $self, @p ) = getSelf(@_);
    my $do = ( defined $p[0] ) ? $p[0] : $defaultconfig;
    if ( -e $do ) { do $do; }
} ## end sub loadSession

=head2 saveSession

=cut

sub saveSession {
    my ( $self, @p ) = getSelf(@_);
    my $l = defined $p[0] ? $p[0] : $defaultconfig;
    $self->SUPER::saveConfig( $l, $session, 'session' );
} ## end sub saveSession

=head1 Private

=head2 getSelf

=cut

sub getSelf {
    return @_ if defined( $_[0] ) && ( !ref( $_[0] ) ) && ( $_[0] eq 'MySQL::Admin::Session' );
    return (
        defined( $_[0] ) && ( ref( $_[0] ) eq 'MySQL::Admin::Session'
            || UNIVERSAL::isa( $_[0], 'MySQL::Admin::Session' ) )
      )
      ? @_
      : ( $MySQL::Admin::Session::DefaultClass->new, @_ );
} ## end sub getSelf

=head1 AUTHOR

Dirk Lindner <lze@cpan.org>

=head2 see Also

L<MySQL::Admin> L<MySQL::GUI> L<MySQL::Admin::Actions> L<MySQL::Admin::Translate> L<MySQL::Admin::Settings> L<MySQL::Admin::Config>

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
