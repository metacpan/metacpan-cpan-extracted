package MySQL::Admin;
use strict;
use warnings;
no warnings 'redefine';
use utf8;
use MySQL::Admin::Settings;
use MySQL::Admin::Translate;
use MySQL::Admin::Config;
use MySQL::Admin::Session;
use MySQL::Admin::Actions;
use CGI
  qw(-compile -utf8 :html2 :html3 :netscape :cgi :internal :html4 :cgi-lib textfield textarea filefield password_field hidden checkbox checkbox_group submit reset defaults radio_group popup_menu button autoEscape
  scrolling_list image_button start_form end_form start_multipart_form end_multipart_form isindex tmpFileName uploadInfo URL_ENCODED MULTIPART -private_tempfiles );

require Exporter;
use vars qw(
  $m_hrParams
  $m_qy
  $m_hrActions
  $ACCEPT_LANGUAGE
  $DefaultClass
  $m_nUplod_bytes
  $DefaultClass
  @EXPORT
  @ISA
  $m_bMod_perl
  $m_hrSettings
  $m_sUser
  $m_hrLng
  @EXPORT_OK
  %EXPORT_TAGS
  $defaultconfig
  $m_bUpload_error
  $m_nUplod_bytes
  );

$CGI::DefaultClass     = 'CGI';
$DefaultClass          = 'MySQL::Admin' unless defined $MySQL::Admin::DefaultClass;
$defaultconfig         = '%CONFIG%';
$CGI::AutoloadClass    = 'CGI';
$MySQL::Admin::VERSION = '1.15';
$m_bMod_perl           = ($ENV{MOD_PERL}) ? 1 : 0;
our $hold = 120;    #session ist 120 sekunden gültig.
@ISA = qw(Exporter CGI);
@MySQL::Admin::EXPORT_OK =
  qw(hook start_table end_table include h1 h2 h3 h4 h5 h6 p br hr ol ul li dl dt dd menu code var strong em tt u i b blockquote pre img a address cite samp dfn html head base body Link nextid title meta kbd start_html end_html input Select option comment charset escapeHTML div table caption th td TR Tr sup Sub strike applet Param embed basefont style span layer ilayer font frameset frame script small big Area Map abbr acronym bdo col colgroup del fieldset iframe ins label legend noframes noscript object optgroup Q thead tbody tfoot blink fontsize center textfield textarea filefield password_field hidden checkbox checkbox_group submit reset defaults radio_group popup_menu button autoEscape scrolling_list image_button start_form end_form start_multipart_form end_multipart_form isindex tmpFileName uploadInfo URL_ENCODED MULTIPART param upload path_info path_translated request_uri url self_url script_name cookie Dump raw_cookie request_method query_string Accept user_agent remote_host content_type remote_addr referer server_name server_software server_port server_protocol virtual_port virtual_host remote_ident auth_type http append save_parameters restore_parameters param_fetch remote_user user_name header redirect import_names put Delete Delete_all url_param cgi_error ReadParse PrintHeader HtmlTop HtmlBot SplitParam Vars https $ACCEPT_LANGUAGE  translate init session createSession $m_hrParams clearSession $m_qy sessionValidity includeAction);
$ACCEPT_LANGUAGE ='de';
%EXPORT_TAGS = (
    'html2' => [
        'h1' .. 'h6', qw/p br hr ol ul li dl dt dd menu code var strong em
          tt u i b blockquote pre img a address cite samp dfn html head
          base body Link nextid title meta kbd start_html end_html
          input Select option comment charset escapeHTML/
    ],
    'html3' => [
        qw/div table caption th td TR Tr sup Sub strike applet Param
          embed basefont style span layer ilayer font frameset frame script small big Area Map/
    ],
    'html4' => [
        qw/abbr acronym bdo col colgroup del fieldset iframe
          ins label legend noframes noscript object optgroup Q
          thead tbody tfoot/
    ],
    'netscape' => [qw/blink fontsize center/],
    'form'     => [
        qw/textfield textarea filefield password_field hidden checkbox checkbox_group
          submit reset defaults radio_group popup_menu button autoEscape
          scrolling_list image_button end_form start_form
          start_multipart_form end_multipart_form isindex tmpFileName uploadInfo URL_ENCODED MULTIPART/
    ],
    'cgi' => [
        qw/param upload path_info path_translated request_uri url self_url script_name
          cookie Dump
          raw_cookie request_method query_string Accept user_agent remote_host content_type
          remote_addr referer server_name server_software server_port server_protocol virtual_port
          virtual_host remote_ident auth_type http append
          save_parameters restore_parameters param_fetch
          remote_user user_name header redirect import_names put
          Delete Delete_all url_param cgi_error/
    ],
    'ssl'     => [qw/https/],
    'cgi-lib' => [qw/ReadParse PrintHeader HtmlTop HtmlBot SplitParam Vars/],
    'html'    => [
        qw/h1 h2 h3 h4 h5 h6 p br hr ol ul li dl dt dd menu code var strong em tt u i b blockquote pre img a address cite samp dfn html head base body Link nextid title meta kbd start_html end_html input Select option comment charset escapeHTML div table caption th td TR Tr sup Sub strike applet Param embed basefont style span layer ilayer font frameset frame script small big Area Map abbr acronym bdo col colgroup del fieldset iframe ins label legend noframes noscript object optgroup Q thead tbody tfoot blink fontsize center/
    ],
    'standard' => [
        qw/h1 h2 h3 h4 h5 h6 p br hr ol ul li dl dt dd menu code var strong em tt u i b blockquote pre img a address cite samp dfn html head base body Link nextid title meta kbd start_html end_html input Select option comment charset escapeHTML div table caption th td TR Tr sup Sub strike applet Param embed basefont style span layer ilayer font frameset frame script small big Area Map abbr acronym bdo col colgroup del fieldset iframe ins label legend noframes noscript object optgroup Q thead tbody tfoot textfield textarea filefield password_field hidden checkbox checkbox_group
          submit reset defaults radio_group popup_menu button autoEscape
          scrolling_list image_button start_form end_form
          start_multipart_form end_multipart_form isindex tmpFileName uploadInfo URL_ENCODED MULTIPART param upload path_info path_translated request_uri url self_url script_name
          cookie Dump
          raw_cookie request_method query_string Accept user_agent remote_host content_type
          remote_addr referer server_name server_software server_port server_protocol virtual_port
          virtual_host remote_ident auth_type http append
          save_parameters restore_parameters param_fetch
          remote_user user_name header redirect import_names put
          Delete Delete_all url_param cgi_error/
    ],
    'push' => [qw/multipart_init multipart_start multipart_end multipart_final/],
    'all'  => [
        qw/h1 h2 h3 h4 h5 h6 p br hr ol ul li dl dt dd menu code var strong em tt u i b blockquote pre img a address cite samp dfn html head base body Link nextid title meta kbd start_html end_html input Select option comment charset escapeHTML div table caption th td TR Tr sup Sub strike applet Param embed basefont style span layer ilayer font frameset frame script small big Area Map abbr acronym bdo col colgroup del fieldset iframe ins label legend noframes noscript object optgroup Q thead tbody tfoot blink fontsize center textfield textarea filefield password_field hidden checkbox checkbox_group submit reset defaults radio_group popup_menu button autoEscape scrolling_list image_button start_form end_form start_multipart_form end_multipart_form isindex tmpFileName uploadInfo URL_ENCODED MULTIPART param upload path_info path_translated request_uri url self_url script_name cookie Dump raw_cookie request_method query_string Accept user_agent remote_host content_type remote_addr referer server_name server_software server_port server_protocol virtual_port virtual_host remote_ident auth_type http append save_parameters restore_parameters param_fetch remote_user user_name header redirect import_names put Delete Delete_all url_param cgi_error ReadParse PrintHeader HtmlTop HtmlBot SplitParam Vars  $ACCEPT_LANGUAGE  translate init session createSession $m_hrParams clearSession $m_qy sessionValidity includeAction include/
    ],
);

=head1 NAME

MySQL::Admin - Just a MySQL administration Web-App

=head1 SYNOPSIS

use MySQL::Admin;

=head1 DESCRIPTION

MySQL::Admin is a Database Web-frontend and CMS.

This Module is an CGI subclass, mainly written for L<MySQL::Admin::GUI>.

=head2 EXPORT

export_ok:

$ACCEPT_LANGUAGE translate init session createSession $m_hrParams clearSession $m_qy include sessionValidity includeAction


export tags:
myqsl: $ACCEPT_LANGUAGE translate init session createSession $m_hrParams clearSession $m_qy include sessionValidity includeAction

and all export tags from L<CGI.pm>

=head1 Public

=head2 new()

=cut

sub new {
    my ($class, @initializer) = @_;
    my $self = {};
    bless $self, ref $class || $class || $DefaultClass;
    return $self;
}

=head2 init()

        init("/srv/www/cgi-bin/config/settings.pl");

        default: /srv/www/cgi-bin

=cut

sub init {
    my ($self, @p) = getSelf(@_);
    my $settingfile = $p[0] ? $p[0] : $defaultconfig;
    loadSettings($settingfile);
    *m_hrSettings = \$MySQL::Admin::Settings::m_hrSettings;
    loadTranslate($m_hrSettings->{translate});
    *m_hrLng = \$MySQL::Admin::Translate::lang;
    loadSession($m_hrSettings->{session});
    *m_qy = \$MySQL::Admin::Session::session;
    loadActions($m_hrSettings->{actions});
    *m_hrAction      = \$MySQL::Admin::Actions::m_hrAction;
    $m_nUplod_bytes  = 0;
    $m_bUpload_error = 0;
}

=head2 include

        %vars = (sub => 'main','file' => "fo.pl");

        $qstring = createSession(\%vars);

        include($qstring); #InVoid context param('include') will be used.

=cut

sub include {
    my ($self, @p) = getSelf(@_);
    my $qstring = $p[0] ? $p[0] : param('include') ? param('include') : 0;
    if (defined $qstring) {
        session($qstring);
        if (defined $m_hrParams->{file} && defined $m_hrParams->{sub}) {
            if (-e $m_hrParams->{file}) {
                do("$m_hrParams->{file}");
                eval($m_hrParams->{sub}) if $m_hrParams->{sub} ne 'main';
                warn $@ if ($@);
            } else {
                do("$m_hrActions->{$m_hrSettings->{defaultAction}}{file}");
                eval($m_hrActions->{$m_hrSettings->{defaultAction}}{sub})
                  if $m_hrActions->{$m_hrSettings->{defaultAction}}{sub} ne 'main';
                warn $@ if ($@);
            }
        }
    }
}

=head2 includeAction

        includeAction('welcome');

see L<MySQL::Admin::Actions>

=cut

sub includeAction {
    my ($self, @p) = getSelf(@_);
    my $m_hrAction = param('action') ? param('action') : $p[0] ? $p[0] : 0;
    if (defined $m_hrActions->{$m_hrAction}) {
        if (defined $m_hrActions->{$m_hrAction}{file} && defined $m_hrActions->{$m_hrAction}{sub}) {
            if (-e $m_hrParams->{file}) {
                do("$m_hrSettings->{cgi}{bin}/Content/$m_hrActions->{$m_hrAction}{file}");
                eval($m_hrActions->{$m_hrAction}{sub})
                  if $m_hrActions->{$m_hrAction}{sub} ne 'main';
                warn $@ if ($@);
            } else {
                do( "$m_hrSettings->{cgi}{bin}/Content/$m_hrActions->{$m_hrSettings->{defaultAction}}{file}"
                  );
                eval($m_hrActions->{$m_hrSettings->{defaultAction}}{sub})
                  if $m_hrActions->{$m_hrSettings->{defaultAction}}{sub} ne 'main';
                warn $@ if ($@);
            }
        }
    }
}

=head2 createSession

    Secure your Session (or simple store session informations);

    my %vars = (first => 'query', secondly => "Jo" , validity => time() );

    my $qstring = createSession(\%vars);

    *params= \$MySQL::Admin::params;

    session( $qstring );

    print $m_hrParams->{first};

=cut

sub createSession {
    my ($self, @p) = getSelf(@_);
    my $par = shift @p;
    $m_sUser = $par->{user} ? $par->{user} : 'guest';
    my $ip   = $self->remote_addr();
    my $time = time();
    my $id   = $par->{action} ? $par->{action} : rand 100;
    use MD5;
    my $md5 = new MD5;
    $md5->add($m_sUser);
    $md5->add($time);
    $md5->add($ip);
    $md5->add($id);
    my $fingerprint = $md5->hexdigest();

    foreach my $key (sort(keys %{$par})) {
        $m_qy->{$m_sUser}{$fingerprint}{$key} = $par->{$key};
        $m_hrParams->{$key} = $par->{$key};
    }
    $m_qy->{$m_sUser}{$fingerprint}{timestamp} =
      defined $par->{validity} ? $par->{validity} : time();
    saveSession($m_hrSettings->{session});
    return $fingerprint;
}

=head2 session

        $qstring = session(\%vars);

        session($qstring);

        print $m_hrParams->{'key'};

=cut

#################################### session###################################################################
# Diese Funktion lädt die Parameter die mit createSession erzeugt wurden.                                     #
# Als parameter erwartet Sie den wert den createSession zurückgegeben hat:                                    #
# Im Void Kontext wird param('include') benutzt.                                                              #
###############################################################################################################

sub session {
    my ($self, @p) = getSelf(@_);
    if (ref($p[0]) eq 'HASH') {
        $self->createSession(@p);
    } else {
        my $param = param('include') ? param('include') : shift @p;
        $m_sUser =  $p[0] ? $p[0]  : 'guest';
        foreach my $key (sort(keys %{$m_qy->{$m_sUser}{$param}})) {
            $m_hrParams->{$key} = $m_qy->{$m_sUser}{$param}{$key};
        }
        $m_hrParams->{session_id} = $param;
#         delete $m_qy->{$m_sUser}{$param};
    }
    saveSession($m_hrSettings->{session});
}

=head2 clearSession

delete old sessions. Delete all session older then 120 sec.

=cut

sub clearSession {
    foreach my $ua (keys %{$m_qy}) {
        foreach my $entry (keys %{$m_qy->{$ua}}) {
            my $t =
              $m_qy->{$ua}{$entry}{timestamp} ? time() - $m_qy->{$ua}{$entry}{timestamp} : time();
            $hold =
                defined $m_qy->{$ua}{$entry}{validity}
              ? defined $m_qy->{$ua}{$entry}{validity}
              : $hold;
            delete $m_qy->{$ua}{$entry} if ($t > $hold);
        }
    }
    saveSession($m_hrSettings->{session});
}

=head2 sessionValidity()

set the session Validity in seconds in scalar context:

        sessionValidity(120); #120is the dafault value

or get it in void context:

        $time = sessionValidity();

=cut

sub sessionValidity {
    my ($self, @p) = getSelf(@_);
    if (defined $p[0] and $p[0] =~ /(\d+)/) {
        $hold = $1;
    } else {
        return $hold;
    }
}

=head2 translate()

        translate(key);

see L<MySQL::Admin::Translate>

=cut

sub translate {
    my ($self, @p) = getSelf(@_);
    my $key = lc $p[0];
    my @a = split(
                  /,/, defined $ENV{HTTP_ACCEPT_LANGUAGE}
                  ? $ENV{HTTP_ACCEPT_LANGUAGE}
                  : 'de,en'
                 );

    my $i = 0;
    while ($i <= $#a) {
        my $lng = $a[$i] =~ s/(\w\w).*/$1/ ? $1 : $m_hrSettings->{language};
        if (defined $m_hrLng->{$lng}{$key}) {
            $ACCEPT_LANGUAGE = $lng;
            return $m_hrLng->{$lng}{$key};
        }
        $i++;
    }
    $m_hrLng->{en}{$key} = $key unless defined $m_hrLng->{en}{$key};
    $m_hrLng->{de}{$key} = $key unless defined $m_hrLng->{de}{$key};

    #$m_hrLng->{es}{$key} = $key unless defined $m_hrLng->{es}{$key};
    saveTranslate($m_hrSettings->{translate}) if $m_hrSettings->{saveTranslate};
    return $p[0];
}

=head2 param

param don't work in oo syntax

=cut

sub param{
    my ($self, @p) = getSelf(@_);
    return CGI::param(@p);
}

=head2 hook

used by include and includeAction.

=cut

sub hook {
    my ($self, @p) = getSelf(@_);
    my ($m_sFilename, $buffer, $bytes_read, $data) = @p;
    warn 'To big upload :', $m_sFilename, $buffer, $bytes_read, $data, $/;
    if ($m_nUplod_bytes <= $m_hrSettings->{uploads}{maxlength}) {
        require bytes;
        $m_nUplod_bytes += bytes::length($buffer);
    } else {
        $m_bUpload_error = 1;
        warn 'To big upload :', $m_sFilename, $/;
    }
}

=head1 Private


=head2 getSelf()

=cut

sub getSelf {
    return @_ if defined($_[0]) && (!ref($_[0])) && ($_[0] eq 'MySQL::Admin');
    return (defined($_[0])
            && (ref($_[0]) eq 'MySQL::Admin' || UNIVERSAL::isa($_[0], 'MySQL::Admin')))
      ? @_
      : ($MySQL::Admin::DefaultClass->new, @_);
}

=head1 AUTHOR

Dirk Lindner <lze@cpan.org>

=head1 LICENSE

Copyright (C) 2005-2016 by Hr. Dirk Lindner

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public License
as published by the Free Software Foundation;
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

=cut

=head2 see Also

L<CGI> L<MySQL::Admin::GUI> L<MySQL::Admin::Actions> L<MySQL::Admin::Translate> L<MySQL::Admin::Settings> L<MySQL::Admin::Config>

=head1 AUTHOR

Dirk Lindner <lze@cpan.org>


=cut

1;
