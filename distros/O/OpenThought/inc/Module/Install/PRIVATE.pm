#line 1 "inc/Module/Install/PRIVATE.pm - dist/Module/Install/PRIVATE.pm"
package Module::Install::PRIVATE;

use strict;
use base 'Module::Install::Base';

use File::NCopy();
use Text::Template();

use File::Copy();
use File::Path;
use ExtUtils::MakeMaker qw(prompt);

eval "use 5.005_03";
if( $@ ) {
    print <<EOT;

 =============================================================
   Perl version 5.005_03 or later is required for OpenThought.
   Unfortunatly, you'll need to upgrade in order for it
   to work.  Try installing a new version of Perl to see
   what you're missing :-)
 =============================================================

EOT

   die "Perl version too old, quiting...\n";
}

sub OpenThought { $_[0] };

sub config {
    unless (prompt("\nCan I install some data files now?", 'Y/n') =~ /^y/i) {
        print "Warning: skipping data file installation.\n";
        print "Installation will be incomplete!\n\n";
        return;
    }

    my $OpenThoughtRoot = prompt("\n\n1. OpenThoughtRoot\n\n"                .
            "Directory, preferably *outside* Apache's DocumentRoot, where\n" .
            "you would like OpenThought Application .pl files to "           .
            "reside.\n\n", "/var/www/OpenThought");

    chomp $OpenThoughtRoot;

    my $OpenThoughtApps = prompt("\n\n2. OpenThoughtApps\n\n"                .
            "Directory, preferably *outside* of both Apache's DocumentRoot\n".
            "and the OpenThoughtRoot, where you would like OpenThought\n"    .
            "Application .pm files and templates to reside.\n\n",
            "/var/www/site");

    chomp $OpenThoughtRoot;

    my $OpenThoughtPrefix = prompt("\n3. Prefix\n\n"                         .
            "Directory prefix under which you would like to store\n"         .
            "OpenThought's data files. This includes the config file,\n"     .
            "some templates, and that sort of thing.\n\n", "/usr/local");

    chomp $OpenThoughtPrefix;

    print "\nCopying Files...\n";

    unless ( -d $OpenThoughtRoot ) {
        mkdir $OpenThoughtRoot, 0777  or die
            "Cannot create $OpenThoughtRoot: $!";
    }

    unless ( -d "$OpenThoughtRoot/demo" ) {
        mkdir "$OpenThoughtRoot/demo", 0777 or die
                                "Cannot create '$OpenThoughtRoot/demo': $!";
    }

    unless ( -d $OpenThoughtApps ) {
        mkdir $OpenThoughtApps, 0777 or die
            "Cannot create $OpenThoughtApps: $!";
    }

    unless ( -d $OpenThoughtPrefix ) {
        mkdir $OpenThoughtPrefix, 0777 or die
            "Cannot create $OpenThoughtPrefix: $!";
    }

   my $file = File::NCopy->new(recursive => 1);
   $file->copy("demo_app/demo/*", "$OpenThoughtRoot/demo") or die
    "Cannot copy demo application to $OpenThoughtRoot/demo: $!";

   my $file = File::NCopy->new(recursive => 1);
   $file->copy("demo_app/site/*", "$OpenThoughtApps") or die
    "Cannot copy demo application to $OpenThoughtApps: $!";

   {
        open FH, ">${OpenThoughtRoot}/demo/index.pl" or die
                "Cannot open config file [index.pl]: $!";

        my $template = Text::Template->new(
            SOURCE => "demo_app/demo/index.pl" )
            or die "Couldn't construct template: $Text::Template::ERROR";

        my $result = $template->fill_in(
                            HASH   => {
                                OpenThoughtPrefix => \$OpenThoughtPrefix,
                                OpenThoughtApps   => \$OpenThoughtApps,
                            },
                            OUTPUT => \*FH, );

        unless ( defined $result ) {
            die "Couldn't fill in template: $Text::Template::ERROR";
        }

        close FH;
   }
   print "\n";

   my @config_files = (     "OpenThought.conf",
                            "OpenThought-httpd-mod_perl1.conf",
                            "OpenThought-httpd-mod_perl2.conf",
                            "OpenThought-startup-mod_perl1.pl",
                            "OpenThought-startup-mod_perl2.pl",
                      );

    foreach my $file ( @config_files ) {
        if (-f "${OpenThoughtPrefix}/etc/${file}") {
            File::Copy::copy("openthought/etc/${file}",
                       "${OpenThoughtPrefix}/etc/${file}.backup") or die
                            "Cannot backup config file [$file]: $!";

        print "Backing up existing $file.\n";
        }
   }

   my $file = File::NCopy->new(recursive => 1);
   $file->copy("openthought/*", $OpenThoughtPrefix) or die
                "Cannot copy data files to $OpenThoughtPrefix: $!";

    print "\nFinished copying.\n";
    print "Updating Config Files...\n";

    foreach my $file ( @config_files ) {
        open FH, ">${OpenThoughtPrefix}/etc/${file}" or die
                "Cannot open config file [$file]: $!";

        my $template = Text::Template->new(
            SOURCE => "openthought/etc/$file" )
            or die "Couldn't construct template: $Text::Template::ERROR";

        my $result = $template->fill_in(
                            HASH   => {
                                OpenThoughtRoot   => \$OpenThoughtRoot,
                                OpenThoughtPrefix => \$OpenThoughtPrefix,
                            },
                            OUTPUT => \*FH, );

        unless ( defined $result ) {
            die "Couldn't fill in template: $Text::Template::ERROR";
        }

        close FH;
    }

    print "Finished Updating.\n\n";


    if ( eval { require Apache2 } ) {
        print "You seem to have mod_perl version 2.x available.\n" .
              "You can add the following line to your httpd.conf to \n" .
              "enable OpenThought's mod_perl support:\n\n" .
              "  Include ${OpenThoughtPrefix}/etc/OpenThought-httpd-mod_perl2.conf\n\n";
    }
    elsif ( eval { require Apache } ) {
        print "You seem to have mod_perl version 1.x available.\n" .
              "You can add the following line to your httpd.conf to \n" .
              "enable OpenThought's mod_perl support:\n\n" .
              "  Include ${OpenThoughtPrefix}/etc/OpenThought-httpd-mod_perl1.conf\n\n";
    }

}

1;
