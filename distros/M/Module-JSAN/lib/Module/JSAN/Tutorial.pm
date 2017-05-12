package Module::JSAN::Tutorial;

our $VERSION = '0.04';

__PACKAGE__;

__END__

=head1 NAME

Module::JSAN::Tutorial - more detailed explanation on writing a JSAN module. Its really not that hard (tm).

=head1 VERSION

Version 0.01

=cut


=head1 SYNOPSIS

In F<Build.PL>:

    use inc::Module::JSAN;
    
    
    name            'Digest.MD5';
        
    version         '0.01';
        
    author          'SamuraiJack <root@symbie.org>';
    abstract        'JavaScript implementation of MD5 hashing algorithm';
        
    license         'perl';
        
    requires        'Cool.JS.Lib' => '1.1';
    requires        'Another.Cool.JS.Lib' => '1.2';
    
    docs_markup     'mmd';
    
    WriteAll;
    
or more relaxed DSL syntax:    

    use inc::Module::JSAN::DSL;
    
    
    name            Digest.MD5
        
    version         0.01
        
    author          'SamuraiJack <root@symbie.org>'
    abstract        'JavaScript implementation of MD5 hashing algorithm'
        
    license         perl
        
    requires        Cool.JS.Lib             1.1
    requires        Another.Cool.JS.Lib     1.2
    
    docs_markup     mmd

Standard process for building & installing JSAN modules:

      perl Build.PL
      ./Build
      ./Build test
      ./Build install

Or, if you're on a platform (like DOS or Windows) that doesn't require the "./" notation, you can do this:

      perl Build.PL
      Build
      Build test
      Build install


=head1 DESCRIPTION

C<Module::JSAN> is a system for building, testing, and installing JavaScript modules. 
Its based on the L<Module::Build> packaging system, and L<Module::Build::Functions> adapter,
which provides more relaxed syntax for building scripts.  

To install JavaScript modules, packaged with C<Module::JSAN>, do the following:

  perl Build.PL       # 'Build.PL' script creates the 'Build' script
  ./Build             # Need ./ to ensure we're using this "Build" script
  ./Build test        # and not another one that happens to be in the PATH
  ./Build install

This illustrates initial configuration and the running of three
'actions'.  In this case the actions run are 'build' (the default
action), 'test', and 'install'.  Other actions defined so far include:

  build                 clean                               
  code                  docs
  
  dist                  distcheck                      
  distclean             distdir                              
  distmeta              distsign                               

  help                  install
  manifest              realclean                                   
  skipcheck


You can run the 'help' action for a complete list of actions.


=head1 ACTIONS

There are some general principles at work here.  First, each task when
building a module is called an "action".  These actions are listed
above; they correspond to the building, testing, installing,
packaging, etc., tasks.

Second, arguments are processed in a very systematic way.  Arguments
are always key=value pairs.  They may be specified at C<perl Build.PL>
time (i.e. C<perl Build.PL destdir=/my/secret/place>), in which case
their values last for the lifetime of the C<Build> script.  They may
also be specified when executing a particular action (i.e.
C<Build test verbose=1>), in which case their values last only for the
lifetime of that command.  Per-action command line parameters take
precedence over parameters specified at C<perl Build.PL> time.

The following build actions are provided by default.

=head3 build

If you run the C<Build> script without any arguments, it runs the
C<build> action, which in turn runs the C<code> and C<docs> actions.


=head3 clean

This action will clean up any files that the build process may have
created, including the C<blib/> directory (but not including the
C<_build/> directory and the C<Build> script itself).

=head3 code

This action builds your code base.

By default it just creates a C<blib/> directory and copies any C<.js>
and C<.pod> files from your C<lib/> directory into the C<blib/>
directory.    

=head3 dist

This action is helps module authors to package up their module for JSAN.  
It will create a tarball of the files listed in F<MANIFEST> and 
compress the tarball using GZIP compression.

By default, this action will use the C<Archive::Tar> module. However, you can
force it to use binary "tar" and "gzip" executables by supplying an explicit 
C<tar> (and optional C<gzip>) parameter:

  ./Build dist --tar C:\path\to\tar.exe --gzip C:\path\to\zip.exe

=head3 distcheck

Reports which files are in the build directory but not in the
F<MANIFEST> file, and vice versa.  (See L<manifest> for details.)

=head3 distclean

Performs the 'realclean' action and then the 'distcheck' action.

=head3 distdir

Creates a "distribution directory" named C<dist_name-dist_version>
(if that directory already exists, it will be removed first), then
copies all the files listed in the F<MANIFEST> file to that directory.
This directory is what the distribution tarball is created from.

=head3 distmeta

Creates the F<META.json> file that describes the distribution.

F<META.json> is a file containing various bits of I<metadata> about the
distribution.  The metadata includes the distribution name, version,
abstract, prerequisites, license, and various other data about the
distribution.  This file is created as F<META.json> in JSON format.
It is recommended that the C<JSON> module be installed to create it.
If the C<JSON> module is not installed, an internal module supplied
with Module::JSAN will be used to write the META.json file, and this
will most likely be fine.

F<META.json> file must also be listed in F<MANIFEST> - if it's not, a
warning will be issued.

The format of F<META.json> file is based on the metadata format for CPAN,
the specification of its current version can be found at
L<http://module-build.sourceforge.net/META-spec-current.html>

=head3 distsign

Uses C<Module::Signature> to create a SIGNATURE file for your
distribution, and adds the SIGNATURE file to the distribution's
MANIFEST.

=head3 disttest

Performs the 'distdir' action, then switches into that directory and
runs a C<perl Build.PL>, followed by the 'build' and 'test' actions in
that directory.

=head3 docs

This action will build a documentation files. Default markup for documentation is POD. 
Alternative markup can be specified with C<docs_markup> configuration parameter (see Synopsis). 
Currently supported markups: 'pod', 'md' (Markdown via Text::Markdown), 'mmd' (MultiMarkdown via Text::MultiMarkdown).

Resulting documentation files will be placed under /docs directory, categorized by the formats. 
For 'pod' markup there will be /doc/html, /doc/pod and /doc/text directories. 
For 'md' and 'mmd' markups there will be /doc/html and /doc/[m]md directories.

=head3 help

This action will simply print out a message that is meant to help you
use the build process.  It will show you a list of available build
actions too.

=head3 install

This action will install current distribution in your L<LOCAL JSAN LIBRARY>. 

=head3 manifest

This is an action intended for use by module authors, not people
installing modules.  It will bring the F<MANIFEST> up to date with the
files currently present in the distribution.  You may use a
F<MANIFEST.SKIP> file to exclude certain files or directories from
inclusion in the F<MANIFEST>.  F<MANIFEST.SKIP> should contain a bunch
of regular expressions, one per line.  If a file in the distribution
directory matches any of the regular expressions, it won't be included
in the F<MANIFEST>. Regular expression should match the full file path, 
starting from the distribution's root (lib/Your/Module.js, not Module.js)

The following is a reasonable F<MANIFEST.SKIP> starting point, you can
add your own stuff to it:

    ^_build
    ^Build$
    ^blib
    ~$
    \.bak$
    ^MANIFEST\.SKIP$
    \b.svn\b            # ignore all SVN directories
    ^\.git\b            # ignore top-level .git directory  
    

Since # can be used for comments, # must be escaped.
  

See the L<distcheck> and L<skipcheck> actions if you want to find out
what the C<manifest> action would do, without actually doing anything.

=head3 realclean

This action is just like the C<clean> action, but also removes the
C<_build> directory and the C<Build> script.  If you run the
C<realclean> action, you are essentially starting over, so you will
have to re-create the C<Build> script again.


=head3 skipcheck

Reports which files are skipped due to the entries in the F<MANIFEST.SKIP> file (See L<manifest> for details)


=head1 CONFIGURATION DIRECTIVES

Unless specified otherwise, a directive is accumulative - it can be used more that once to add value to a list. 

All the configuration directives also can be used in DSL notation, with mostly omitted punctuation,
including trailing semi-colon. Some of directives have synonyms.

=head2 Metadata

Functions in this section are used when generating metadata for C<META.json> file. 


=head4 module_name

=head4 name 

    name 'Useful.Module.Indeed';
    
    module_name 'Useful.Module.Indeed';

Specifies the name of the main module for this distribution.  This will also set the distribution's name.

=head4 dist_name

    dist_name 'useful-module-indeed';

Specifies the name for this distribution. Most authors won't need to set 
this directly, they can use L<module_name|/module_name> to set C<dist_name> 
to a reasonable default. However, generally, distributions may have names 
that don't correspond directly to their's main module name, 
so C<dist_name> can be set independently. 

This is a required parameter.


=head4 dist_version

=head4 version

    version '0.001_001';

Specifies a version number for the distribution. This is a required parameter. 


=head4 dist_abstract

=head4 abstract

    abstract        'JavaScript implementation of MD5 hashing algorithm';

This should be a short description of the distribution. 
    

=head4 dist_author

=head4 author

    dist_author 'John Doe <jdoe@example.com>';
    author 'Jane Doe <doej@example.com>';

This should be something like "John Doe <jdoe@example.com>", or if there are 
multiple authors, this routine can be called multiple times, or an anonymous 
array of strings may be specified. 
    

=head4 license

    license 'lgpl';

Specifies the licensing terms of your distribution. Valid options include:

=over 4

=item apache

The distribution is licensed under the Apache Software License
(L<http://opensource.org/licenses/apachepl.php>).

=item artistic

The distribution is licensed under the Artistic License, as specified
by the F<Artistic> file in the standard Perl distribution.

=item artistic_2

The distribution is licensed under the Artistic 2.0 License
(L<http://opensource.org/licenses/artistic-license-2.0.php>.)

=item bsd

The distribution is licensed under the BSD License
(L<http://www.opensource.org/licenses/bsd-license.php>).

=item gpl

The distribution is licensed under the terms of the GNU General
Public License (L<http://www.opensource.org/licenses/gpl-license.php>).

=item lgpl

The distribution is licensed under the terms of the GNU Lesser
General Public License
(L<http://www.opensource.org/licenses/lgpl-license.php>).

=item mit

The distribution is licensed under the MIT License
(L<http://opensource.org/licenses/mit-license.php>).

=item mozilla

The distribution is licensed under the Mozilla Public
License.  (L<http://opensource.org/licenses/mozilla1.0.php> or
L<http://opensource.org/licenses/mozilla1.1.php>)

=item open_source

The distribution is licensed under some other Open Source
Initiative-approved license listed at
L<http://www.opensource.org/licenses/>.

=item perl

The distribution may be copied and redistributed under the same terms
as Perl itself (this is by far the most common licensing option for
modules on CPAN).  This is a dual license, in which the user may
choose between either the GPL or the Artistic license.

=item restrictive

The distribution may not be redistributed without special permission
from the author and/or copyright holder.

=item unrestricted

The distribution is licensed under a license that is B<not> approved
by www.opensource.org but that allows distribution without
restrictions.

=back



=head4 meta_add

=head4 meta_merge

    meta_add    'provides', { 'Useful.Module' => { file => 'lib/Useful/Module.js', version => '0.001_010'} };
    meta_merge  'resources', 'bugtracker' => 'http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-JSAN';

meta_add and meta_merge adds their parameters to the C<META.json> file.

The first parameter is the key to add or merge to, and the second parameter 
is the value of that key (which may be a string, an arrayref, or a hashref.)

The one difference is that meta_add overwrites anything else in that key, 
while meta_merge will merge an arrayref or hashref into the current 
contents of the key. 

Also, meta_merge allows a hashref to be ommitted if it contains only one value.


=head2 Lists of modules

All lists of modules take a module name (with an optional version) or a 
hashref that contains a list of modules and versions.

Versions are specified as L<Module::Build::Authoring|Module::Build::Authoring#Format_of_prerequisites>
specifies them.

If the version parameter is omitted when one module is being added to the 
list, the version is assumed to be 0.

=head4 requires

    requires 'Useful.Module' => 2.17;
    
    #or in DSL notation
    requires Useful.Module      2.17

Modules listed using this function are required for using the module(s) being installed.

=head4 recommends

    recommends 'Useful.Module' => 2.17;
    
    #or in DSL notation
    recommends Useful.Module      2.17

Modules listed using this directive are recommended, but not required, for using the module(s) being installed.

=head4 build_requires

    build_requires 'Useful.Module' => 2.17;
    
    #or in DSL notation    
    build_requires Useful.Module    2.17

Modules listed using this function are only required for running C<./Build> 
itself, not C<Build.PL>, nor the module(s) being installed.


=head4 conflicts

    conflicts 'Useful.Module' => 2.17;
    
    #or in DSL notation    
    conflicts Useful.Module    2.17

Modules listed using this function conflict in some serious way with the 
module being installed, and the Build.PL will not continue if these modules 
are already installed.


=head2 Flags

Functions listed here are B<not> accumulative - only the last value a flag has 
been set to will apply.


=head4 create_makefile_pl

    create_makefile_pl 'passthrough';
    create_makefile_pl 'small';         #not supported
    create_makefile_pl 'traditional';   #not supported

This function lets you use Module::Build::Compat during the C<distdir> (or 
C<dist>) action to automatically create a C<Makefile.PL>. The only supported
parameter value is 'passthrough', which delegates all actions from Makefile.PL
to actions from Build.PL with corresponding names. 


=head4 dynamic_config

    dynamic_config 1;
    dynamic_config 0;

This function indicates whether the Build.PL file must be executed, or 
whether this module can be built, tested and installed solely from 
consulting its metadata file. The main reason to set this to a true value 
is that your module performs some dynamic configuration as part of its 
build/install process. If the flag is omitted, the META spec says that 
installation tools should treat it as 1 (true), because this is a safer way 
to behave.


=head4 sign

    sign 1;

If this is set to 1, Module::Build will use L<Module::Signature> to create 
a signature file for your distribution during the C<distdir> action.


=head2 Other functions

=head4 add_to_cleanup
 
    add_to_cleanup 'Useful.Module-*';
    add_to_cleanup 'Makefile';

Adds a file specification (or an array of file specifications) to the 
list of files to cleanup when the C<clean> action is performed.

=head4 create_build_script

=head4 WriteAll

Creates the I<Build.PL> to be run in future steps, and returns the L<Module::Build> object created.

This directive should appears the last in the builder script. 
It can be omitted if script is written in the DSL notation.

=head4 repository

    repository 'http://svn.ali.as/cpan/trunk/Module-Build-Functions/';

Alias for 

    meta_merge 'resources', 'repository' => $url 

=head4 bugtracker

    bugtracker 'http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-Build-Functions';

Alias for 

    meta_merge 'resources', 'bugtracker' => $url 


=head1 LOCAL JSAN LIBRARY

This module uses concept of local JSAN library, which is organized in the same way as libraries for other languages.

The path to the library is resolved in the following order:

1. B<--install_base> command-line argument

2. environment variable B<JSAN_LIB>

3. Either the first directory in C<$Config{libspath}>, followed with C</jsan> (probably C</usr/local/lib> on linux systems)
or C<C:\JSAN> (on Windows)

As a convention, it is recommended, that you configure your local web-server
that way, that B</jsan> will point at the B</lib> subdirectory of your local
JSAN library. This way you can access any module from it, with URLs like:
B<'/jsan/Test/Run.js'>  


=head1 AUTHOR

Nickolay Platonov, C<< <nplatonov at cpan.org> >>


=head1 ACKNOWLEDGEMENTS

Many thanks to Module::Build authors, from which a lot of content were borrowed.


=head1 COPYRIGHT & LICENSE

Copyright 2009 Nickolay Platonov, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
