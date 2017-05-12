#! /usr/bin/perl -I /home/dag/projects/perlstack/unstable/yadis/lib -I /home/dag/projects/perlstack/unstable/openid/lib

use CGI;
use CGI::Session;
use File::Spec;
use Net::OpenID::JanRain::Consumer;
use Net::OpenID::JanRain::Stores::FileStore;

my $STORE_DIR = File::Spec->tmpdir.'/openid/store';
my $SESSION_DIR = File::Spec->tmpdir.'/openid/session';

my $cgi = new CGI;
my $session = new CGI::Session(undef, $cgi, {Directory => $SESSION_DIR});
$cookie = $cgi->cookie(CGISESSID => $session->id );

my $store = Net::OpenID::JanRain::Stores::FileStore->new($STORE_DIR);
my $consumer = Net::OpenID::JanRain::Consumer->new($session, $store);

my $user_url = $cgi->param('openid_url');
if($user_url) { # Begin OpenID transaction
    my $request = $consumer->begin($user_url);
    if($request->status eq 'failure') { # this is an unrecoverable discovery failure
        display_failure($request);
    }
    else { # Redirect to OpenID server
        my $trust_root = $cgi->url(-base => 1);
        my $return_to = $cgi->url;
        my $redirect_url = $request->redirectURL($trust_root, $return_to);
        print $cgi->header(-cookie=>$cookie,-location=>$redirect_url);
    }
}
elsif ($cgi->param('openid.mode')) { # We're back from the server
    my %query = $cgi->Vars;
    my $response = $consumer->complete(\%query);
    if ($response->status eq 'success') {
        display_success($response);
    }
    elsif ($response->status eq 'failure') {
        display_failure($response);
    }
    elsif ($response->status eq 'cancel') {
        display_cancel($response);
    }
    else {
        warn "I don't know what to do with a ".$response->status." response!\n";
    }
}
else {
    print $cgi->header(-cookie=>$cookie);
    print $cgi->start_html('Perl OpenID consumer example'),
          $cgi->h1('Perl OpenID consumer example');
    display_openid_form();
    print $cgi->end_html;
}

exit(0);

sub display_failure {
    my $response = shift;

    print $cgi->header(-cookie=>$cookie);
    print $cgi->start_html('OpenID Failure'),
          $cgi->h1('OpenID Failure'),
          $cgi->p($response->{message});

    print $cgi->p($response->{identity_url}) if $response->{identity_url};
    display_openid_form();
    print $cgi->end_html;
}

sub display_cancel {
    my $response = shift;

    print $cgi->header(-cookie=>$cookie);
    print $cgi->start_html('OpenID Cancelled'),
          $cgi->h1('OpenID Cancelled'),

    print $cgi->p($response->{identity_url}) if $response->{identity_url};
    display_openid_form();
    print $cgi->end_html;
}


sub display_success {
    my $response = shift;

    print $cgi->header(-cookie=>$cookie);
    my $id_url = $response->{identity_url};
    
    print $cgi->start_html('OpenID Success'),
          $cgi->h1('OpenID Success'),
          $cgi->p("Verification of $id_url succeeded.");
    display_openid_form();
    print $cgi->end_html;
}

sub display_openid_form {
    print $cgi->start_form,
          "Enter an OpenID URL:",
          $cgi->textfield('openid_url'),
          $cgi->submit('Submit'),
          $cgi->end_form;
}
