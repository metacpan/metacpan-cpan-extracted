# NAME

MooX::Locale::Passthrough - provide API used in translator modules without translating

# SYNOPSIS

    { package WonderBar;
      use Moo;
      with "MooX::Locale::Passthrough";

      sub tell_me { my $self = shift; $self->__("Hello world"); }
    }

    WonderBar->new->tell_me;

# DESCRIPTION

`MooX::Locale::Passthrough` is made to allow CPAN modules use translator API
without adding heavy dependencies (external software) or requirements (operating
resulting solution).

This software is released together with [MooX::Locale::TextDomain::OO](https://metacpan.org/pod/MooX::Locale::TextDomain::OO), which
allowes then to plugin any desired translation.

# METHODS

## \_\_ MSGID

returns MSGID

## \_\_n MSGID, MSGID\_PLURAL, COUNT

returns MSGID when count is equal 1, MSGID\_PLURAL otherwise

## \_\_p MSGCTX, MSGID

returns MSGID

# AUTHOR

Jens Rehsack, `<rehsack at cpan.org>`

# BUGS

Please report any bugs or feature requests to
`bug-MooX-Locale-Passthrough at rt.cpan.org`, or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooX-Locale-Passthrough](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooX-Locale-Passthrough).
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooX::Locale::Passthrough

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooX-Locale-Passthrough](http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooX-Locale-Passthrough)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/MooX-Locale-Passthrough](http://annocpan.org/dist/MooX-Locale-Passthrough)

- CPAN Ratings

    [http://cpanratings.perl.org/m/MooX-Locale-Passthrough](http://cpanratings.perl.org/m/MooX-Locale-Passthrough)

- Search CPAN

    [http://search.cpan.org/dist/MooX-Locale-Passthrough/](http://search.cpan.org/dist/MooX-Locale-Passthrough/)

# LICENSE AND COPYRIGHT

Copyright 2017 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
