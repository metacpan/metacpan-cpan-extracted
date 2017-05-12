# NAME

Pod::Simpler::Aoh - Parse pod into array of hashes.

# VERSION

Version 0.01

# SYNOPSIS

Parse POD into an array of hashes

    use Pod::Simpler::Aoh;

    my $pod_parser = Pod::Simpler::Aoh->new();
    my $pod = $pod_parser->parse_file( 'perl.pod' );

    @pod_aoh = $parser->aoh;

    ...

    [
        {
            identifier => 'head1',
            title => NAME,
            content => 'Some::Module - Mehhhh?',
        },
        ......

    ]

# SUBROUTINES/METHODS

[Pod::Simpler::Aoh](https://metacpan.org/pod/Pod::Simpler::Aoh) Extends [Pod::Simple](https://metacpan.org/pod/Pod::Simple)

## parse\_file

Parse a file containing pod.

## parse\_string\_document

Parse a string containing pod.

## pod

Returns the parsed pod as an arrayref of hashes.

## aoh

Returns the parsed pod as an array of hashes.

## get

Accepts an index, returns a single \*section\* of pod.

# AUTHOR

Robert Acock, `<thisusedtobeanemail at gmail.com>`

# BUGS

Please report any bugs or feature requests to `bug-pod-simpler-hash at rt.cpan.org`, or through
the web interface at [http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Pod-Simpler-Aoh](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Pod-Simpler-Aoh).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Pod::Simpler::Aoh

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Pod-Simpler-Aoh](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Pod-Simpler-Aoh)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Pod-Simpler-Aoh](http://annocpan.org/dist/Pod-Simpler-Aoh)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Pod-Simpler-Aoh](http://cpanratings.perl.org/d/Pod-Simpler-Aoh)

- Search CPAN

    [http://search.cpan.org/dist/Pod-Simpler-Aoh/](http://search.cpan.org/dist/Pod-Simpler-Aoh/)

# ACKNOWLEDGEMENTS

# LICENSE AND COPYRIGHT

Copyright 2017 Robert Acock.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

[http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic_license_2_0)

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
