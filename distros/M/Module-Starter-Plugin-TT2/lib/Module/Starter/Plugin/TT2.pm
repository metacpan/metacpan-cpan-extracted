use warnings;
use strict;
package Module::Starter::Plugin::TT2;

our $VERSION = '0.125';

use Template;

=head1 NAME

Module::Starter::Plugin::TT2 - TT2 templates for Module::Starter::Template

=head1 VERSION

version 0.125

=head1 SYNOPSIS

 use Module::Starter qw(
   Module::Starter::Simple
   Module::Starter::Plugin::Template
   Module::Starter::Plugin::TT2
     ...
 );

 Module::Starter->create_distro( ... );

=head1 DESCRIPTION

This Module::Starter plugin is intended to be loaded after
Module::Starter::Plugin::Template.  It implements the C<renderer> and C<render>
methods, required by the Template plugin.  The methods are implemented with
Template Toolkit.

This module's distribution includes a directory, C<templates/dir>, and a file
C<templates/inline> that contain stock templates for use with the InlineStore
and DirStore plugins.  The module itself contains default templates in its data
section.

=head1 USAGE

This module is meant to be used with the template stores in the SimpleStore
distribution (although you could certainly write your own template store).  If
you only want to use the built-in templates, you could have lines like this in
your config file (C<~/.module-starter/config>):

 author: Lord Poncemby
 email: ponce@peerage.eng
 plugins: Module::Starter::Simple Module::Starter::Plugin::Template
  Module::Starter::Plugin::ModuleStore Module::Starter::Plugin::TT2
 template_module: Module::Starter::Plugin::TT2

(Where the plugins line is one line.)  This tells Module::Starter to look for
the templates in the data section of Module::Starter::Plugin::TT2, which isn't
very interesting, since you'll end up getting the same effect as if you'd just
used Module::Starter without plugins.

To override this behavior, you'd instruct Module::Starter to look somewhere
else, either by changing the C<template_module> setting, changing the
MODULE_TEMPLATE_MODULE environment variable, or using a different template
store altogether (q.v., SimpleStore or other plugins).

=head1 METHODS

=head2 C<< renderer >>

As implemented, this method just creates a new Template Toolkit engine and
stores it in the Module::Starter object.

=cut

sub renderer {
  my ($self) = @_;
  my $conf = (eval $self->{template_parms})||{};
  my $renderer = Template->new($conf);
}

=head2 C<< render( $template, \%options ) >>

This method passes the given template contents and options to the TT2 renderer
and returns the resulting document.

=cut

sub render {
  my $self = shift;
  my $template = shift;
  my $options = shift;
  my $output;

  $options->{self} = $self;
  $options->{year} = $self->_thisyear;
  
  $self->renderer->process(\$template, $options, \$output);
  return $output;
}

=head1 AUTHOR

Ricardo SIGNES, C<< <rjbs@cpan.org> >>

=head1 COPYRIGHT

Copyright 2004-2006 Ricardo SIGNES, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

__DATA__
___Module.pm___
package [%module%];

use warnings;
use strict;

=head1 NAME

[%module%] - The fantastic new [%module%]!

=head1 VERSION

version 0.001

=cut

our $VERSION = '0.001';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use [%module%];

    my $foo = [%module%]->new;
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 function1

=cut

sub function1 {
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

[%self.author%], C<< <[%self.email%]> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-[%rtname%]@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright [%year%] [%self.author%], All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of [%module%]
___Makefile.PL___
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => '[%main_module%]',
    AUTHOR              => '[% self.author %] <[% self.email %]>',
    VERSION_FROM        => '[%main_pm_file%]',
    ABSTRACT_FROM       => '[%main_pm_file%]',
    LICENSE             => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => '[%self.distro%]-*' },
);
___MI_Makefile.PL___
use inc::Module::Install;

name     '[% self.distro  %]';
all_from '[% main_pm_file %]';
author   '[% self.author %] <[% self.email %]>';

build_requires 'Test::More';

WriteAll;
___Build.PL___

use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => '[%main_module%]',
    license             => '[%self.license%]',
    dist_author         => '[%self.author%] <[%self.email%]>',
    dist_version_from   => '[%main_pm_file%]',
    requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ '[%self.distro%]-*' ],
);

$builder->create_build_script();
___Changes___
Revision history for [%self.distro%]

0.001   Date/time
        First version, released on an unsuspecting world.

___README___
[%self.distro%]

The README is used to introduce the module and provide instructions on
how to install the module, any machine dependencies it may have (for
example C compilers and installed libraries) and any other information
that should be provided before the module is installed.

A README file is required for CPAN modules since CPAN extracts the README
file from a module distribution so that people browsing the archive
can use it get an idea of the modules uses. It is usually a good idea
to provide version information here so that people can decide whether
fixes for the module are worth downloading.

INSTALLATION

[%build_instructions%]

COPYRIGHT AND LICENCE

Put the correct copyright and licence information here.

Copyright (C) [%year%] [% self.author %]

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
___pod.t___
use Test::More;
eval "use Test::Pod 1.14";
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;
all_pod_files_ok();
___pod-coverage.t___
use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage"
    if $@;
all_pod_coverage_ok();
___00-load.t___
use Test::More tests => [% modules.size %];

BEGIN {
[% FOREACH module = modules -%]
  use_ok('[%module%]');
[% END -%]
}

diag( "Testing [%modules.0%] $[%modules.0%]::VERSION" );
___MANIFEST___
[% FOREACH file = files -%]
[% file %]
[% END -%]
___cvsignore___
blib*
Makefile
Makefile.old
Build
_build*
pm_to_blib*
*.tar.gz
.lwpcookies
.releaserc
[%self.distro%]-*
cover_db
