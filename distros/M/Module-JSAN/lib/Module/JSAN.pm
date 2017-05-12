package Module::JSAN;

use warnings;
use strict;

our $VERSION = '0.04';


sub import {
    
    {
        package main;
        
        use warnings;
        use inc::Module::Build::Functions(build_class => 'Module::Build::JSAN::Installable');
        
        Module::Build::Functions::copy_package('Module::JSAN');
        Module::Build::Functions::copy_package('Module::Build::JSAN', 'true');
        Module::Build::Functions::copy_package('Module::Build::JSAN::Installable', 'true');
        
        Module::Build::Functions::_mb_required('0.35');
        
        my $old_get_builder = \&Module::Build::Functions::get_builder;
        
        no warnings;
        
        *Module::Build::Functions::get_builder = sub {
            *Module::Build::Functions::build_requires = sub {};
            *Module::Build::Functions::configure_requires = sub {};
            
            return &$old_get_builder();
        }
    }
}


__PACKAGE__;

__END__

=head1 NAME

Module::JSAN - Build JavaScript distributions for JSAN

=head1 VERSION

Version 0.03

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
    

To build, test and install a distribution:

  % perl Build.PL
  % ./Build
  % ./Build test  
  % ./Build install
    
    

=head1 DESCRIPTION

JSAN is the "JavaScript Archive Network," a JavaScript library akin to CPAN. Visit L<http://www.openjsan.org/> for details.
This module is a developer aid for creating JSAN distributions. 

This module works as simple wrapper for L<Module::Build::JSAN::Installable>, please also refer to its documentation for additional details. 
The difference is that this module provides a less perl-specifiec and more relaxed syntax for builder scripts. 


=head1 WRITING A JSAN MODULE

This is a short tutorial on writing a simple JSAN module. Its really not that hard (tm).

=head2 The Layout

The basic files in a module look something like this.

        Build.PL
        lib/Your/Module.js

See the synopsys above for the sample content of Build.PL. That's all that's strictly necessary.
There's additional files you'll need to publish your module on JSAN, most of them can be generated automatically,
with the help of this module.

More advanced layout will look like:

        lib/Your/Other/Module.js
        t/01_some_test.t.js
        t/02_some_other_test.t.js
        Changes
        README
        INSTALL
        MANIFEST
        MANIFEST.SKIP


Below is the explanation of each item in the layout.


=over 4

=item Build.PL

When you run Build.PL, it creates a 'Build' script.  That's the whole point of Build.PL.  

    perl Build.PL

The 'Build' is a simple, cross-platform perl script, which loads
Module::Build::JSAN::Installable and couple of another modules to manage the 
distribution. 

Here's an example of what you need for a very simple module:

    use inc::Module::JSAN;

    name        'Your.Module';
    
    version     0.01;

'name' directive indentifies the name of your distribution and 'version' - its version. Pretty simple.
Name and version is the only metadata which is strictly required to publish your module. For other
pieces of metadata which can be specified, please refer to more in-depth tutorial: L<Module::JSAN::Tutorial>.

'Build' script accepts arguments on command line. The 1st argument is called - action. Other arguments
are various for different actions. Example of calling 'doc' action:

    ./Build doc
    
    
or on Windows

    Build doc    

=item MANIFEST

Manifest is a simple listing of all the files in your distribution.

        Build.PL
        MANIFEST
        lib/Your/Module.js

Filepaths in a MANIFEST always use Unix conventions (ie. /) even if you're not on Unix.

You can write this by hand or generate it with 'manifest' action.

    ./Build manifest


=item lib/

This is the directory where your *.js files you wish to have installed go.  They are layed out according to namespace.  
So Foo.Bar is lib/Foo/Bar.js.


=item t/

Tests for your modules go here.  Each test filename ends with a .t.js.

Automated testing is not yet implemented. Please refer to documentation of various testing tools on JSAN,
which allows to run the test suite semi-automatically. 
Examples: L<http://openjsan.org/go?l=Test.Run> or L<http://openjsan.org/go?l=Test.Simple>.


=item Changes

A log of changes you've made to this module.  The layout is free-form. Here's an example:

    1.01 Fri Apr 11 00:21:25 PDT 2003
        - thing() does some stuff now
        - fixed the wiggy bug in withit()

    1.00 Mon Apr  7 00:57:15 PDT 2003
        - "Rain of Frogs" now supported


=item README

A short description of your module, what it does, why someone would use it
and its limitations.  JSAN automatically pulls your README file out of
the archive and makes it available to JSAN users, it is the first thing
they will read to decide if your module is right for them.


=item INSTALL

Instructions on how to install your module along with any dependencies.
Suggested information to include here:

    any extra modules required for use
    the required javascript engine
    required operating systems/browser


=item MANIFEST.SKIP

A file full of regular expressions to exclude when using './Build manifest' 
to generate the MANIFEST.  These regular expressions are checked against each full filepath 
found in the distribution (so you're matching against "t/foo.t" not "foo.t").

Here's a sample:

    ~$          # ignore emacs and vim backup files
    .bak$       # ignore manual backups
    \b\.svn\b   # ignore all SVN directories
    ^\.git\b    # ignore top-level .git directory

Since # can be used for comments, # must be escaped.

Module::JSAN comes with a default MANIFEST.SKIP to avoid things like
version control directories and backup files. You can alter it as necessary.


=head2 The Documentation

The work isn't over until the paperwork is done, and you're going to need to put in 
some time writing some documentation for your module.
JSAN module can be documented in several markup languages, notably in 

=over 3

=item POD 

Plain Old Documentation. Authors with perl background may prefere this markup language, as its native to perl

L<http://perldoc.perl.org/perlpod.html>

=item Markdown 

Very convenient markup language, with main focus on documents readability. Markdown documents
can be published as-is, as plain text, without looking like it's been marked up with tags or formatting instructions. 

L<http://daringfireball.net/projects/markdown/syntax>


=item MultiMarkdown

Further extension of Markdown with ability to specify some metadata for documents.

L<http://fletcherpenney.net/multimarkdown/users_guide/multimarkdown_syntax_guide/>

=back

if you're not sure about the format, check the links and choose the most appropriate for you. 
Put the documentation in JavaScript comments, which starts at line begining with double star:

    /**
    
    Name
    ====
    
    Your.Module - A new and shining JSAN module
    
    SYNOPSIS
    ========
    
        var instance = new Your.Module({
            foo     : 'bar',
            bar     : 'var'
            var     : 'baz'
        })
        
        instance.saveMyDay()

    
    DESCRIPTION
    ===========
    
    Your.Module is very useful module, which do a single task, and do it good.
    
    */

parser will found such comments and extract the documentation from them. 
Pod documentation can be put in the usual comments.

Provide a good synopsis of how your module is used in code, a description, and then 
notes on the syntax and function of the individual subroutines or methods. 
Use comments for developer notes and documentation for end-user notes.


=head2 The Tarball

Once you have all the preparations done and documentation written, its time to create a release tarball.
Execute 'dist' action of the 'Build' script:

    ./Build dist

Perhaps you'll need to specify paths to gzip and tar archivers on your system: 

    ./Build dist --gzip=gzip --tar=tar
    
    
    % Deleting META.json
    % Creating META.json
    % Creating Task.Joose.Stable-3.04
    % Creating Task.Joose.Stable-3.04.tar.gz
    % tar cf Task.Joose.Stable-3.04.tar Task.Joose.Stable-3.04
    % gzip Task.Joose.Stable-3.04.tar
    % Deleting Task.Joose.Stable-3.04

Thats all, tarball is ready for uploading to JSAN.     


=head2 The Mantra

JSAN modules can be installed from expanded tarballs using this simple mantra:

    perl Build.PL
    ./Build
    ./Build install


=head2 The Magic

For more in-depth explanations please refer to L<Module::JSAN::Tutorial>
 

=head1 AUTHOR

Nickolay Platonov, C<< <nplatonov at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-module-jsan at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-JSAN>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Module::JSAN


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Module-JSAN>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Module-JSAN>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Module-JSAN>

=item * Search CPAN

L<http://search.cpan.org/dist/Module-JSAN/>

=back


=head1 ACKNOWLEDGEMENTS

Many thanks to Curtis Jewell, who's L<Module::Build::Functions> made this module possible.

Many thanks to Jarkko Hietaniemi for his ExtUtils::MakeMaker::Tutorial, from which a lot of content were borrowed.


=head1 COPYRIGHT & LICENSE

Copyright 2009 Nickolay Platonov, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
