package Python::Serialize::Pickle::InlinePython::Functions;
use strict;
use warnings;
use base 'Exporter';
our @EXPORT = qw/Dump Load DumpFile LoadFile/;

use Inline Python => <<'...';
from pickle import dumps, loads
import pickle

def _LoadFile(fname):
    return pickle.load(open(fname, 'rb'))

def _DumpFile(fname, obj):
    return pickle.dump(obj, open(fname, 'wb'))
...

sub LoadFile { scalar _LoadFile(@_) }
sub Load { scalar loads(@_) }
sub Dump { dumps(@_) }
sub DumpFile { _DumpFile(@_) }

1;
__END__

=head1 NAME

Python::Serialize::Pickle::InlinePython::Functions - functional version of pickle serializer/deserializer

=head1 SYNOPSIS

    use Python::Serialize::Pickle::InlinePython::Functions;
    my $serialized = Dump([1,2,3]);
    Load($serialized);

    DumpFile("foo.pickle", [1,2,3]);
    LoadFile("foo.pickle");

=head1 METHODS

=over 4

=item Dump($obj)

dump object to memory

=item Load($serialized)

load serialized data from memory

=item DumpFile($fname, $obj)

dump data to file

=item LoadFile($fname)

load data from file

=back

=head1 AUTHORS

Tokuhiro Matsuno

=head1 SEE ALSO

L<Python::Serialize::Pickle::InlinePython>

