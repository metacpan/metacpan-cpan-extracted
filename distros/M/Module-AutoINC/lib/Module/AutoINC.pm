package Module::AutoINC;

use strict;
our $PPM;
BEGIN {eval 'use PPM::UI'; $PPM = not "$@"}  # Do we have Perl Package Manager?
use CPAN;
use File::Spec;
use File::Basename;
use Config;

our $VERSION = '0.02';
our $FORCE;

sub import {
    my $package = shift;
    $FORCE = grep /^force$/i, @_;
    my $ppm = grep /^ppm$/i, @_;
    my $cpan = grep /^cpan$/i, @_;
    die "You can't specify both PPM and CPAN installation methods." 
        if $ppm && $cpan;
    *Module::AutoINC::INC = *Module::AutoINC::PPMINC if $ppm;
    *Module::AutoINC::INC = *Module::AutoINC::CPANINC if $cpan;
}

sub new { bless {}, ref($_[0]) || $_[0] }

{
my $ppmpath;
sub Module::AutoINC::PPMINC {
    my ($self, $filename) = @_;

    $ppmpath ||= File::Spec->catfile(dirname($Config{perlpath}), 'ppm');

    if ($filename =~ /^(.+)\.pm$/) {
        my $module = $1;
        $module =~ tr|/|-|;
        
        system($ppmpath, 'install', $FORCE ? '-force' : (), $module);
        
        foreach my $prefix (@INC) {
            my $realfilename = File::Spec->catfile($prefix,$filename);
            my $fh;
            return $fh if -f $realfilename && open($fh, $realfilename);
        }
    }  
    
    return undef;
}
}

sub Module::AutoINC::CPANINC {
    my ($self, $filename) = @_;

    if ($filename =~ /^(.+)\.pm$/) {
        my $module = $1;
        $module =~ s|/|::|g;
        
        foreach my $m (expand('Module', $module)) {
            $FORCE ? CPAN::Shell->force('install', $m)
                   : CPAN::Shell->install($m);
        
            foreach my $prefix (@INC) {
                my $realfilename = File::Spec->catfile($prefix,$filename);
                my $fh;
                return $fh if -f $realfilename && open($fh, $realfilename);
            }
        }
    }

    return undef;
}


BEGIN {
    *Module::AutoINC::INC = $PPM ? *Module::AutoINC::PPMINC 
                                 : *Module::AutoINC::CPANINC;
    push (@INC, new Module::AutoINC());
};

1;
__END__

=pod

=head1 NAME

Module::AutoINC - Download and install CPAN/PPM modules upon first use.

=head1 SYNOPSIS

  perl -MModule::AutoINC <script>

=head1 ABSTRACT

When Module::AutoINC is loaded, it will add itself to @INC and catch any 
requests for missing resources.  If a Perl module is requested that has not been 
installed, then this will attempt to load it.  Under Active State Perl (or any 
Perl where PPM is available), PPM will attempt to install it.  Otherwise CPAN 
will be queried and, assuming that the module exists on CPAN, CPAN::Shell will 
be invoked to install it. Execution of the script continues after the requisite 
module has been installed.

=head1 DESCRIPTION

Module::AutoINC is a slightly useful tool designed to streamline the process of 
installing the modules required by a script.  By loading the Module::AutoINC 
module (usually via a "-MModule::AutoINC" command-line option), the user is 
registering a handler that will catch any attempt to use a module that does not 
exist on the local machine.  In this case, the CPAN::Shell module will be 
invoked to search for the specified module and, if found, an attempt will be 
made to install the module.  If successful, the module will be loaded and 
execution will continue as normal.

=head2 Imported Symbols

You can modify the behavior of the module slightly using several import symbols. 
All import symbols are case-insensitive.

If you import the special symbol 'force' then the installation of the module(s) 
will be forced.  The definition of a 'forced' installation varies depending 
on whether you are installing using PPM or CPAN.  See the relevant documentation 
for each system for more information.

You can override the installation method detection using the import symbols, 
'cpan' or 'ppm'.  'cpan' will cause CPAN to be used for module installation no 
matter whether PPM is available or not.  'ppm' will attempt to install the 
module using PPM regardless of whether ppm is findable by Module::AutoINC.  Of 
course, you should know what you are doing if you use these import symbols.

=head1 Examples

  perl -MModule::AutoINC -MLingua::Num2Word=cardinal -le 'print cardinal("en", 42)'

...will download and install Lingua::Num2Word and Lingua::EN::Num2Word.

  perl -MModule::AutoINC=cpan -MLingua::Num2Word=cardinal -le 'print cardinal("de", 42)'

...will then download and install (using CPAN, even under ActiveState Perl) Lingua::DE::Num2Word (German).

  perl -MModule::AutoINC=force -MLingua::Num2Word=cardinal -le 'print cardinal("es", 42)'

...will then download and install (forcefully) Lingua::ES::Numeros (Spanish).

=head1 CPAN CAVEATS

=over

=item *

The "CPAN" module must be properly configured to run for the user whom
you plan to be when you execute your scripts.  By default CPAN tends
to install into a system path (e.g., /usr/lib/perl), so you would need
to run your scripts as root for this to work transparently.  However,
you can also configure CPAN for other users by installing a
~/.cpan/CPAN/MyConfig.pm file.  In particular, you may want to
override makepl_arg to add a "PREFIX=~/.cpan/install" setting.

=item *

Make sure that the directory where your Perl modules are installed is
in your @INC by default, either by adding a -I option to your command
line or by seting your $PERL5LIB environmental variable.  This is most
likely only necessary if you are not running your scripts as root.

=item *

If the entire directory structure does not exist the first time you
use Module::AutoINC, you may need to run your script twice.  For
example, if your PREFIX is set to "~/.cpan/install" and your
PERL5LIB is set to
"~/.cpan/install/perl5:~/.cpan/install/perl5/site_perl",
~/.cpan/install/perl5/site_perl/5.8.0 and
~/.cpan/install/perl5/site_perl/5.8.0/i686-linux will not be
added to your @INC unless they existed before your module was
installed.  In this case loading of the installed module would fail and
you would need to re-run your script.

=item *

You may wish to configure CPAN to always follow dependencies.  This
can be done by setting your 'prerequisites_policy' option to 'follow'.
However, this doesn't guarantee that all module installations will go
smoothly without human intervention; some installation or test
procedures explicitly prompt the user.

=item *

It seems that the CPAN module itself uses Log::Agent somehow, so you
will likely see this installed as the first module.

=back

=head1 PPM CAVEATS

=over 4

=item *

Whether this module can find the given modules will depend on which repositories
are configured in PPM.  Other ways in which PPM may be configured will impact
on how this module behaves when doing a PPM installation.

=item *

As with CPAN you will need to have appropriate permissions to install new 
modules on your system, in order for installations to succeed.

=back

=head1 MOTIVATION

=head2 Don's Motivation

The description for the Acme::RemoteINC CPAN module ("Slowest Possible
Module Loading") prompted me to write this module.  The only thing
slower than loading precompiled modules via FTP is loading module
source code from FTP and compiling it.  Except maybe carrier pigeons.

As you can see from the CAVEATS section, there is a fair amount of
set-up work required and it will not work for all modules.  This makes
it relatively useless, especially in a production environment.  But
it's a cool hack, and could potentially be useful under very limited
circumstances.

=head2 Mike's Motivation

Since we use a number of CPAN modules in our scripts at work setting up new 
systems with the range of modules can be onerous especially for those who are 
not very experienced with Perl and it's nuances.  Don's CPAN::AutoINC was a good 
start on a solution, but since we use a mix of Linux and Windows systems I 
wanted something that would handle ActiveState Perl as well as vanilla Perl 
transparently.

=head1 HISTORY

=over 4

=item v0.02

=over 4

=item *

No code changes.  The Makefile.pl was asking for too recent a version of Perl. 
Now it asks for Perl 5.004 as a minimum which is about the time the CPAN.pm
module was introduded, near as I can tell.

=back

=item v0.01

=over 4

=item *

Uses Perl Package Manager to do installations if it is available.

=item *

Renamed module to reflect broader functionality 

=item *

Added ability to do 'forced' intalls.

=item *

Added ability to explicitly choose between CPAN and PPM installation methods.

=back

=item CPAN::AutoINC v0.01

Don Schwarz's original version.  Did CPAN installs only.

=back

=head1 SEE ALSO

L<CPAN::AutoINC>, L<CPAN>, Perl Package Manager documentation,
L<perlfunc>'s section on the C<require> function for the features of C<@INC> 
that this module uses.

=head1 AUTHOR

Mike MacKenzie, E<lt>mackenzie@cpan.orgE<gt>
Original CPAN::AutoINC: Don Schwarz, E<lt>don@schwarz.nameE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Language Weaver, Inc.

Based on CPAN::AutoINC

Copyright 2004 by Don Schwarz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
