package SOAP::StructSerializer;

use strict;
use vars qw($VERSION);
use SOAP::Serializer;

$VERSION = '0.28';

sub new {
    my $class = shift;
    my $self = {
	struct   => shift,
	multiref => 1,
    };
    bless $self, $class;
}

sub set_typeinfo {
    my $self = shift;
    ($self->{typeuri}, $self->{typename}) = @_;
}

sub not_multiref {
    my $self = shift;
    $self->{multiref} = 0;
}

sub get_typeinfo {
    my $self = shift;
    @$self{'typeuri', 'typename'};
}

sub is_compound {
    1;
}

sub is_multiref {
    my $self = shift;
    $self->{multiref};
}

sub is_package {
    0;
}

sub serialize {
    my ($self, $stream, $envelope) = @_;

    my SOAP::Struct $struct = $self->{struct};
    my $content        = $struct->{content};
    my $contains_types = $struct->{contains_types};

    my $len = @$content;
    for (my $i = 0; $i < $len;) {
	my $k = $content->[$i++];
	my $v = $content->[$i++];
	if ($contains_types) {
	    $v = SOAP::TypedPrimitive->new($v, $content->[$i++]);
	}
	_serialize_object($stream, $envelope, undef, $k, $v);
    }
}

1;
__END__

=head1 NAME

SOAP::StructSerializer - (internal) serializer for SOAP structs

=head1 DEPENDENCIES

SOAP::Struct
SOAP::Serializer

=head1 AUTHOR

Keith Brown

=head1 SEE ALSO

SOAP::Struct

=cut




