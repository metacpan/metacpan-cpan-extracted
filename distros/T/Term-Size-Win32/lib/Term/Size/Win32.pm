package Term::Size::Win32;

use strict;
#use Carp;
use vars qw(@EXPORT_OK @ISA $VERSION);

use Exporter ();

require Win32::Console;

@ISA = qw(Exporter);
@EXPORT_OK = qw(chars pixels);

$VERSION = '0.209';

sub chars {
    my @size = Win32::Console->new()->Size();  # FIXME argument ignored
    return @size if wantarray;
    return $size[0];
}

sub pixels {
    return (0, 0) if wantarray;
    return 0;
}

1;

__END__
