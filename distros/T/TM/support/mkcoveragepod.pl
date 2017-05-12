use TM;

use constant DL => "\n\n";

my $TMVERSION = shift @ARGV || die "no version provided";

print <<EOT;
package TM::Coverage;

our \$VERSION = '0.1';

=pod

=head1 NAME

TM::Coverage - Topic Maps, Code Coverage

=head1 DESCRIPTION

This auxiliary package keeps track of the code coverage. Probably
quite irrelevant for a user.

Automatically generated for TM ($TMVERSION).

EOT

my $coverage = `cat /tmp/coverage.txt`;

$coverage =~ s/Reading.*?cover_db\n//s;
$coverage =~ s/Writing HTML.*done.//s;

print join "\n", map { "   $_" } split /\n/, $coverage;

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
