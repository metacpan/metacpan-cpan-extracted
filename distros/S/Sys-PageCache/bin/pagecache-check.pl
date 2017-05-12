#!perl

use strict;
use warnings;

use Getopt::Long qw(:config posix_default no_ignore_case no_ignore_case_always);
use Pod::Usage;

use Sys::PageCache;

MAIN: {
    my $offset = 0;
    my $length = 0;
    GetOptions(
        'offset|o=i' => \$offset,
        'length|l=i' => \$length,
        'help|h|?' => sub { pod2usage(-verbose=>1) }) or pod2usage();

    ### offset: $offset
    ### length: $length

    my $fnlen = 8;
    for (@ARGV) { $fnlen = length($_) if $fnlen < length($_) }
    ### $fnlen

    for my $file (@ARGV) {
        my $r = fincore $file, $offset, $length;
        ### r: $file, $r
        printf("%-${fnlen}s: cached/total_size=%llu/%llu cached/total_pages=%llu/%llu\n",
               $file,
               $r->{cached_size}, $r->{file_size},
               $r->{cached_pages}, $r->{total_pages},
           );
    }

    exit 0;
}

__END__

=head1 NAME

B<pagecache-check.pl> - determine whether pages are resident in memory

=head1 SYNOPSIS

B<pagecache-check.pl>
[B<-o> I<offset>]
[B<-l> I<length>]
I<file> [I<file> ...]

B<pagecache-check.pl> B<-h> | B<--help> | B<-?>

    $ pagecache-check.pl foo bar
    foo     : cached/total_size=0/187394 cached/total_pages=0/46
    bar     : cached/total_size=36864/36558 cached/total_pages=9/9

=head1 DESCRIPTION

Determine whether pages are resident in memory on arbitrary files.

=head1 OPTIONS

=over 4

=item B<-o> I<offset>, B<--offset> I<offset>

Default is 0. In most cases you don't need to set this option.
Offset must be a multiple of the page size.

=item B<-l> I<length>, B<--length> I<length>

Default is 0. In most cases you don't need to set this option.

=back

=head1 SEE ALSO

L<Sys::PageCache|Sys::PageCache>,
mincore(2)

=head1 AUTHOR

HIROSE, Masaaki E<lt>hirose31 _at_ gmail.comE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# for Emacsen
# Local Variables:
# mode: cperl
# cperl-indent-level: 4
# cperl-close-paren-offset: -4
# cperl-indent-parens-as-block: t
# indent-tabs-mode: nil
# coding: utf-8
# End:

# vi: set ts=4 sw=4 sts=0 et ft=perl fenc=utf-8 :
