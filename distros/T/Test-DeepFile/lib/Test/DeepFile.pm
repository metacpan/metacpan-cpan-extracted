package Test::DeepFile;

use 5.010000;
use strict;
use warnings;
use Test::More;
use Test::Deep;

use YAML qw (LoadFile DumpFile);

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Test::DeepFile ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    cmp_deeply_file
);

our $VERSION = '0.003';

our %seen;

sub cmp_deeply_file
{
    die "usage: cmp_deeply_file( expect, name);" unless @_ == 2;
    my ($d1, $name) = @_;
    die "All ready tested $name" if $seen{$name};
    $seen{$name} = 1;
    my $filename = "t/deepfile/$name.data";
    
    if (-r $filename) {
        my $d2 = LoadFile $filename;
	cmp_deeply($d1, $d2, $name);
    } else {
        mkdir 't/deepfile/';
        DumpFile $filename, $d1;
	pass("Created $filename");
    }
}

1;
__END__

=head1 NAME

Test::DeepFile - A file base extention of Test::Deep

=head1 SYNOPSIS

  use Test::More tests => $Num_Tests;
  use Test::DeepFile;

cmp_deeply(
    $actual_horrible_nested_data_structure,
    'filename of the saved data'
);

=head1 DESCRIPTION

=over

=item B<cmp_deeply_file>

=back

=cut


=head2 EXPORT

C<cmp_deeply_file>

=head1 SEE ALSO

L<Test::Deep>

=head1 AUTHOR

G. Allen Morris III, E<lt>gam3@gam3.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by G. Allen Morris III

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
