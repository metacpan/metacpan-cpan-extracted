package Python::Serialize::Pickle::InlinePython;
use strict;
use warnings;
our $VERSION = '0.01';

use Inline Python => <<'...';
from pickle import Pickler, Unpickler

def __pickler(fname):
    return Pickler(open(fname, 'wb'))

def __unpickler(fname):
    return Unpickler(open(fname, 'rb'))

def __load(unp):
    try:
        return unp.load()
    except EOFError:
        return "EOFErrorEOFErrorEOFErrorEOFError" # wtf?
...

sub new {
    my ($class, $fname) = @_;
    if ($fname =~ s/^>//g) {
        bless { pickler => __pickler($fname) }, 'Python::Serialize::Pickle::InlinePython';
    } else {
        bless { unpickler => __unpickler($fname) }, 'Python::Serialize::Pickle::InlinePython';
    }
}

sub dump {
    my ($self, $stuff) = @_;
    die "this is not a writer-obj" unless $self->{pickler};
    $self->{pickler}->dump($stuff);
}

sub load {
    my $self = shift;
    die "this is not a reader-obj" unless $self->{unpickler};
    my $ret = __load($self->{unpickler});
    if ($ret eq 'EOFErrorEOFErrorEOFErrorEOFError') {
        return undef; ## no critic
    } else {
        return $ret;
    }
}

sub close {
    my $self = shift;
    delete $self->{$_} for keys %$self;
}

1;
__END__

=head1 NAME

Python::Serialize::Pickle::InlinePython - handle pickled data with Inline::Python

=head1 SYNOPSIS

    use Data::Dumper;
    use Python::Serialize::Pickle::InlinePython;

    # load it
    my $pic = Python::Serialize::Pickle::InlinePython->new('data.pickle');
    while (my $dat = $pic->load()) {
        warn Dumper($dat);
    }

    # dump it
    my $pic = Python::Serialize::Pickle::InlinePython->new('>data.pickle');
    $pic->dump('foo');
    $pic->dump('bar');
    $pic->close();

=head1 DESCRIPTION

Python::Serialize::Pickle::InlinePython is a python's pickle data serializer/deserializer using Inline::Python.

This module has same interface with L<Python::Serialize::Pickle>.L<Python::Serialize::Pickle> is no longer maintained, does not works with newer version of Python.

=head1 ALTERNATIVES

You could always dump the data structure out as YAML in Python and then read it back in with YAML in Perl.

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom  slkjfd gmail.comE<gt>

=head1 SEE ALSO

L<Python::Serialize::Pickle>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
