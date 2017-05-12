package String::ZeroButTrue;

use strict;
use warnings;

$String::ZeroButTrue::VERSION = '0.2';

use base 'Exporter';
@String::ZeroButTrue::EXPORT      = qw(get_zero_but_true is_zero_but_true);
@String::ZeroButTrue::EXPORT_OK   = qw(get_zero_but_true_uc get_zero_but_true_phrase);
%String::ZeroButTrue::EXPORT_TAGS = (
    'all' => [@String::ZeroButTrue::EXPORT, @String::ZeroButTrue::EXPORT_OK],
);

sub get_zero_but_true {
    return '0e0';
}

sub get_zero_but_true_uc {
    return '0E0';
}

sub get_zero_but_true_phrase {
    return '0 but true';
}

sub is_zero_but_true {
    my $string = shift;
    # We have to do a string eq because $string && $string == 0 it true when its a string being compared numerically:
    #     perl -Mstrict -we 'if ("hello world" == 0) { print "yes it is 0\n" }
    # no warnings 'numeric'; # string might *be* a string == Argument "$string" isn't numeric in numeric eq (==) at ...
    # return 1 if defined $string && $string && $string == 0;
    
    $string =~ tr/A-Z/a-z/;
    return 1 if defined $string && $string && ($string eq '0e0' || $string eq '0 but true');
    return;
}

1; 

__END__

=head1 NAME

String::ZeroButTrue - utils for consistent zero-but-true usage

=head1 VERSION

This document describes String::ZeroButTrue version 0.2

=head1 SYNOPSIS

    use String::ZeroButTrue;
    
    my $rc = func(@args);
    if (is_zero_but_true($rc)) {
        # act on zero but true $rc
    }
    elsif($rc) {
        # act on otherwise true $rc 
    }
    else {
        # act on false $rc   
    }
    
    ...
    
    sub func {
        ....
        return get_zero_but_true() if $whatever;
        ....
    }

=head1 DESCRIPTION

Zero-but-true is cool. There are some nuances that are easy to overlook though.

For example, the ever common "dyslexia" that ends up E0E instead of 0E0, the 'bareword instead of string' use that changes its behavior, the numeric check (e.g. $string && $string == 0) that throws warnings when the value in question is string, etc etc

So this little module is here to help!

=head1 INTERFACE 

is_zero_but_true() and get_zero_but_true() are imported into your namespace by default. The rest can be. ':all' will bring import all of them.

=head2 is_zero_but_true()

Takes one argument and returns true if the value is zero-but-true and false otherwise.

=head2 get_zero_but_true()

returns the string 0e0 

This is the default one (i.e. no special ending on the function name) because its easiest to type (i.e. its short and does not require pressing shift)

=head2 get_zero_but_true_uc()

returns the string 0E0 

=head2 get_zero_but_true_phrase()

returns the string '0 but true'

=head1 DIAGNOSTICS

Thorws no warnings or errors.

=head1 CONFIGURATION AND ENVIRONMENT

String::ZeroButTrue requires no configuration files or environment variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-string-zerobuttrue@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 SEE ALSO

L<Return::DataButBool> and L<Contextual::Return>

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

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