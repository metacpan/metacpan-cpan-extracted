package String::Normal::Config;
use strict;
use warnings;

use String::Normal::Config::BusinessStem;
use String::Normal::Config::BusinessStop;
use String::Normal::Config::BusinessCompress;
use String::Normal::Config::AddressStem;
use String::Normal::Config::AddressStop;
use String::Normal::Config::States;
use String::Normal::Config::AreaCodes;
use String::Normal::Config::TitleStem;
use String::Normal::Config::TitleStop;

sub _slurp {
    my $fh   = shift;
    my @data = ();
    chomp( @data = map { $_ || () } map { split /\s+/, $_, 2 } <$fh> );
    close $fh;
    return @data;
}

sub _expand_ranges {
    my @expanded = ();

    for my $line (@_) {
        my @ranges = map { /(\w)-?(\w)/;[$1..$2] } $line =~ /\[(\w-?\w)+\]/g;
        $line =~ s/\[.*//;
        _expand( \my @results, $line, @ranges );
        push @expanded, @results;
    }

    return @expanded;
}

sub _expand {
    my ($results,$str,$car,@cdr) = @_;

    if (ref $car ne 'ARRAY') {
        push @$results, $str;
        return;
    }

    for (@$car) {
        _expand( $results, $str . $_, @cdr );
    };
}

sub _attach {
    my ($t, $car, @cdr) = @_;
    return unless defined $car;
    $t->{$car} = {} unless ref $t->{$car};
    _attach( $t->{$car}, @cdr );
}

1;

__END__
=head1 NAME

String::Normal::Config;

=head1 DESCRIPTION

Base class for String::Normal Configurations. Contains utility private
methods for producing the necessary data structures.

=head1 CONFIG CLASSES

=over 4

=item * L<String::Normal::Config::BusinessStop>

=item * L<String::Normal::Config::BusinessStem>

=item * L<String::Normal::Config::BusinessCompress>

=item * L<String::Normal::Config::AddressStop>

=item * L<String::Normal::Config::AddressStem>

=item * L<String::Normal::Config::State>

=item * L<String::Normal::Config::AreaCodes>

=item * L<String::Normal::Config::TitleStop>

=item * L<String::Normal::Config::TitleStem>

=back

=head1 AUTHOR

Jeff Anderson, C<< <jeffa at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Jeff Anderson.

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
