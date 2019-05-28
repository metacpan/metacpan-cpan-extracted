package MySQL::Admin::GUI;
use strict;
use warnings;
use utf8;
use DBI::Library::Database qw(:all);
use HTML::Menu::Pages;
use MySQL::Admin qw(:all :cgi-lib);
use HTML::Entities;
use User::pwent;
use MySQL::Admin::Settings;
use MySQL::Admin::Translate;
use MySQL::Admin::Config;
use MySQL::Admin::Session;
use HTML::Menu::TreeView qw(:all);
use HTML::Editor::Markdown;
use CGI::QuickForm;
use HTML::Editor;
use Encode;
use Fcntl qw(:flock);
use Symbol;
use URI::Escape;

#use diagnostics;
use Authen::Captcha;
use JSON::XS;
use XML::Simple;
use CGI::Carp qw(fatalsToBrowser);
require Exporter;
use vars qw(
  $m_outXML
  $m_sJson
  $m_bMainTemplate
  $DefaultClass
  $ACCEPT_LANGUAGE
  @EXPORT @ISA
  $m_bMod_perl
  %m_hUniq
  $m_hrParams
  $m_hrSettings
  $m_hrLng
  $m_nStart
  $m_nEnd
  $m_nRight
  $m_sAction
  $m_sSid
  $m_sStyle
  $m_sTitle
  $m_sUser
  $m_sCurrentDb
  $m_sCurrentHost
  $m_sCurrentUser
  $m_sCurrentPass
  $m_nSkipCaptch
);
@MySQL::Admin::GUI::EXPORT  = qw( ContentHeader Body ChangeDb Unique openFile action applyRights maxlength);
@ISA                        = qw( Exporter MySQL::Admin );
$MySQL::Admin::GUI::VERSION = '1.18';
$m_bMod_perl                = ( $ENV{MOD_PERL} ) ? 1 : 0;
local $^W = 0;
our @m_processlist;
our $m_bFirstTime = 0;
our $m_oDatabase;
our $m_dbh;

=head1 NAME

MySQL::Admin::GUI - Just a MySQL administration Web-App

=head1 SYNOPSIS

use MySQL::Admin::GUI;

ContentHeader("config/settings.pl");

print Body();

=head2 EXPORT

  action Body maxlength openFile

=cut

=head2 ContentHeader

    ContentHeader("/path/to/your/settings.pl");

=cut

sub ContentHeader {
    my $m_hrSettingsfile = shift;
    init($m_hrSettingsfile) unless $m_bMod_perl and $m_bFirstTime;
    $m_nSkipCaptch = 0;
    $m_bMainTemplate = param('m_blogin') eq 'true' ? 1 : 0;
    my $cyrptpass ;
    *m_hrLng     = \$MySQL::Admin::Translate::lang;
    $m_oDatabase = new DBI::Library::Database();
    $m_oDatabase->serverName( $m_hrSettings->{cgi}{serverName} );
    $m_oDatabase->floodtime( $m_hrSettings->{floodtime} );
    $m_dbh = $m_oDatabase->initDB(
        {
            name     => $m_hrSettings->{database}{name},
            host     => $m_hrSettings->{database}{host},
            user     => $m_hrSettings->{database}{user},
            password => $m_hrSettings->{database}{password},
        }
    ) unless $m_bFirstTime;
    $m_bFirstTime = 1;
    $m_sAction = param('action') ? param('action') : $m_hrSettings->{defaultAction};
    translate($m_sAction);
    $m_sAction = ( $m_sAction =~ /^(\w{3,50})$/ ) ? $1 : $m_hrSettings->{defaultAction};
    $m_sJson = {
        m_sCurrentAction => $m_sAction,
        m_nRight         => $m_nRight,
        m_nHtmlright     => $m_hrSettings->{htmlright},
        msStyle          => $m_hrSettings->{cgi}{style},
        m_sServerName    => $m_hrSettings->{cgi}{serverName},
        m_nSize          => $m_hrSettings->{size},
        m_sTitle         => $m_hrSettings->{cgi}{title}
    };
    
    my $cookiepath = $m_hrSettings->{cgi}{cookiePath};
    $m_sSid =
        defined cookie( -name => 'sid' ) ? cookie( -name => 'sid' )
      : defined param('sid') ? param('sid')
      : '123'
      unless $m_sAction eq 'logout';

    $m_sUser = $m_oDatabase->getName($m_sSid);
    $m_sUser = defined $m_sUser ? $m_sUser : 'guest';
    my @aCookies;
    if ( $m_sAction eq 'logout' or ( $m_sUser eq 'guest' and $m_sAction ne 'login' ) ) {
        my $cookie = cookie(
            -name    => 'sid',
            -value   => '123',
            -expires => '+1y',
            -path    => "$cookiepath"
        );
        push @aCookies, $cookie;
        print header(
            -type                        => 'text/xml',
            -charset                     => 'UTF-8',
            -access_control_allow_origin => '*',
            -cookie                      => [@aCookies]
        );
        $m_sUser   = 'guest';
        $m_sSid    = '123';
        $m_sAction = $m_bMainTemplate ? $m_hrSettings->{defaultAction} : 'news' if ( $m_sAction eq 'logout' );

    } elsif ( $m_sAction eq 'login' ) {
        my $ip = remote_addr();
        my $u  = param('user');
        my $p  = param('pass');
        $m_nSkipCaptch = 0;
        $DB::signal = 1;
        eval {
            my $captcha = Authen::Captcha->new(
                data_folder   => "$m_hrSettings->{cgi}{bin}/config/",
                output_folder => "$m_hrSettings->{cgi}{DocumentRoot}/images"
            );
            $m_nSkipCaptch = $captcha->check_code( param("captcha"), param("md5") );
        };

        $m_nSkipCaptch = 1 if $@;

        if ( defined $u && defined $p && defined $ip && $m_nSkipCaptch > 0 ) {
            use MD5;
            my $md5 = new MD5;
            $md5->add($u);
            $md5->add($p);
             $cyrptpass = $md5->hexdigest();
            my $result    = 1;
            if ( $m_oDatabase->checkPass( $u, $cyrptpass ) ) {
         
                $m_nSkipCaptch = 2;
                $m_sSid = $m_oDatabase->setSid( $u, $p, $ip );
                my $cookie = cookie(
                    -name    => 'sid',
                    -value   => "$m_sSid",
                    -path    => "$cookiepath",
                    -expires => '+1y'
                );
                push @aCookies, $cookie if $result eq 1;
                print header(
                    -type                        => 'text/xml',
                    -access_control_allow_origin => '*',
                    -charset                     => 'UTF-8',
                    -cookie                      => [@aCookies]
                );
                $m_sUser = $u;
                $m_sAction = $m_bMainTemplate ? $m_hrSettings->{defaultAction} : 'news';
            } else {
                $m_sAction = 'showLogin';

                print header(
                    -type                        => 'text/xml',
                    -access_control_allow_origin => '*',
                    -charset                     => 'UTF-8',
                );
            } ## end else [ if ( $m_oDatabase->checkPass...)]
        } else {
            $m_sAction = 'showLogin';
            print header(
                -type                        => 'text/xml',
                -access_control_allow_origin => '*',
                -charset                     => 'UTF-8',
            );
        } ## end else [ if ( defined $u && defined...)]
    } else {
        $m_sUser = $m_oDatabase->getName($m_sSid);
        print header(
            -type                        => 'text/xml',
            -access_control_allow_origin => '*',
            -charset                     => 'UTF-8'
        );
    } ## end else [ if ( $m_sAction eq 'logout'...)]
    my $ip = remote_addr();
    $m_nRight = $m_oDatabase->userright($m_sUser);
    $m_sCurrentHost = $m_hrSettings->{database}{CurrentHost};
    $m_sCurrentUser = $m_hrSettings->{database}{CurrentUser};
    $m_sCurrentPass = $m_hrSettings->{database}{CurrentPass};

    if ( param('m_ChangeCurrentDb') && $m_nRight >= 5) {
        $m_sCurrentHost = param('m_shost') ? param('m_shost') : $m_sCurrentHost;
        $m_sCurrentUser = param('m_suser') ? param('m_suser') : $m_sCurrentUser;
        $m_sCurrentPass = param('m_spass') ? param('m_spass') : $m_sCurrentPass;
        $m_sCurrentDb                          = param('m_ChangeCurrentDb');
        $m_hrSettings->{database}{CurrentDb}   = $m_sCurrentDb;
        $m_hrSettings->{database}{CurrentHost} = $m_sCurrentHost;
        $m_hrSettings->{database}{CurrentUser} = $m_sCurrentUser;
        $m_hrSettings->{database}{CurrentPass} = $m_sCurrentPass;
        $m_sAction                             = 'ShowTables';
        saveSettings($m_hrSettingsfile);
    } else {
        $m_sCurrentDb = $m_hrSettings->{database}{CurrentDb};
    } ## end else [ if ( param('ChangeCurrentDb'...))]

    print qq(<?xml version="1.0" encoding="UTF-8"?>\n<xml>\n\n);
    $m_sJson->{m_sSid} = $m_sSid;
    my $encode_json = encode_json $m_sJson;
    print qq|<output id="sid"><![CDATA[
    <script>
    m_sJson   = '$encode_json';
    m_sid     = "$m_sSid";
    cAction   = "$m_sAction";
    size      = $m_hrSettings->{size};
    right     = $m_nRight;
    htmlright = $m_hrSettings->{htmlright};
    style     = "$m_hrSettings->{cgi}{style}";
	m_oSettings = JSON.parse(m_sJson);
    </script>]]></output>|;
} ## end sub ContentHeader

=head2 Body

  print Body();

=cut

sub Body {
    CGI::upload_hook( \&hook );
    $m_sStyle = $m_hrSettings->{cgi}{style};
    $m_nStart = param('von') ? param('von') : 0;
    $m_nStart = ( $m_nStart =~ /^(\d+)$/ ) ? $1 : 0;
    $m_nEnd   = param('bis') ? param('bis') : 30;
    $m_nEnd   = ( $m_nEnd =~ /^(\d+)$/ ) ? $1 : 0;
    if ( $m_nStart < 0 ) {
        $m_sAction = 'exploit';
        $m_nStart  = 0;
    } ## end if ( $m_nStart < 0 )
    $m_nRight = defined $m_nRight ? $m_nRight : 0;
    my $exploit = 0;
    my $query   = "select * from actions join actions_set on actions.action = actions_set.foreign_action where actions_set.action = ?";
    $query .= " || actions_set.action = 'default'" if $m_bMainTemplate;
    my @action_set = $m_oDatabase->fetch_AoH( $query, $m_sAction );
    $exploit = 1 if $@;
    for ( my $i = 0 ; $i <= $#action_set ; $i++ ) {
        my $action = $action_set[$i];
        $m_sTitle = $action->{title};
        if ( $m_nRight >= $action->{right} ) {
            if ( $action->{type} eq 'xml' ) {
                print qq|<output id="$action->{output_id}" type="xml"  xsl="$action->{xsl}"><![CDATA[|;
                do("$m_hrSettings->{cgi}{bin}/Content/$action->{file}") if -e "$m_hrSettings->{cgi}{bin}/Content/$action->{file}";
                eval( $action->{sub} ) if $action->{sub} ne 'main';
                print XMLout( $m_outXML, NoAttr => 1, RootName => 'action' );
                print q|]]></output>|;
            } else {
                print qq|<output id="$action->{output_id}" type="html"><![CDATA[|;
                do("$m_hrSettings->{cgi}{bin}/Content/$action->{file}")
                  if -e "$m_hrSettings->{cgi}{bin}/Content/$action->{file}";
                eval( $action->{sub} ) if $action->{sub} ne 'main';
                print q|]]></output>|;
            } ## end else [ if ( $action->{type} eq...)]
            if ($@) {
                print qq|<output id="errorMessage"><![CDATA[$@]]></output>|;
                warn "MySQL::Admin::Body $@  $/";
            } ## end if ($@)
        } else {
            $exploit = 1;
        } ## end else [ if ( $m_nRight >= $action...)]
    } ## end for ( my $i = 0 ; $i <=...)
    if ($exploit) {
        print qq|<output id="content"><![CDATA[|;
        do("$m_hrSettings->{cgi}{bin}/Content/exploit.pl");
        print q|]]></output>|;
        if ($@) {
            print qq|<output id="errorMessage"><![CDATA[$@]]></output>|;
            warn "MySQL::Admin::Body $@  $/";
        } ## end if ($@)
    } ## end if ($exploit)
    my $encode_json = encode_json $m_sJson;
    $encode_json =~ s/\\/\\\\/g;
    $encode_json =~ s/'/\\'/g;
    print qq|<output id="postScript" type="script"><![CDATA[
	var oFile =  JSON.parse('$encode_json');
	showEditor(oFile.m_sFile);
    ]]></output>|;
    ChangeDb(
        {
            name     => $m_hrSettings->{database}{name},
            host     => $m_hrSettings->{database}{host},
            user     => $m_hrSettings->{database}{user},
            password => $m_hrSettings->{database}{password},
        }
    );
    print '</xml>';
} ## end sub Body

=head2 ChangeDb

    my %db = {

	    name => '',

	    host   => '',

	    user => '',

	    password => '',

    };

    ChangeDb(\%db);

=cut

sub ChangeDb {
    my $hash = shift;
    my $m_sTitle = defined $hash->{title} ? $hash->{title} : "";
    $m_dbh = $m_oDatabase->initDB(
        {
            name     => $hash->{name},
            host     => $hash->{host},
            user     => $hash->{user},
            password => $hash->{password},
        }
    );
} ## end sub ChangeDb

=head2 Unique()

  $unique =Unique();

=cut

sub Unique {
    my $unic;
    do { $unic = int( rand(1000000) ); } while ( defined $m_hUniq{$unic} );
    $m_hUniq{$unic} = 1;
    return $unic;
} ## end sub Unique

=head2 openFile

   my $file = openFile("filename");

=cut

sub openFile {
    my $file = shift;
    if ( -e $file ) {
        use Fcntl qw(:flock);
        use Symbol;
        my $fh = gensym;
        open $fh, "<:encoding(UTF-8)", $file or warn "$!: $file $/";
        seek $fh, 0, 0;
        my $lines;
        while ( my $line = <$fh> ) {
            $lines .= $line;
        } ## end while ( my $line = <$fh> )
        close $fh;
        return $lines;
    } else {
        warn "file not found: $file$/";
    } ## end else [ if ( -e $file ) ]
} ## end sub openFile

=head2 applyRights()

updates the user rights to a treeviewLink

        applyRights(\@tree);

=cut

sub applyRights {
    my $t = shift;
    for ( my $i = 0 ; $i < @$t ; $i++ ) {
        my $r = @$t[$i]->{right} ? @$t[$i]->{right} : 0;
        if ( $r > $m_nRight ) {
            undef @$t[$i];
        } elsif ( ref @$t[$i]->{subtree}[0] eq "HASH" ) {
            applyRights( \@{ @$t[$i]->{subtree} } );
        } ## end elsif ( ref @$t[$i]->{subtree...})
    } ## end for ( my $i = 0 ; $i < ...)
} ## end sub applyRights

=head2 action

        my %action = {

                title => '',

                src   => 'ea67',#webfont

                location => '',#url

                style => 'optional',

        };

        print action{\%action);

=cut

sub action {
    my $hash     = shift;
    my $title    = defined $hash->{title} ? $hash->{title} : "";
    my $src      = defined $hash->{src} ? $hash->{src} : "";
    my $location = defined $hash->{location} ? $hash->{location} : "";
    if ( $location !~ /^javascript:/ ) {
        $location = "requestURI('$location',this.id,'$title')";
    } ## end if ( $location !~ /^javascript:/)
    return qq(<a onclick="$location" class="batch">&#x$src;</a><a class="link" href="javascript:$location" >$title</a> );
} ## end sub action

=head2  maxlength()
     
     maxlength($length ,\$text);

=cut

sub maxlength {
    my $maxWidth = shift;
    ++$maxWidth;
    my $txt = shift;
    if ( length($$txt) > $maxWidth ) {
        my $maxLength = $maxWidth;
        my $i++;
        while ( $i < length($$txt) ) {
            if ( substr( $$txt, $i, 1 ) eq "<" ) {
                $maxLength = $maxWidth;
                do { $i++ } while ( substr( $$txt, $i, 1 ) ne ">" and $i < length($$txt) );
            } ## end if ( substr( $$txt, $i...))
            if ( substr( $$txt, $i, 1 ) eq "&" ) {
                $maxLength = $maxWidth;
                do { $i++ } while ( substr( $$txt, $i, 1 ) ne ";" and $i < length($$txt) );
            } ## end if ( substr( $$txt, $i...))
            $maxLength = ( substr( $$txt, $i, 1 ) =~ /\S/ ) ? --$maxLength : $maxWidth;
            if ( $maxLength eq 0 ) {
                substr( $$txt, $i, 1 ) = " ";
                $maxLength = $maxWidth;
            } ## end if ( $maxLength eq 0 )
            $i++;
        } ## end while ( $i < length($$txt...))
    } ## end if ( length($$txt) > $maxWidth)
} ## end sub maxlength

=head1 SEE ALSO

L<CGI> L<MySQL::Admin>
L<DBI> L<DBI::Library> L<DBI::Library::Database>
L<MySQL::Admin::Main> L<HTML::TabWidget>  L<HTML::Menu::Pages>


=head1 AUTHOR

Dirk Lindner <lze@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2019 by Hr. Dirk Lindner

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public License
as published by the Free Software Foundation;
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

=cut
1;
