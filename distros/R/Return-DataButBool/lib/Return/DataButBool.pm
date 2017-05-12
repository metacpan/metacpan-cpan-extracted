package Return::DataButBool;

use warnings;
use strict;

use version; our $VERSION = qv('0.0.3');

use base 'Exporter';
our @EXPORT = qw(zero_but_true data_but_true data_but_false);

# bring in the big guns
use Contextual::Return;

sub zero_but_true {
    return '0e0';	
}

sub data_but_true {
    my $num = _get_num_from( shift() );
    my $str = shift();
    $str    = $num if !defined $str;
    
    return (
        BOOL { 1; }
        NUM  { $num }
        STR  { $str }
    );
}

sub data_but_false {
    my $num = _get_num_from( shift() );
    my $str = shift();
    $str    = $num if !defined $str;

    return (
        BOOL { 0; }
        NUM  { $num }
        STR  { $str }
    );
}

# out in external num() func or something?
sub _get_num_from {
	my ($num) = @_;
	return $num =~ m{ \A ([-+]? \d+ (?: [.] \d+ )?) \z }xms ? $1 : int($num);
}

1; 

__END__

=head1 NAME

Return::DataButBool - Return a boolean value that also has arbitrary numeric and string values


=head1 VERSION

This document describes Return::DataButBool version 0.0.3

=head1 SYNOPSIS

    use Return::DataButBool;

    sub whatever {
	    ...
	    return $ok ? data_but_true( $count ) : data_but_false( $count, $error );
    }

later in the code using this function:

    my $total = 0;
    for my $thing ( @stuff ) {
	    my $rc = whatever( $thing );
	    $total += $rc; # numeric value
	
	    if( !$rc ) { # boolean value
		    carp "Error happened: $rc"; # string value
	    }
    }

=head1 DESCRIPTION

Perl's Zero-But-True ( 0e0 ) is a most handy tool (See L<String::ZeroButTrue>). This module expands on that idea by having a return value that has different boolean, numeric, and string values.

For example you could return a count of files processed (say 42 which is "true") but still say it failed in boolean context.

or you could return any false value ( not just '0' ) but still return true. The flexibility allows for all sorts of use.

=head1 EXPORT

All 3 functions are exported by default.

=head1 INTERFACE 

The data_but_* functions take one or two arguments.

The first is the numeric value. Can be signed and/or decimal if you like. If its not [+-] digit [decimal digit] then it is passed through int() - see _get_num_from()

The second is the string value. If not specified the numeric value is used.

=head2 zero_but_true()

takes no args, returns good 'ol 0e0 (zero but true). See L<String::ZeroButTrue> for more comprehensive alternatives.

=head2 data_but_true()

The value returned evaluates to true in a boolean context. The numeric and string context are determined by the arguments passed as describe above.

=head2 data_but_false()

The value returned evaluates to false in a boolean context. The numeric and string context are determined by the arguments passed as describe above.

=head2 Internal functions

=head3 _get_num_from()

This function makes sure your first argument is numeric ( possible sign, digits, possihle decimal point more digits - or int() )

=head1 DIAGNOSTICS

Throws no errors or warnings

=head1 CONFIGURATION AND ENVIRONMENT

Return::DataButBool requires no configuration files or environment variables.

=head1 DEPENDENCIES

This uses the excellent L<Contextual::Return> whcih can be used if your return needs are more complicated than this module's purpose.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-return-databutbool@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

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