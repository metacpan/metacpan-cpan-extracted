# NAME

MooX::Locale::TextDomain::OO - provide API used in translator modules without translating

# SYNOPSIS

    { package WonderBar;
      use Moo;
      with "MooX::Locale::TextDomain::OO";

      sub tell_me { my $self = shift; $self->__("Hello world"); }
    }

    WonderBar->new->tell_me;

# DESCRIPTION

`MooX::Locale::TextDomain::OO` 

# OVERLOADED METHODS

## \_\_ MSGID

returns translation for MSGID

## \_\_n MSGID, MSGID\_PLURAL, COUNT

returns translation for MSGID when count is equal 1, translation for MSGID\_PLURAL otherwise

## \_\_p MSGCTXT, MSGID

returns translation for MSGID in MSGCTXT context

# AUTHOR

Jens Rehsack, `<rehsack at cpan.org>`

# BUGS

Please report any bugs or feature requests to
`bug-MooX-Locale-TextDomain-OO at rt.cpan.org`, or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooX-Locale-TextDomain-OO](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooX-Locale-TextDomain-OO).
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooX::Locale::TextDomain::OO

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooX-Locale-TextDomain-OO](http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooX-Locale-TextDomain-OO)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/MooX-Locale-TextDomain-OO](http://annocpan.org/dist/MooX-Locale-TextDomain-OO)

- CPAN Ratings

    [http://cpanratings.perl.org/m/MooX-Locale-TextDomain-OO](http://cpanratings.perl.org/m/MooX-Locale-TextDomain-OO)

- Search CPAN

    [http://search.cpan.org/dist/MooX-Locale-TextDomain-OO/](http://search.cpan.org/dist/MooX-Locale-TextDomain-OO/)

# LICENSE AND COPYRIGHT

Copyright 2017 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
