package PheMail::Vhost;

use 5.006;
use strict;
use warnings;
use DBI;
use vars qw($sth $dbh $sname $sadmin $droot $id $extensions @sextensions $redirect
	    $soptions $i $htaccess $sdomain $servername $users %SQL $hoster $eredirect
	    $safe_mode $open_basedir $magic_quotes $enableauth $authname $disablefunc);

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use PheMail::Vhost ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
		 LoadVhosts	
		 ReportSql
		 alterSqlFromString
		 alterSql
);
our $VERSION = '0.14';


# Preloaded methods go here.
# alter the SQL interface from the outside.
sub alterSqlFromString($$$$$$) {
    ($SQL{'backend'},$SQL{'user'},$SQL{'pass'},$SQL{'database'},$SQL{'hostname'},$SQL{'whoami'}) = @_;
}
sub RandSalt() {
    # function to create a random 2-char salt. Thanks Kimusan.
    my @chars = ('a'..'z','A'..'Z',0..9);
    return join '', map $chars[rand @chars], 1..2;
}
sub ReportSql {
    print "SQL Information:\n---------------\n";
    foreach my $foo (keys %SQL) {
	print $foo." = ".$SQL{$foo}."\n";
    }
}
sub LoadVhosts($) {
    my $VirtualHost = shift;
    $i = 0;
#    $dbh = DBI->connect("DBI:".$SQL{'backend'}.":".$SQL{'database'}.":".$SQL{'hostname'},$SQL{'user'},$SQL{'pass'}); # for MySQL
    $dbh = DBI->connect("DBI:".$SQL{'backend'}.":dbname=".$SQL{'database'}.";host=".$SQL{'hostname'},$SQL{'user'},$SQL{'pass'}) 
	or die("DBI Error: ".DBI::errstr);
    $sth = $dbh->prepare("SELECT * FROM vhosts WHERE hoster='".$SQL{'whoami'}."'");
    $sth->execute();
    while (($id,
	    $hoster,
	    $sname,
	    $droot,
	    $sadmin,
	    $sdomain,
	    $soptions,
	    $htaccess,
	    $users,
	    $extensions,
	    $redirect,
	    $eredirect,
	    $open_basedir,
	    $safe_mode,
	    $magic_quotes,
	    $enableauth,
	    $authname,
	    $disablefunc) = $sth->fetchrow_array()) {
	$i++;
	$droot =~ s/^\///;
	$servername = $sname ? $sname.".".$sdomain : $sdomain;
	if (-d "/home/customers/$sdomain/wwwroot/$droot") {
	    if ($htaccess) {
		open(HT,"> /home/customers/$sdomain/wwwroot/$droot/.htaccess") 
		    or die("Couldn't open: $!");
		print HT $htaccess;
		close(HT);
	    } else {
		system("/bin/rm /home/customers/$sdomain/wwwroot/$droot/.htaccess") 
		    if (-e "/home/customers/$sdomain/wwwroot/$droot/.htaccess");
	  }
	} else {
	    if (!$redirect) {
		warn "PheMail::Vhost: Warning: ".$servername."'s documentroot does not exist.\n";
		next;
	    } 
	}
        @sextensions = split("\n",$extensions) if $extensions;
	my $lamext; 
	push @$lamext, [ "image/x-icon", ".ico" ]; # just to have something for default AddType so it won't fail.
	foreach my $grasp (@sextensions) {
	    chomp($grasp); # remove the latter \n
	    my($dotext,$handler) = split(/:/,$grasp);
	    $handler =~ s/\r//g if $handler; # obviously this created some errors in the arrayref push
	    push @$lamext, [ $handler, $dotext ] if ($dotext && $handler); # push in the new extensions
	}
	my $php_modes; my $php_flags;
	push @$php_modes, [ "sendmail_from", $sadmin ]; # default values in the modes, just to have something
	push @$php_modes, [ "include_path", "/usr/home/customers/$sdomain/wwwroot/$droot:/usr/local/share/pear" ]; # include path
	# disable functions?
	if ($disablefunc) {
	    push @$php_modes, [ "disable_functions", $disablefunc ];
	}
	# -- /disable functions --
	if ($open_basedir > 0) { 
	    push @$php_modes, [ "open_basedir", "/usr/home/customers/".$sdomain."/wwwroot/".$droot ]; 
	}
	if ($safe_mode  > 0) {
	    push @$php_flags, [ "safe_mode", 1 ]; 
	} else {
	    push @$php_flags, [ "safe_mode", 0 ];
	}
	if ($magic_quotes > 0) {
	    push @$php_flags, [ "magic_quotes_gpc", 1 ];
	} else {
	    push @$php_flags, [ "magic_quotes_gpc", 0 ];
	}
	# prepare auth-directory thingie
	my %Location; # decius: reset every time
	if ($enableauth) {
	    print "[+] Enabled HTTP-Auth for vhost $servername..";
	    $authname =~ s/\s/_/g;
	    $Location{'/'} = {
		"Limit" => {
		    "METHODS" => "post get", # no idea why you need this, won't work without though.
		    "require" => "valid-user", 
		},
		"AuthType" => "Basic",
		"AuthName" => ($authname ? $authname : "PheMail"),
		"AuthUserFile" => "/usr/home/customers/$sdomain/wwwroot/$droot/.htpasswd",
	    };
	    print ". done.\n";
	}
	# write users here
	# decius: problem with enabling auth. I'll take a look.
	if ($enableauth) {
	    open(FOOPWD,"> /usr/home/customers/$sdomain/wwwroot/$droot/.htpasswd") or die("Unable to open .htpasswd: $!");
	    print "Writing file for $servername..\n";
	    my @rusers = split(/\n/,$users);
	    foreach my $user (@rusers) {
		$user =~ s/\r//g;
		my($username,$password) = split(/:/,$user);
		print FOOPWD $username.":".crypt($password,&RandSalt)."\n";
	    }
	    close(FOOPWD);
	}
	# enable redirect here
	if ($eredirect) {
	    push @{$VirtualHost->{'*'}}, {
		ServerName       => $servername,
		ServerAdmin      => $sadmin,
		ErrorLog         => "/usr/home/customers/$sdomain/log/httpd-error.log",
		TransferLog      => "/usr/home/customers/$sdomain/log/httpd-access.log",
		Redirect         => [ "/", $redirect ],
	    };
	} else { # no redirect? oh well, write the normal one.
	    push @{$VirtualHost->{'*'}}, {
		ServerName       => $servername,
		ServerAdmin      => $sadmin,
		DocumentRoot     => "/usr/home/customers/$sdomain/wwwroot/$droot",
		ErrorLog         => "/usr/home/customers/$sdomain/log/httpd-error.log",
		TransferLog      => "/usr/home/customers/$sdomain/log/httpd-access.log",
		AddType          => $lamext,
		php_admin_value  => $php_modes,
		php_admin_flag   => $php_flags,
		Directory	 => {
		    "/usr/home/customers/$sdomain/wwwroot/$droot" => {
			Options => $soptions,
			AllowOverride => "All",
		    },
		},
		Location => { 
		    %Location,
		},
	    };
	}
    }
    printf("PheMail: Done loading %d vhosts.\n",$i);
    $sth->finish();
    $dbh->disconnect();
}
1;
__END__
# Below is stub documentation for your module. You better edit it! I did you friggin program.

=head1 NAME

PheMail::Vhost - Perl extension for Apache MySQL Vhost loading

=head1 SYNOPSIS

  use PheMail::Vhost;
  alterSqlFromString("backendtype","user","password","mysqlhost","myip");
  PheMail::LoadVhosts(\%VirtualHost);

=head1 DESCRIPTION

PheMail::Vhost loads vhosts into httpd.conf (Apache 1.3.x) collected from
a MySQL database. Used in Project PheMail.
It is possible to extend it's features to do a lot of other stuff.
Here's a sample MySQL structure:

CREATE TABLE `vhosts` (
  `id` int(11) NOT NULL auto_increment,
  `hoster` varchar(15) NOT NULL default '192.168.1.1',
  `sname` varchar(255) NOT NULL default '',
  `droot` varchar(255) NOT NULL default '',
  `sadmin` varchar(255) NOT NULL default 'spike@printf.dk',
  `domain` varchar(255) NOT NULL default '',
  `soptions` varchar(255) NOT NULL default '',
  `htaccess` text NOT NULL,
  `users` text NOT NULL,
  `extensions` text NOT NULL,
  `redirect` varchar(255) NOT NULL default '',
  `eredirect` enum('1','0') NOT NULL default '0',
  `open_basedir` enum('1','0') NOT NULL default '1',
  `safe_mode` enum('1','0') NOT NULL default '0',
  `magic_quotes` enum('1','0') NOT NULL default '1',
  `enableauth` enum('1','0') NOT NULL default '0',
  `authname` varchar(255) NOT NULL default 'PheMail Protected Area',
  `disablefunc` text NOT NULL,
  PRIMARY KEY  (`id`)
) TYPE=MyISAM;

The fields should be pretty selfexplanatory.
Since this is a part of a project, I don't really support the structure.

=head2 EXPORT

LoadVhosts();
ReportSql();
altersqlFromString();

=head1 AUTHOR

Jesper Noehr, E<lt>jesper@noehr.orgE<gt>

=head1 SEE ALSO

L<perl>, L<DBI>

=head1 TODO

I rewrote the code, it seems pretty stable as it is now. I will need to add more features later.

=cut
