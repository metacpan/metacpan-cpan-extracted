# NAME

Pod::Section - select specified section from Module's POD

# VERSION

Version 0.02

# SYNOPSIS

    use Pod::Section qw/select_podsection/;

    my @function_pods = select_podsection($module, @functions);
    my @section_pods = select_podsection($module, @sections);

In scalar context, pod is joined as one scalar.

    my $function_pods = select_podsection($module, @functions);
    my $section_pods = select_podsection($module, @sections);

use podsection on shell

    % podsection Catalyst req res
    $c->req
      Returns the current Catalyst::Request object, giving access to
      information about the current client request (including parameters,
      cookies, HTTP headers, etc.). See Catalyst::Request.
    
    $c->res
      Returns the current Catalyst::Response object, see there for details.

# EXPORT

## select\_podsection

See SYNOPSIS.

# AUTHOR

Ktat, `<ktat at cpan.org>`

# BUGS

The way to search section is poor. This cannot find section correctly in some modules.

Please report any bugs or feature requests to `bug-pod-section at rt.cpan.org`, or through
the web interface at [http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Pod-Section](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Pod-Section).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Pod::Section
    perldoc podsection

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Pod-Section](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Pod-Section)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Pod-Section](http://annocpan.org/dist/Pod-Section)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Pod-Section](http://cpanratings.perl.org/d/Pod-Section)

- Search CPAN

    [http://search.cpan.org/dist/Pod-Section/](http://search.cpan.org/dist/Pod-Section/)

# ACKNOWLEDGEMENTS

# SEE ALSO

## Pod::Select

This also select section, but cannot search function/method explanation.

# LICENSE AND COPYRIGHT

Copyright 2010 Ktat.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
