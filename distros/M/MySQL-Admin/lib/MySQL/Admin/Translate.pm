package MySQL::Admin::Translate;
use strict;
use warnings;
use utf8;
require Exporter;
use vars qw($ACCEPT_LANGUAGE $lang $DefaultClass @EXPORT  @ISA $defaultconfig);
@MySQL::Admin::Translate::EXPORT = qw(loadTranslate saveTranslate $lang);
use MySQL::Admin::Config;
@ISA                              = qw(Exporter MySQL::Admin::Config);
$MySQL::Admin::Translate::VERSION = '1.12';
$DefaultClass  = 'MySQL::Admin::Translate' unless defined $MySQL::Admin::Translate::DefaultClass;
$defaultconfig = '%CONFIG%';

=head1 NAME

MySQL::Admin::Translate - Translations for MySQL::Admin.

=head1 SYNOPSIS

        use MySQL::Admin::Translate;

        use vars qw($lang);

        loadTranslate("/srv/www/cgi-bin/config/translate.pl");

        *lang = \$MySQL::Admin::Translate::lang;

        print $lang->{de}{firstname};  #'Vorname'

=head1 DESCRIPTION

Translations for MySQL::Admin.

=head2 EXPORT

loadTranslate() saveTranslate() $lang

=head1 Public

=head2 new()

=cut

sub new {
    my ($class, @initializer) = @_;
    my $self = {};
    bless $self, ref $class || $class || $DefaultClass;
    return $self;
}

=head2 loadTranslate()

=cut

sub loadTranslate {
    my ($self, @p) = getSelf(@_);
    my $do = (defined $p[0]) ? $p[0] : $defaultconfig;
    if (-e $do) { do $do; }
}

=head2  saveTranslate()

=cut

sub saveTranslate {
    my ($self, @p) = getSelf(@_);
    my $l = defined $p[0] ? $p[0] : $defaultconfig;
    $self->SUPER::saveConfig($l, $lang, 'lang');
}

=head1 Private

=head2 getSelf()

=cut

sub getSelf {
    return @_ if defined($_[0]) && (!ref($_[0])) && ($_[0] eq 'MySQL::Admin::Translate');
    return (
            defined($_[0])
              && (ref($_[0]) eq 'MySQL::Admin::Translate'
                  || UNIVERSAL::isa($_[0], 'MySQL::Admin::Translate'))
           )
      ? @_
      : ($MySQL::Admin::Translate::DefaultClass->new, @_);
}

=head2 see Also

L<MySQL::Admin> L<MySQL::GUI> L<MySQL::Admin::Actions> L<MySQL::Admin::Translate> L<MySQL::Admin::Settings> L<MySQL::Admin::Config>

=head1 AUTHOR

Dirk Lindner <lze@cpan.org>

=head1 LICENSE

Copyright (C) 2015 by Hr. Dirk Lindner

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public License
as published by the Free Software Foundation;
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

=cut

1;
