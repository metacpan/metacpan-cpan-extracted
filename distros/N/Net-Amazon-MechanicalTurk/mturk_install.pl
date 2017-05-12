#!/usr/bin/perl
package MTurkInstaller;
use Config;
use strict;
use IO::Dir;
use File::Basename;
use Cwd;

our %MODULES = (
    required => [
        ['XML::Parser', 'XML::Parser::Lite'],
        'MIME::Base64',
        'Digest::HMAC_SHA1',
        'LWP',
        'LWP::Protocol::https',
        'Mozilla::CA',
        'URI::Escape'
    ],
    optional => [
        'IO::String',
        'DBI',
        'DBD::SQLite2'
    ]
);

sub new {
    my $self = bless {};
    return $self;
}

sub run {
    my $self = shift;

    print <<END_TXT;

-------------------------------------------------------
MechanicalTurk Perl Module Installation:
-------------------------------------------------------

END_TXT
    my $ans = $self->prompt_yesno("Do you want to continue with install?\n[yes/no] ");
    if ($ans eq "no") {
        return;
    }

    my $dir = dirname($0);
    if (!chdir($dir)) {
        die "Can not change to directory $dir - $!";
    } 
    $self->{dir} = Cwd::getcwd();

    my $installModule = 1;

    
    foreach my $modules (@{$MODULES{required}}) {
        $self->ensure_module($modules, 1);
    }
    foreach my $modules (@{$MODULES{optional}}) {
        $self->ensure_module($modules, 0);
    }

    # CPAN could have changed our dir
    if (!chdir($self->{dir})) {
        die "Could not change to $self->{dir} - $!.";
    }
    
    my $doInstall = 1;
    eval { require Net::Amazon::MechanicalTurk; };
    if (!$@) {
        my $ans = $self->prompt_yesno("Net::Amazon::MechanicalTurk has already been installed. Do you want to reinstall it?\n[yes/no] ");
        if ($ans eq "no") {
            $doInstall = 0;
        }
    }

    if ($doInstall) {
        $self->build;
    }
    
    eval { require Net::Amazon::MechanicalTurk; };
    if ($@) {
        die "Could not load installed MechanicalTurk modules.\n";
    }
    
    print "\n\nMechanicalTurk perl modules are installed!\n\n";

    print "\nInstall Complete.\n";
    
    print "\n";
    require Net::Amazon::MechanicalTurk::Configurer;
    Net::Amazon::MechanicalTurk::Configurer::configure();
    
    print <<END_TXT;
    
You installation is complete.

Type mturk help to find out how to use the mturk command line tool.
Type perldoc Net::Amazon::MechanicalTurk to find out how to use the API.

Don't forget to look at the samples directory as well.

END_TXT
    
}

sub build {
    my $self = shift;
    if ($self->is_installed("Module::Build")) {
        $self->build_mb;
    }
    elsif ($^O =~ /^MSWin32$/i) {
        $self->ensure_module("Module::Build", 1);
    }
    else {
        $self->ensure_module("Module::Build", 0);
        if ($self->is_installed("Module::Build")) {
            $self->build_mb;
        }
        else {
            $self->build_mm;
        }
    }
}

sub build_mm { # Make::Maker
    print "\n\nInitializing MechanicalTurk build....\n";
    if (system("\"$Config{perlpath}\" Makefile.PL")) {
        die "Build initialization failed.";
    }
    print "\n\nBuilding MechanicalTurk ....\n";
    if (system("make")) {
        die "Build failed.";
    }
    print "\n\nInstalling MechanicalTurk ....\n";
    if (system("make install")) {
        die "Install failed.";
    }
}

sub build_mb { # Module::Build
    print "\n\nInitializing MechanicalTurk build....\n";
    if (system("\"$Config{perlpath}\" Build.PL")) {
        die "Build initialization failed.";
    }
    print "\n\nBuilding MechanicalTurk ....\n";
    my $command = ($^O =~ /^MSWin32$/) ? ".\\Build" : "./Build";
    if (system($command)) {
        die "Build failed.";
    }
    print "\n\nInstalling MechanicalTurk ....\n";
    if (system("$command install")) {
        die "Install failed.";
    }
}

sub installer {
    my $self = shift;
    if (exists $self->{installer}) {
        return $self->{installer};
    }

    # On windows look for ppm to use as an installer for dependent modules.
    if ($^O =~ /^MSWin32$/) {
        my $perlpath = $Config{perlpath};
        $perlpath =~ s/[\\\/]+[^\\\/]*$//;
        foreach my $ppm (qw{ ppm.bat }) { 
            if (-f "$perlpath\\$ppm") {
                $self->{ppm} = "$perlpath\\$ppm";
                $self->{installer} = sub { return $self->ppm_installer(@_); };
                last;
            }
        }
    }

    # Try and use cpan for installation
    if (!$self->{installer}) {
        eval { require CPAN; };
        if ($@) {
            die "Error: can not find a perl installer tool.\n" .
                "Consider installing the CPAN module which can be found at:\n\n" .
                "    http://www.cpan.org/modules/by-module/CPAN/\n" .
                "Download CPAN-<latest version>.tar.gz from there.\n\n";
        }
        $self->{installer} = sub { return $self->cpan_installer(@_); };
    }

    return $self->{installer};
}

sub ppm_installer {
    my ($self, $module) = @_;
    system("\"$self->{ppm}\" install \"$module\"");
    return $self->is_installed($module);
}

sub cpan_installer {
    my ($self, $module) = @_;
    eval {
        CPAN::Shell->install($module);
    };
    return $self->is_installed($module);
}

sub ensure_module {
    my ($self, $modules, $required) = @_;

    if (!UNIVERSAL::isa($modules, "ARRAY")) {
        $modules = [$modules]; 
    }

    my $installed_index = -1;
    my $index = 0;
    foreach my $module (@$modules) {
        if ($self->is_installed($module)) {
            print "Found module $module.\n";
            $installed_index = $index;
            last;
        }
        $index++;
    }

    if ($installed_index == -1) {
        if ($required) {
            if ($#{$modules} > 0) {
                while (1) {
                    my $mname = $self->prompt_choice(
                        "Choose one of the following required modules to install:\n".
                        "  (Favored modules are listed at the top.)\n\n",
                        $modules 
                    );
                    if (!$self->installer->($mname)) {
                        print "Failed to install $mname\n\n";
                    }
                    else {
                        last;
                    }
                }
            }
            else {
                my $ans = $self->prompt_yesno("Install required module " . $modules->[0] . "?\n[yes/no] ");
                if ($ans eq "no") {
                    die "Aborting intall.";
                }
                if (!$self->installer->($modules->[0])) {
                    die "Aborting install, could not install " . $modules->[0] . ".";
                }
            }
        }
        else {
            if ($#{$modules} > 0) {
                while (1) {
                    my $mname = $self->prompt_choice(
                        "Install 1 of the following optional modules:\n". 
                        "  (Favored modules are listed at the top.)\n\n",
                        [@$modules, "None"] 
                    );
                    last if ($mname eq "None");
                    if (!$self->installer->($mname)) {
                        print "Failed to install $mname\n\n";
                    }
                    else {
                        last;
                    }
                }
            }
            else {
                my $ans = $self->prompt_yesno("Install optional module " . $modules->[0] . "?\n[yes/no] ");
                if ($ans eq "yes") {
                    if (!$self->installer->($modules->[0])) {
                        warn "Could not install optional module " . $modules->[0] . ".";
                    }
                }
            }
        }
    }
}

sub prompt_yesno {
    my ($self,$prompt) = @_;
    $|=1;
    while (1) {
        print $prompt;
        my $ans = <STDIN>;
        chomp($ans);
        if ($ans =~ /^(yes|no)$/i) {
            return lc($ans);
        }
    }
}

sub prompt_choice {
    my ($self, $text, $choices) = @_;
    $|=1;
    while (1) {
        print $text, "\n";
        for (my $i=0; $i<=$#{$choices}; $i++) {
             printf "  [%2d] %s\n", ($i+1), $choices->[$i];
        }
        print "  ? ";
        my $ans = <STDIN>;
        chomp($ans);
        if ($ans =~ /^\d+$/) {
            $ans = $ans - 1;
            if ($ans >= 0 and $ans <= $#{$choices}) {
                return $choices->[$ans];
            }
        }
    }
}

sub is_installed {
    my ($self, $module) = @_;
    my $moduleFile = $module . ".pm";
    $moduleFile =~ s/::/\//g;
    eval {
        require $moduleFile;
    };
    return !$@;
}

package main;

eval {
    MTurkInstaller->new->run;
};
if ($@) {
    print $@, "\n";
}

$|=1;
print "\nPress [Enter] to exit.\n";
<STDIN>;


