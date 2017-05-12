package Provision::Unix::Web::Apache;
# ABSTRACT: provision web hosting accounts on Apache
$Provision::Unix::Web::Apache::VERSION = '1.08';
use strict;
use warnings;

use English qw( -no_match_vars );
use Params::Validate qw( :all );

my ( $prov, $util, $web );

sub new {
    my $class = shift;

    my %p = validate(
        @_,
        {   prov  => { type => OBJECT },
            web   => { type => OBJECT },
            debug => { type => BOOLEAN, optional => 1, default => 1 },
            fatal => { type => BOOLEAN, optional => 1, default => 1 },
        }
    );

    $web  = $p{web};
    $prov = $p{prov};
    ## no critic
    eval "require Apache::Admin::Config";
    ## use critic
    if ( $EVAL_ERROR ) {
        return $prov->error( 'Apache::Admin::Config not installed', 
            fatal => $p{fatal}, 
            debug => $p{debug},
        );
    };
    $util = $prov->get_util;

    my $self = {};
    bless( $self, $class );

    return $self;
}

sub create {

    my $self = shift;

    my %p = validate(
        @_,
        {   'request'   => { type => HASHREF, optional => 1, },
            'prompt'    => { type => BOOLEAN, optional => 1, default => 0 },
            'test_mode' => { type => BOOLEAN, optional => 1, default => 0 },
            'fatal'     => { type => SCALAR,  optional => 1, default => 1 },
            'debug'     => { type => SCALAR,  optional => 1, default => 1 },
        },
    );

    my $vals = $web->get_vhost_attributes(
        {   request => $p{request},
            prompt  => $p{prompt},
        }
    );

    $prov->audit("apache create");

    if ( $self->exists( request => $vals ) ) {
        return $prov->error( "that virtual host already exists", );
    }

    # test all the values and make sure we've got enough to form a vhost
    # minimum needed: vhost servername, ip[:port], documentroot

    my $ip      = $vals->{'ip'} || '*:80';
    my $name    = lc( $vals->{'vhost'} );
    my $docroot = $vals->{'documentroot'};
    my $home    = $vals->{'admin_home'} || "/home";

    unless ($docroot) {
        if ( -d "$home/$name" ) { $docroot = "$home/$name" }
        return $prov->error( 
                "documentroot was not set and could not be determined!", )
            unless -d $docroot;
    }

    if ( $p{debug} ) { use Data::Dumper; print Dumper($vals); }

    # define the vhost
    my @lines = "\n<VirtualHost $ip>";
    push @lines, "	ServerName $name";
    push @lines, "	DocumentRoot $docroot";
    push @lines, "	ServerAdmin " . $vals->{'serveradmin'}
        if $vals->{'serveradmin'};
    push @lines, "	ServerAlias " . $vals->{'serveralias'}
        if $vals->{'serveralias'};
    if ( $vals->{'cgi'} ) {
        if ( $vals->{'cgi'} eq "basic" ) {
            push @lines,
                "	ScriptAlias /cgi-bin/ \"/usr/local/www/cgi-bin.basic/";
        }
        elsif ( $vals->{'cgi'} eq "advanced" ) {
            push @lines,
                "	ScriptAlias /cgi-bin/ \"/usr/local/www/cgi-bin.advanced/\"";
        }
        elsif ( $vals->{'cgi'} eq "custom" ) {
            push @lines,
                  "	ScriptAlias /cgi-bin/ \""
                . $vals->{'documentroot'}
                . "/cgi-bin/\"";
        }
        else {
            push @lines, "	ScriptAlias " . $vals->{'cgi'};
        }

    }

# options needs some directory logic included if it's going to be used
# I won't be using this initially, but maybe eventually...
#push @lines, "	Options "      . $vals->{'options'}      if $vals->{'options'};

    push @lines, "	CustomLog " . $vals->{'customlog'} if $vals->{'customlog'};
    push @lines, "	CustomError " . $vals->{'customerror'}
        if $vals->{'customerror'};
    if ( $vals->{'ssl'} ) {
        if (   !$vals->{'sslkey'}
            or !$vals->{'sslcert'}
            or !-f $vals->{'sslkey'}
            or !$vals->{'sslcert'} )
        {
            return $prov->error( 
                    "ssl is enabled but either the key or cert is missing!" );
        }
        push @lines, "	SSLEngine on";
        push @lines, "	SSLCertificateKey " . $vals->{'sslkey'}
            if $vals->{'sslkey'};
        push @lines, "	SSLCertificateFile " . $vals->{'sslcert'}
            if $vals->{'sslcert'};
    }
    push @lines, "</VirtualHost>\n";

    # write vhost definition to a file
    my ($vhosts_conf) = $self->get_file($vals);

    return 1 if $p{test_mode};

    if ( -f $vhosts_conf ) {
        $prov->audit("appending to file: $vhosts_conf");
        $util->file_write( $vhosts_conf,
            lines  => \@lines,
            append => 1,
        );
    }
    else {
        $prov->audit("writing to file: $vhosts_conf");
        $util->file_write( $vhosts_conf, lines => \@lines );
    }

    $self->restart($vals);

    $prov->audit("returning success");
    return 1;
}

sub conf_get_dir {

    my $self = shift;
    my %p    = validate(
        @_,
        {   'conf'  => HASHREF,
            'debug' => { type => SCALAR, optional => 1, default => 1 },
        },
    );

    my $conf = $p{'conf'};

    my $prefix    = "/usr/local";
    my $apachectl = "$prefix/sbin/apachectl";

    unless ( -x $apachectl ) {
        $apachectl = $util->find_bin( "apachectl",
            debug => 0,
            fatal => 0
        );

        unless ( -x $apachectl ) {
            die "apache->conf_get_dir: failed to find apachectl!
        Is Apache installed correctly?\n";
        }
    }

    # the -V flag to apachectl returns this string:
    #  -D SERVER_CONFIG_FILE="etc/apache22/httpd.conf"

    # and we can grab the path to httpd.conf from the string
    if ( grep ( /SERVER_CONFIG_FILE/, `$apachectl -V` ) =~ /=\"(.*)\"/ ) {

        # and return a fully qualified path to httpd.conf
        if ( -f "$prefix/$1" && -s "$prefix/$1" ) {
            return "$prefix/$1";
        }

        warn
            "apachectl returned $1 as the location of your httpd.conf file but $prefix/$1 does not exist! I'm sorry but I cannot go on like this. Please fix your Apache install and try again.\n";
    }

    # apachectl did not return anything useful from -V, must be apache 1.x
    my @paths;
    my @found;

    if ( $OSNAME eq "darwin" ) {
        push @paths, "/opt/local/etc";
        push @paths, "/private/etc";
    }
    elsif ( $OSNAME eq "freebsd" ) {
        push @paths, "/usr/local/etc";
    }
    elsif ( $OSNAME eq "linux" ) {
        push @paths, "/etc";
    }
    else {
        push @paths, "/usr/local/etc";
        push @paths, "/opt/local/etc";
        push @paths, "/etc";
    }

PATH:
    foreach my $path (@paths) {
        if ( !-e $path && !-d $path ) {
            next PATH;
        }

        @found = `find $path -name httpd.conf`;
        chomp @found;
        foreach my $find (@found) {
            if ( -f $find ) {
                return $find;
            }
        }
    }

    return;
}

sub restart {

    my ( $self, $vals ) = @_;

    # restart apache

    print "restarting apache.\n" if $vals->{'debug'};

    if ( -x "/usr/local/etc/rc.d/apache2.sh" ) {
        $util->syscmd( "/usr/local/etc/rc.d/apache2.sh stop" );
        $util->syscmd( "/usr/local/etc/rc.d/apache2.sh start" );
    }
    elsif ( -x "/usr/local/etc/rc.d/apache.sh" ) {
        $util->syscmd( "/usr/local/etc/rc.d/apache.sh stop" );
        $util->syscmd( "/usr/local/etc/rc.d/apache.sh start" );
    }
    else {
        my $apachectl = $util->find_bin( "apachectl" );
        if ( -x $apachectl ) {
            $util->syscmd( "$apachectl graceful" );
        }
        else {
            warn "WARNING: couldn't restart Apache!\n ";
        }
    }
}

sub enable {

    my $self = shift;

    my %p = validate( @_, { request => { type => HASHREF } } );
    my $vals = $p{'request'};

    if ( $self->exists( request => $vals) ) {
        return {
            error_code => 400,
            error_desc => "Sorry, that virtual host is already enabled."
        };
    }

    print "enabling $vals->{'vhost'} \n";

    # get the file the disabled vhost would live in
    my ($vhosts_conf) = $self->get_file($vals);

    print "the disabled vhost should be in $vhosts_conf.disabled\n"
        if $vals->{'debug'};

    unless ( -s "$vhosts_conf.disabled" ) {
        return {
            error_code => 400,
            error_desc => "That vhost is not disabled, I cannot enable it!"
        };
    }

    $vals->{'disabled'} = 1;

    # split the file into two parts
    ( undef, my $match, $vals ) = $self->get_match($vals);

    print "enabling: \n", join( "\n", @$match ), "\n";

    # write vhost definition to a file
    if ( -f $vhosts_conf ) {
        print "appending to file: $vhosts_conf\n" if $vals->{'debug'};
        $util->file_write( $vhosts_conf,
            lines  => $match,
            append => 1
        );
    }
    else {
        print "writing to file: $vhosts_conf\n" if $vals->{'debug'};
        $util->file_write( $vhosts_conf, lines => $match );
    }

    $self->restart($vals);

    if ( $vals->{'documentroot'} ) {
        print "docroot: $vals->{'documentroot'} \n";

        # chmod 755 the documentroot directory
        if ( $vals->{'documentroot'} && -d $vals->{'documentroot'} ) {
            my $chmod = $util->find_bin( "chmod" );
            $util->syscmd( "$chmod 755 $vals->{'documentroot'}" );
        }
    }

    print "returning success or error\n" if $vals->{'debug'};
    return { error_code => 200, error_desc => "vhost enabled successfully" };
}

sub disable {
    my $self = shift;

    my %p = validate( @_, { request => { type => HASHREF } } );
    my $vals = $p{'request'};

    if ( ! $self->exists( request => $vals) ) {
        warn "Sorry, that virtual host does not exist.";
        return;
    }

    print "disabling $vals->{'vhost'}\n";

    # get the file the vhost lives in
    $vals->{'disabled'} = 0;
    my ($vhosts_conf) = $self->get_file($vals);

    # split the file into two parts
    ( my $new, my $match, $vals ) = $self->get_match($vals);

    print "Disabling: \n" . join( "\n", @$match ) . "\n";

    $util->file_write( "$vhosts_conf.new", lines => $new );

    # write out the .disabled file (append if existing)
    if ( -f "$vhosts_conf.disabled" ) {

        # check to see if it's already in there
        $vals->{'disabled'} = 1;
        ( undef, my $dis_match, $vals ) = $self->get_match($vals);

        if ( @$dis_match[1] ) {
            print "it's already in $vhosts_conf.disabled. skipping append.\n";
        }
        else {

            # if not, append it
            print "appending to file: $vhosts_conf.disabled\n"
                if $vals->{'debug'};
            $util->file_write( "$vhosts_conf.disabled",
                lines  => $match,
                append => 1,
            );
        }
    }
    else {
        print "writing to file: $vhosts_conf.disabled\n" if $vals->{'debug'};
        $util->file_write( "$vhosts_conf.disabled",
            lines => $match,
        );
    }

    if ( ( -s "$vhosts_conf.new" ) && ( -s "$vhosts_conf.disabled" ) ) {
        print "Yay, success!\n" if $vals->{'debug'};
        if ( $< eq 0 ) {
            use File::Copy;    # this only works if we're root
            move( "$vhosts_conf.new", $vhosts_conf );
        }
        else {
            my $mv = $util->find_bin( "move" );
            $util->syscmd( "$mv $vhosts_conf.new $vhosts_conf" );
        }
    }
    else {
        return {
            error_code => 500,
            error_desc =>
                "Oops, the size of $vhosts_conf.new or $vhosts_conf.disabled is zero. This is a likely indication of an error. I have left the files for you to examine and correct"
        };
    }

    $self->restart($vals);

    # chmod 0 the HTML directory
    if ( $vals->{'documentroot'} && -d $vals->{'documentroot'} ) {
        my $chmod = $util->find_bin( "chmod" );
        $util->syscmd( "$chmod 0 $vals->{'documentroot'}" );
    }

    print "returning success or error\n" if $vals->{'debug'};
    return { error_code => 200, error_desc => "vhost disabled successfully" };
}

sub destroy {

    my ( $self, $vals ) = @_;

    unless ( $self->exists( request => $vals) ) {
        return {
            error_code => 400,
            error_desc => "Sorry, that virtual host does not exist."
        };
    }

    print "deleting vhost " . $vals->{'vhost'} . "\n";

# this isn't going to be pretty.
# basically, we need to parse through the config file, find the right vhost container, and then remove only that vhost
# I'll do that by setting a counter that trips every time I enter a vhost and counts the lines (so if the servername declaration is on the 5th or 1st line, I'll still know where to nip the first line containing the virtualhost opening declaration)
#

    my ($vhosts_conf) = $self->get_file($vals);
    my ( $new, $drop ) = $self->get_match($vals);

    print "Dropping: \n" . join( "\n", @$drop ) . "\n";

    if ( scalar @$new == 0 || scalar @$drop == 0 ) {
        return {
            error_code => 500,
            error_desc => "yikes, something went horribly wrong!"
        };
    }

    # now, just for fun, lets make sure things work out OK
    # we'll write out @new and @drop and compare them to make sure
    # the two total the same size as the original

    $util->file_write( "$vhosts_conf.new",  lines => $new );
    $util->file_write( "$vhosts_conf.drop", lines => $drop );

    if ( ( ( -s "$vhosts_conf.new" ) + ( -s "$vhosts_conf.drop" ) )
        == -s $vhosts_conf )
    {
        print "Yay, success!\n";
        use File::Copy;
        move( "$vhosts_conf.new", $vhosts_conf );
        unlink("$vhosts_conf.drop");
    }
    else {
        return {
            error_code => 500,
            error_desc =>
                "Oops, the size of $vhosts_conf.new and $vhosts_conf.drop combined is not the same as $vhosts_conf. This is a likely indication of an error. I have left the files for you to examine and correct"
        };
    }

    $self->restart($vals);

    print "returning success or error\n" if $vals->{'debug'};
    return { error_code => 200, error_desc => "vhost deletion successful" };
}

sub get_vhosts {
    my $self = shift;

    my $vhosts_conf = $prov->{config}{Apache}{vhosts};
    return $vhosts_conf if $vhosts_conf;

    $vhosts_conf
        = lc( $OSNAME eq 'linux' )   ? '/etc/httpd/conf.d'
        : lc( $OSNAME eq 'darwin' )  ? '/etc/apache2/extra/httpd-vhosts.conf'
        : lc( $OSNAME eq 'freebsd' ) ? '/usr/local/etc/apache2/Includes'
        :   warn "could not determine where your apache vhosts are\n";

    return $vhosts_conf if $vhosts_conf;
    $prov->error( "you must set [Apache][etc] in provision.conf" );
}

sub exists {

    my $self = shift;

    my %p = validate( @_, { request => { type => HASHREF } } );
    my $vals = $p{'request'};

    my $vhost       = lc( $vals->{vhost} );
    my $vhosts_conf = $self->get_vhosts;

    if ( -d $vhosts_conf ) {

       # test to see if the vhosts exists
       # this implies some sort of unique naming mechanism for vhosts
       # For now, this requires that the file be the same as the domain name
       # (example.com) for the domain AND any subdomains. This means subdomain
       # declarations live within the domain file.

        my ($vh_file_name) = $vhost =~ /([a-z0-9-]+\.[a-z0-9-]+)(\.)?$/;
        $prov->audit("cleaned up vhost name: $vh_file_name");

        $prov->audit("searching for vhost $vhost in $vh_file_name");
        my $vh_file_path = "$vhosts_conf/$vh_file_name.conf";
        
        if ( !-f $vh_file_path ) {   # file does not exist
            $prov->audit("vhost $vhost does not exist");
            return;
        }; 

        # the file exists that the virtual host should be in.
        # determine if the vhost is defined in it
        require Apache::ConfigFile;
        my $ac =
          Apache::ConfigFile->read( file => $vh_file_path, ignore_case => 1 );

        for my $vh ( $ac->cmd_context( VirtualHost => '*:80' ) ) {
            my $server_name = $vh->directive('ServerName');
            $prov->audit( "ServerName $server_name") if $vals->{'debug'};
            return 1 if ( $vhost eq $server_name );

            my $alias = 0;
            foreach my $server_alias ( $vh->directive('ServerAlias') ) {
                return 1 if ( $vhost eq $server_alias );
                if ( $vals->{'debug'} ) {
                    print "\tServerAlias  " unless $alias;
                    print "$server_alias ";
                }
                $alias++;
            }
            print "\n" if ( $alias && $vals->{'debug'} );
        }
        return 0;
    }
    elsif ( -f $vhosts_conf ) {
        print "parsing vhosts from file $vhosts_conf\n";

#        my $ac =
#          Apache::ConfigFile->read( file => $vhosts_conf, ignore_case => 1 );

     #        for my $vh ( $ac->cmd_context( VirtualHost => '*:80' ) ) {
     #            my $server_name = $vh->directive('ServerName');
     #            print "ServerName $server_name\n" if $vals->{'debug'};
     #            return 1 if ( $vhost eq $server_name );
     #
     #            my $alias = 0;
     #            foreach my $server_alias ( $vh->directive('ServerAlias') ) {
     #                return 1 if ( $vhost eq $server_alias );
     #                if ( $vals->{'debug'} ) {
     #                    print "\tServerAlias  " unless $alias;
     #                    print "$server_alias ";
     #                }
     #                $alias++;
     #            }
     #            print "\n" if ( $alias && $vals->{'debug'} );
     #        }

        return;
    }

    return;
}

sub show {

    my ( $self, $vals ) = @_;

    unless ( $self->exists($vals) ) {
        return {
            error_code => 400,
            error_desc => "Sorry, that virtual host does not exist."
        };
    }

    my ($vhosts_conf) = $self->get_file($vals);

    ( my $new, my $match, $vals ) = $self->get_match($vals);
    print "showing: \n" . join( "\n", @$match ) . "\n";

    return { error_code => 100, error_desc => "exiting normally" };
}

sub get_file {

    my ( $self, $vals ) = @_;

    # determine the path to the file the vhost is stored in
    my $vhosts_conf = $self->get_vhosts();
    if ( -d $vhosts_conf ) {
        my ($vh_file_name)
            = lc( $vals->{'vhost'} ) =~ /([a-z0-9-]+\.[a-z0-9-]+)(\.)?$/;
        $vhosts_conf .= "/$vh_file_name.conf";
    }
    else {
        if ( $vhosts_conf !~ /\.conf$/ ) {
            $vhosts_conf .= ".conf";
        }
    }

    return $vhosts_conf;
}

sub get_match {

    my ( $self, $vals ) = @_;

    my ($vhosts_conf) = $self->get_file($vals);
    $vhosts_conf .= ".disabled" if $vals->{'disabled'};

    print "reading in the vhosts file $vhosts_conf\n" if $vals->{'debug'};
    my @lines = $util->file_read( $vhosts_conf);

    my ( $in, $match, @new, @drop );
LINE: foreach my $line (@lines) {
        if ($match) {
            print "match: $line\n" if $vals->{'debug'};
            push @drop, $line;
            if ( $line =~ /documentroot[\s+]["]?(.*?)["]?[\s+]?$/i ) {
                print "setting documentroot to $1\n" if $vals->{'debug'};
                $vals->{'documentroot'} = $1;
            }
        }
        else { push @new, $line }

        if ( $line =~ /^[\s+]?<\/virtualhost/i ) {
            $in    = 0;
            $match = 0;
            next LINE;
        }

        $in++ if $in;

        if ( $line =~ /^[\s+]?<virtualhost/i ) {
            $in = 1;
            next LINE;
        }

        my ($servername) = $line =~ /([a-z0-9-\.]+)(:\d+)?(\s+)?$/i;
        if ( $servername && $servername eq lc( $vals->{'vhost'} ) ) {
            $match = 1;

            # determine how many lines are in @new
            my $length = @new;
            print "array length: $length\n" if $vals->{'debug'};

        # grab the lines from @new going back to the <virtualhost> declaration
        # and push them onto @drop
            for ( my $i = $in; $i > 0; $i-- ) {
                push @drop, @new[ ( $length - $i ) ];
                unless ( $vals->{'documentroot'} ) {
                    if ( @new[ ( $length - $i ) ]
                        =~ /documentroot[\s+]["]?(.*?)["]?[\s+]?$/i )
                    {
                        print "setting documentroot to $1\n"
                            if $vals->{'debug'};
                        $vals->{'documentroot'} = $1;
                    }
                }
            }

            # remove those lines from @new
            for ( my $i = 0; $i < $in; $i++ ) { pop @new; }
        }
    }

    return \@new, \@drop, $vals;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Provision::Unix::Web::Apache - provision web hosting accounts on Apache

=head1 VERSION

version 1.08

=head1 SYNOPSIS

=head1 FUNCTIONS

=head2 create

Create an Apache vhost container like this:

  <VirtualHost *:80 >
    ServerName blockads.com
    ServerAlias ads.blockads.com
    DocumentRoot /usr/home/blockads.com/ads
    ServerAdmin admin@blockads.com
    CustomLog "| /usr/local/sbin/cronolog /usr/home/example.com/logs/access.log" combined
    ErrorDocument 404 "blockads.com
  </VirtualHost>

	my $apache->create($vals, $conf);

	Required values:

         ip  - an ip address
       name  - vhost name (ServerName)
     docroot - Apache DocumentRoot

    Optional values

 serveralias - Apache ServerAlias names (comma seperated)
 serveradmin - Server Admin (email address)
         cgi - CGI directory
   customlog - obvious
 customerror - obvious
      sslkey - SSL certificate key
     sslcert - SSL certificate

=head2 enable

Enable a (previously) disabled virtual host. 

    $apache->enable($vals, $conf);

=head2 disable

Disable a previously disabled vhost.

    $apache->disable($vals, $conf);

=head2 destroy

Delete's an Apache vhost.

    $apache->destroy();

=head2 exists

Tests to see if a vhost definition already exists in your Apache config file(s).

=head2 show

Shows the contents of a virtualhost block that matches the virtual domain name passed in the $vals hashref. 

	$apache->show($vals, $conf);

=head2 get_file

If vhosts are each in their own file, this determines the file name the vhost will live in and returns it. The general methods on my systems works like this:

   example.com would be stored in $apache/vhosts/example.com.conf

so would any subdomains of example.com.

thus, a return value for *.example.com will be "$apache/vhosts/example.com.conf".

$apache is looked up from the contents of $conf.

=head2 get_match

Find a vhost declaration block in the Apache config file(s).

=head1 BUGS

Please report any bugs or feature requests to C<bug-unix-provision-virtualos at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Provision-Unix>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Provision::Unix

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Provision-Unix>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Provision-Unix>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Provision-Unix>

=item * Search CPAN

L<http://search.cpan.org/dist/Provision-Unix>

=back

=head1 ACKNOWLEDGEMENTS

=head1 AUTHOR

Matt Simerson <msimerson@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by The Network People, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
