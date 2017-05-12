package RPM::NEVRA;

use strict;
use warnings;

=head1 NAME

RPM::NEVRA - Parses, validates NEVRA format

=head1 VERSION

Version 0.0.5

=cut

our $VERSION = 'v0.0.5';

=head1 SYNOPSIS

NEVRA is the best format to describe an RPM with full details.  The problem is, rpm's handling of epoch is different
from how repoquery handles epoch.  rpm omits the epoch when undefined, whereas repoquery thinks epoch was insignificant.
This subtle difference leads to incomplete queries such as this:

    $ repoquery bind-9.10.2-2.P1.fc22.x86_64
    bind-32:9.10.2-2.P1.fc22.x86_64

In the above example, I had the bind package from rpm -qa, which omitted epoch because it was undefined.  However, when
I feed it to repoquery, it gave me back with a package with epoch of 32.  This was an ambiguous query and the solution
is to ALWAYS specify the epoch in repoquery queries.

    use RPM::NEVRA;

    my $obj = RPM::NEVRA->new();
    my %info = $obj->parse_nevra('bind-32:9.10.2-2.P1.fc22.x86_64');
    print $info{epoch}; # prints 32

    my ( $is_nevra, $missing ) = $obj->is_nevra('bind-9.10.2-2.P1.fc22.x86_64'); # returns ( 0, 'epoch' )
    my $str = $obj->convert_to_nevra('bind-9.10.2-2.P1.fc22.x86_64'); # returns 'bind-0:9.10.2-2.P1.fc22.x86_64'

=head1 SUBROUTINES/METHODS

=head2 new

Constructor, takes no argument.

=cut

sub new {
    my $class = shift;
    return bless {}, $class;
}

=head2 parse_nevra($str)

Takes a string and returns a hash of name, epoch, ver, rel and arch.

=cut

sub parse_nevra {
    my ( $self, $str ) = @_;

    my $arch = ( split( /\./, $str ) )[-1];
    $str =~ s/\.$arch$//;

    my $rel = ( split( /-/, $str ) )[-1];
    $str =~ s/-$rel$//;

    my $ver_str = ( split( /-/, $str ) )[-1];
    my ( $epoch, $ver ) = split( /:/, $ver_str );
    my $trimmer;

    if ( !defined($ver) ) {    # no epoch
        $ver     = $epoch;
        $epoch   = undef;
        $trimmer = $ver;
    }
    else {
        $trimmer = "$epoch:$ver";
    }
    $str =~ s/-\Q$trimmer\E//;

    my %info;
    @info{qw(name arch rel ver epoch)} = ( $str, $arch, $rel, $ver, $epoch );
    return %info;
}

=head2 is_nevra($str)

Takes a string and returns (1, undef) if NEVRA, (0, $missing_field) otherwise

=cut

sub is_nevra {
    my ( $self, $str ) = @_;
    my %info = $self->parse_nevra($str);
    for my $key ( keys %info ) {
        my $val = $info{$key};
        return ( 0, $key ) unless ( defined $val );
    }
    return ( 1, undef );
}

=head2 convert_to_nevra($str)

Takes a string, parses it and convert to nevra format.

=cut

sub convert_to_nevra {
    my ( $self, $str ) = @_;
    my %pieces = $self->parse_nevra($str);
    my ( $name, $epoch, $ver, $rel, $arch ) = @pieces{qw(name epoch ver rel arch)};
    $epoch = 0 if ( !$epoch );
    return "$name-$epoch:$ver-$rel.$arch";
}

=head1 AUTHOR

Satoshi Yagi, C<< <satoshi.yagi at yahoo.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rpm-nevra at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RPM-NEVRA>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc RPM::NEVRA


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=RPM-NEVRA>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/RPM-NEVRA>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/RPM-NEVRA>

=item * Search CPAN

L<http://search.cpan.org/dist/RPM-NEVRA/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Satoshi Yagi.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

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


=cut

1;    # End of RPM::NEVRA
