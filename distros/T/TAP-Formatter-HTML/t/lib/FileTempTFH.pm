package FileTempTFH;

use strict;
use warnings;

use Fcntl qw( SEEK_SET );

use base qw( File::Temp );

sub get_all_output {
    my $self = shift;
    $self->seek( 0, SEEK_SET );
    my $html;
    {
	local $/ = undef;
	$html = <$self>;
    }
    return $html;
}

1;
