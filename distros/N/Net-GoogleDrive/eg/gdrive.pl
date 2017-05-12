#!/usr/bin/perl

use common::sense;

use CGI qw/:standard/;
use Net::GoogleDrive;

my $q = CGI->new();
print($q->header(-type => 'text/html', -expires => 'now'));

print("Hi<br>\n");

my $config = Storable::retrieve("$ENV{DOCUMENT_ROOT}/config.storable");

#
# Needs:
#
# scope
# redirect_uri
# client_id
# client_secret
# 
my $gdrive = Net::GoogleDrive->new(%{ $config });

if ($q->param("code")) {
    print("code: ", $q->param("code"), "<br>");

    $gdrive->token($q->param("code"));

    my $files = $gdrive->files();
    print("files: $#{ $$files{items} }<br>");

    foreach my $f (@{ $$files{items} }) {
        print("$$f{title}<br>\n");
    }
}
else {
    print($q->a({href=>$gdrive->login_link()}, "login"));
}
