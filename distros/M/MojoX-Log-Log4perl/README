MojoX-Log-Log4perl
==================

This module provides a Mojo::Log implementation that uses Log::Log4perl
as the underlying log mechanism. It provides all the methods listed in
Mojo::Log (and many more from Log4perl) so, if you already use Mojo::Log
in your application, there is no need to change a single line of code!

```perl
    package MyApp;
    use Mojo::Base 'Mojolicious';
    use MojoX::Log::Log4perl;

    sub startup {
        my $self = shift;

        # that's all the extra code you need!
        $self->log( MojoX::Log::Log4perl->new );

        # next, just set up your app's routes as you normally would
    }
```

Now all your logging can be controlled via the ```log4perl.conf``` file :)

See the module's documentation for extra information and available methods.


INSTALLATION
------------

    # from CPAN
    $ cpan MojoX::Log::Log4perl

    # from cpanm
    $ cpanm MojoX::Log::Log4perl

    # cloning the repository
    $ git clone git://github.com/garu/MojoX-Log-Log4perl.git

    # manual installation, after downloading
    perl Makefile.PL
    make
    make test
    make install


USAGE
-----

In lib/MyApp.pm from your Mojolicious project:

    use MojoX::Log::Log4perl;

    sub startup {
        # ... your routes & etc here
        $self->log( MojoX::Log::Log4perl->new('mylogger.conf') );
    }

Now $self->app->log will use Log4perl and whatever setup you made
on 'mylogger.conf' inside your Mojolicious app!

Please refer to https://metacpan.org/module/MojoX::Log::Log4perl
for the complete documentation, or type:

    perldoc MojoX::Log::Log4perl

on the terminal after installation.


SUPPORT AND DOCUMENTATION
-------------------------

You can also look for information at:

    RT, CPAN's request tracker
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=MojoX-Log-Log4perl

    AnnoCPAN, Annotated CPAN documentation
        http://annocpan.org/dist/MojoX-Log-Log4perl

    CPAN Ratings
        http://cpanratings.perl.org/d/MojoX-Log-Log4perl

    Search MetaCPAN
        https://metacpan.org/module/MojoX::Log::Log4perl


COPYRIGHT AND LICENCE
---------------------

Copyright (C) 2009-2016 Breno G. de Oliveira

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

