package Scalar::Constant;

use strict;
use Carp;
use Scalar::Quote 'quote';
use Scalar::Util qw(looks_like_number);

use vars qw( $VERSION );
$VERSION = 0.001_005;


sub import {
    my $module = shift;
    my %constant = @_ 
      or return;

    my $calling_package = (caller)[0];
    my @code;
    while(my($name, $value) = each %constant) {
        if(ref($value)) {
            croak 'References are not supported';
        }
        if(! looks_like_number($value)) {
            $value = quote($value);
        }
        push @code, sprintf('*%s::%s = \ %s;', $calling_package, $name, $value);
    } 

    my $code = join("\n", @code);
    eval $code
      or confess "This shouldn't happen: $@";
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Scalar::Constant - lightweight constant scalars. 


=head1 SYNOPSIS

    use Scalar::Constant
        PI => 3.1415926535,
        C  => 299_792_458,
        HI => 'hello world';

    print "pi is $PI, and c is $C m/s\n";  

    $PI = 0; # dies with "Modification of a read-only value attempted at"
  
=head1 DESCRIPTION

This module gives you a simple way to define constant scalars. Unlike the constants created 
with L<constant>, these can be interpolated into strings and used as hash keys.

=head1 CONFIGURATION AND ENVIRONMENT

Scalar::Constant requires no configuration files or environment variables.


=head1 DEPENDENCIES

L<Scalar::Quote>


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

Only simple scalars i.e. numbers and strings are supported. Attempting to
define a constant with a reference value will result in an exception (compilation will be aborted).

Please report any bugs or feature requests through
the GitHub web interface at L<https://github.com/arunbear/perl5-scalar-constant/issues>.


=head1 AUTHOR

Arun Prasaad  C<< <arunbear@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

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
