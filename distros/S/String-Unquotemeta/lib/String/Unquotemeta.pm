package String::Unquotemeta;

use strict;
use warnings;

$String::Unquotemeta::VERSION = '0.1';

sub import {
    no strict 'refs';    # I know, PBG says not to do this helps keep it very simple and light
    *{ caller() . '::unquotemeta' } = \&unquotemeta;
}

# I know, PBP says no prototypes and I very much agree but I want it to
# behave like quotemeta() without a lot of fuss (see tests for details)
sub unquotemeta(;$) {
    my ($string) = scalar(@_) ? $_[0] : $_;    # quotemeta() "If EXPR is omitted, uses $_."
    return '' if !defined $string;             # quotemeta() undef behavior

    $string =~ s/(?:\\(?!\\))//g;
    $string =~ s/(?:\\\\)/\\/g;

    return $string;
}

1;

__END__

=head1 NAME

String::Unquotemeta - undo what quotemeta() does, nothing more nothing less

=head1 VERSION

This document describes String::Unquotemeta version 0.1

=head1 SYNOPSIS

    use String::Unquotemeta;
    
    my $japh = 'J.A.P.H.';
    my $meta = quotemeta($japh); # J\.A\.P\.H\.
    my $undo = unquotemeta($meta); # J.A.P.H.

=head1 DESCRIPTION

This module provides one simple function, unquotemeta(), that undoes the escaping that quotemeta() does. 

It handles undefined values, no values, too many values, etc the same way as quotemeta(). Think of it as quotemeta()'s evil twin.

unquotemeta() is exported into the calling name space unless you bring in the module without it's import() method being called:

    use String::Unquotemeta (); # do not call import() == do not pollute my name space
    my $undone = String::Unquotemeta::unquotemeta($string);  

    require String::Unquotemeta; # do not call import() == do not pollute my name space
    my $undone = String::Unquotemeta::unquotemeta($string);

=head1 INTERFACE 

=head2 unquotemeta()

Takes one argument, the string to undo what quotemeta() did.

If no argument is given, then it uses $_ (like quotemeta()).

If an undefined argument is given, it returns '' (like quotemeta()).

=head1 DIAGNOSTICS

Throws no warnings or errors of it's own.

=head1 CONFIGURATION AND ENVIRONMENT

String::Unquotemeta requires no configuration files or environment variables.

=head1 DEPENDENCIES

None.

=head1 SEE ALSO

L<String::Escape> has an unquotemeta() function also. If you need all of the other utilities and exporting it provides feel free to use it instead.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-string-unquotemeta@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
