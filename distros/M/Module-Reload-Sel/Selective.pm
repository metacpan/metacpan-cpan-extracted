#!/usr/bin/perl
## Emacs: -*- tab-width: 4; -*-

use strict;

package Module::Reload::Selective;           

use vars qw($VERSION);              $VERSION = '1.02';

=pod

=head1 NAME

Module::Reload::Selective - Reload perl modules during development

=head1 SYNOPSIS

Instead of:

	use                        Foobar::MyModule;

Do this:

	use Module::Reload::Selective; 
	&Module::Reload::Selective->reload(qw(Foobar::MyModule));

Or, if you need the "import" semantics of "use", do this:

	use                        Foobar::MyModule    (@ImportArgs);

Do this:

	use Module::Reload::Selective; 
 	Module::Reload::Selective->reload(qw(Foobar::MyModule));
	import                     Foobar::MyModule    (@ImportArgs);


... then configure your server or other runtime environment settings
to trigger Module::Reload::Selective to only kick in when you need.

For example: you could have it kick in only when the web server is
running on a particular port number or particular (development) host.

=head1 OVERVIEW

Utility for module developers to selectively reload needed modules
and/or conditionally augment @INC with additional, per-developer
library directories, at development time based on environment
variables.

Particularly helpful in conjunction with mod_perl applications where
some or all application logic resides in separate Perl modules that
would otherwise not get reloaded until the server restarts.

Copyright (c) 2002, Chris Thorman.

Released to the public under the terms of the Perl Artistic License.

=head1 DETAILS

This module defines a "reload" routine that scripts, CGI scripts,
Embperl scripts, handlers, etc.  can use to reload (re-require) a
module or modules, optionally forcing the modules AND ANY MODULES THEY
USE, recursively, to reload, even if already previously loaded and
listed in %INC.

The reloading feature is helpful for when you're actively writing and
debugging modules intended to be used with Apache and mod_perl (either
used by Apache::Registry or HTML::Embperl script, or handlers, or
other mechanisms) and want to ensure that your code changes get
reloaded on every hit, even if the module had previously been loaded
into the parent or child process.

In addition to the selective reloading feature, this module can also
(optionally) dynamically prepend some additional paths to @INC to
allow programmers to work on, test, and debug private development
copies of modules in a private directory while other modules are
loaded from a more stable, shared, or public, library directory.

The @INC-modifying feature is helpful even if you're only developing
command-line perl scripts in an environment where there are multiple
programmers and an individual programmer, for testing purposes, needs
to optionally load some modules under development from his or her own
private source directory in preference to the "standard" locations.

This is a common need when multiple Perl developers are working on the
same Unix host.

How this module differs from Module::Reload:

=over 4

=item *

Module::Reload reloads just files that it sees have changed on disk
since the last reload, whereas this module conditionally reloads based
on other conditions at runtime; this module also has other features of
convenience to develoepers.

=back

How this module differs from Apache::StatINC:

=over 4

=item *

Reloads requested modules (recursively) regardless of modification
date.

=item *

Skips reloading any modules that have been previously loaded from
lib/perl* (or other customizable list of dir name patterns), so you
can only reload items outside the standard library locations, by
default.

=item *

Allows dynamic overriding of @INC on a per-USER basis.

=item *

This module lacks StatINC's ability to disable symbol-redef warnings,
so best not to reload modules with const subroutines...  (sorry).

=item *

Works outside of Apache as well as within it (not sure whether this is
true of Apache::StatINC), so is testable from the command line, and
even useful in a batch script context, if not for its reloading
capabilities, then at least for its ability to override the search
path on a per-USER basis, allowing the development and debugging of a
private copy of a system-wide module or modules.

=item *

Works fine from within individual pages or scripts; does not
necessarily need to be loaded at server startup time.

=item *

Is a no-op (does not reload) unless certain environment variables
and/or options are set, allowing you to leave calls to it in
production code with negligible performance hit on non-debugging
servers.

=back

=head1 DISCUSSION

To request that a module Foobar::MyModule, and any modules it calls,
be reloaded, do this:

	use Module::Reload::Selective; 
 	Module::Reload::Selective->reload(qw(Foobar::MyModule));


This reloads the module, executing its BEGIN blocks, syntax-checking
it, and recompiling any subroutines it has.  

Then, if you want to import any semantics from the module into the
current namespace, you should  directly "import" the module.

	import                     Foobar::MyModule    (@ImportArgs);

IMPORTANT: Under normal circumstances, reload will load the module
normally with no difference from the usual behavior of "use"
... i.e. files won't be reloaded if they already have been, and no
special modifications to @INC will be applied.

BUT, if certain environment variables (see below) are set to non-false
values, Module::Reload::Selective will force them and any modules THEY need, to
be reloaded from their source file every time, also using temporary
modifications to @INC.

The variables are:

$ENV{RLD}  ## Useful for command-line testing/debugging

prompt> RLD=1 perl index.cgi

Just set this environment variable before invoking the script and the
Reloader will be activated.

$ENV{DEBUGGING_SERVER} ## Set this in the server startup

At server startup, set the environment variable conditionally, only if
you're starting up a private debugging server, say, on a different
port.  You could use something like this in a <Perl> section in your
httpd.conf, for example:

	if (($My::HostName =~ /^dev/) && $Port == 8081)
	{
	    $User = 'upload';
	    $Group = 'upload';
	    print STDERR "Starting as user $User/$Group\n" if -t STDERR;

	    push @PerlSetEnv, ['DEBUGGING_SERVER', 1];

	    ## Could also set other Module::Reload::Selective runtime options here.
	}



=head1 RUNTIME OPTIONS

Runtime options are initialized by Module::Reload::Selective when it
is first "use"d, and may be overridden individually later before
calling "reload", by setting a few elements of the
$Module::Reload::Selective::Options hash, like this:

	$Module::Reload::Selective::Options->{SearchProgramDir} = 0;


The available options, and their initial default values, are:

	ReloadOnlyIfEnvVarsSet      => 1,

	## If 0, always reloads, regardless of environment var settings
	## described above.

	SearchProgramDir            => 1,

	## If 1, cur working dir of script, as determined from $0, will be
	## added to the search paths before reloading.

	## This is very handy for keeping private local copies of modules
	## being tested in the same directory tree as the application that
	## uses them.

	SearchUserDir               => 1,

	## If 1, "user dir" as determined by the other "User" options
	## below, will added to the search paths, after ProgramDir.

	DontReloadIfPathContains    => ['lib/perl'],

	## List of strings that, if found in the loaded path of an already
	## loaded module, prevent that module from being re-loaded.  By
	## specifying "lib/perl" (on Unix), no library modules installed
	## in the standard perl library locations will ever be reloaded.
	## Force reloading of those, too, by removing that entry, or add
	## additional strings to disable additional subdirectories,
	## perhaps ones of your own.

    FirstAdditionalPaths        => [],
    LastAdditionalPaths         => [],

	## Lists; if non-empty, these specify additional paths to be
	## searched before or after any of the obove options, but in any
	## case always before any of the other locations normally in @INC.

	User                        => '',

	## Name of user whose directory will be searched.

	DefaultUser                 => $ENV{RELOAD_USER} || $ENV{USER} || $ENV{REMOTE_USER},

	## Name of user whose directory will be searched if no User option
	## is specified to override it.  If empty, no user name will be
	## used.

	UserDirTemplate             => '/home/USER/src/lib',

	## Path to search when looking for source modules in a User's
	## programming directory.  If "USER" is in the path, it will be
	## substituted at runtime with the value of User or DefaultUser as
	## appropriate.  The resulting directory path is only added to the
	## search paths if it actually exists.

=head1 DEBUGGING & ANALYSIS OF WHAT GOT LOADED

For debugging purposes, Module::Reload::Selective creates these hash
references, in the same format as %INC, that show what the last
"reload" command did.  You can examine these (e.g. with Data::Dumper)
after calling reload if you want to be sure that reload did its job.

	$Module::Reload::Selective::Debug->{INCHashBefore}
	$Module::Reload::Selective::Debug->{INCHashAfter}

	$Module::Reload::Selective::Debug->{NewlyLoaded}
	$Module::Reload::Selective::Debug->{Reloaded}
	$Module::Reload::Selective::Debug->{NotReloaded}

	$Module::Reload::Selective::Debug->{GotLoaded}

NewlyLoaded -- modules that weren't loaded (from anywhere) prior to
calling reload.

Reloaded -- modules that previously appeared in %INC but got reloaded.

NotReloaded -- modules that previously appeared in %INC but were not
reloaded.

GotLoaded -- The union of Reloaded and NewlyLoaded -- i.e. anything
that got loaded as a result of the "reload" command.

You can examine these by putting something like one of these
statements in your code:

	use Data::Dumper;
	print &Dumper($Module::Reload::Selective::Debug);
	print &Dumper($Module::Reload::Selective::Debug->{GotLoaded});

For example, if you use HTML::Embperl, you could put the following
line in your application:

	<PRE>[+ &Dumper($Module::Reload::Selective::Debug); +]</PRE>

... and comment it out when done:

	[# <PRE>[+ &Dumper($Module::Reload::Selective::Debug); +]</PRE> #]

Note: if you use "reload" to force a reload of all your modules into a
virgin child process, the "NewlyLoaded" hash should be empty in a web
server environment where the Web server has been properly configured
to pre-load all necessary modules at server startup.  You could use
this side-effect as a way to test your server configuration to see if
you've remembered to preload everything needed by your application at
server startup; anything that shows up in NewlyLoaded is something
you've forgotten to preload and you can fix that.

To see what private version of @INC was used by "reload", have a look
at this debugging variable:

	$Module::Reload::Selective::Debug->{INCArrayAfterModification}

To see what time the last reload occurred, view this variable:

	$Module::Reload::Selective::Debug->{LastLoadTime}

(This, along with the GotLoaded hash, will also help you reassure
yourself that the things you wanted to reload really did get reloaded;
if GotLoaded doesn't list your module, and/or LastLoadTime did not
change, then something did not reload.)

=head1 WARNINGS

RELOADING IS RECURSIVE

If you reload module A that uses module B, module B will be reloaded,
too.  This allows you to reload all related modules at one time.  But
if you're not working on A, only on B, it is more efficient to just
reload module B.  Don't reload more than you need, in other words.


RELOADING CAN MESS WITH GLOBALS IN APACHE CHILD PROCESSES

Note that the reloaded modules are loaded into the (child) process's
global namespace and so will affect all applications served by the
affected process... including any bugs you've introduced or modules
that failed to compile.

So if using Module::Reload::Selective for Web application development, each
programmer should be testing with his/her own private Apache server,
(possibly running on a unique port).

This way when you force the reloading of a buggy version of a module,
everyone else's runtime environment is not also screwed up.


WARNING: SYMBOL REDEFINITION WARNINGS

If the loaded module, or any module it reloads uses constant
subroutines, as in constant.pm, you will get warnings every time it
reloads.  I tried to emulate a trick used by Doug MacEachern in
Apache::StatINC to prevent this from happening, but in this version, I
haven't been able to get that to work.  Suggestions / fixes welcome.

=head1 THANKS

Thanks to Joshua Pritikin for suggestions and the use of the
Module::Reload namespace.

=head1 INSTALLATION

Using CPAN module:

    perl -MCPAN -e 'install Module::Reload::Selective'

Or manually:

    tar xzvf Module-Reload-Sel*gz
    cd Module-Reload-Sel*-?.??
    perl Makefile.PL
    make
    make test
    make install

=head1 SEE ALSO

The Module::Reload::Selective home page:

    http://christhorman.com/projects/perl/Module-Reload-Selective/

Apache(3), mod_perl, http://perl.apache.org/src/contrib,
Module::Reload, Apache::StatINC.

The implementation in Selective.pm.

The perlmod manual page.

=head1 AUTHOR

Chris Thorman <chthorman@cpan.org>

Copyright (c) 1995-2002 Chris Thorman.  All rights reserved.  

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

{};	## Get emacs to indent correctly. Sigh.

use Data::Dumper;

BEGIN
{
	$Module::Reload::Selective::Debug								||= {};

	$Module::Reload::Selective::Options								||= {};

	$Module::Reload::Selective::Options->{ReloadOnlyIfEnvVarsSet} 	||= 1;
	$Module::Reload::Selective::Options->{SearchProgramDir}			||= 1;
	$Module::Reload::Selective::Options->{SearchUserDir}			||= 1;

	$Module::Reload::Selective::Options->{DontReloadIfPathContains}	||= ['lib/perl'];

	$Module::Reload::Selective::Options->{FirstAdditionalPaths}		||= [];
	$Module::Reload::Selective::Options->{LastAdditionalPaths}		||= [];

	$Module::Reload::Selective::Options->{User}						||= '',
	$Module::Reload::Selective::Options->{DefaultUser}				||= $ENV{RELOAD_USER} || $ENV{USER} || $ENV{REMOTE_USER},
	$Module::Reload::Selective::Options->{UserDirTemplate}			||= '/home/USER/src/lib',

}

sub import
{
	my ($Class, @Args) = @_;
}


### reload

### Can be called either procedurally or as a class method.  Knows to
### not reload the Module::Reload::Selective class itself.

sub reload	
{
	my (@PackageNames) = @_;

	my $ReturnVal = undef;


	## This module doesn't reload itself.  Sorry.  Restart
	## your server for that.

	@PackageNames = (grep {$_ ne __PACKAGE__} @PackageNames);

	## Do nothing unless given at least one package name to reload.

	goto done unless @PackageNames;

	## Initialize/empty out the debugging info

	$Module::Reload::Selective::Debug = {};

	## RELOAD MODE... kicks in if either of the two environment
	## variables is set or the ReloadOnlyIfEnvVarsSet option is turned
	## off.

	if (
		$ENV{DEBUGGING_SERVER}		|| 
		$ENV{RLD}					|| 
		!$Module::Reload::Selective::Options->{ReloadOnlyIfEnvVarsSet}
		)
	{

		## FIRST MODIFY @INC TO HAVE SOME ADDITIONAL SEARCH DIRS
		## PREPENDED...

		my $ExtraSearchDirs = [];

		if ($Module::Reload::Selective::Options->{FirstAdditionalPaths} && 
			@{$Module::Reload::Selective::Options->{FirstAdditionalPaths}})
		{
			push @$ExtraSearchDirs, @{$Module::Reload::Selective::Options->{FirstAdditionalPaths}};
		}

		if ($Module::Reload::Selective::Options->{SearchProgramDir})
		{
			(my $ProgramDir = $0) =~ s|(.*/).*|$1|;
			push @$ExtraSearchDirs, $ProgramDir if -d $ProgramDir;
		}

		if ($Module::Reload::Selective::Options->{SearchUserDir})
		{
			my $User = ($Module::Reload::Selective::Options->{User       } || 
						$Module::Reload::Selective::Options->{DefaultUser});

			my $UsersProgrammingDir = $Module::Reload::Selective::Options->{UserDirTemplate};
			$UsersProgrammingDir =~ s/\bUSER\b/$User/g;

			push @$ExtraSearchDirs, $UsersProgrammingDir if $User && -d $UsersProgrammingDir;
		}
			
		if ($Module::Reload::Selective::Options->{LastAdditionalPaths} && 
			@{$Module::Reload::Selective::Options->{LastAdditionalPaths}})
		{
			push @$ExtraSearchDirs, @{$Module::Reload::Selective::Options->{LastAdditionalPaths}};
		}
		
		## Prepend the ExtraSearchDirs to a local copy of @INC so they
		## will get searched in order before any of the places in
		## @INC.

		local @INC = @INC;					
		unshift @INC, @$ExtraSearchDirs;
		
		$Module::Reload::Selective::Debug->{INCArrayAfterModification} = [@INC];

		## die &Dumper(\@INC, $ExtraSearchDirs, $Module::Reload::Selective::Options);

		## THEN MODIFY %INC TO REMOVE ANY MENTION OF ITEMS THAT MIGHT
		## NEED TO GET RELOADED....
		
		## Before mucking with %INC, get a list of any installed perl
		## library modules that we don't want to muck with (any items
		## with "lib/perl" in the path).... or any other of a list of
		## path elements that should be disabled...
		
		my $DisabledPatterns = $Module::Reload::Selective::Options->{DontReloadIfPathContains};

		my $DisabledItems = {};
		foreach my $Pattern (@$DisabledPatterns)
		{
			@$DisabledItems{grep {$INC{$_} =~ m|\Q$Pattern\E|} keys %INC}  = undef;
		}
		@$DisabledItems{keys %$DisabledItems} = @INC{keys %$DisabledItems};
		
		## die &Dumper($DisabledItems);
		
		## Empty out our private copy of %INC, so "require" doesn't
		## think any modules have yet been loaded.
		
		$Module::Reload::Selective::Debug->{INCHashBefore} = {%INC};
		local %INC = ();	
		
		## Restore the disabled items in %INC so we don't reload those.
		
		@INC{keys %$DisabledItems} = values %$DisabledItems;
		## die &Dumper(\%INC);
		

		## THEN LOAD EACH OF THE REQUESTED MODULES...

		foreach my $PackageName (@PackageNames)
		{

			(my $PackageRelPath = "$PackageName.pm") =~ s|::|/|g;
			
			## Many thanks to Doug MacEachern / Apache::StatINC for
			## this attempt turning of warnings for const subroutine
			## redefinitions, but I can't seem to get it to work, so it's commented out.

			## require Apache::Symbol;
			## my $Class = Apache::Symbol::file2class($PackageRelPath);
			## $Class->Apache::Symbol::undef_functions( undef, 1 );
			
			require            ($PackageRelPath);
			$ReturnVal = import $PackageName;
		}
		
		## TAKE A SNAPSHOT OF THE NEW %INC FOR LATER ANALYSIS...

		$Module::Reload::Selective::Debug->{INCHashAfter} = {%INC};
		delete @{$Module::Reload::Selective::Debug->{INCHashAfter}}{keys %$DisabledItems};
		$Module::Reload::Selective::Debug->{LastLoadTime} = localtime().'';

		## %INC and @INC WILL BE RESTORED HERE BY local %INC and local
		## @INC GOING OUT OF SCOPE... 
	}

	## REGULAR MODE: Do the equivlaent of a "use", except that
	## semantics won't be imported into the caller's namespace.

	else
	{
		foreach my $PackageName (@PackageNames)
		{
			(my $PackageRelPath = "$PackageName.pm") =~ s|::|/|g;
			require            ($PackageRelPath);
			$ReturnVal = import $PackageName;
		}
		
		$Module::Reload::Selective::Debug->{Reload_Disabled_Because} = "No environment variables were set.";
	}
	
  done:

	## if %INC was messed with, we analyze the differences between the
	## before and after and set some derived hashes.

	if ($Module::Reload::Selective::Debug->{INCHashBefore} && 
		$Module::Reload::Selective::Debug->{INCHashAfter})
	{
		($Module::Reload::Selective::Debug->{NotReloaded}, 
		 $Module::Reload::Selective::Debug->{NewlyLoaded}, 
		 $Module::Reload::Selective::Debug->{Reloaded}) = 
			 CompareHashKeys($Module::Reload::Selective::Debug->{INCHashBefore}, 
							 $Module::Reload::Selective::Debug->{INCHashAfter});
		
		## CompareHashKeys leaves the values undefined; for
		## convenience, we pick up the values from the Before and
		## After hashes.
		
		foreach ($Module::Reload::Selective::Debug->{NotReloaded}, 
				 $Module::Reload::Selective::Debug->{NewlyLoaded}, 
				 $Module::Reload::Selective::Debug->{Reloaded})
		{	
			@{$_}{keys %$_} = (map {($Module::Reload::Selective::Debug->{INCHashAfter }->{$_} ||
									 $Module::Reload::Selective::Debug->{INCHashBefore}->{$_})} keys %$_);
		}

		## Finally make another debugging hash of anything that got
		## loaded for any reason, whether newly, or re-loaded.
		
		$Module::Reload::Selective::Debug->{GotLoaded} = {};
		@{$Module::Reload::Selective::Debug->{GotLoaded}}{keys %{$Module::Reload::Selective::Debug->{NewlyLoaded}}} = values %{$Module::Reload::Selective::Debug->{NewlyLoaded}};
		@{$Module::Reload::Selective::Debug->{GotLoaded}}{keys %{$Module::Reload::Selective::Debug->{Reloaded   }}} = values %{$Module::Reload::Selective::Debug->{Reloaded   }};
		
		## Copy entries for the items that changed into the non-local %INC hash.
		@INC{keys %{$Module::Reload::Selective::Debug->{GotLoaded}}} = values %{$Module::Reload::Selective::Debug->{GotLoaded}};
		
	}
	
	return($ReturnVal);
}



######### Utility routines ##########

sub CompareHashKeys
{
    my ($Hash1, $Hash2) = @_;

    my $In1NotIn2 = {}; @$In1NotIn2{keys %$Hash1              } = undef; delete @$In1NotIn2{keys %$Hash2                      };
    my $In2NotIn1 = {}; @$In2NotIn1{keys %$Hash2              } = undef; delete @$In2NotIn1{keys %$Hash1                      };
    my $Subset    = {}; @$Subset   {keys %$Hash1, keys %$Hash2} = undef; delete @$Subset   {keys %$In1NotIn2, keys %$In2NotIn1};

    return($In1NotIn2, $In2NotIn1, $Subset);
}

1;
