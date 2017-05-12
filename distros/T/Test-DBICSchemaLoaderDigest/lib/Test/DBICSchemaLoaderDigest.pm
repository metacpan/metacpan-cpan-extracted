#
# This file is part of Test-DBICSchemaLoaderDigest
#
# This software is copyright (c) 2012 by Tokuhiro Matsuno E<lt>tokuhirom@gmail.comE<gt>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Test::DBICSchemaLoaderDigest;
{
  $Test::DBICSchemaLoaderDigest::VERSION = '0.04';
}
use strict;
use warnings;
use 5.00800;
use base qw/Exporter/;
use Test::More;
use Digest::MD5 ();
our @EXPORT = qw/test_dbic_schema_loader_digest/;

our $MARK_RE = qr{^(# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:)([A-Za-z0-9/+]{22})\n};

sub test_dbic_schema_loader_digest {
    my $fname = shift;

    open my $fh, '<', $fname or die "$fname $!";

    my $buf = '';
    while ( my $line = <$fh> ) {
        if ( $line =~ $MARK_RE ) {
            $buf .= $1;
            is Digest::MD5::md5_base64( $buf ), $2, "$fname is valid";
            close $fh;
            return;
        }
        else {
            $buf .= $line;
        }
    }
    close $fh;

    ok undef, "md5sum not found: $fname";
}

# ABSTRACT: test the DBIC::Schema::Loader's MD5 sum

1;


=pod

=for :stopwords Tokuhiro Matsuno E<lt>tokuhirom@gmail.comE<gt> Chris Weyl
AAAAHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH

=head1 NAME

Test::DBICSchemaLoaderDigest - test the DBIC::Schema::Loader's MD5 sum

=head1 VERSION

This document describes version 0.04 of Test::DBICSchemaLoaderDigest - released June 30, 2012 as part of Test-DBICSchemaLoaderDigest.

=head1 SYNOPSIS

  use Test::More tests => 1;
  use Test::DBICSchemaLoaderDigest;
  test_dbic_schema_loader_digest('lib/Proj/Schema/Foo.pm');

=head1 DESCRIPTION

Hey DBIC::Schema::Loader dumps follow code:

    # DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2lkIltTa9Ey3fExXmUB/gw

But, some programmer MODIFY THE ABOVE OF
THIS CODE!!!!!!!!!! AAAAHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH!!!

This module tests for manual changes to the forbidden zone. If you use this
test, you can stop this problem before it becomes a real problem.

=encoding utf8

=head1 METHODS

=head2 test_dbic_schema_loader_digest('lib/Proj/Schema/Foo.pm')

Check the MD5 sum.

=head1 CODE COVERAGE

    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    File                           stmt   bran   cond    sub    pod   time  total
    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    ...DBICSchemaLoaderDigest.pm  100.0  100.0    n/a  100.0  100.0  100.0  100.0
    Total                         100.0  100.0    n/a  100.0  100.0  100.0  100.0
    ---------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<DBIx::Class::Schema::Loader>

=back

=head1 SOURCE

The development version is on github at L<http://github.com/RsrchBoy/test-dbicschemaloaderdigest>
and may be cloned from L<git://github.com/RsrchBoy/test-dbicschemaloaderdigest.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/RsrchBoy/test-dbicschemaloaderdigest/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

=over 4

=item *

Tokuhiro Matsuno E<lt>tokuhirom@gmail.comE<gt>

=item *

Chris Weyl <cweyl@alumni.drew.edu>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Tokuhiro Matsuno E<lt>tokuhirom@gmail.comE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

