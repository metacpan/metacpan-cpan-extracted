use TM;

use constant DL => "\n\n";

my $TMVERSION = shift @ARGV || die "no version provided";

print <<EOT;
package TM::Axes;

our \$VERSION = '0.2';

=pod

=head1 NAME

TM::Axes - Topic Maps, Axes for TM::match*

=head1 DESCRIPTION

The L<TM> module offers the method C<match> (and friends) to query assertions in a TM data
structure. While there is a generic search specification, it will be too slow. Instead some axes
have been implemented specifically. These are listed below.

=head1 SEARCH SPECIFICATIONS

Automatically generated from TM ($TMVERSION)

EOT

print "=over".DL;
foreach my $k (sort keys %TM::forall_handlers) {
    my $v = $TM::forall_handlers{$k};
    print "=item Code:".($k || '<empty>').DL;

    print $v->{desc}.DL;

    use Data::Dumper;
    my @s = split /\n/, Dumper $v->{params};
    pop @s;
    shift @s;
    print join "\n", @s;

    print DL
}
print "=back".DL;

print <<EOT;

=head1 SEE ALSO

L<TM>

=head1 COPYRIGHT AND LICENSE

Copyright 200[8] by Robert Barta, E<lt>drrho\@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

1;

EOT
