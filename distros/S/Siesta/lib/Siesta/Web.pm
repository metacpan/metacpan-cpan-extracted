use strict;
package Siesta::Web;
use Apache::Constants qw( :common );
use Template;
use Apache::Session::SharedMem;
use CGI;
use Siesta;
use Siesta::Config;

use constant Cookie => 'siesta_session';

=head1 SYNOPSIS

 PerlModule          Siesta::Web
 <Files *.tt2>
     SetHandler      perl-script
     PerlHandler     Siesta::Web
 </Files>

=cut

my $tt;
sub handler {
    my $r = shift;

    my $file = $r->filename;
    $file =~ /\.tt2$/ or return DECLINED;

    my $cgi = CGI->new;
    my $session_id = $cgi->cookie( Cookie );
    my %session;
    # try the session in the cookie, or a new one
    for my $id ($session_id, undef) {
        eval {
            tie %session, 'Apache::Session::SharedMem', $id,
              +{ expires_in => 24 * 60 * 60 }; # 24 hours
        };
        last unless $@;
    }

    unless ( $session{_session_id} ) {
        $r->log_reason( "couldn't get session" );
        return SERVER_ERROR;
    }

    my @headers = (
        [ 'Set-Cookie' =>
            $cgi->cookie(-name  => Cookie,
                         -value => $session{_session_id}) ]
       );

    my $params = {
        set_header => sub { push @headers, @_; return },
        uri        => $r->uri,
        cgi        => $cgi,
        session    => \%session,
    };

    my $root = $Siesta::Config::config->root;
    $tt ||= Template->new(
        ABSOLUTE     => 1,
        INCLUDE_PATH => "$root/web-frontend/siesta:$root/web-frontend/lib" );

    my $out;
    $tt->process($file, $params, \$out)
      or do {
          $r->log_reason( $tt->error );
          return SERVER_ERROR;
      };

    $r->header_out( @$_ ) for @headers;
    $r->content_type('text/html');
    $r->send_http_header;
    $r->print( $out );

    return OK;
}

1;
