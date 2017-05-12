use strict;
use warnings;
package Skeletor::Template::Quick;

our $VERSION = "0.02";

1;

__END__

=head1 NAME

Skeletor::Template::Quick - Quick set of skeletor templates

=head1 SYNOPSIS

      # First, configure the preferences file
    $ cat ~/.skeletor.yml
    # ~/.skeletor.yml
    author: Joe Schmoe <joe@schmoe.com>

      # Then, create skeletons for new cpan modules
    $ skel Foo::Bar

    $ tree Foo-Bar/
    Foo-Bar/
    ├── Changes
    ├── eg
    │   └── foo-bar
    ├── lib
    │   └── Foo
    │       └── Bar.pm
    ├── Makefile.PL
    ├── MANIFEST.SKIP
    └── t
        └── 001Basic.t

4 directories, 6 files

=head1 DESCRIPTION

C<Skeletor::Template::Quick> is a template for C<App::Skeletor>, a utility to create
skeletons for new Perl module distributions. 

It comes with a command line utilty C<skel> which requires a preferences file 
C<~/.skeletor.yml> and alleviates the user from having to specify the same list of parameters
(author, template, etc.) on C<skeletor> calls every time.

=head1 LEGALESE

Copyright 2015 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2015, Mike Schilli <cpan@perlmeister.com>
