use strict;
use warnings;
use vars qw{$MISC_LOG 
	    $SESS_LOG 
	    $XFER_LOG 
	    @EXPORT
	    @EXPORT_OK};

use base 'Exporter';
@EXPORT = qw{slurp_log};
@EXPORT_OK = qw{$MISC_LOG $SESS_LOG $XFER_LOG};

use File::Spec;
use FindBin qw{$Bin};

my $root  = File::Spec->catdir($Bin, 'logs');
$MISC_LOG = File::Spec->catdir($root, 'misc.log');
$SESS_LOG = File::Spec->catdir($root, 'sess.log');
$XFER_LOG = File::Spec->catdir($root, 'xfer.log');

sub slurp_log
{
    my $parser = shift;    
    my @entries;

    while(my $line = $parser->next) {
	push @entries, $line;
    }

    die $parser->error if $parser->error;
    @entries;
}
