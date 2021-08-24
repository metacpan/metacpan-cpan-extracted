package SomeFile;
use strict;
use warnings;
use OtherFile ();
BEGIN { our @ISA = qw(OtherFile) }

sub foo {
}

sub bar {
}

1;
__END__

=head2 foo

This is covered

L<OtherFile>
