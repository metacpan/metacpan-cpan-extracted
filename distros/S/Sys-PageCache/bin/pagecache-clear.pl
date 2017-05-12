#!perl

use strict;
use warnings;

use Getopt::Long qw(:config posix_default no_ignore_case no_ignore_case_always);
use Pod::Usage;

use Sys::PageCache;

MAIN: {
    my $offset = 0;
    my $length = 0;
    my $rate;
    GetOptions(
        'rate|r=f' => \$rate,
        'help|h|?' => sub { pod2usage(-verbose=>1) }) or pod2usage();

    my $fnlen = 8;
    for (@ARGV) { $fnlen = length($_) if $fnlen < length($_) }
    ### $fnlen

    for my $file (@ARGV) {
        my $r;
        printf("%-${fnlen}s:\n", $file);

        if (defined $rate && $rate > 0) {
            ### rate: $rate
            $rate = 1 if $rate > 1;
            $length = int( (stat $file)[7] * $rate );
        }

        ### offset: $offset
        ### length: $length

        $r = fincore $file;
        printf("  before cached/total_size=%llu/%llu cached/total_pages=%llu/%llu\n",
               $r->{cached_size}, $r->{file_size},
               $r->{cached_pages}, $r->{total_pages},
           );

        $r = fadvise $file, $offset, $length, POSIX_FADV_DONTNEED;

        $r = fincore $file;
        printf("  after  cached/total_size=%llu/%llu cached/total_pages=%llu/%llu\n",
               $r->{cached_size}, $r->{file_size},
               $r->{cached_pages}, $r->{total_pages},
           );
    }

    exit 0;
}

__END__

=head1 NAME

B<pagecache-clear.pl> - free pages are resident in memory

=head1 SYNOPSIS

B<pagecache-clear.pl>
[B<-r> I<rate>]
I<file> [I<file> ...]

B<pagecache-clear.pl> B<-h> | B<--help> | B<-?>

    $ pagecache-clear.pl foo
    foo     :
      before cached/total_size=36864/36558 cached/total_pages=9/9
      after  cached/total_size=0/36558 cached/total_pages=0/9
    
    $ pagecache-clear.pl -r 0.7 foo
    foo     :
      before cached/total_size=36864/36558 cached/total_pages=9/9
      after  cached/total_size=8192/36558 cached/total_pages=2/9

=head1 DESCRIPTION

Free whether pages are resident in memory on arbitrary files.

=head1 OPTIONS

=over 4

=item B<-r> I<rate>, B<--rate> I<rate>

Rate to free. "-r 0.5" frees pages that 50% of file size from beginning of a file.
pagecache-clear.pl try to free all pages if not specified this -r option.

=back

=head1 SEE ALSO

L<Sys::PageCache|Sys::PageCache>,
posix_fadvise(2)

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
