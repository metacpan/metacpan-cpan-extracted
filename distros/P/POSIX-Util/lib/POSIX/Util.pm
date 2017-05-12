# Copyrights 2012 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.00.
use warnings;
use strict;

package POSIX::Util;
use vars '$VERSION';
$VERSION = '0.10';

use base 'Exporter';

use POSIX::1003::Pathconf qw/_PC_REC_INCR_XFER_SIZE/;
use POSIX::1003::FdIO     qw/writefd readfd BUFSIZ SSIZE_MAX/;

my @fdio      = qw/readfd_all writefd_all/;
my @functions = (@fdio);

# need to extract the POSIX::1003 exporter
our @EXPORT    = @functions;

our %EXPORT_TAGS =
 ( functions => \@functions
 , fdio      => \@fdio
 );


sub writefd_all($$;$)
{   my ($to, $data, $do_close) = @_;
    my $size = length $data;

    while(my $l = length $data)
    {   my $written = writefd $to, $data, $l;
        defined $written or return;

        last if $l eq $written;    # normal case
        substr($data, 0, $written) = '';
    }

    $do_close && !defined closefd($to) ? undef : $size;
}


sub readfd_all($;$$)
{   my ($in, $size, $do_close) = @_;
    defined $size or $size = SSIZE_MAX;
    my ($data, $buf) = ('', '');

    my $block = _PC_REC_INCR_XFER_SIZE($in) || BUFSIZ || 4096;

    # we should probably align the $in-fd onto a block size in the
    # first read for optimal performance under all cirmstances...

    my $bytes;
    while($bytes = readfd $in, $buf, ($block < $size ? $block : $size))
    {   last if $bytes==0;   # readfd will return "0 but true"
        $data .= $buf;
        $size -= $bytes;
    }
    defined $bytes or return;

    $do_close && !defined closefd($in) ? undef : $data;
}

1;
