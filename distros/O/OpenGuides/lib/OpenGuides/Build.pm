package OpenGuides::Build;

use strict;

use vars qw( $VERSION );
$VERSION = '0.04';

use Module::Build;
use OpenGuides::Config;
use File::Path;
use base 'Module::Build';

sub ACTION_install {
    my $self = shift;
    $self->SUPER::ACTION_install;
    $self->ACTION_install_extras;

    eval "use Config::Tiny";
    die "Config::Tiny is required to set up this application.\n" if $@;

    my $config = OpenGuides::Config->new( file => "wiki.conf" );

    # Initialise the database if necessary.
    # Using destdir here is a bit far-fetched, unless we expect
    # packagers to ship pre-initialised databases. However, it is
    # better than ignoring it. A better solution would be to allow
    # more control over whether the database is initialised here.
    my $dbname = ( $config->dbtype eq 'sqlite' && defined $self->destdir ) ?
        File::Spec->catdir($self->destdir, $config->dbname) :
        $config->dbname;
    my $dbuser = $config->dbuser;
    my $dbpass = $config->dbpass;
    my $dbhost = $config->dbhost;
    my $dbtype = $config->dbtype;

    my %cgi_wiki_exts = ( postgres => "Pg",
			  mysql    => "MySQL",
			  sqlite   => "SQLite" );

    my $cgi_wiki_module = "Wiki::Toolkit::Setup::" . $cgi_wiki_exts{$dbtype};
    eval "require $cgi_wiki_module";
    die "There was a problem: $@" if $@;

    print "Checking database schema...\n";
    {
	no strict 'refs';
        &{$cgi_wiki_module . "::setup"}( $dbname, $dbuser, $dbpass, $dbhost );
    }
}

sub ACTION_fakeinstall {
    my $self = shift;
    $self->SUPER::ACTION_fakeinstall;
    $self->ACTION_install_extras( fake => 1 );
    print "Checking database schema...\n";
}

sub ACTION_install_extras {
    my ($self, %args) = @_;
    my $FAKE = $args{fake} || 0;

    eval "use Config::Tiny";
    die "Config::Tiny is required to set up this application.\n" if $@;

    my $config = OpenGuides::Config->new( file => "wiki.conf" );

    # Install the scripts where we were told to.
    my $install_directory    = defined $self->destdir ? File::Spec->catdir( $self->destdir, $config->install_directory ) : $config->install_directory;
    my $script_name          = $config->script_name;
    my $template_path        = defined $self->destdir ? File::Spec->catdir( $self->destdir, $config->template_path ) : $config->template_path;
    my $custom_template_path = defined $self->destdir ? File::Spec->catdir( $self->destdir, $config->custom_template_path ) : $config->custom_template_path;
    my $custom_lib_path      = $config->custom_lib_path;
    my $static_path          = defined $self->destdir ? File::Spec->catdir( $self->destdir, $config->static_path ) : $config->static_path;
    my @extra_scripts        = @{ $self->config_data( "__extra_scripts" ) };
    my @templates            = @{ $self->config_data( "__templates" ) };
    my @static_files         = @{ $self->config_data( "__static_files" ) };

    print "Installing scripts to $install_directory:\n";
    # Allow for blank script_name - assume "index.cgi".
        my $script_filename = $script_name || "index.cgi";
    if ( $FAKE ) {
        print "wiki.cgi -> $install_directory/$script_filename (FAKE)\n";
    } else {
        if ( $script_filename ne "wiki.cgi" ) {
            File::Copy::copy("wiki.cgi", $script_filename)
	        or die "Can't copy('wiki.cgi', '$script_filename'): $!";
	}
        my $copy = $self->copy_if_modified(
                                            $script_filename,
                                            $install_directory
                                          );
        if ( $copy ) {
            $self->fix_shebang_line($copy);
	    $self->make_executable($copy);
            $self->add_custom_lib_path( $copy, $custom_lib_path )
              if $custom_lib_path;
        } else {
            print "Skipping $install_directory/$script_filename (unchanged)\n";
        }
        print "(Really: wiki.cgi -> $install_directory/$script_filename)\n"
            unless $script_filename eq "wiki.cgi";
    }

    if ( $FAKE ) {
        print "Trying to ensure that wiki.conf is protected.\n";
    } else {
        my $mentionswikidotconf = 0;
        print "Trying to ensure that wiki.conf is protected by .htaccess.. ";
        if (-f "$install_directory/.htaccess") {
	    if (open HTACCESS, "$install_directory/.htaccess") {
                while (<HTACCESS>) {
                    if (/wiki\.conf/) {
                        $mentionswikidotconf = 1;
                    }
                }
	        close HTACCESS;
            } else {
                warn "Could not open $install_directory/.htaccess for reading: $!";
            }
        }
        if ($mentionswikidotconf == 0) {
            if (open HTACCESS, ">>$install_directory/.htaccess") {
                print HTACCESS "# Added by OpenGuides installer\n";
                print HTACCESS "<Files wiki.conf>\ndeny from all\n</Files>";
                close HTACCESS;
                print "apparent success. You should check that this is working!\n";
            } else {
                warn "Could not open $install_directory/.htaccess for writing: $!";
            }
        } else {
            print ".htaccess appears to already mention wiki.conf.\n";
        }
    }

    foreach my $script ( @extra_scripts ) {
        if ( $FAKE ) {
	    print "$script -> $install_directory/$script (FAKE)\n";
        } else {
	    my $copy = $self->copy_if_modified( $script, $install_directory );
	    if ( $copy ) {
		$self->fix_shebang_line($copy);
		$self->make_executable($copy) unless $script eq "wiki.conf";
                $self->add_custom_lib_path( $copy, $custom_lib_path )
                  if $custom_lib_path;
	    } else {
		print "Skipping $install_directory/$script (unchanged)\n";
	    }
        }
    }

    print "Installing templates to $template_path:\n";
    foreach my $template ( @templates ) {
        if ( $FAKE ) {
            print "templates/$template -> $template_path/$template (FAKE)\n";
	    } else {
	        $self->copy_if_modified(from => "templates/$template", to_dir => $template_path, flatten => 1)
                or print "Skipping $template_path/$template (unchanged)\n";
        }
    }
    if ( $FAKE ) {
        print "Making $custom_template_path.\n";
    } else {
        unless (-d $custom_template_path) {
            print "Creating directory $custom_template_path.\n";
            File::Path::mkpath $custom_template_path or warn "Could not make $custom_template_path";
        }
    }

    print "Installing static files to $static_path:\n";
    foreach my $static_file ( @static_files ) {
        if ( $FAKE ) {
            print "static/$static_file -> $static_path/$static_file (FAKE)\n";
        } else {
            $self->copy_if_modified(from => "static/$static_file", to_dir => $static_path, flatten => 1)
                or print "Skipping $static_path/$static_file (unchanged)\n";
        }
    }
}

sub add_custom_lib_path {
    my ($self, $copy, $lib_path) = @_;
    local $/ = undef;
    open my $fh, $copy or die $!;
    my $content = <$fh>;
    close $fh or die $!;
    $content =~ s|use strict;|use strict\;\nuse lib qw( $lib_path )\;|s;

    # Make sure we can write to the file before we try to (see perldoc -f stat)
    my @file_info = stat( $copy );
    my $orig_mode = $file_info[2] & 07777;
    chmod( $orig_mode | 0222, $copy )
        or warn "Couldn't make $copy writeable: $!";
    open $fh, ">$copy" or die $!;
    print $fh $content;
    close $fh or die $!;
    chmod( $orig_mode, $copy )
        or warn "Couldn't restore permissions on $copy: $!";

    return 1;
}

1;
