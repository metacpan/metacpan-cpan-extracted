#!/usr/bin/perl

use Cwd;

my $website	= $ARGV[0];
my $ns		= $ARGV[1] || &ns($website);

die "Usage: puzzle_setup.pl www.yourwebsite.com namespace" unless ($website);

print "This script will create\n\t$website\nfolder in\n\t". getcwd(). 
	"\nwith namespace\n\t$ns" .
	"\nContinue? [y/n]: ";

my $rep = <STDIN>;
exit unless ($rep eq "y\n");

mkdir $website,0775 or die "Folder $website already exists";
mkdir "$website/logs",0775 or die "Folder $website/logs already exists";;
mkdir "$website/www",0775 or die "Folder $website/www already exists";;
mkdir "$website/lib",0775 or die "Folder $website/lib already exists";;
mkdir "$website/conf",0775 or die "Folder $website/conf already exists";;

open(FILE,">$website/conf/httpd.conf") 
	or die "Unable to create $website/conf/httpd.conf";

print FILE<<"";
<VirtualHost $website:80>
	DocumentRoot "/www/$website/www"
	ServerName $website
	ServerAdmin info\@$website
	DirectoryIndex index.mpl index.htm
	ErrorLog /www/$website/logs/error_log
	CustomLog /www/$website/logs/access_log_cmb combined
	<IfModule mod_perl.c>
		AddType	text/html .mpl
		PerlSetVar ServerName "$website"
		PerlSetVar MasonErrorMode output 
		PerlSetVar MasonStaticSource 0
		<Perl>
			use lib '/www/$website/lib';
		</Perl>
		<FilesMatch "\\.(htm|mpl|pl)\$">
			SetHandler  perl-script
			PerlHandler Puzzle::MasonHandler
		</FilesMatch>
		<LocationMatch "(\\.mplcom|handler|\\.htt|\\.yaml)\$|autohandler">
			Order deny,allow 
			Deny from All
		</LocationMatch>
	</IfModule>
</VirtualHost>                                  

close(FILE);

open(FILE,">$website/www/config.yaml") 
	or die "Unable to create $website/www/config.yaml";

print FILE<<EOF;
frames:            0
base:              ~
frame_top_file:    ~
frame_right_file:  ~
frame_bottom_file: ~
frame_left_file:   ~

# you MUST CHANGE auth component because this is a trivial auth controller
# auth_class:   "Puzzle::Session::Auth"
# auth_class:   "${ns}::Auth"
gids:          
              - everybody

login:        /login.mpl

namespace:    $ns
description:  ""
keywords:     ""

debug:        1
cache:        0

db:
  enabled:                0
#  persistent_connection:  0
#  username:               $ns
#  password:               SET_YOUR_PASSWORD
#  host:                   localhost
#  name:                   $ns
#  session_table:          sysSessions

#traslation:
#en:           "${ns}::Lang::en"
#it:           "${ns}::Lang::it"
#default:      en

#mail:
#  server:       "YOUR.SMTP.SERVER"
#  from:         "YOUR\@EMAIL.COM"

#page:
#  center:       "${ns}::Page::Center"
#debug_class:   "Puzzle::Debug"
EOF

close(FILE);


open(FILE,">$website/www/autohandler") 
	or die "Unable to create $website/www/autohandler";

print FILE<<EOF;
<%once>
	use Puzzle;
	use $ns;
</%once>

<%init>
	\$${ns}::puzzle ||= new Puzzle(cfg_path => \$m->interp->comp_root
		.  '/config.yaml');
	#\$${ns}::dbh = \$${ns}::puzzle->dbh;
	\$${ns}::puzzle->process_request;
</%init>
EOF

close(FILE);

open(FILE,">$website/lib/$ns.pm") 
	or die "Unable to create $website/www/$ns.pm";

print FILE<<EOF;
package $ns;

our \$puzzle;
our \$dbh;

1;
EOF

print "Creation completed. Your next step is to manually configure" .
 "\n\t$website/www/config.yaml\naccording to your preferences\n";


sub ns {
	my $ws 	= shift;
	my @i	= split /\./,$ws;
	if ($i[0] eq 'www') {
		return substr($i[1],0,3);
	} else {
		return substr($i[0],0,3);
	}
}

__END__


