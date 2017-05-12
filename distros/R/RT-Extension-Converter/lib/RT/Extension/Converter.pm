package RT::Extension::Converter;

our $VERSION = '0.03';

use warnings;
use strict;
use Carp;


=head1 NAME

RT::Extension::Converter - base class for rtX-to-rt3 scripts


=head1 SYNOPSIS

    use RT::Extension::Converter;
    my $rt1converter = RT::Extension::Converter->new( type => 'rt1' );
    my $rt3converter = RT::Extension::Converter->new( type => 'rt3' );

    foreach my $user ($rt1converter->users) {
        $rt3converter->add_user( $user );
    }

=head1 DESCRIPTION

Top level Converter class, used to get access to the RT(1,2,3) converter
objects.

=head1 METHODS

=head2 new

Requires a type argument

 new( type => 'RT1' );

=cut

sub new {
    my $class = shift;
    my %args = @_;

    Carp::confess "Must pass a type [$args{type}]" unless $args{type};

    my $subclass = "${class}::$args{type}";
    eval "require $subclass";
    if ($@) {
        Carp::confess "Not a valid type $args{type} $subclass $@";
    }

    return $subclass->new;
}


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-rtx-converter@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org> or on C<rt-devel@lists.bestpractical.com>


=head1 AUTHOR

Kevin Falcone  C<< <falcone@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Best Practical Solutions, LLC.  All rights reserved.

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

=cut

1;
