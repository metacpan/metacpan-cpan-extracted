package Local::Test::Helper;

use 5.010;
use strict;
use warnings;
use autodie;

use File::Temp qw(tempdir);
use File::Spec::Functions;
use Test::Builder::Tester;
use Exporter qw(import);

our @EXPORT_OK   = qw(write_changes set_test_out set_test_out_ok set_test_out_all_ok);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

sub write_changes {
  my $file = catfile(tempdir(CLEANUP => 1), $_[1] // 'Changes');

  open(my $fh, '>', $file);
  print $fh ($_[0]);
  close($fh);

  return $file;
}

sub set_test_out {
  @_ % 2 and die("Odd number of arguments");
  my $count = 0;
  while (@_) {
    my ($result, $msg) = (shift @_, shift @_);
    ++$count;
    test_out("$result $count - $msg");
  }
}

sub set_test_out_ok {
  set_test_out(map {(ok => $_)} @_);
}

sub set_test_out_all_ok {
  set_test_out_ok("Changes file passed strict checks");
}


1;

__END__


=pod


=head1 NAME

Local::Test::Helper - Helper functions for testing purposes


=head1 SYNOPSIS

   use Local::Test::Helper qw(write_changes);

   my $file = write_changes($content);


=head1 DESCRIPTION

=head2 Functions


=over

=item C<write_changes(I<CONTENT>, L<FILE>)>

=item C<write_changes(I<CONTENT>)>

Writes I<C<CONTENT>> to file I<C<FILE>> (default: "Changes") in newly
generated temporary directory. Returns the full path to the file.

The temporary directory is automatically deleted when the program terminates.

=back


=head1 COPYRIGHT

    Copyright 2026 Klaus Rindfrey


=head1 SEE ALSO

L<File::Temp>

=cut




