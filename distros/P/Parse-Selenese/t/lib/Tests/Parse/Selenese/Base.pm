package Tests::Parse::Selenese::Base;
use strict;
use warnings;

use Test::Class::Most attributes => [qw/ empty_test_case selenese_data_files /];
use Algorithm::Diff;
use Cwd;
use Data::Dumper;
use File::Basename;
use File::Find qw(find);
use FindBin;
use Test::Differences;
use YAML qw'freeze thaw LoadFile';


sub startup : Tests(startup) {
}

#sub startup : Tests(startup) {
#    my $self = shift;
#    $self->selenese_data_files(
#        sub {
#            my $case_data_dir = "$FindBin::Bin/test_case_data";
#            my @selenese_data_files;
#            find sub {
#                push @selenese_data_files, $File::Find::name
#                  if /_TestCase\.html$/;
#            }, $case_data_dir;
#            $self->{_selenese_data_files} = \@selenese_data_files;
#          }
#          ->()
#    );
#}

sub setup : Tests(setup) {
}

sub teardown : Tests(teardown) {
}

sub shutdown : Tests(shutdown) {
}

1;
__END__

=head1 NAME

Parse::Selenese::Base

=head1 SYNOPSIS

  use Parse::Selenese::Base;

=head1 DESCRIPTION

Parse::Selenese::Base is the base class for the test classes for Parse::Selenese.

=head2 Functions

=over

=item C<setup()>

Empty method.

=item C<startup()>

Empty method.

=back

=head1 AUTHOR

Theodore Robert Campbell Jr.  E<lt>trcjr@cpan.orgE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
