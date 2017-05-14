#!/usr/bin/perl
#$Id: psweb.pm 4843 2013-08-14 12:17:58Z pro $ $URL: svn://svn.setun.net/search/trunk/lib/psweb.pm $

=copyright
PRO-search web shared library
Copyright (C) 2003-2011 Oleg Alexeenkov http://pro.setun.net/search/ proler@gmail.com

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
=cut

#print "Content-type: text/html\n\n" if defined($ENV{'SERVER_PORT'}); # for web dev debug
package    #no cpan
  psweb;
use strict;
our $VERSION = ( split( ' ', '$Revision: 4843 $' ) )[1];
#use locale;
use Encode;
use utf8;
#use open qw(:utf8 :std);
#use encoding "utf8", STDOUT => "utf8", STDIN => "utf8", STDERR => "utf8";
#use encoding 'utf-8';
#use open ':utf8';
use Data::Dumper;    #dev only
$Data::Dumper::Sortkeys = $Data::Dumper::Useqq = $Data::Dumper::Indent = 1;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use lib::abs qw(./);
use psmisc qw(:all);
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw(
  mylink
  out_bold
  destroy_html
  get_param_hash
  get_param_str
  get_param_url_str
  grab_begin
  grab_end
  nameid
  part
  gotopage
  fromto
  cache_file
  cache_file_js
  cache_file_css
  is_img
  %work %config %stat %static $param
);
use Socket;
#use Time::HiRes qw(time);
no warnings qw(uninitialized);
no if $] >= 5.017011, warnings => 'experimental::smartmatch';
our ( %config, %work, %stat, %static, $param, );
#*config=\%::config;
#*psweb::stat = *main::stat;
#*psweb::work = *main::work;
*stat   = *main::stat;
*work   = *main::work;
*config = *main::config;
*param  = *main::param;
sub BEGIN { $static{'script_start'} = psmisc::timer(); }

sub config_init {
  return if $static{'lib_init_psweb'}{ $ENV{'SCRIPT_FILENAME'} }++;
  #my ($param) = @_;
  psmisc::conf(
    sub {
      #warn "psweb::config_init;";
      #my ($param) = @_;   # print "confonce($param);";    #,%$param   ;
      $config{'root_url'} ||= $ENV{'SCRIPT_NAME'} if $ENV{'REQUEST_URI'} =~ /^\Q$ENV{'SCRIPT_NAME'}/;
      $config{'root_dir'} ||= $1 if $ENV{'SCRIPT_NAME'} =~ m{^(.*/)([^/]+)?};
      my $script = $2;
      $config{'root_url'} ||= $config{'root_dir'};
      $config{'root_url'} ||= './';
      $config{'css_url'}  ||= $config{'root_dir'};
      $config{'js_url'}   ||= $config{'root_dir'};
      $config{'img_url'}  ||= $config{'root_dir'};
      $config{'rewrite'} = $ENV{'REQUEST_URI'};
      $config{'rewrite'} =~ s/^$config{'root_dir'}(?:$script)?//;
      $config{'rewrite'} =~ s/\?.*//;
      $config{'rewrite'} = decode_url( $config{'rewrite'} );
      $config{'result'} ||= $config{'rewrite'} || grep { defined( $param->{$_} ) } @{ $config{'user_param_founded'} };
      $config{'gotopage_bb'} ||= 5;    #gotopage buttons before current
      $config{'gotopage_ba'} ||= 5;    #      --//--     after  --//--
      $config{'jscript_open'}  ||= qq{<script type="text/javascript" language="JavaScript">/*<![CDATA[*/};
      $config{'jscript_close'} ||= "/*]]>*/</script>";
      $config{'lang_default'} ||= '';    # empty = autodetect, en or ru or...
      #$config{'lng_default_auto'}           ||= 'en';               # if autodetect fail
      $config{'lng'}{'en'}{'language-code'} ||= 'en';
      #$config{'lng'}{'en'}{'codepages'}     ||= [qw(utf-8 iso-8859-1)];
      $config{'lng'}{'ru'}{'language-code'} ||= 'ru';
      $config{'config_sets'} ||= [qw(mode style)];
      $config{'config_user'} ||= [ @{ $config{'config_sets'} }, qw(lang specify on_page css css_add ) ];    #codepage
      $config{'lng'}{''}{'darr'}      ||= '&darr;';
      $config{'lng'}{''}{'uarr'}      ||= '&uarr;';
      $config{'lng'}{''}{'>'}         ||= '&gt;';
      $config{'lng'}{''}{'<'}         ||= '&lt;';
      $config{'lng'}{''}{'cp1251'}    ||= 'WINDOWS-1251';
      $config{'lng'}{''}{'ctrl-prev'} ||= '(Ctrl &#8592;)';
      $config{'lng'}{''}{'ctrl-next'} ||= '(Ctrl &#8594;)';
      $config{'lng'}{''}{'thislink'}  ||= '.';
      $config{'sel_sep'}              ||= ' ';
      $config{'foot_stat_sep'}        ||= ' :: ';
      $config{'http-header-default'}  ||= "http-header: text/plain\n\n";                                    #'text/html'
      $config{'post_init_every'}{'psweb'} = sub {
        my ($param) = @_;
        if ( $config{'param_cookie'} ) {
          local %_;
          @_{ @{ $config{'param_cookie'} || [] } } = (1) x @{ $config{'param_cookie'} || [] };
          delete $param->{$_} for grep { !$_{$_} } keys %{ get_params_one( undef, split( /;\s*/, $ENV{'HTTP_COOKIE'} ) ) };
        }
        %$param = ( %{ $param || {} }, %{ $config{'force_param'} || {} } );
        $param->{ $config{'param_trans'}{$_} } = $param->{$_} for ( grep $config{'param_trans'}{$_}, keys %$param );
        $config{'view'} ||= ( $param->{'view'} || ( defined( $ENV{'SERVER_PORT'} ) ? 'html' : 'text' ) );
        if ( $param->{'json'} and psmisc::use_try 'JSON' ) {
          $config{'view'} = 'json';
          my $j = {};
          eval { $j = JSON->new->decode( $param->{'json'} ) || {} };    #allow_nonref->
          #warn Dumper $j;
          $param->{$_} = $j->{$_} for keys %$j;
        }
        for ( split( /\s*,\s*/, $ENV{'HTTP_ACCEPT_LANGUAGE'} ) ) {
          $_ = lc;
          s/\;.*$//;
          $work{'lang'} ||= $_, last if $config{'lng'}{$_};
          $work{'lang'} ||= $_, last if s/-(\w+)$// and ( $config{'lng'}{$_} or $config{'lng'}{$1} );
        }
        if ( !$work{'lang'} or $work{'lang'} eq 'en' ) {
          $ENV{'HTTP_USER_AGENT'} =~ /\(([^)]+)\)/;
          for ( split '; ', $1 ) {
            $_ = lc;
            $work{'lang'} = $_, last if exists $config{'lng'}{$_} and $config{'lng'}{$_};
          }
        }
        $work{$_} = ( $param->{$_} || $config{$_} || $work{$_} ) for @{ $config{'config_sets'} };
        #TODO recurse hash copy
        %config = ( %config, %{ $config{ $work{$_} } || {} } ) for @{ $config{'config_sets'} };
        $work{$_} = ( length( $param->{$_} ) ? $param->{$_} : ( $config{$_} or $work{$_} ) ) for @{ $config{'config_user'} };
        $work{$_} = $param->{$_} for grep { defined( $param->{$_} ) } @{ $config{'param_config'} };
        $work{'lang'} = undef if $work{'lang'} and !exists $config{'lng'}{ $work{'lang'} };
        $work{'lang'} ||= $config{'lang_default'};
        $config{'lng'}{'ru'}{'codepages'} ||= [ keys %{ $config{'trans'} } ];
        my %c = ( map { $_ => 1 } @{ $config{'lng'}{ $work{'lang'} }{'codepages'} || [] } );
        $work{'codepage'} = 'utf-8';
        #binmode( STDOUT, ':utf8' );
        #binmode( STDIN,  ':utf8' );

=old
        for ( map { lc } split( /\s*,\s*/, $ENV{'HTTP_ACCEPT_CHARSET'} ) ) {
          s/\;.*$//;
          $_ = psmisc::cp_normalize( $_ || next );
          $work{'codepage'} ||= $_, last if $c{$_};
        }
        $work{'codepage'} = undef if $work{'codepage'} and !Encode::find_encoding( $work{'codepage'} );
        $work{'codepage'} ||=
             $config{'lng'}{ $work{'lang'} }{'codepage_default'}
          || $config{'codepage_default'}
          || $config{'codepage'};
        $work{'codepage'} = psmisc::cp_normalize( $work{'codepage'} );
        $config{'rewrite'} = cp_trans( 'utf-8', $work{'codepage'}, $config{'rewrite'} );
=cut

        $config{'lng'}{'en'}{'specify'} ||= 'more options';
        }
    },
    1001
  );
  psmisc::conf(
    sub {
      #warn Dumper __FILE__, __LINE__, $param;
      $config{'internet_bots'} //=
        join( '|', qw(bot crawler spider checker worm ping heritrix perl  yandex rambler NG/ Yahoo mail\.ru facebook) )
        ;    #Gigabot googlebot msnbot Gokubot
      $config{'client_bot'} //= 1
        if ( $ENV{'HTTP_USER_AGENT'} =~ /$config{'internet_bots'}/i )
        or $param->{'testbot'}
        or ( $ENV{'SERVER_PORT'} and !$ENV{'HTTP_USER_AGENT'} );
      $config{'client_no_high_priority'} = 1 if $ENV{'HTTP_USER_AGENT'} =~ /Mediapartners-Google/i;
      #warn "bot:", $config{'client_bot'}, Dumper $param;
      $config{'out'}{'html'}{'result-flush'} ||= sub {
        my ($param) = @_;
        print $config{'jscript_open'}, qq{sort_res()}, $config{'jscript_close'};
      };
      $config{'out'}{''}{'search'} ||= sub {
        my ( $param, $table, $where ) = @_;
        #print( 'dev', 'SEARCHSS', $where, 'lim=', $static{'db'}->{'limit'} );
        part( 'similar-query', $param, $table ) if $param->{'q'};
        #printlog( 'dev', 'search001' , Dumper($param));
        $static{'db'}->user_params($param);
        #$static{'db'}->dump_cp();
        my $tim = time();
        #printlog( 'dev', 'tim0', $stat{'found_time'} ,time() , $tim);
        $static{'db'}->count( $param, $table ) if $static{'db'}->{'page'} eq 'rnd';
        $stat{'found_time'} += time() - $tim;
        #printlog( 'dev', 'tim1', $stat{'found_time'} ,time() , $tim);
        #printlog( 'dev', 'search01', $static{'db'}->{'limit_offset'}, $static{'db'}->{'page'} );
        my $err;
        #printlog( 'dev', 'search00', $where, 'lim=', $static{'db'}->{'limit'} );
        #$where ||= $static{'db'}->where( $param, undef, $table );
        $where ||= $static{'db'}->can_select( $param, $table );
        if ( $where and $static{'db'}->{'limit'} > 0 ) {
          #printlog( 'dev', 'search0', $where, 'lim=', $static{'db'}->{'limit'} );

=was
    if ( $static{'db'}->{'limit'} > 0 ) {
#printlog( 'dev', 'search1', $where , $param->{'codepage'} ,$static{'db'}->{'cp_in'});
      psmisc::flush();
#++$err if $static{'db'}->prepare( $static{'db'}->select_body( scalar cp_trans( $param->{'codepage'} ,$static{'db'}->{'codepage'}, $where ), $param, $table ) ) > 0;
      ++$err if $static{'db'}->prepare( $static{'db'}->select_body( $where , $param, $table ) ) > 0;
#printlog( 'dev', 'serr=', $err, $static{'db'}->{'sth'}, $static{'db'}->{'actual'}, $static{'db'}->{'limit'} );
    }
    if ( !$err and $static{'db'}->{'sth'} and $static{'db'}->{'actual'} > 0 and $static{'db'}->{'limit'} > 0 ) {
      #printlo
      my $row = $static{'db'}->{'sth'}->fetchrow_hashref();
      part( 'result_head', $param, $table, $row, { 'no_cont' => 1 } );
#while ( my $row = $static{'db'}->{'sth'}->fetchrow_hashref ) {
      while ($row) {
        part( 'result_string_pre', $param, $table, $row, { 'no_cont' => 1 } );
        part( 'result_string',     $param, $table, $row, { 'no_cont' => 1 } );
        ++$stat{'results'};
        part( 'result_string_post', $param, $table, $row, { 'no_cont' => 1 } );
        $row = $static{'db'}->{'sth'}->fetchrow_hashref;
      }
      $static{'db'}->count( $param, $table );
      part( 'result_foot', $param, $table, undef, { 'no_cont' => 1 } );
    }
    $static{'db'}->count( $param, $table );
#$static{'db'}->count( $param, $table );
    part( 'result_error', $param, $table ) if $err;
=cut

          psmisc::flush();
#if ( $static{'db'}->{'limit'} > 0 ) {
#printlog( 'dev', 'search1', $where , $param->{'codepage'} ,$static{'db'}->{'cp_in'});
#++$err if $static{'db'}->prepare( $static{'db'}->select_body( scalar cp_trans( $param->{'codepage'} ,$static{'db'}->{'codepage'}, $where ), $param, $table ) ) > 0;
#++$err if $static{'db'}->prepare( $static{'db'}->select_body( $where , $param, $table ) ) > 0;
#printlog( 'dev', 'serr=', $err, $static{'db'}->{'sth'}, $static{'db'}->{'actual'}, $static{'db'}->{'limit'} );
#}
#if ( !$err and $static{'db'}->{'sth'} and $static{'db'}->{'actual'} > 0 and $static{'db'}->{'limit'} > 0 ) {
#printlo
#my $row = $static{'db'}->{'sth'}->fetchrow_hashref();
          my $n;
          my $tim = time();
          #printlog( 'dev', 'searchr0000',  Dumper $param);
          my $line = sub (@) {
            for my $row (@_) {
              #utf8::decode $_ for values %$row;
              #printlog( 'dev', 'searchr0', Dumper $row );
              #$stat{'found_time'} ||= time() - $work{'start_time'};
              $stat{'found_time'} += time() - $tim unless $n;
              #printlog( 'dev', 'tim2', $stat{'found_time'} ,time() , $tim);
              part( 'result_head', $param, $table, $row, { 'no_cont' => 1 } ) unless $n++;
              #while ( my $row = $static{'db'}->{'sth'}->fetchrow_hashref ) {
              #while ($row) {
              part( 'result_string_pre', $param, $table, $row, { 'no_cont' => 1 } );
              part( 'result_string',     $param, $table, $row, { 'no_cont' => 1 } );
              ++$stat{'results'};
              part( 'result_string_post', $param, $table, $row, { 'no_cont' => 1 } );
              #$row = $static{'db'}->{'sth'}->fetchrow_hashref;
              #printlog( 'dev', 'searchr1', $row);
            }
          };
          #my $sort = sub { print $config{'jscript_open'}, qq{sort_res()}, $config{'jscript_close'}; };
          for my $row (
            $static{'db'}->select(
              $table, $param, {
                row => $line,
                #flush => sub { part( 'result-flush', $param ); psmisc::flush() }
                flush => sub {
                  #$sort->();
                  part( 'result-flush', $param );
                  psmisc::flush();
                },
              }
            )
            )
          {
            $line->($row);
          }
          $err += $static{'db'}->err();
          #printlog( 'dev', 'search err', $static{'db'}->err());
          $static{'db'}->count( $param, $table );
          $err += $static{'db'}->err();
          #$sort->();
          part( 'result-flush', $param );
          part( 'result_foot', $param, $table, undef, { 'no_cont' => 1 } );
          #}
          #$static{'db'}->count( $param, $table );
          #$static{'db'}->count( $param, $table );
          part( 'result_error', $param, $table, $err ) if $err;
        }
        #$stat{'found_time'} ||= time() - $work{'start_time'};
        part( 'result-report', $param ) unless $err;
      };
      $config{'out'}{''}{'main_or_search'} ||= sub {
        my ( $param, $table ) = @_;
        my ($param_num);
        #my $wparam = {%$param};
        #print "PCP1[$work{'codepage'}, $config{'cp_int'}]($wparam->{path})", Dumper $wparam;
        #cp_trans_hash( $work{'codepage'}, $config{'cp_int'}, $wparam );
        #print "PCP2[$work{'codepage'}, $config{'cp_int'}]($wparam->{path})";
        #my $where = $static{'db'}->where( $param, $param_num, $table );
        my $where = $static{'db'}->can_select( $param, $table );
        psmisc::printall( \$config{'html_result_bef'}, $param ) if $where;
        #$work{'start_time'} ||= time();
        #printlog( 'dev', 'PRE-SERACH', Dumper $where, $param, $table , "($config{'use_sphinx'} and $param->{'q'})");
        if ( (
               ( $where and ( $static{'db'}->where( \%{ $config{'force_param'} }, $param_num, $table ) ne $where ) )
            or ( $param->{ 'count_f' . $param_num }    and !$config{'force_param'}{ 'count_f' . $param_num } )
            or ( $param->{ 'count_size' . $param_num } and !$config{'force_param'}{ 'count_size' . $param_num } )
            or ( $static{'db'}{'use_sphinx'}           and $param->{'q'} )
          )
          )
        {
          part( 'search', $param, $table, $where );
        } else {
          part( 'main', $param, $table );
        }
      };
      $config{'out'}{'html'}{'header'} ||= sub {
        my ( $param, $table ) = @_;
        part( 'loading', $param ) if ( $config{'ajax'} );
        part( 'pre-search-form', $param, $table );
        part( 'search-form',     $param, $table );
        #print '<br/><br/>', lang('starting downloading'), ' <a href="', $param->{'go'}, '">', $param->{'go'}, '</a><br/>',
        #lang('if download does not start you can try other locations'), '<br/><br/>'
        #if $param->{'go'};
      };
      $config{'out'}{'html'}{'search-form'} ||= sub {
        my ( $gparam, $table ) = @_;
        my $param = {%$gparam};
        #print "PCP[$work{'codepage'}, $config{'cp_int'}]", Dumper $param;
        cp_trans_hash( $work{'codepage'}, $config{'cp_int'}, $param );
        print $config{'jscript_open'}, 'function disable_form(obj) {',
          map( 'repl(\'' . $_ . '\', \'disabled\', \'true\');', @{ $config{'user_param_disable'} } ),
          'if (!gid(\'search_prev\').checked)',
          join( ',', map { 'repl(\'' . $_ . '0\',\'value\',\'\')' . $config{'js_debug'} } @{ $config{'user_param_founded'} } ),
          ';',
          'for(i = 0; i < obj.length; ++i) { if (!obj[i].value || obj[i].className==\'input-help\') obj[i].disabled=true;}',
          '}',
          #'for(i in obj) { if (!obj[i].value || obj[i].className==\'input-help\') obj[i].disabled=true;}', '}',
          'function enable_form(obj) {',
          'for(i = 0; i < obj.length; ++i) if (!obj[i].value || obj[i].className==\'input-help\') obj[i].disabled=false;', '}',
#'for(i in obj) if (\'value\' in obj[i] &&(!obj[i].value || obj[i].className==\'input-help\')&& \'disabled\' in obj[i]) obj[i].disabled=false;', '}',
          $config{'jscript_close'};
        print ' <form method="', $config{'form_method'}, '" action="', $config{'root_url'},
          '" id="searchform" ' . $config{'js_debug'} . 'onsubmit="disable_form(this);',
          ( $config{'ajax'} ? 'dosubmit(); return false;' : '' ),
          '" ' . $config{'js_debug'} . 'onmouseover="enable_form(this);" ',
#(!$config{'no_ajax'} ? ' onchange="alert(100);dosubmit();" ' : ''),
#(!$config{'no_ajax'} ? ' onkeypress="disable_form(this);dosubmit();enable_form(this);" _onchange="disable_form(this);dosubmit();enable_form(this);" ' : ''),
          '>';
        part( 'search-form-input', $param, $table );
        print $config{'jscript_open'}, qq@
var obj=gid('searchform');
for(i in obj){
//if(!obj[i]||!obj[i].addEventListener)continue;
//obj[i].addEventListener('change',function(e){var el=gid('page');if(el.value>1)el.value=1;},false);
setup_event(obj[i], 'change', function(e){var el=gid('page');if(el.value>1)el.value=1;});
}
@, $config{'jscript_close'};
        print '</form>',
          #$config{'jscript_open'},        qq@form_strip_setup('searchform');@,        $config{'jscript_close'},
          ;
      };
      $config{'out'}{'html'}{'http-header'}   ||= "Content-type: text/html\n\n";
      $config{'out'}{'html'}{'form-i-search'} ||= sub {
        my ( $param, $table, $fparam, $cparam, $paramnum, $valuenum ) = @_;
        print '', (
          defined($paramnum)
          ? (
            '<select name="glueg',
            $paramnum,
            '" dir="ltr" >',
            '<option value="">',
            lang('and'),
            '</option>',
            '<option value="or" ',
            ( $param->{ 'glueg' . $valuenum } eq 'or' ? 'selected="selected"' : '' ),
            '>',
            lang('or'),
            '</option>', (
              $config{'enable_xor_query'}
              ? (
                '<option value="xor" ',
                ( $param->{ 'glueg' . $valuenum } eq 'xor' ? 'selected="selected"' : '' ),
                '>', lang('xor'), '</option>',
                )
              : ()
            ),
            '</select> '
            )
          : psmisc::printall( $config{'i-search_bef'} )
          ),
          '<input type="text" ', nameid( 'q' . $paramnum ), ' size="',
          ( ( !$paramnum and $config{'main_q_length'} )
          ? $config{'main_q_length'}
          : check_int( length( $param->{ 'q' . $valuenum } ), 20, 30, 20 ) ), '" maxlength="160" ',
          value( $param->{ 'q' . $valuenum } ),
          #'" maxlength="160" value="', to_quot($param->{'q'.$valuenum}, '"'),
          #'" />', $config{'form-i-search-input_right'};
          #(!$config{'no_ajax'} ? ' onchange="dosubmit();" ' : ''),
          #(!$config{'no_ajax'} ? ' onkeypress="dosubmit();" ' : ''),
          '/>', $config{'form-i-search-input_bef'};
        print '<input ',
          ( !$config{'ajax'}
          ? 'type="submit"'
          : 'type="button" ' . $config{'js_debug'} . 'onclick="disable_form(gid(\'searchform\'));dosubmit(); return false;"' ),
          ' value="'
          #. 'onclick="dosubmit(); return false;"' ), ' value="'
          . lang('search'), '"/> ' unless ( defined($paramnum) );
      };
      $config{'out'}{'html'}{'form-reset'} ||= sub {
        my ( $param, $table, $fparam, $cparam, $paramnum, $valuenum ) = @_;
        print $config{'sel_sep'},
          mylink( lang('reset'), undef, { 'onclick' => 'gid(\'searchform\').reset(); return false;', 'href' => '#' }, {} );
      };
      $config{'out'}{'html'}{'form-clear'} ||= sub {
        my ( $param, $table, $fparam, $cparam, $paramnum, $valuenum ) = @_;
        print $config{'sel_sep'}, mylink(
          lang('clear'),
          undef, {
                'onclick' => 'var obj = gid(\'searchform\');'
              . 'for(i = 0; i < obj.length; ++i) { if (obj[i].value && (obj[i].className!=\'input-help\' && obj[i].type!=\'submit\' && obj[i].type!=\'button\')) obj[i].value=\'\';}; return false;',
#. 'for(i in obj) { if (obj[i].value && (obj[i].className!=\'input-help\' && obj[i].type!=\'submit\' && obj[i].type!=\'button\')) obj[i].value=\'\';}; return false;',
            'href'  => '#',
            'class' => 'a',
          },
          { 'tag' => 'span', },
        );
      };
      $config{'out'}{'html'}{'form-link-hide-specify'} ||= sub {
        #my ( $param, $table, $fparam, $cparam, $paramnum, $valuenum ) = @_;
        print '<span class="a" ' . $config{'js_debug'} . 'onclick="hide_adv();return false;">', lang('hide'), '</span>';
      };
      $config{'out'}{'html'}{'form-link-specify'} ||= sub {
        #my ( $param, $table, $fparam, $cparam, $paramnum, $valuenum ) = @_;
        print '<span class="a" ' . $config{'js_debug'} . 'onclick="show_adv();return false;">', lang('specify'), '</span>';
      };
      $config{'out'}{'html'}{'form-link-specify-hide'} ||= sub {
        my ( $param, $table, $fparam ) = @_;
        #print "lspc1:";
        part(
          'form-link-hide-specify', $param, $table, undef,    #$param, $table, undef,
          #{ 'cont_param' => ' id="form-link-hide-specify" style="display:none;" ' },
          { 'cont_param' => ' style="display:none;" ' },
          #$work{'paramnum'}, $work{'valuenum'}
        ) unless $config{'no_hide'};
        #print "lspcss";
        part(
          'form-link-specify',                                #undef,undef,undef, #$param, $table, undef, undef,
          #{ 'cont_param' => ' id="form-link-specify" ' },
          #$work{'paramnum'}, $work{'valuenum'}
        ) unless $config{'no_hide'};
        #print "lspc2";
      };
      $config{'out'}{'html'}{'form-links'} ||= sub {
        my ( $param, $table ) = @_;
        #print "ZZZ";
        print $config{'form-link-bef'}, mylink( lang('..'), undef, undef, { 'base' => $_ } ), $config{'form-link-aft'},
          $config{'sel_sep'}
          if !$config{'no_form-links-up'} and ( ( $_ = $config{'root_url'} ) =~ s|^(\w+://[^/]+)/.+$|$1| );
        print $config{'form-link-bef'}, mylink( lang('main') ), $config{'form-link-aft'}, $config{'sel_sep'}
          if !$config{'no_form-links-main'};    #and ( $config{'ajax'} or ( $config{'result'} || $param->{'show'} ) );
        print $config{'form-link-bef'}, mylink( lang('stats'), { 'show' => 'stat' } ), $config{'form-link-aft'},
          $config{'sel_sep'}
          unless $config{'no_form-links-stat'};
        print $config{'form-link-bef'}, mylink( lang('add'), { 'show' => 'add' } ), $config{'form-link-aft'}, $config{'sel_sep'}
          if $config{'allow_add'} and ( !$config{'web_adder_mask'} xor $config{'client_ip'} =~ $config{'web_adder_mask'} );
      };
      $config{'out'}{'html'}{'form-adjust'} ||= sub {
        my ( $param, $table, $fparam, $cparam, $paramnum, $valuenum ) = @_;
        part( 'form-adjust-win', $param, $table, undef, { 'cont_param' => ' style="display:none;" ' }, $paramnum, $valuenum );
        $config{'form-adjust-no-move'} //= 0;
        print $config{'form-link-bef'},
            qq{<span class="a" }
          . $config{'js_debug'}
          . qq{onclick="menu_toggle(this, gid(\'form-adjust-win\'), -20, 5, $config{'form-adjust-no-move'} );">},
          lang('adjust'), '</span>', $config{'form-link-aft'};
      };
      $config{'out'}{'html'}{'form-adjust-win-config'} ||= sub {
        my ( $param, $table, $fparam, $cparam, $paramnum, $valuenum ) = @_;
        print lang($_), ' <input type="checkbox" ', nameid($_), ' ' . $config{'js_debug'} . 'onclick="cookie_checkbox(this);" ',
          ( ( $config{$_} ) ? 'checked="checked"' : '' ), '/><br/>'
          for @{ $config{'param_config'} || [] };
      };
      $config{'out'}{'html'}{'form-adjust-win'} ||= sub {
        my ( $param, $table, $fparam, $cparam, $paramnum, $valuenum ) = @_;
        print q{<div class="results">};
        print lang('show results'),
            '<select name="on_page" dir="ltr" '
          . $config{'js_debug'}
          . 'onchange="createCookie(\'on_page\', value);"><option value=""></option>',
          map( (
            '<option value="',
            $_, '" ', ( $param->{'on_page'} == $_ ? 'selected="selected"' : '' ),
            '>', lang($_), '</option>'
          ),
          ( 10, 20, 50, 100 ) ),
          '</select></div>';
        print q{<div class="spacify">};
        print lang('specify'),
            '<select name="on_page" dir="ltr" '
          . $config{'js_debug'}
          . 'onchange="createCookie(\'specify\', value); if(value==\'on\') allow_show_adv_auto = 1,show_adv(); if(value==\'off\') allow_show_adv_auto = 0, hide_adv();if(value==\'auto\') allow_show_adv_auto = 1;"><option value=""></option>',
          map( (
            '<option value="',
            $_, '" ', ( ( $work{'specify'} eq $_ ) ? 'selected="selected"' : '' ),
            '>', lang($_), '</option>'
          ),
          qw(auto on off) ),
          '</select></div>';
        print q{<div class="images">};
        psmisc::printu lang('show images'), ' <select dir="ltr" id="img" name="img" title="', lang('max in bytes or all'),
          '" ' . $config{'js_debug'} . 'onchange="createCookie(\'img\', value);" >', '<option value="">', lang('no'),
          '</option>',
          map(
          ( '<option value="', $_, '" ', ( ( $work{'img'} eq $_ ) ? 'selected="selected"' : '' ), '>', lang($_), '</option>' ),
          @{ $config{'img_show_sizes'} } ),
          '</select></div>'
          unless $config{'no_player'};
#print ' Будут показаны картинки с размером, не превышающий указанный, если all - то все картинки. Целесообразно использовать с галочкой online' if $param->{'help'};
        part( 'form-adjust-win-config', $param, $table, undef, undef, $paramnum, $valuenum );
        print '<div><span class="a apply" ' . $config{'js_debug'} . 'onclick="window.location.reload(false);">', lang('apply'),
          '</span></div>';
        print '<div><span class="a reset" ' . $config{'js_debug'} . 'onclick="',
          map( "eraseCookie('$_');", @{ $config{'param_cookie'} } ), 'window.location.reload(false);">', lang('reset'),
          '</span></div>';
        print '<div><span class="a close" ' . $config{'js_debug'} . 'onclick="menu_hide();return false;">', lang('hide'),
          '</span></div>';
      };
      $config{'out'}{'html'}{'form-in-founded'} ||= sub {
        my ( $param, $table, $fparam, $cparam, $paramnum, $valuenum ) = @_;
        print $config{'sel_sep_head'}, lang('in found'), ' <input type="checkbox" id="search_prev" name="search_prev" ',
          ( $config{'client_ie'} ? 'onclick' : 'onchange' ), '="',    # IE SUKA MUST DIE
          'toggleview(\'tr_hidden_prev\');',
          map( 'if (checked &amp;&amp; gid(\''
            . $_
            . '\').value== \''
            . destroy_quotes( $param->{$_} )
            . '\') gid(\''
            . $_
            . '\').value=\'\';',
          grep $param->{$_},
          @{ $config{'user_param_founded'} } ),
          map( 'if (!checked &amp;&amp; (gid(\''
            . $_
            #map( 'if (!checked && (gid(\'' . $_
            . '\').value== \'\' || gid(\''
            . $_
            . '\').className==\'input-help\')) gid(\''
            . $_
            . '\').value=\''
            . destroy_quotes( $param->{$_} )
            . '\', gid(\''
            . $_
            . '\').className=\'input-normal\';', grep $param->{$_}, @{ $config{'user_param_founded'} } ),
          '"/> ';
      };
      $config{'out'}{'html'}{'form-accurate'} ||= sub {
        my ( $param, $table, $fparam, $cparam, $paramnum, $valuenum ) = @_;
        if (
          grep {
            ( $config{'sql'}{'table'}{$table}{$_}{'fulltext'} and $config{'sql'}{'table'}{$table}{$_}{'stem'} )
              or ( $config{'sql'}{'table_param'}{$table}{'stemmed_index'} and !$config{'use_sphinx'} )
          } keys %{ $config{'sql'}{'table'}{$table} }
          )
        {
          print $config{'sel_sep_head'};
          my $link = 1 if $config{'result'} and $param->{ 'q' . $valuenum };
          print '<a href="#" onclick="gid(\'accurate' . $paramnum . '\').checked=\'',
            ( $param->{ 'accurate' . $valuenum } ? '' : 'checked' ), '\'; dosubmit(); return false;">',
            if $link;
          print lang('accurate');
          print '</a>' if $link;
          psmisc::printu ' <input type="checkbox" ', nameid( 'accurate' . $work{'paramnum'} ), ' ',
            ( ( $param->{ 'accurate' . $valuenum } eq 'on' ) ? 'checked="checked"' : '' ), '/>';
          return 1;
        }
        print '<input type="hidden" ', nameid( 'accurate' . $work{'paramnum'} ), '/>';
        return 0;
      };
      $config{'out'}{'html'}{'one-query'} ||= sub {
        my ( $param, $table, $fparam ) = @_;
        local $param->{'help'} = 0 if defined $work{'paramnum'};
        my $questions = 0;
        map { ++$questions; } grep defined( $param->{ $_ . $work{'valuenum'} } ), @{ $config{'user_param_founded'} };
        return
          if ( $work{'paramnum'} )
          and ( $work{'paramnum'} > 100 or ( $work{'paramnum'} > $param->{'complex'} and !$questions ) );
        local $config{'sel_sep'} = ' ' . lang( $param->{ 'gluel' . $work{'valuenum'} } ) . ' '
          if $param->{ 'gluel' . $work{'valuenum'} };
        #print "P$work{'paramnum'};V$work{'valuenum'};";
        psmisc::printall( $config{ 'html_header-' . $work{'paramnum'} . '-bef' }, $param, $table, $fparam );
        print '<div class="header-', ( ( defined $work{'paramnum'} or defined $work{'valuenum'} ) ? 'extended"' : '1"' ),
          ( $work{'paramnum'} eq 0 ? ' ' . nameid('tr_hidden_prev') . ' style="display:none;" ' : '' ), '>';
        part( 'form-i-search', $param, $table, undef, undef, $work{'paramnum'}, $work{'valuenum'} );
        unless ( defined( $work{'paramnum'} ) ) {
          part( 'form-accurate', $param, $table, undef, undef, $work{'paramnum'}, $work{'valuenum'} );
          if (  $config{'allow_search_in_founded'}
            and $questions
            and ( !$config{'use_sphinx'} or !$param->{ 'q' . $work{'valuenum'} } ) )
          {
            part( 'form-in-founded', $param, $table, undef, undef, $work{'paramnum'}, $work{'valuenum'} );
          } else {
            print '<input type="hidden" ', nameid('search_prev'), '/>';
          }
          part( 'form-online', $param, $table, undef, undef, $work{'paramnum'}, $work{'valuenum'} ) if !$config{'no_online'};
          unless ( $config{'no_index'}
            or $config{'ignore_index'}
            or $config{'table_param'}{$table}{'no_index'}
            or $config{'table_param'}{$table}{'ignore_index'} )
          {
#print'Искать только на доступных в данный момент ресурсах.' if $param->{'help'};      #  print'</tr><tr>' if $param->{'help'};
            part( 'form-help', $param, $table, undef, undef, $work{'paramnum'}, $work{'valuenum'} );
            part( 'form-link-specify-hide', $param, $table, ) unless $config{'one-query-no-link-specify'};
          }
        }
        unless ( defined( $work{'paramnum'} ) ) {
          print '</div>';
          psmisc::printall( $config{'html_header-1-aft'}, $param, $table, $fparam );
          print '<div class="header-2" id="tr_adv" ', ( $config{'no_hide'} ? '' : 'style="display:none;">' );
        } else {
          print $config{'sel_sep'};
        }
        print qq{<div class="path">};
        my $name;
        for (
          sort { $config{'sql'}{'table'}{$table}{$b}{'order'} <=> $config{'sql'}{'table'}{$table}{$a}{'order'} } grep {
            !$config{ 'no_' . $_ }
              and $config{'sql'}{'table'}{$table}{$_}{'nav_field'}
              and !$config{'sql'}{'table'}{$table}{$_}{'nav_hide'}
          } keys %{ $config{'sql'}{'table'}{$table} }
          )
        {
          my $value = $param->{ $_ . $work{'valuenum'} };
          $name = lang( $_ . '_symb' );
          #($param->{ $_ . $work{'valuenum'} } ? () : lang( $_ . '_symb_alt' )),
          ( $name eq $_ . '_symb' ? ( $name = lang($_) ) : () ),
            print( $name , ( $value ? () : $config{'lng'}{''}{ $_ . '_symb_alt' } ), ),
            ( ( $param->{'expert'} or $param->{ $_ . '_mode' . $work{'valuenum'} } )
            ? select_mode( $param, $work{'paramnum'}, $work{'valuenum'} )
            : 0 );
          print(
            '<input class="input" style="display:none" type="text" id="',
            $_,
            $work{'paramnum'},
            '" name="',
            $_,
            $work{'paramnum'},
            '" title="',
            lang($_),
            '" placeholder="',
            lang($_),
            '" size="',
            psmisc::check_int( length($value), 5, 25 ),
            '" ',
            value($value),
            '/>',
            qq{<span class="a input},
            ( length $value ? ' filled' : '' ),
qq{" onclick="var w = this.offsetWidth;hide_id(this);show_id('$_$work{'paramnum'}');if (w)gid('$_$work{'paramnum'}')/*.clientWidth*/.style.width=w+'px';" title="},
            lang($_),
            qq{">},
            ( destroy_html( $param->{ $_ . $work{'valuenum'} } ) // lang($_) ),
            qq{</span>},
            )
            #(
            #( defined( $param->{ $_ . $work{'valuenum'} } ) and ( length( $param->{ $_ . $work{'valuenum'} } ) > 5 ) )
            #? length( $param->{ $_ . $work{'valuenum'} } )
            #: '5'
            #),
        }
        print qq{</div><div class="sorter">};
        print( $config{'sel_sep'} ), select_mode( $param, $work{'paramnum'}, $work{'valuenum'} ), print(
          '<input type="text" id="', $_, $work{'paramnum'}, '" name="', $_, $work{'paramnum'}, '" size="5" ',
          #( defined( $param->{ $_ . $work{'valuenum'} } ) ? value($param->{ $_ . $work{'valuenum'} })  : '' ), '/> ' )
          value( $param->{ $_ . $work{'valuenum'} } ), '/> '
          )
          for (
          sort { $config{'sql'}{'table'}{$table}{$b}{'order'} <=> $config{'sql'}{'table'}{$table}{$a}{'order'} } grep {
            !$config{ 'no_' . $_ }
              and $config{'sql'}{'table'}{$table}{$_}{'nav_num_field'}
              and !$config{'sql'}{'table'}{$table}{$_}{'nav_hide'}
          } keys %{ $config{'sql'}{'table'}{$table} }
          );
        print $config{'sel_sep'}, '<select id="search_days_mode', $work{'paramnum'}, '" name="search_days_mode',
          $work{'paramnum'}, '" dir="ltr">', '<option value="">', lang('days'), '</option>', '<option value="g" ',
          ( $param->{ 'search_days_mode' . $work{'valuenum'} } =~ /[g>]/i ? 'selected="selected"' : '' ), '>', lang('<'),
          '</option>', '<option value="l" ',
          ( $param->{ 'search_days_mode' . $work{'valuenum'} } =~ /[l<]/i ? 'selected="selected"' : '' ), '>', lang('>'),
          '</option>', '</select><input type="text" id="search_days', $work{'paramnum'}, '" name="search_days',
          $work{'paramnum'}, '" size="3" '
          #. (
          #defined( $param->{ 'search_days' . $work{'valuenum'} } )
          #? value($param->{ 'search_days' . $work{'valuenum'} })
          #: ''
          #),
          , value( $param->{ 'search_days' . $work{'valuenum'} } ), '/> '
          if !$config{'no_search_days'} and $config{'sql'}{'table'}{$table}{'time'};
        if ( $param->{'expert'} or defined( $param->{ 'gluel' . $work{'valuenum'} } ) ) {
          print ' <select id="gluel', $work{'paramnum'}, '" name="gluel', $work{'paramnum'}, '" dir="ltr" >',
            '<option value="">', lang('and'), '</option>', '<option value="or" ',
            ( $param->{ 'gluel' . $work{'valuenum'} } eq 'or' ? 'selected="selected"' : '' ), '>', lang('or'), '</option>',
            (
            $config{'enable_xor_query'}
            ? (
              '<option value="xor" ',
              ( $param->{ 'glueg' . $work{'valuenum'} } eq 'xor' ? 'selected="selected"' : '' ),
              '>', lang('xor'), '</option>',
              )
            : ()
            ),
            '</select> ';
        } else {
          print '<input type="hidden" id="gluel', $work{'paramnum'}, '" name="gluel', $work{'paramnum'}, '"/>';
        }
        print $config{'sel_sep'}, '<select ', nameid( 'order' . $work{'paramnum'} ), ' dir="ltr"><option value="">',
          lang('sort'), '</option>';
        print '<option value="', $_, '" ', ( $param->{ 'order' . $work{'valuenum'} } eq $_ ? 'selected="selected"' : '' ), '>',
          lang($_), '</option>'
          for sort { $config{'sql'}{'table'}{$table}{$b}{'order'} <=> $config{'sql'}{'table'}{$table}{$a}{'order'} } grep {
          ( $config{'sql'}{'table'}{$table}{$_}{'sort'} or !$config{'sql'}{'table'}{$table}{$_}{'no_order'} )
            and !$config{'sql'}{'table'}{$table}{$_}{'hide'}
          } keys %{ $config{'sql'}{'table'}{$table} };
        psmisc::printu '</select> ', lang('reverse'), ' <input type="checkbox" ', nameid( 'order_mode' . $work{'paramnum'} ),
          ' ', ( ( $param->{ 'order_mode' . $work{'valuenum'} } ) ? 'checked="checked"' : '' ), '/>';
        print qq{</div><div class="checks">};
        unless ( defined( $work{'paramnum'} ) ) {
          print $config{'sel_sep'}, '&sum;', lang('files'), '<input type="checkbox" id="count_f" name="count_f" ',
            ( ( $param->{'count_f'} eq 'on' ) ? 'checked="checked"' : '' ), ' /> ', $config{'sel_sep'}
            unless $config{'no_count_f'};
          psmisc::printu ' &sum;', lang($_), ' <input type="checkbox" id="count_', $_, '" name="count_', $_, '" ',
            ( ( $param->{ 'count_' . $_ } eq 'on' ) ? 'checked="checked"' : '' ), ' />', $config{'sel_sep'}
            for grep { !$config{ 'no_count_' . $_ } and $config{'sql'}{'table'}{$table}{$_}{'allow_count'} }
            sort { $config{'sql'}{'table'}{$table}{$b}{'order'} <=> $config{'sql'}{'table'}{$table}{$a}{'order'} }
            keys %{ $config{'sql'}{'table'}{$table} };
          psmisc::printu lang('page'), ': <input type="text" id="page" name="page" size="2" ', value( $param->{'page'} ),
            '/> ';
          #(или "rnd")
          #print ' Показать данную страницу, если rnd - то случайную' if $param->{'help'};
          print $config{'sel_sep'}, '<select id="distinct" name="distinct" dir="ltr" ><option value="">', lang('distinct'),
            '</option>',
            map( {
                  '<option value="'
                . $_ . '" '
                . ( $param->{'distinct'} eq $_ ? 'selected="selected"' : '' ) . '>'
                . lang($_)
                . '</option>'
            } sort { $config{'sql'}{'table'}{$table}{$b}{'order'} <=> $config{'sql'}{'table'}{$table}{$a}{'order'} }
              grep { $config{'sql'}{'table'}{$table}{$_}{'sort'} or $config{'sql'}{'table'}{$table}{$_}{'index'} }
              keys %{ $config{'sql'}{'table'}{$table} } ),
            '</select>'
            unless $config{'no_distinct'};
          part( 'form-reset', $param, $table, undef, undef, $work{'paramnum'}, $work{'valuenum'} );
          part( 'form-clear', $param, $table, undef, undef, $work{'paramnum'}, $work{'valuenum'} );
        }
        print $config{'sel_sep'},
          mylink( lang('thislink'), { get_param_hash($param), 'form' => 1 },
          undef, { 'destroy' => $config{'destroy_link_view'} } )
          if !$config{'no_thislink'} and $fparam->{'hide_link'};
        print '</div >' if defined( $work{'paramnum'} );
        unless ( $config{'no_js'} ) {

=no js placeholder
		  print $config{'jscript_open'},
            #'if(document.getElementById) {',
            (
            map {
           #'var ph' . $_ . $work{'paramnum'} . ' = new InputPlaceholder (document.getElementById (\'' . $_ . $work{'paramnum'},
              'var ph' . $_ . $work{'paramnum'} . ' = new InputPlaceholder (gid(\'' . $_ . $work{'paramnum'},
                '\'), \'' . lang($_) . '\', \'\', \'input-help\');',
#"\n",
#'gid(\'' . $_ . $work{'paramnum'}, '\').addEventListener(\'change\', function (e) {alert(se);gid(\'page\').value = 1;}, false);'
              } grep {
              $config{'sql'}{'table'}{$table}{$_}{'nav_field'}
              } keys %{ $config{'sql'}{'table'}{$table} }
            ),
            #"}",
            $config{'jscript_close'} if !$config{'no_placeholder'} and $config{'input_help'} > $work{'paramnum'};
=cut          

          if ( $work{'specify'} eq 'off' ) {
            print $config{'jscript_open'}, "allow_show_adv_auto = 0;", $config{'jscript_close'};
          } else {
            print $config{'jscript_open'}, "show_adv(", ( $work{'specify'} eq 'auto' ), ");", $config{'jscript_close'}
              if (
              !defined( $work{'paramnum'} )
              and (
                $work{'specify'} eq 'on'
                or ( (
                    @_ = (
                      grep( $param->{$_},
                        grep( $config{'sql'}{'table'}{$table}{$_}{'nav_field'}, keys %{ $config{'sql'}{'table'}{$table} } ),
                        @{ $config{'param_advanced'} } ),
                      grep defined( $param->{$_} ),
                      @{ $config{'param_advanced_num'} }
                    )
                  )
                  and !(
                       $config{'no_index'}
                    or $config{'ignore_index'}
                    or $config{'table_param'}{$table}{'no_index'}
                    or $config{'table_param'}{$table}{'ignore_index'}
                  )
                )
              )
              );
          }
        }
        print "</div>";
        ++$work{'one'}{$_} for grep {
          $work{'paramnum'} ne 0
            and !( $param->{'q'} and $static{'db'}->{'disable_slow'} )
            and $param->{ $_ . $work{'valuenum'} }
            and $param->{ $_ . $work{'valuenum'} } !~ /((^|\s)!)|[*]/
        } keys %{ $config{'sql'}{'table'}{$table} };
        $work{'paramnum'} += ( defined( $work{'paramnum'} ) ? 1 : 0 );
        $work{'valuenum'} = $work{'paramnum'} - ( $param->{'search_prev'} ? 1 : 0 );
        --$work{'valuenum'} if $work{'paramnum'} eq 0 and !$param->{'search_prev'};
        $work{'valuenum'} = undef if $work{'valuenum'} < 0;
        part( 'one-query', $param, $table, undef, { 'no_cont' => 1 } ) unless $config{'no_second_query'};
      };
      $config{'out'}{'html'}{'head'} ||= sub {
        my ( $param, $table ) = @_;
        print  #'<?xml version="1.0"?>',
               #'<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">',
               #'<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">',
               #'<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN">',
          '<!DOCTYPE html><html><head>';
#'<html xmlns="http://www.w3.org/1999/xhtml" lang="' . lang('language-code') . '" xml:lang="' . lang('language-code') . '">';
#print '<head>';
#print map { '<META HTTP-EQUIV="Set-Cookie" CONTENT="' . $_ . '=' . encode_url($param->{$_}) . '; EXPIRES=Friday,31-Dec-15 23:59:59 GMT;"/>' } grep $param->{$_}, @{ $config{'user_param_save'} } ;# if $param->{'param_save'} # DOMAIN=domain_name; PATH=path;  SECURE
        part( 'head-head', $param, $table, undef, { 'no_cont' => 1 } );    #
        print '<meta http-equiv="Content-Type" content="text/html; charset=', lang( $work{'codepage'} ), '"/>',
          '<meta http-equiv="Content-Language" content="', lang('language-code'), '"/>', '<meta name="language" content="',
          lang('language-code'), '"/>';
        print '<meta http-equiv="refresh" content="', $config{'redirect_sleep'}, '; URL=', encode_url_link( $param->{'go'} ),
          '">'
          if $param->{'go'};
        print "<title>";
        psmisc::printall( $config{'title'} );
        print( ( $param->{'q'} ? destroy_html(" : $param->{'q'}") : '' ), '</title>' );
        psmisc::printall( \$config{'html_head'}, $param );

=old
    print '<link rel="stylesheet" media="screen"  title="', $config{'style'}, '" href="', $config{'css_url'}, $config{'css_list'}{$config{'style'}}, '" type="text/css"/>';
    print '<link rel="stylesheet" media="screen"  title="', $config{'style'}, '" href="', $config{'css_url'}, $config{'css_list_add'}{$config{'style'}}, '" type="text/css"/>' if $config{'css_list_add'}{$config{'style'}};
    print '<link rel="alternate stylesheet" media="screen"  title="', $_, '" href="', $config{'css_url'}, $config{'css_list'}{$_}, '" type="text/css"/>' ,
    ($config{'css_list_add'}{$_} ? ('<link rel="alternate stylesheet" media="screen"  title="', $_, '" href="', $config{'css_url'}, $config{'css_list_add'}{$_}, '" type="text/css"/>') : ())
     for grep {$_ ne $config{'style'}} keys %{ $config{'css_list'} };
=cut

        cache_file_css( {
            'pre_url'    => '<link rel="stylesheet" media="screen" type="text/css" title="' . $work{'style'} . '" href="',
            'pre_cached' => '<style rel="stylesheet" media="screen" type="text/css" title="' . $work{'style'} . "\" >",
          },
          $config{'css'},
          $config{'css_add'}
        );

=temp disabled
    cache_file_css({'pre_url'=> '<link rel="alternate stylesheet" media="screen"  title="' . $_ . '" type="text/css" href="',
    'pre_cached'=> '<style rel="alternate stylesheet" media="screen" type="text/css" title="' . $_ . "\" >", #<!--\n
#}, $config{'css_list'}{$_}, $config{'css_list_add'}{$_}
#) for grep {$_ ne $config{'style'}} keys %{ $config{'css_list'} };
    }, $config{$_}{'css'}, $config{$_}{'css_add'}
    ) for grep {$_ ne $work{'style'}} @{ $config{'styles'} };
=cut

        print '<link rel="alternate" type="application/rss+xml" title="RSS version" href="',
          get_param_url_str( $param, ['view'] ), '&amp;view=rss2"/>'
          if !$config{'destroy_link_view'}
            and $param->{'order'}
            and $config{'out'}{'rss2'}{'result_string'};
        #<link rel="first" title="Первая страница" href="/">
        #<link rel="prev" title="Предыдущая страница" href="/">
        unless ( $config{'no_js'} ) {
          print $config{'jscript_open'};
          sub js_quote { return $_[0] =~ /^\d+$/ ? $_[0] : "'$_[0]'" }
          print map { "var $_=" . js_quote( $config{$_} or 0 ) . ";" } grep { $_ } @{ $config{'js_config'} || [] };
          print map { "var $_=" . js_quote( $work{$_}   or 0 ) . ";" } grep { $_ } @{ $config{'js_work'}   || [] };
          print map { "var lang_$_='" . lang($_) . "';" } grep { $_ } @{ $config{'js_lang'} } unless $config{'no_img'};
          print $config{'jscript_close'};
          cache_file_js( undef, @{ $config{'js_list'} || [] } );
        }
        print '</head><body ' . $config{'html_body_params'} . '>';
        $work{'param_str'} = get_param_url_str( $param, $config{'skip_from_link'} );
      };
      $config{'out'}{'html'}{'loading'} ||= sub { };
      $config{'out'}{'html'}{'lang-select'} ||= sub {
        my ($param) = @_;
        if ( scalar keys %{ $config{'lng'} || {} } > 1 ) {
          print lang('lang'), ': ' if !$config{'no_select_describe'};
          print "<ul>";
          for my $lang ( sort grep { $_ } keys %{ $config{'lng'} } ) {
            print "<li>",
              mylink(
              lang($lang),
              { get_param_hash($param), 'lang' => $lang },
              {
                'title'   => lang('lang') . ' ' . lang($lang),
                'class'   => 'lang' . ( $lang eq $work{'lang'} ? ' selected' : '' ),
                'onclick' => qq{createCookie('lang', '$lang');window.location.reload(false);},
                ( $lang eq $work{'lang'} ) ? ( 'href' => undef ) : ()
              },
              { 'destroy' => $config{'destroy_link_lang'} }
              ),
              "</li>";
#print "N&f;<a class=\"lang\"  ";
#my $notcurlng;
#print 'href="#"' if $notcurlng = $lang ne $work{'lang'};
#print ' ' . $config{'js_debug'} . 'onclick="createCookie(\'lang\', \'', $lang,'\');window.location.reload(false);">', lang($lang), '</a>';
          }
          print "</ul>";
        }
      };
      $config{'out'}{'html'}{'cp-select'} ||= sub {
        my ( $param, $table ) = @_;
        local @_ = ();
        if (
          scalar( $config{'lng'}{ $work{'lang'} }{'codepages'} ? @{ $config{'lng'}{ $work{'lang'} }{'codepages'} } : @_ ) > 1 )
        {
          print "(";    #. $work{'codepage'};
          print lang('cp'), ': ' if !$config{'no_select_describe'};
          print join ' ', map {
            "<a class=\"codepage\" "
              . ( $_ ne $work{'codepage'} ? "href=\"#\" " : ' ' ) . ' '
              . $config{'js_debug'}
              . 'onclick="createCookie(\'codepage\', \''
              . $_
              . '\');window.location.reload(false);"'
              . ">", $_, "</a>"
          } sort ( $config{'lng'}{ $work{'lang'} }{'codepages'} ? @{ $config{'lng'}{ $work{'lang'} }{'codepages'} } : @_ );
          print ")";
        }
      };
      $config{'out'}{'html'}{'mode-select'} ||= sub {
        my ( $param, $table ) = @_;
        if ( scalar @{ $config{'modes'} || [] } > 1 ) {
          print lang('mode'), ': ' if !$config{'no_select_describe'};
          #print ' <a ', ( $_ ne $work{'mode'} ? ' href="#" ' : ' ' ),
          #  ' ' . $config{'js_debug'} . 'onclick="createCookie(\'mode\', \'', $_, '\');',
          #  'window.location.reload(false);" title="', lang('mode'), ' ', $_, '">', lang($_), '</a>'
          #  for sort @{ $config{'modes'} };
          print ' ',
            mylink(
            lang($_),
            { get_param_hash($param), 'mode' => $_ },
            {
              'title'   => lang('mode') . " $_",
              'onclick' => qq{createCookie('mode', '$_');window.location.reload(false);},
              ( $_ eq $work{'mode'} ) ? ( 'href' => undef ) : ()
            },
            { 'destroy' => $config{'destroy_link_mode'} }
            ) for sort @{ $config{'modes'} };
        }
      };
      $config{'out'}{'html'}{'style-select'} ||= sub {
        my ( $param, $table ) = @_;
        if ( scalar @{ $config{'styles'} || [] } > 1 ) {
          print lang('style'), ': ' if !$config{'no_select_describe'};
          print ' <span class="a" ', (
            $work{'style'} ne $_
            ? (
              'href="#" ' . $config{'js_debug'} . 'onclick="createCookie(\'style\', \'',
              $_,
              '\');'
                . (
                ( $config{'style_change_reload'} or $config{$_}{'style_change_reload'} )
                ? 'window.location.reload(false);'
                : ( 'setActiveStyleSheet(\'', $_, '\');' )
                )
                . '" '
              )
            : ''
            ),
            'title="', lang('style'), ' ', $_, '">', lang($_), '</span>'
            for $work{'style'}, sort grep { !$config{$_}{'hide'} and $_ ne $work{'style'} } @{ $config{'styles'} };
        }
      };
      $config{'out'}{'html'}{'view-select'} ||= sub {
        my ( $param, $table ) = @_;
        part( 'lang-select',  $param, $table );
        part( 'cp-select',    $param, $table );
        part( 'style-select', $param, $table );
        part( 'mode-select',  $param, $table );
      };
      $config{'out'}{'html'}{'search-form-input'} ||= sub {
        my ( $param, $table ) = @_;
        print '<input type="hidden" name="', $_, '" ', value( $param->{$_} ), ' />'
          for ( @{ $config{'user_param_hidden'} }, @{ $config{'user_param_save_hidden'} }, qw(distinct live live_mode) );
        part( 'one-query', $param, $table, { 'hide_link' => 1 } );
        print '</div>';    # opened in one-query, advanced search - hidden
      };
      $config{'out'}{'html'}{'pre-search-form'} ||= sub {
        my ( $param, $table ) = @_;
        #print "z";
        part( 'form-links',  $param, $table );
        part( 'form-adjust', $param, $table );
        part( 'view-select', $param, $table );
      };
      $config{'out'}{'html'}{'similar-query'} ||= sub {
        my ( $param, $table, $fparam ) = @_;
        local $_ = $param->{'q'};
        s/\s*\S+:\S+\s*//g;
        return unless $_;
#printlog( "WH:", $static{'db'}->where( { %$param, 'query' => $param->{'q'}, 'query_mode' => '!' }, undef, $config{'sql_tquerystat'} ));
        local $param->{'page'} = undef;
        local $param->{'q'}    = scalar cp_trans( $work{'codepage'}, $config{'cp_db'}, $param->{'q'}, );
        local $work{'query'}   = {};
        local $work{'word'}    = {};
        #printlog('dev', "qstat", Dumper($param));
        part(
          'query',
          { %$param, 'order' => '', },
          $config{'sql_tquerystat'}, {
            'where' => $static{'db'}->where( {
                %$param,
                'query' => $param->{'q'},
                #'query'  => scalar cp_trans( $work{'codepage'}, $config{'cp_db'}, $param->{'q'}, ),
                'query_mode' => '!'
              },
              undef,
              $config{'sql_tquerystat'}
            ),
            'no_desc' => 1,
            'desc'    => lang('similar requests') . ': '
          }
        );
      };
      $config{'out'}{'html'}{'result_error'} ||= sub {
        my ( $param, $table, $error ) = @_;
        print ucfirst lang('sorry');
        if   ( $error eq 'timeout' ) { print ', ', lang('the database is busy right now'); }
        else                         { print ', ', lang('database error'); }
        print '. <a href="javascript:location.reload()">', lang('reload the page'), '</a>, ',
          lang('change your query or try again later'), '.';
      };
      $config{'out'}{'html'}{'result_head'} ||= sub {
        my ( $param, $table, $row ) = @_;
        psmisc::printall( \$config{'html_result_header_top'}, $param ) unless $param->{'no_result_header'};
        $work{'n'} = $static{'db'}->{'limit_offset'};
        print '<table class="result-table" ';
        psmisc::printall( \$config{'html_result-table_param'}, $param );
        print '>';
        return if $param->{'no_result_header'};
        if ( $config{'one_string'} and keys %{ $work{'one'} } ) {
          local $work{'n'} = -1;
          my (%string) = (%$param);
          delete $string{$_} for grep ( ( $work{'one'}{$_} != 1 ), keys %string );
          $string{'full'} = join_url( \%string );
          local $work{'one'}                = ();
          local $config{'allow_vote'}       = 0;
          local $config{'no_dir_word'}      = 1;
          local $config{'allow_pinger'}     = 0;
          local $config{'no_rel_path_link'} = 0;
          part( 'result_string_pre',  $param, $table, \%string, { 'no_cont' => 1 } );
          part( 'result_string',      $param, $table, \%string, { 'no_cont' => 1 } );
          part( 'result_string_post', $param, $table, \%string, { 'no_cont' => 1 } );
        }
        print '<tr class="result-head"><td>N</td>';
        if ( $param->{'distinct'} ) { print '<td>', $param->{'distinct'}, '</td>'; }
        else {
          #print "HI";
          my %ord_param_hash = get_param_hash( $param, ( 'order', 'order_mode', 'page' ) ) unless $config{'destroy_link_sort'};
          #for my $rown ( sort keys %{ $config{'sql'}{'table'}{$table} } ) {
          for my $rown ( sort { $config{'sql'}{'table'}{$table}{$b}{'order'} <=> $config{'sql'}{'table'}{$table}{$a}{'order'} }
            grep { $config{'sql'}{'table'}{$table}{$_} and !$config{'sql'}{'table'}{$table}{$_}{'hide'} } keys %$row )
          {
            print '<td>';
            #print "zz";
            psweb::sorter( $param, { 'order' => $rown }, \%ord_param_hash );
            print '</td>';
          }
          print '</tr>';
        }
      };
      $config{'out'}{'html'}{'result_string'} ||= sub {
        my ( $param, $table, $row ) = @_;
        $row->{'n'} = ++$work{'n'};
        print "<tr><td>$row->{'n'}</td>";
        for my $rown ( sort { $config{'sql'}{'table'}{$table}{$b}{'order'} <=> $config{'sql'}{'table'}{$table}{$a}{'order'} }
          grep { $config{'sql'}{'table'}{$table}{$_} and !$config{'sql'}{'table'}{$table}{$_}{'hide'} } keys %$row )
        {
          print '<td>';
          $config{'sql'}{'table'}{$table}{$rown}{'show'}
            ? psmisc::printall( $config{'sql'}{'table'}{$table}{$rown}{'show'}, $row->{$rown} )
            : print mylink(
            $row->{$rown}, {
              $rown => $row->{$rown},
              #'size_mode' => 'e'
            }, {
              #'title' => "$row->{'size'} bytes",
              ( $row->{$rown} == $param->{$rown} ? ( 'class' => 'hilight1' ) : () ),
              #( $row->{'files'}                    ? ( 'href'  => undef )      : () )
            },
            #{ 'destroy' => $config{'destroy_link_size'}, }
            ) if $row->{$rown};
          print '</td>';
        }
        #print "<td>[$row->{'stem'}]</td>";
        print "</tr>";
        #local $row->{'size'} = undef if $row->{'size'} ==1;
        #print "<tr><td colspan='20'>";
        $work{'head'}{$_} += ( $row->{$_} =~ /^\s*\d+\s*$/ ? $row->{$_} : ( $row->{$_} =~ /\S/ ? 1 : 0 ) ),
          #print("$_ = $work{'head'}{$_};")
          for
          grep { ( $config{'sql'}{'table'}{$table}{$_}{'row'} or !$config{'sql'}{'table'}{$table}{$_}{'hide'} ) and $row->{$_} }
          keys %{ $config{'sql'}{'table'}{$table} };
        #print "</td></tr>";
      };
      $config{'out'}{'html'}{'result_foot'} ||= sub {
        my ( $param, $table ) = @_;
        print '</table>';
        part( 'result_foot_hide', $param, $table );
      };
      $config{'out'}{'html'}{'result_foot_hide'} ||= sub {
        my ( $param, $table ) = @_;
        print $config{'jscript_open'};
        print 'toggleview(\'head_', $_, '\');' for grep {
          ( $config{'sql'}{'table'}{$table}{$_}{'row'} or !$config{'sql'}{'table'}{$table}{$_}{'hide'} )
            and ( !$work{'head'}{$_} or $work{'n'} < 1 )
        } keys %{ $config{'sql'}{'table'}{$table} };
        print $config{'jscript_close'};
      };
      $config{'out'}{'html'}{'result-report'} ||= sub {
        my ( $param, $table ) = @_;
        print lang('found'), ' '
          if $stat{'found_time'} > 0
            or $static{'db'}->{'founded'} > 0
            or $static{'db'}->{'stat'}{'found'}{'size'} > 0
            or !$stat{'results'};
        print " $static{'db'}->{'founded'} ", lang('files'), ' ' if $static{'db'}->{'founded'} > 0 or !$stat{'results'};
        psmisc::printu " $stat{'found'}{'size'} ", lang('bytes'),
          ( $static{'db'}->{'stat'}{'found'}{'size'} > 1000
          ? ' (' . psmisc::human( 'size', $static{'db'}->{'stat'}{'found'}{'size'} ) . ')'
          : ' ' )
          if $static{'db'}->{'stat'}{'found'}{'size'} > 0;
        psmisc::printu ' ', lang('in'), ' ', psmisc::human( 'time_period', $stat{'found_time'} ), ' '
          if $stat{'found_time'} > 0;
        print ', ', lang('showed'), ' ',
          ( $static{'db'}->{'dbirows'} ? $static{'db'}->{'limit_offset'} + 1 : $static{'db'}->{'limit_offset'} ) . '-'
          . ( $static{'db'}->{'founded'} > $static{'db'}->{'limit_offset'} + $static{'db'}->{'limit'}
          ? $static{'db'}->{'limit_offset'} + $static{'db'}->{'limit'}
          : ( $static{'db'}->{'founded'} or $static{'db'}->{'limit_offset'} + $static{'db'}->{'dbirows'} ) )
          . ( $static{'db'}->{'page'}
          ? ' (' . lang('page') . " $static{'db'}->{'page'} " . lang('from') . " $static{'db'}->{'page_last'})"
          : '' )
          if $static{'db'}->{'page_last'} > 1;
        print '<br/>';
        #printlog('d', Dumper($param));
        part(
          'gotopage',
          $param, $table, {
            'current'   => $static{'db'}->{'page'},
            'total'     => $static{'db'}->{'founded'},
            'actual'    => $static{'db'}->{'dbirows'},
            'size'      => $static{'db'}->{'limit'},
            'last'      => $static{'db'}->{'page_last'},
            'total_max' => $static{'db'}->{'founded_max'},
          }
        );
        part( 'viewas', $param, $table ) if $static{'db'}->{'founded'};
        if ( ( $static{'db'}->{'dbirows'} > 0 or $static{'db'}->{'founded'} > 0 ) and $static{'db'}->{'limit'} > 0 ) {
          print $config{'jscript_open'}, q{toggleview('form-in-founded');}, $config{'jscript_close'} if $param->{'page'} <= 1;
        } else {
          psmisc::printall( \$config{'no_results_insert'}, $param );
        }
      };
      $config{'out'}{'html'}{'gotopage'} ||= sub {
        my ( $param, $table, $fparam ) = @_;
        #printlog('dev' , "gtp",  Dumper($fparam));
        my $gotopage = gotopage($fparam);    #$param,
        #printlog('dev' , "gtp", gotopage($fparam), Dumper($fparam));
        return unless keys %$gotopage;
        #print "GOOO";
        print lang('goto page') . ' ';
        my %param_hash = get_param_hash( $param, 'page' );
        #printlog('d', Dumper($param,\%param_hash));
        print ' ',
          mylink(
          lang('ctrl-prev') . ' ' . lang('prev'),
          { %param_hash, ( $_ == 1 ? () : 'page' => $_ ) },
          { 'id'      => 'prev_page', 'title' => $gotopage->{'prev'}->{$_} },
          { 'destroy' => $config{'destroy_link_page'} }
          ),
          ' '
          for sort { $a <=> $b } keys %{ $gotopage->{'prev'} };
        print ' ', mylink(
          $_,
          { %param_hash, ( $_ == 1 ? () : 'page' => $_ ) },
          { 'title' => $gotopage->{'big'}->{$_}, ( $fparam->{'current'} == $_ ? ( 'href' => undef ) : () ) },
          {
            'destroy' => $config{'destroy_link_page'},
            #( $fparam->{'current'} == $_ ? ( 'href' => 'NO' ) : () )
          }
          ),
          ' ' for sort {
          $a <=> $b
          } keys %{ $gotopage->{'big'} };
        print ' ',
          mylink(
          $_,
          { %param_hash, 'page' => $_ },
          { 'class'   => 'unknownlink', 'title' => $gotopage->{'small'}->{$_} },
          { 'destroy' => $config{'destroy_link_page'}, }
          ),
          ' '
          for sort { $a <=> $b } keys %{ $gotopage->{'small'} };
        print ' ',
          mylink(
          lang('next') . ' ' . lang('ctrl-next'),
          { %param_hash, 'page' => $_ },
          { 'id'      => 'next_page', 'title' => $gotopage->{'next'}->{$_} },
          { 'destroy' => $config{'destroy_link_page'}, }
          ),
          ' '
          for sort { $a <=> $b } keys %{ $gotopage->{'next'} };
      };
      $config{'out'}{'html'}{'viewas'} ||= sub {
        my ( $param, $table ) = @_;
        print '[';
        #printlog('vi', $config{'view'}, $param->{'view'});
        print ' ', mylink(
          lang($_), { get_param_hash( $param, 'view' ), 'view' => $_ }, undef,
     #{ 'destroy' => $config{'destroy_link_view'}, ( ( $_ ne 'html' and $config{'view'} ne $_ ) ? () : ( 'href' => 'NO' ) ) } ),
          { 'destroy' => $config{'destroy_link_view'} || ( ( $_ ne 'html' and $config{'view'} ne $_ ) ? ('') : ('YES') ) }
          ),
          ' '
          for ( sort grep { $_ and !$config{'out'}{$_}{'hide'} } keys %{ $config{'out'} } );
        print ']';
      };
      $config{'out'}{'html'}{'stat'} ||= sub {
        my ($param) = @_;
        part( 'main-topquery', $param, undef, { 'no_split' => 1, 'no_result_header' => 1, 'no_gotopage' => 1 } )
          if $config{'allow_query_stat'};
        part( 'main-stat', $param );
        part( 'main-top-stat', $param, undef, { 'no_gotopage' => 1 } );
      };
      $config{'out'}{'html'}{'main'} ||= sub {
        my ( $param, $table, ) = @_;
        part( 'stat', $param );
        part( 'examples', $param, $table );
      };
      $config{'out'}{'html'}{'main-top-stat'} ||= sub {
        my ( $param, $table, $fparam ) = @_;
        part( 'top', $param, undef, $fparam );
      };
      #$config{'out'}{'html'}{'footer-stat'} ||= sub {
      $config{'html_footer_stat_bef'} //= '<!-- ';
      $config{'html_footer_stat_aft'} //= ' -->';
      $config{'out'}{'html'}{'footer_stat'} ||= sub {
        my ($param) = @_;
        print $config{'foot_stat_sep'};
        print '[', psmisc::human( 'date_time', ), ']', $config{'foot_stat_sep'};
        print 'this page generated in ', ( psmisc::human( 'time_period', $work{'page_start'}->() ) or '0s' ),
          $config{'foot_stat_sep'}
          if $work{'page_start'};
        print 'with ', ( $static{'db'}->queries() || 0 ), ' queries (',
          psmisc::human( 'time_period', $static{'db'}->{'queries_time'} ), ')',, $config{'foot_stat_sep'}, ' perl ',
          psmisc::human( 'time_period', $work{'page_start'}->() - $static{'db'}->{'queries_time'} ), $config{'foot_stat_sep'}
          if $static{'db'}
            and $static{'db'}->queries()
            and $work{'page_start'};
        print 'MP:', $$, ' SP:', $static{'runs'}, ' UP:',
          ( psmisc::human( 'time_period', $static{'script_start'}->() ) or '0s' ), $config{'foot_stat_sep'}
          if $ENV{'MOD_PERL'} || $ENV{'FCGI_ROLE'};
        print $work{'counter'}{'total'}, ' hits [', $work{'counter'}{'pday'}, ':', $work{'counter'}{'day'}, ']',
          $config{'foot_stat_sep'}
          if $work{'counter'}{'total'};
      };
      $config{'out'}{'html'}{'footer'} ||= sub {
        my ($param) = @_;
        part( 'footer_stat', $param, undef, undef, { 'no_cont' => 1 } );
        psmisc::printu '    ';
      };
      $config{'out'}{'html'}{'item_info'} ||= sub {
        my ($row) = @_;
        local @_ = (
          !$config{'no_query_count'} && $$row{'top'} ? $$row{'top'} : (),
          !$config{'no_query_dl'}    && $$row{'dl'}  ? $$row{'dl'}  : (),
          !$config{'no_query_time'} && $$row{'last'} ? psmisc::human( 'time_period', time() - $$row{'last'} ) : (),
          !$config{'no_query_ip'} && $$row{'lastip'} ? $$row{'lastip'} : ()
        );
        print '[', join( ',', @_ ), '] ' if @_;
      };
      for my $stat (qw(word query)) {
        #$config{'out'}{'html'}{'string'}{$stat} ||= sub {
        $config{'out'}{'html'}{ 'string_' . $stat } ||= sub {
          #my ( $row, $param ) = @_;
          my ( $param, undef, $row, ) = @_;
          #cp_trans_row($row);
          #printlog( "zzz",Dumper($row));
          print mylink(
            psmisc::human( 'string_long', $$row{$stat}, 30 ),
            { 'q' => $$row{$stat} },
            undef, { 'destroy' => $config{'destroy_link_top'} }
            ),
            ' ';
          part( 'item_info', $row, undef, undef, { 'no_cont' => 1 } );
          #print ' (', ( $param->{'order'} eq 'top' ? ( $$row{'top'} ) : () ),
          #( $param->{'order'} eq 'last' ? ( psmisc::human( 'time_period', time() - $$row{'last'} ) ) : () ), ')'
          #if $param->{'order'};
          #print ' ';
        };
      }
      #$config{'out'}{'html'}{'string'}{'file'} ||= sub {
      $config{'out'}{'html'}{'string_file'} ||= sub {
        #my ( $row, $param ) = @_;
        my ( $param, undef, $row, ) = @_;
        my %url = split_url( $$row{'file'} );
        #print "========",join':',%$row;
        #print "====", $work{'codepage'}, $$row{'cp'}||hconfig( 'cp_res', $url{'host'}, $url{'prot'} );

=direct links
        print $config{'redirector'}->( {
#'go' => scalar psmisc::cp_trans($work{'codepage'}, $$row{'cp'} || hconfig( 'cp_res', $url{'host'}, $url{'prot'} ), $$row{'file'}),
            'go' => scalar psmisc::encode_safe( $$row{'cp'} || hconfig( 'cp_res', $url{'host'}, $url{'prot'} ), $$row{'file'} ),
            'actname' => part( 'result_string_img', undef, undef, { 'ext' => $url{'ext'}, size => 1 }, { 'no_cont' => 1 } )
              . join_url( {
                'name' => psmisc::human( 'string_long', $url{'name'}, 25 ),
                'ext'  => psmisc::human( 'string_long', $url{'ext'},  5 )
              }
              )
          }
        );
=cut

        print mylink(
          part( 'result_string_img', undef, undef, { 'ext' => $url{'ext'}, size => 1 }, { 'no_cont' => 1 } )
            . join_url( {
              'name' => psmisc::human( 'string_long', $url{'name'}, 25 ),
              'ext'  => psmisc::human( 'string_long', $url{'ext'},  5 )
            }
            ),    #{%url, 'prot'=>undef, 'host'=>undef, 'user'=>undef, 'pass'=>undef, 'path'=>undef}
          #{'q'=> $$row{'file'} ,}
          { 'name' => $url{'name'}, 'ext' => $url{'ext'}, },
          undef,
          { 'destroy' => $config{'destroy_link_file'} },
        );
        part( 'item_info', $row, undef, undef, { 'no_cont' => 1 } );
        #item_info($row);
        #print '', ( ( $config{'show_query_ip'} and $$row{'lastip'} ) ? '[' . $$row{'lastip'} . ']' : '' );
        #print ' (', ( $param->{'order'} eq 'dl' ? ( $$row{'dl'} ) : () ),
        #( $param->{'order'} eq 'last' ? ( psmisc::human( 'time_period', time() - $$row{'last'} ) ) : () ), ')'
        #if $param->{'order'};
        #print ' ';
      };
      for my $stat (qw(file word query)) {
        $config{'out'}{'html'}{$stat} ||= sub {
          my ( $param, $table, $fparam ) = @_;
          $table = $config{ 'sql_t' . $stat . 'stat' };
          #printlog( 'dev', "fwq: $stat, $table;" , Dumper($param));
          #$param->{'on_page'} =
          $static{'db'}->user_params($param);
          local $static{'db'}->{'limit'} = check_int( $param->{'results'}, 1, $config{'top_query_max'}, $config{'top_query'} );
          $param->{'order'}      = 'top' unless defined $param->{'order'};
          $param->{'order_mode'} = '!'   unless defined $param->{'order_mode'};
          local $static{'db'}->{'disable_slow'} = 0;    #!
#?          local $config{'sql'}{'database'} =            ref $config{'sql_base_up'} eq 'HASH' ? $config{'sql_base_up'}{'database'} : $config{'sql_base_up'};
          local $config{'allow_null_count'} = 1;
          $static{'db'}->count( $param, $table ),
            $stat{'top_founded_max'} = max( $stat{'top_founded_max'}, $stat{'found'}{'files'} ),
            $stat{'top_pages_max'}   = max( $stat{'top_pages_max'},   $static{'db'}->{'page_last'} )
            unless $fparam->{'no_gotopage'};
          #printlog( 'dev', 'fwq0' );
          my $top = $static{'db'}->query( $static{'db'}->select_body( $fparam->{'where'}, $param, $table ) )
            #my $top = $static{'db'}->select( $static{'db'}->select_body( $fparam->{'where'}, $param, $table ) )
            if $static{'db'}->{'limit'};
          #$param->{'on_page'};
          #printlog( 'dev', 'fwq1', $top );
          if ( $static{'db'}->{'limit'} and $top and scalar @$top >= 1 and keys %{ $top->[0] } ) {
            print $fparam->{'desc'};
            print lang( $stat . ' ' . $param->{'order'} ) unless $fparam->{'no_desc'};
            print ' (', mylink( '100', { 'show' => 'topquery', 'results' => '100' } ), ')' if $fparam->{'link_100'};
            print ':', ( $fparam->{'no_split'} ? ' ' : '<br/>' ) unless $fparam->{'no_desc'};
            #$config{'out'}{'html'}{'string'}{$stat}->( $_, $param ) for (@$top);
            #$config{'out'}{'html'}{'string_'.$stat}->( $param,$_,  ) for (@$top);
            part( 'string_' . $stat, $param, undef, $_, { 'no_cont' => 1 } ) for (@$top);
          }
        };
      }
      for my $stat (qw(queries dls)) {
        $config{'out'}{'html'}{$stat} ||= sub {
          my ( $param, $table, $fparam ) = @_;
          return unless @{ $work{$stat} };
          print lang( 'my ' . $stat ), ': ';
          my $output = $stat eq 'dls' ? 'file' : 'query';
          #$config{'out'}{'html'}{'string_'.$output}->(  { %$param, 'order' => undef }, { $output => $_ }, )
          part( 'string_' . $output, { %$param, 'order' => undef }, undef, { $output => $_ }, { 'no_cont' => 1 } )
            for ( @{ $work{$stat} } );
          print ' [<a href="#" ' . $config{'js_debug'} . 'onclick="createCookie(\'', $stat, '\', \'\');hide_id(\'', $stat,
            '\');', $stat, '_cleared = 1; return false;">', lang('clear'), '</a>] ';
        };
      }
      $config{'out'}{'html'}{'main-topquery'} ||= sub {
        my ( $param, $table, $fparam ) = @_;
        print( ucfirst( lang('queries') ), ' 10 (', mylink( '100', { 'show' => 'topquery', 'results' => '100' } ), ') :' );
        part( 'topquery', $param, undef, $fparam ) if $config{'allow_query_stat'};
      };
      $config{'out'}{'html'}{'topquery'} ||= sub {
        my ( $paramorig, $table, $fparam ) = @_;
        my $param = {%$paramorig};
        #printlog('dev', 'topq', $paramorig, $table, $fparam);
        $fparam->{'no_gotopage'} = 1 unless $config{'topquery_gotopages'};
        psmisc::printall( \$config{'html_result_header_top'}, $param, $fparam ) if !$fparam->{'no_result_header'};
        my $delim = ( $fparam->{'no_split'} ? '' : '<br/>' );
        #print $delim;
        #part( 'word', $param, $table, $fparam );
        print $delim;
        part( 'query', $param, $table, $fparam );
        if ( $config{'allow_topfiles'} ) {
          print $delim;
          $param->{'order'} = 'dl';
          part( 'file', $param, $table, $fparam );
        }
        psmisc::printall $config{'html_topquery_split'};
        {
          $param->{'order'} = 'last';
          $param->{'count_f'} = 'on' unless $fparam->{'no_gotopage'};
          part( 'query', $param, $table, $fparam );
          delete $param->{'order'};
        }
        if ( $config{'allow_topfiles'} ) {
          print $delim;
          $param->{'order'} = 'last';
          part( 'file', $param, $table, $fparam );
        }
        for my $q (qw(queries dls)) {
          print $delim;
          part( $q, $param, $table, $fparam, { 'cont_param' => 'id="' . $q . '"' } );
        }
        part(
          'gotopage',
          $paramorig,
          undef, {
            'current'  => $param->{'page'},
            'buttonsb' => $config{'topquery_gotopages'},
            'buttonsa' => $config{'topquery_gotopages'},
            'total'    => $stat{'top_founded_max'},
            'actual'   => $static{'db'}->{'limit'},
            'size'     => $static{'db'}->{'limit'},
            'last'     => $stat{'top_pages_max'}
          }
        ) unless $fparam->{'no_gotopage'};
      };
      $config{'out'}{'html'}{'presets'} ||= sub {
        my ($param) = @_;
        for my $sets ( sort keys %{ $config{'preset'} } ) {
          print lang($sets), ":<br/>";
          for my $preset ( sort { $config{'preset'}{$sets}{$a}{'order'} <=> $config{'preset'}{$sets}{$b}{'order'} }
            keys %{ $config{'preset'}{$sets} } )
          {
            psmisc::printu ' ', mylink( $preset, { 'q' => ':' . $preset } ), ":\t ";
            print join ' & ',
              map { "$_=$config{'preset'}{$sets}{$preset}{'set'}{$_}" } sort keys %{ $config{'preset'}{$sets}{$preset}{'set'} };
            print '<br/>';
          }
        }
      };
      $config{'out'}{'html'}{'empty'} ||= sub { };
      $config{'out'}{'m3u'}{'http-header'} =
        "Content-type: audio/x-mpegurl\n" . "Content-Disposition:attachment; filename=searchlist.m3u\n\n";
      $config{'out'}{'m3u'}{'head'} ||= sub {
        $work{'m3u_limit_max'}           = $static{'db'}->{'limit_max'};
        $static{'db'}->{'limit_max'}     = $config{'maxplaylist'};
        $work{'m3u_web_max_search_time'} = $config{'web_max_search_time'};
        $config{'web_max_search_time'}   = 600;
        print "#EXTM3U\n";
        psmisc::flush();
      };
      $config{'out'}{'m3u'}{'foot'} ||= sub {
        $static{'db'}->{'limit_max'} = $work{'m3u_limit_max'};
        $config{'web_max_search_time'} = $work{'m3u_web_max_search_time'};
      };
      $config{'out'}{'text'}{'head'} ||= sub { print "#Result\n"; };
      $config{'out'}{'text'}{'size'} ||= sub {
        my ( $param, $table, $row ) = @_;
        psmisc::printu psmisc::human( 'size', $row->{'size'}, ' ' );
      };
      $config{'out'}{'text'}{'time'} ||= sub {
        my ( $param, $table, $row ) = @_;
        psmisc::printu psmisc::human( 'time_period', int(time) - $row->{'time'} );
      };
      for my $field (qw(desc full tiger)) {
        $config{'out'}{'text'}{$field} ||= sub {
          my ( $param, $table, $row ) = @_;
          print $row->{$field};
        };
      }
      $config{'out'}{'text'}{'result_string'} ||= sub {
        my ( $param, $table, $row ) = @_;
        $row->{'n'} = ++$work{'n'};
        print $row->{'n'};
        for my $rown ( sort { $config{'sql'}{'table'}{$table}{$b}{'order'} <=> $config{'sql'}{'table'}{$table}{$a}{'order'} }
          grep { $config{'sql'}{'table'}{$table}{$_} and !$config{'sql'}{'table'}{$table}{$_}{'hide'} } keys %$row )
        {
          print "\t", $row->{$rown};
        }
        print "\n";
      };
      $config{'out'}{'rss2'}{'http-header'} = "Content-type: application/rss+xml\n\n";
      $config{'out'}{'rss2'}{'head'} ||= sub {
        my ( $param, $table ) = @_;
        $work{'param_str'} = get_param_url_str( $param, $config{'skip_from_link'} );
        $work{'rssn'} = $work{'n'} = $static{'db'}->{'limit_offset'};
        print '<?xml version="1.0" encoding="', lang( $work{'codepage'} ), '" ?>';
        #print '<?xml-stylesheet type="text/css" href="', $config{'root_url'}, $config{'css'}, '" ?>' if $config{'css'};
        print '<rss version="2.0" xmlns:dc="http://purl.org/dc/elements/1.1/">', '<channel>';
        print '<title>', $config{'title'}, '</title>' if $config{'title'};
        print '<link>',        $config{'root_url'},         '</link>'        if $config{'root_url'};
        print '<description>', $config{'rss2_description'}, '</description>' if $config{'rss2_description'};
        print '<language>', lang('language-code'), '</language>';
      };
      $config{'out'}{'rss2'}{'result_string'} ||= sub {
        my ( $param, $table, $row ) = @_;
        #printlog('dev', 'rss2RS');
        print '<item>';
        #"\n<link>", get_param_url_str( $param, ['view'] ), '#n', ( ++$work{'rssn'} ), '</link>';
        #'<description>';
        #my $buffer;
        #$buffer .= '<table>';
        #print 'ITEMS:[' ,join',',%$row;
        unless ( $row->{'description'} ) {
          grab_begin( \$row->{'description'} );
          print '<![CDATA[<table>';
          {
            local $config{'view'} = 'html';
            #local $config{'view_from'}          = 'rss2';
            local $config{'allow_vote'}    = 0;
            local $config{'no_plus_minus'} = 1;
            local $config{'no_play'}       = 1;
            #print('dev', 'call parsRS', "\n");
            part( 'result_string', $param, undef, $row, { 'no_cont' => 1 } );
          }
          #print('dev', 'buf=[',$buffer,"]\n");
          print '</table>]]>';
          grab_end();
        }
        #$buffer .= '</table>';
        #html_chars( \$buffer );
        #print $buffer;
        #print '</description>';
        my $unique = $row->{ $config{'rss2_guid'} || 'full' };
        #print "UNIQ1[$unique:$config{'rss2_guid'}]";#, join',',%$row;
        html_chars( \$unique );
        $row->{'guid'} ||= $unique;
        #print "UNIQ[$unique]";#, join',',%$row;
        $row->{'pubDate'} ||= psmisc::human( 'rfc822_date_time', $row->{'time'} );
        $row->{'link'} ||= get_param_url_str( $param, ['view'] ), '#n', ( ++$work{'rssn'} );
        print '<', $_, '>', $row->{$_}, '</', $_, ">\n"
          for grep { $row->{$_} } qw(title description author category comments guid pubDate link);
        #'<pubDate>', , '</pubDate>',
        #"<guid></guid>"
        print "</item>\n";
      };
      $config{'out'}{'rss2'}{'footer'} ||= sub { print '</channel></rss>'; };
      $config{'out'}{'xml'}{'http-header'} = "Content-type: application/xml\n\n";
      $config{'out'}{'xml'}{'head'} ||= sub {
        $work{'rssn'} = $work{'n'} = $static{'db'}->{'limit_offset'};
        print '<?xml version="1.0" encoding="', lang( $work{'codepage'} ), "\" ?>\n<search>\n";
      };
      $config{'out'}{'xml'}{'footer'} ||= sub { print '</search>'; };
      $config{'out'}{'html'}{'ajax'} ||= sub {
        my ( $param, $table ) = @_;
        return unless ( $config{'ajax'} and $param->{'JsHttpRequest'} );
        eval "
  use lib \$$config{'root_path'}.'./';
  use JsHttpRequest; 
";
        local $config{'log_all'}    = 't.log';
        local $config{'log_screen'} = '0';
        my $jsr = JsHttpRequest->new(
          'params' => $param,
          'func'   => sub {
            my $buffer;
            my @needupdate = ( 'search', 'show' );
            for my $as (@needupdate) {
              my $part = $as;
              $_[1]->{$as} = ' ', next if $part eq 'show' and !$param->{'show'};
              $part = $param->{'show'} if $part eq 'show';
              $_[1]->{$as} = ' ', next if $part eq 'search' and ( $param->{'show'} or $param->{'form'} );
              $buffer = '';
              grab_begin($buffer);
              part( $part, $param, $table, undef, { 'no_cont' => 1 } );
              grab_end();
              $_[1]->{$as} = $buffer;
              printlog( 'dbg', 'JSRET', $part, $as, $buffer );
            }
          }
        );
        print $jsr->{'header'};
        print $jsr->{'jscode'};
        printlog( 'dbg', "<br\n><br\n><h1>param:</h1><br\n><br\n>" );
        for ( sort keys %$param ) { printlog( 'dbg', "$_ = [$param->{$_}]<br\n>" ); }
        exit;
      };
      $config{'out'}{'json'}{'http-header'} = "Content-type: application/json\n\n";
      $config{'out'}{'json'}{'footer'} ||= sub {
        my ( $param, ) = @_;
        return print +($param->{'callback'} ? $param->{'callback'} . '(':'') ,${ psmisc::json_encode($param->{__result} || {}) }, ($param->{'callback'} ? ');' : '');
      };
      $config{'out'}{'json'}{'result_string'} ||= sub {
        my ( $param, $table, $row ) = @_;
        #print 'string',Dumper \@_;
        push @{ $param->{__result}{'rows'} ||= [] }, $row;
      };
      $config{'out'}{''}{'run'} ||= sub {
        my ( $param, $table ) = @_;
        return if $config{'out'}{ $config{'view'} }{'disabled'};
        part( 'ajax', $param, $table, undef, { 'no_cont' => 1 } );
        print( $config{'out'}{ $config{'view'} }{'http-header'} || $config{'http-header-default'} )
          if !$config{'out'}{ $config{'view'} }{'no-http-header'}
            and ( $config{'force-http-header'} or defined( $ENV{'SERVER_PORT'} ) );
        #printlog('dev', '1part', 'nofunc', $config{'view'}, $config{'out'}{'html'}{'cattest'}, 'runw:',@_, $config{'view'});
        part( 'head', $param, $table, undef, { 'no_cont' => 1 } );
        part( 'header', $param, $table ) unless $config{'no_auto_header'};
        #printlog('dev', 'show', $param->{'show'});
        part( $param->{'show'}, $param, $table );
        part( 'show',           $param, $table );
        alarmed( $config{'web_max_search_time'}, sub { part( 'main_or_search', $param, $table ); } )
          if !$param->{'show'} and !$param->{'form'};
        part( 'result_error', $param, $table, 'timeout' ) if $@;
        part( 'footer', $param, $table ) unless $config{'no_auto_footer'};
        alarmed(
          $config{'web_max_finish_time'},
          sub {
            part( 'foot', $param, $table, undef, { 'no_cont' => 1 } );
            redirect_update( $param, $table ) if $param->{'go'};
            update_query_stat() if $stat{'results'} and !$work{'fulltext_fail'};
            #printlog('dev', 'alarmed upstat end ');
          }
        );
        #printlog('dev', 'the end');
      };
    }
  );
}
#BEGIN { config_init(); }
config_init($param);

sub mylink {
  my ( $body, $param, $params, $lparam, ) = @_;
  #printlog('dev', 'mylink', $body, %{$param or {}}, %{$params or {}}, %{$lparam or {}}) ;
  #printlog(Dumper([$body, $param, $params, $lparam]));
  $config{'mylink_bef_bef'}->( \( $body, $param, $params, $lparam, ) ) if ref $config{'mylink_bef_bef'} eq 'CODE';
  local %_ = (
    'glue'      => '&amp;',
    'delim'     => '?',
    'tag'       => 'a',
    'href'      => 'href',
    'body'      => ( length($body) ? $body : 'link' ),
    'base'      => $config{'root_url'} || $config{'root_dir'} || './',
    'param_add' => $work{'uparam'},
    %{ $lparam || {} },
  );
  $params ||= {};
  $config{$_}->( \( $body, $param, $params ), \%_, ) for grep { ref $config{$_} eq 'CODE' } (qw(mylink_bef mylink_rewrite));
  local $config{'ajax'} = 0 if ( $_{'base'} ne $config{'root_url'} ) or ( $param->{'view'} and ( $param->{'view'} ne 'html' ) );
  my %modes =
    #map {s/(\d*)$//;$_ => $param->{$_.'_mode'.$1} }
    map { s/_mode(\d*)$//; $_ . $1 => $param->{ $_ . '_mode' . $1 } }
    #grep { s/_mode(\d*)$/$1/ and $param->{$_.'_mode'.$1}=~ /^\W+$/}
    #grep { /^(.+)_mode(\d*)$/ and $param->{$1.'_mode'.$1}=~ /^\W+$/}
    grep { /_mode\d*$/ and $param->{$_} =~ /^\W+$/ } keys %$param;
  #printlog('dev', Dumper(\%modes));
  local @_ = sort grep { length($_) and length( $param->{$_} ) and !( /^(.+)_mode(\d*)$/ and $modes{ $1 . $2 } ) } keys %$param;
  if ( !$config{'ajax'} ) {
    if ( !$_{'destroy'} ) {
      $params->{'href'} //=
          $_{'base'}
        . ( ( @_ or $_{'param_add'} ) ? $_{'delim'} : '' )
        . join( $_{'glue'}, map { encode_url($_) . $modes{$_} . '=' . encode_url( $param->{$_} ) } @_ )
        . $_{'param_add'}
        unless exists $params->{'href'};
    }
  } else {
    $params->{'href'} //= '#';
    $params->{'onclick'} ||= 'dosubmit({' . join( ',', map { "'$_':'$param->{$_}'" } @_ ) . '});return false;';
  }
  local $_ = join '', '<', $_{'tag'}, ' ',
    #print("[$_ = $params->{$_}] "),
    join( ' ', map { $_ . '="' . $params->{$_} . '"' } sort grep { defined $params->{$_} } keys %$params ), '>', $_{'body'},
    '</', $_{'tag'}, '>';
  $config{'mylink_aft'}->( \$_ ) if ref $config{'mylink_aft'} eq 'CODE';
  return $_;
}

sub out_bold {
  my ( $string, $what, @whata ) = @_;
  #printlog "OB:",utf8::is_utf8($string)," out_bold($string, $what, @whata);", Dumper $string;
  return $string if !( ( length $what or @whata ) and length $string );
  my $mask = (
    join '|',
    map { s/(\W)/\\$1/g; $_ } grep { length $_ } sort { length($b) <=> length($a) } @whata,
    ( $what =~ s/^\s*\"(.+)\"\s*$/$1/ ? ($what) : split( /\s+|\W+|_+/, $what ) )
  ) or return $string;
  #print " obmask=$mask; ";
  #!return $string if $string =~ /[\xD0\xD1]/;    #dont break utf
  $string =~ s{($mask)}{ length $1 ? qq{<span class="hilight1">$1</span>} : ''}gie;
  return $string;
}

sub destroy_html {
  my ($string) = @_;
  #? &->&amp; "->&quot;
  $string =~ s/</&lt;/g;
  $string =~ s/>/&gt;/g;
  $string =~ s/\\\\n/<br\/>/g;
  return $string;
}

sub destroy_quotes {
  my ($string) = @_;
  $string =~ s/"/&quot;/g;    #" mc colorer bug '
  $string =~ s/'/&#39;/g;
  return $string;
}

=c
sub to_quot {    #v0c0
  local ($_) = @_;
  s/\"/&quot;/g;
  return $_;
}
=cut

sub value {
  return unless defined $_[0];
  return
    ' value="'
    . ( $_[0] ? destroy_quotes( cp_trans( $config{'cp_int'}, $work{'codepage'}, $_[0] ), $_[1] || '"' ) : '' ) . '" ';
}

sub get_param_hash {
  my ( $param, @skip ) = @_;
  push @skip, @{ $config{'param_cookie'} || [] };
  my (%ret);
GPSL1: for my $par ( sort keys %$param ) {
    next unless ( $par and $param->{$par} ne '' );
    for my $sk (@skip) { next GPSL1 if $sk eq $par; }
    $ret{$par} = $param->{$par};
  }
  return %ret;
}

sub get_param_str {    #future? remove
  my ( $param, $skip, $glue, $mask ) = @_;
  $glue ||= '&amp;';
  $skip ||= [];
  push @$skip, @{ $config{'param_cookie'} || [] };
  my ( $string, $tmp );
GPSL1: for my $par ( sort keys %$param ) {
    next unless ( $par and $param->{$par} ne '' );
    for my $sk (@$skip) { next GPSL1 if $sk eq $par; }
    $tmp = encode_url( $param->{$par}, $mask );
    $string .= $par . '=' . $tmp . $glue;
  }
  $string =~ s/$glue$//g;
  #print "[$glue, $string]";
  return $string;
}

sub get_param_url_str {
  my $gps = get_param_str(@_);
  return $config{'root_url'} . ( $gps ? '?' . $gps : '' );
}
{
  #no strict;    #strange error with open(STDOUT, [ ActiveState Perl v5.6.1 build 631]
  #local *OLDSTDOUT;
  #local *STDOUT;
  #our (OLDSTDOUT, STDOUT);
  sub grab_begin {    #(\$)    #v1
    open( OLDSTDOUT, '>&', STDOUT );    #local *
    close(STDOUT);                      # or return;
    open( STDOUT, '>>', $_[0] );        # or return
  }

  sub grab_end {                        #v1
    close(STDOUT);                      #  or return;
    open( STDOUT, '>&', OLDSTDOUT );    #  or return;  #local *
  }
}
sub nameid { return qq{ name="$_[0]" id="$_[0]" }; }

sub part {
  #printlog('', 'part:',$config{'view'},@_);
  my ($part) = shift;
  #my ( $param, $table, $part_param, $cont_param, $paramnum, $valuenum ) = @_;
  my ( $param, $table, $part_param, $cont_param ) = @_;
  my $func =
       $config{'out'}{ $config{'view'} }{$part}
    || $config{'out'}{''}{$part}
    || $config{ $config{'view'} . '_' . $part }
    || $config{ '_' . $part };
#printlog('', 'view:',$config{'view'} , 'func',$func, 'param', %$param);
#printlog('dev', 'part', 'nofunc', $config{'view'}, $config{'out'}{'html'}{'cattest'}, 'runw:',@_)      if (!$part      or $param->{ 'no_' . $part }     or $config{ 'no_' . $part }      or !$func)      and $cont_param ne 'NODIV'      ;
  $cont_param ||= {};
  #print "COPAR[$part]:", %$cont_param if $part eq 'search';
  #sub check_opt {
  #my ( $part, $param, $cont_param, $opt ) = @_;
  my $check_opt = sub {
    my ($opt) = @_;
#print "CO","[$part]:$opt=",$param->{$part.'_'.$opt} ,'or', $config{$part.'_'.$opt} ,'or', $config{$config{'view'} . '_' .$part.'_'.$opt} ,'or', $cont_param->{$opt};
    return $param->{ $opt . '_' . $part } || $work{ $opt . '_' . $part } || $config{ $opt . '_' . $part } || $cont_param->{$opt}
      if $opt eq 'no';
    return defined $config{ $part . '_' . $opt } ? $config{ $part . '_' . $opt } : $config{ $opt . '_def' }
      if $config{ $opt . '_def' };
    return
         $param->{ $part . '_' . $opt }
      || $work{ $part . '_' . $opt }
      || $config{ $part . '_' . $opt }
      || $work{ $config{'view'} . '_' . $part . '_' . $opt }
      || $config{ $config{'view'} . '_' . $part . '_' . $opt }
      || $cont_param->{$opt};
  };
  return if !$part or !$func or $check_opt->('no');
  #my $cont = ($cont_param->{'cont'} or ( $part =~ /^form-/ ? 'span' : 'div' ));
  #print "[1]";
  my $cont = $check_opt->('tag') || ( $part =~ /^form-/ ? 'span' : 'div' );
  #printlog('trace',"<br/>part:$part:"),
  #print "[2]";
  print "\n<!-- $part BEGIN $cont [$config{'view'}] no_cont=", $check_opt->('no_cont'), " -->\n"
    if $param->{'debug'} eq 'on'    #' ',Dumper(@_),
                                    #;#
      and !$check_opt->('no_cont');
  $work{'part_stack'}{$part} = ++$work{'part_stack_current'};
  #psmisc::printall( \$config{ $config{'view'} . '_' . $part . '_bef_bef' }, @_ );
  #print "P1";
  psmisc::printall( $check_opt->('bef_bef'), psmisc::is_code( $check_opt->('bef_bef') ) ? @_ : () );
  #print "P2";
  #return if $config{ 'no_' . $part } or !$func;
  #print "[3]";
  return if !$part or !$func or $check_opt->('no');
  #print "[4]";
  if ( $config{'view'} eq 'html' and !$check_opt->('no_cont') ) {
    print '<', $cont, ( $check_opt->('no_class') ? () : ( ' class="', $cont_param->{'class'} || $part, '" ' ) ),
      ( $check_opt->('no_nameid') ? () : ( nameid($part) ) ), $cont_param->{'cont_param'}, ' ';
    #psmisc::printall( \$config{ $config{'view'} . '_' . $part . '_param' }, @_ );
    psmisc::printall( $check_opt->('param'), @_ );
    print '>';
  }
  psmisc::printall( $check_opt->('bef'), @_ );
  #psmisc::printall( \$config{ $config{'view'} . '_' . $part . '_bef' }, @_ );
  #$func->( $param, $table, $part_param, $paramnum, $valuenum );
  #print "[5fu $func]";
  #$func->(@_) if ref $func eq 'CODE';
  psmisc::printall( $func, @_ );
  psmisc::printall( $check_opt->('aft'), psmisc::is_code( $check_opt->('aft') ) ? @_ : () );
  #psmisc::printall( \$config{ $config{'view'} . '_' . $part . '_aft' }, @_ );
  print "</$cont>" if $config{'view'} eq 'html' and !$check_opt->('no_cont');
  psmisc::printall( $check_opt->('aft_aft'), @_ );
  #psmisc::printall( \$config{ $config{'view'} . '_' . $part . '_aft_aft' }, @_ );
  --$work{'part_stack_current'};
  delete $work{'part_stack'}{$part};
  print "\n<!-- $part END -->\n" if $param->{'debug'} eq 'on' and !$check_opt->('no_cont');
}
#changed!
#founded_files founded -> total
#onpage limit -> size
#dbirows -> actual
#maxpage -> last
sub gotopage {    # $Id: psweb.pm 4843 2013-08-14 12:17:58Z pro $ $URL: svn://svn.setun.net/search/trunk/lib/psweb.pm $
  my ($fparam) = @_;    #$param,
  my (%ret);
  #$fparam->{'total'} : total results, usually COUNT(*) as total
  #-----------size -- : size of one page in rows (LIMIT x,size)
  #current : current page number
  #actual : usually $DBI::rows, if total unknown
  #last : last page number (auto calculated from total/size if 0)
  #total_max = 1000 : maximum db results
  #printlog('dmp', 'gotopage start:', Dumper($fparam));
  $fparam->{'size'} = 100 unless defined $fparam->{'size'};
  return {} unless $fparam->{'size'};
  $fparam->{'actual'} = $fparam->{'size'} unless defined $fparam->{'actual'};
  $fparam->{'current'} ||= 1;
  $fparam->{'last'} ||=
    $fparam->{'size'} < 1
    ? undef
    : ( int( $fparam->{'total'} / ( $fparam->{'size'} || 1 ) ) + ( $fparam->{'total'} % ( $fparam->{'size'} || 1 ) ? 1 : 0 ) );
  $fparam->{'buttonsb'} ||= $config{'gotopage_bb'} || 5;    #before
  $fparam->{'buttonsa'} ||= $config{'gotopage_ba'} || 5;    #after
  $fparam->{'align'}   = 1 unless defined $fparam->{'align'};
  $fparam->{'jumpten'} = 1 unless defined $fparam->{'jumpten'};
  $fparam->{'power'}   = 2 unless defined $fparam->{'power'};
  my $fromto = sub {
    my ($n) = @_;
    return (
      ( ( ( $n - 1 ) * $fparam->{'size'} ) + 1 ) . '-'
        . (
        ( $fparam->{'total'} and ( $fparam->{'total'} < $n * $fparam->{'size'} ) ) ? $fparam->{'total'} : $n * $fparam->{'size'}
        )
    );
  };
  my $align = sub {
    my $a = int(shift);
    my $len = shift || $fparam->{'align'};
    substr( $a, $len, length($a) - $len ) = '0' x ( length($a) - $len ) if $len > 0 and length($a) > $len;
    return $a;
  };
  #printlog('dmp', 'gotopage calc:'," <br\n/>" .Dumper($fparam) . "<br\n/>");
  my $next = $fparam->{'actual'} >= $fparam->{'size'};
  if ( ( !$fparam->{'total'} and $fparam->{'actual'} > 0 )
    or $fparam->{'total'} >= $fparam->{'size'}
    or $fparam->{'current'} > 1 )
  {
    $ret{'prev'}{ $fparam->{'current'} - 1 } = $fromto->( $fparam->{'current'} - 1 ) if $fparam->{'current'} > 1;
    for my $n ( ( $fparam->{'current'} > $fparam->{'buttonsb'} ? $fparam->{'current'} - $fparam->{'buttonsb'} : 2 )
      .. $fparam->{'current'} + ( $next ? $fparam->{'buttonsa'} : 0 ) )
    {
      last if $fparam->{'total'} and $n > $fparam->{'last'};
      last if $fparam->{'total_max'} and $n * $fparam->{'size'} > $fparam->{'total_max'};
      ( ( !$fparam->{'total'} and $n > $fparam->{'current'} + 1 ) ? ( \%{ $ret{'small'} } ) : ( \%{ $ret{'big'} } ) )->{$n} =
        $fromto->($n);
    }
    if ( $fparam->{'jumpten'} ) {
      $fparam->{'jumpfrom'} ||= '1' . ( 0 x ( length( $fparam->{'current'} - $fparam->{'buttonsb'} ) - 1 ) );
      $fparam->{'jumpto'} ||= '1' . ( 0 x length( $fparam->{'current'} + $fparam->{'buttonsa'} ) );
      $ret{'big'}{$_} = $fromto->($_)
        for grep { !$fparam->{'last'} or $_ <= $fparam->{'last'} }
        map { '1' . ( 0 x $_ ) } 1 .. length( $fparam->{'current'} ) - 1;
      if ($next) {
        $ret{'big'}{$_} = $fromto->($_)
          for map { '1' . ( 0 x $_ ) } length( $fparam->{'current'} ) .. length( $fparam->{'last'} ) - 1;
      }
    }
    $fparam->{'jumpfrom'} ||= 1;
    $fparam->{'jumpto'}   ||= $fparam->{'last'};
    #$fparam->{'jumpto'} = psmisc::min( $fparam->{'jumpto'}, $fparam->{'last'} );
    $fparam->{'jumpto'} = $fparam->{'last'} if $fparam->{'last'} < $fparam->{'jumpto'};
    if ( $fparam->{'power'} > 1 ) {
      my ($n);
      $n = $fparam->{'current'} - $fparam->{'buttonsb'} * $fparam->{'power'};
      for (
        $_ = $fparam->{'buttonsb'} ;
        $fparam->{'jumpfrom'} >= 1 and $n > $fparam->{'jumpfrom'} and $n < $fparam->{'last'} ;
        $n -= ( $_ *= $fparam->{'power'} )
        )
      {
        $ret{'big'}{ $align->($n) } = $fromto->( $align->($n) );
      }
      $n = $fparam->{'current'} + $fparam->{'buttonsa'} * $fparam->{'power'};
      for ( $_ = $fparam->{'buttonsa'} ; $next and $n < $fparam->{'jumpto'} ; $n += ( $_ *= $fparam->{'power'} ) ) {
        $ret{'big'}{ $align->($n) } = $fromto->( $align->($n) );
      }
    }
    $ret{'big'}{ $fparam->{'last'} } = $fromto->( $fparam->{'last'} ) if $fparam->{'last'} > 1 and $next;
    $ret{'big'}{1} ||= $fromto->(1)
      if ( $fparam->{'last'} > 1 or !$fparam->{'total'} )
      and $fparam->{'actual'} >= $fparam->{'size'};
    $ret{'next'}{ $fparam->{'current'} + 1 } = $fromto->( $fparam->{'current'} + 1 )
      if $next and !$fparam->{'last'}
        or $fparam->{'current'} < $fparam->{'last'};
  }
  #printlog('dmp', 'gotopage ret:', Dumper(\%ret));
  return wantarray ? ( sort { $a <=> $b } keys %{ $ret{'big'} }, keys %{ $ret{'small'} } ) : \%ret;
}

sub cache_file {
  my $fparam = ( shift or {} );
  for my $file ( grep $_, @_ ) {
    if ( $fparam->{'cache'} and !$fparam->{'url'} ) {
      my $full = $config{'root_path'} . $file;
      if (
        !defined $static{'cache'}{$full} and open( CFH, '<',
          #$ENV{'PROSEARCH_PATH'}
          $full
        )
        )
      {
        local $/;
        $static{'cache'}{$full} = cp_trans( $config{'cp_cache'}, $config{'cp_int'}, <CFH> );
        close(CFH);
        #print "cache readed($file, $full) = ",length $static{'cache'}{$full},";\n";
      }
      #print "cache print($file, $full);\n";
      print $fparam->{'pre_cached'}, cp_trans( $config{'cp_int'}, $work{'codepage'}, $static{'cache'}{$full} ),
        $fparam->{'post_cached'};
    } else {
      print $fparam->{'pre_url'}, ( $file =~ m{^\w+://} ? () : $fparam->{'url'} ), $file, $fparam->{'post_url'};
    }
  }
}

sub cache_file_js {
  my $fparam = ( shift or {} );
  cache_file( {
      'cache'       => $config{'cache_js'},
      'url'         => $config{'js_url'},
      'pre_cached'  => $config{'jscript_open'},
      'post_cached' => $config{'jscript_close'},
      'pre_url'     => '<script type="text/javascript" language="JavaScript" src="',
      'post_url'    => "\">\n</script>",
      %$fparam,
    },
    @_
  );
}

sub cache_file_css {
  my $fparam = shift || {};
  cache_file( {
      'cache'       => $config{'cache_css'},
      'url'         => $config{'css_url'},
      'pre_cached'  => "<style type=\"text/css\" media=\"screen\" rel=\"stylesheet\">",
      'post_cached' => "</style>",
      'pre_url'     => '<link rel="stylesheet" media="screen" type="text/css" href="',
      'post_url'    => '"/>',
      %$fparam,
    },
    @_
  );
}

sub is_img {
#printlog('devw', '0is_img', "F[$_[0]]", defined( $static{'is_img'}{ $_[0] } ), $static{'is_img'}{ $_[0] }, "external[$config{'img_external'}{$_[0]}] url=$config{'img_url'} path=$config{'img_path'}");
  return undef unless length $_[0];
  return $static{'is_img'}{ $_[0] } if defined( $static{'is_img'}{ $_[0] } );
  local $_ = $_[0];
  $_ = $config{'img_trans'}{$_} if defined $config{'img_trans'}{$_};
  #printlog('devw', '1is_img=', $_[0]),
  return $static{'is_img'}{$_} = $_[0] if $_[0] =~ m|^\w+://|;
  #printlog('devw', '2is_img=', $config{'img_url'} .$config{'img_path'}. $_ . '.' . $config{'img_ext'}),
  return $static{'is_img'}{$_} = $config{'img_url'} . $config{'img_path'} . $_ . '.' . $config{'img_ext'}
    if $config{'img_url'} =~ m{^\w+://} and ( $config{'img_external'}{$_} or -e $config{'root_path'} . $_[0] );
#printlog('devw', '3is_img=', !!-e $config{'root_path'} . $config{'img_path'} . $_ . '.' . $config{'img_ext'}    ? $config{'img_url'} . $_ . '.' . $config{'img_ext'}    : '',   $config{'img_path'} . $_ . '.' . $config{'img_ext'}),
  return $static{'is_img'}{$_} = $_[0] if $_[0] =~ m|/| and !!-e $config{'root_path'} . $_[0];
  #return $static{'is_img'}{$_} = !!-e if  $config{'img_url'} =~ m|^\w+://| and ;
  #my $r =
  return $static{'is_img'}{$_} =
    !!-e $config{'root_path'} . $config{'img_path'} . $_ . '.' . $config{'img_ext'}
    ? $config{'img_url'} . $config{'img_path'} . $_ . '.' . $config{'img_ext'}
    : '';
#printlog('devw', '4is_img=', $_[0], $config{'root_path'} . $config{'img_path'} . $_ . '.' . $config{'img_ext'}, $config{'img_url'} . $config{'img_path'}.$_ . '.' . $config{'img_ext'}, );
#return $r;
}

sub select_mode {
  my ( $param, $paramnum, $valuenum ) = @_;
  print '<select name="', $_, '_mode', $paramnum, '" dir="ltr" >', '<option value="">', lang($_), '</option>',
    '<option value="=" ', ( $param->{ $_ . '_mode' . $valuenum } =~ /[e=]/i ? 'selected="selected"' : '' ), '>', lang('='),
    '</option>', '<option value="!" ', ( $param->{ $_ . '_mode' . $valuenum } =~ /[n!]/i ? 'selected="selected"' : '' ), '>',
    lang('!'), '</option>', '<option value=">" ',
    ( $param->{ $_ . '_mode' . $valuenum } =~ /[g>]/i ? 'selected="selected"' : '' ), '>', lang('>'), '</option>',
    '<option value="<" ', ( $param->{ $_ . '_mode' . $valuenum } =~ /[l<]/i ? 'selected="selected"' : '' ), '>', lang('<'),
    '</option>', '<option value="~" ', ( $param->{ $_ . '_mode' . $valuenum } =~ /[r~]/i ? 'selected="selected"' : '' ), '>',
    lang('~'), '</option>', '<option value="@" ',
    ( $param->{ $_ . '_mode' . $valuenum } =~ /[s@]/i ? 'selected="selected"' : '' ), '>', lang('@'), '</option>', '</select>';
}

=dep
sub cp_trans_row {
  my ($row) = @_;
  return cp_trans_hash( $config{'cp_db'}, $work{'codepage'}, $row );
}
=cut

sub update_query_stat {
  return if !$config{'allow_query_stat'} or $config{'client_bot'};
#printlog( 'dev', 'update_query_stat' , $work{'codepage'}, $config{'cp_db'}, keys %{ $work{'word'} }, keys %{ $work{'query'} }, Dumper \%work);
  print $config{'jscript_open'}, 'createCookie(\'queries\', \'',
    ( join '||', map { encode_url($_) } grep { $_ } ( keys %{ $work{'query'} }, @{ $work{'queries'} } )[ 0 .. 10 ], ), '\');',
    $config{'jscript_close'}
    if $config{'view'} eq 'html' and keys %{ $work{'query'} };
  psmisc::flush();
  local $config{'sql'}{'database'} = $config{'sql_base_wup'};
  #local $static{'db'}->{'cp_in'} = $config{'cp_db'};
  delete $work{'word'} if $config{'no_word'};
  for my $word ( grep { $_ =~ /\w/ } keys %{ $work{'word'} } ) {
    #map {scalar cp_trans( $self->{'cp_in'}, $self->{'codepage'}, $_ )}
    $_->update(
      $config{'sql_twordstat'},
      ['word'], {
        #'word'   => $word,
        'word'   => scalar cp_trans( $work{'codepage'}, $config{'cp_db'}, $word ),
        'lastip' => $config{'client_ip'},
        'last'   => int( time() )
      },
      '',
      '',
      ", " . $_->rquote('top') . " = " . $_->rquote('top') . "+" . $_->quote(1)
    ) for $static{'dbs_up_all'} ? @{ $static{'dbs_up_all'} } : $static{'db'};
  }
#$static{'db'}->dump_cp();
#printlog( 'dev', 'update_query_stat' , $work{'codepage'}, $config{'cp_db'}, keys %{ $work{'word'} }, keys %{ $work{'query'} });
  for my $query ( grep $_ =~ /\w/, keys %{ $work{'query'} } ) {
    #printlog( 'dev', 'query', $query, utf8::is_utf8($query) );
    #$query =~ s/\W+/ /g ,    $query =~ s/(^\s+)|(\s+$)//g if $config{'cp_db'} ne 'utf-8';
    $_->update(
      $config{'sql_tquerystat'},
      ['query'], {
        #'query'  => $query, #scalar cp_trans( $work{'zcodepage'}, $config{'cp_db'}, $query ),
        'query'  => scalar cp_trans( $work{'codepage'}, $config{'cp_db'}, $query ),
        'lastip' => $config{'client_ip'},
        'last'   => int( time() )
      },
      '',
      '',
      #", `top` = `top`+'1'"
      ", " . $_->rquote('top') . " = " . $_->rquote('top') . "+" . $_->quote(1)
    ) for $static{'dbs_up_all'} ? @{ $static{'dbs_up_all'} } : $static{'db'};
  }
}

sub sorter {
  my ( $param, $fparam, $oph ) = @_;
  $fparam->{'id'}   ||= $fparam->{'order'};
  $fparam->{'lang'} ||= $fparam->{'order'};
  #print "hi", Dumper(( $param, $fparam, $oph ));
  print '<span id="head_', $fparam->{'id'}, '">';
  psmisc::printu mylink(
    lang( $fparam->{'lang'} ), {
      %$oph,
      'order' => $fparam->{'order'},
      ( ( $param->{'order'} eq $fparam->{'order'} and $param->{'order_mode'} ) ? () : ( 'order_mode' => '!' ) ),
    },
    undef,
    { 'destroy' => $config{'destroy_link_sort'} }
    ),
    ' '
    unless $fparam->{'no_lang'};
  psmisc::printu mylink(
    lang('darr'),
    { %$oph, 'order' => $fparam->{'order'}, },
    undef, {
      'destroy' => $config{'destroy_link_sort'}
        || ( ( $param->{'order'} eq $fparam->{'order'} and !$param->{'order_mode'} ) ? ('NO') : () ),
#( ( $param->{'order'} eq $fparam->{'order'} and !$param->{'order_mode'}  ) ? ( 'href' => 'NO' ) : () ),      'destroy' => $config{'destroy_link_sort'}
    },
    ),
    ' '
    unless $fparam->{'no_down'};
  print mylink(
    lang('uarr'),
    { %$oph, 'order' => $fparam->{'order'}, 'order_mode' => '!' },
    undef, {
#( ( $param->{'order'} eq $fparam->{'order'} and $param->{'order_mode'} ) ? ( 'href' => 'NO' ) : () ),      'destroy' => $config{'destroy_link_sort'}
      'destroy' => $config{'destroy_link_sort'}
        || ( ( $param->{'order'} eq $fparam->{'order'} and $param->{'order_mode'} ) ? ('NO') : () ),
    },
    ),
    unless $fparam->{'no_up'};
  print $config{'sel_sep'} unless $fparam->{'no_sep'};
  print '</span> ';
}

sub date_period {
  #return;
  my ( $time, $name ) = @_;
  #print '[',@_,']';
  print mylink(
    psmisc::human( 'time_period', int( time() ) + $config{'timediff'} - $time ) || 0,
    undef, {
      'title' => lang( $name, undef, undef, ' ' ) . psmisc::human( 'date_time', $time - $config{'timediff'} ),
      'href'  => undef,
    },
  ) if $time;
}

sub next_user {
  #my $self = shift;
  #$self->{'queries'} = $self->{'queries_time'} = $self->{'errors_chain'} = $self->{'errors'} = $self->{'connect_tried'} = 0;
  delete $stat{$_} for qw (found files found_time onpage results top_founded_max top_pages_max);
  #$self->{ 'on_user' . $_ }->($self) for grep { ref $self->{ 'on_user' . $_ } eq 'CODE' } ( '', 1 .. 5 );
  #$self->{ 'on_user' }->($self) for grep { ref $self->{ 'on_user' } eq 'CODE'}('');
  #$self->log('dev', 'nup');
  #found
}
1;
