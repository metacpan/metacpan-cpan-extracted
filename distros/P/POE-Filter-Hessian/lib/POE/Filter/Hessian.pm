package  POE::Filter::Hessian;

## no critic
our $VERSION = '1.00';
eval $VERSION;
## use critic
use Moose;
use Hessian::Translator;
use Hessian::Exception;
use YAML;
#use Smart::Comments;

with 'MooseX::Clone';

has 'version' => ( is => 'ro', isa => 'Int', default => 1 );

has 'translator' => (    #{{{
    is      => 'ro',
    isa     => 'Hessian::Translator',
    lazy    => 1,
    default => sub {
        my $self    = shift;
        my $version = $self->version();
        my $translator =
          Hessian::Translator->new( 
              chunked => 1, 
              version => $version 
          );
        return $translator;
      }

);                       #}}}

has 'internal_buffer' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub {
        [];
    }
);

sub get_one_start {      #{{{
    my ( $self, $array ) = @_;
    my $internal_buffer = $self->internal_buffer();
    push @{$internal_buffer}, @{$array};
}    #}}}

sub get_one {    #{{{
    my $self            = shift;
    my $translator      = $self->translator();
    my $internal_buffer = $self->internal_buffer();
    my $element         = shift @{$internal_buffer};
    return [] unless $element;
    $translator->append_input_buffer($element);
    ### get_one

    my $result;
    my $return_array = [];
    eval { $result = $translator->process_message(); };
    if ( my $e = $@ ) {
        my $exception = ref $e;
        if ($exception) {
            return [] if Exception::Class->caught('MessageIncomplete::X');
            $e->rethrow();
        }
    }
    push @{$return_array}, $result;# if $result;
    return $return_array;

}    #}}}

sub get {    #{{{
    my ( $self, $array ) = @_;
    $self->get_one_start($array);
    my $result = [];
    while ( my $processed_chunk = $self->get_one() ) {
        my $processed_ref = ref $processed_chunk;
        ### Processed data: Dump($processed_chunk)
        ### type: $processed_ref
        last unless @{$processed_chunk};
        push @{$result}, @{$processed_chunk};
    }
    return $result;
}    #}}}

sub put {    #{{{
    my ( $self, $array ) = @_;
    my $translator = $self->translator();
    $translator->serializer();
    ### serializing: Dump($array)
    my @data = map { $translator->serialize_message($_) } @{$array};
    return \@data;
}    #}}}

sub get_pending {    #{{{
    my $self = shift;
}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

POE::Filter::Hessian - Translate datastructures to and from Hessian for
transmission via a POE ReadWrite wheel.

=head1 SYNOPSIS

   use POE::Filter::Hessian;

   my $filter  = POE::Filter::Hessian->new( version => 2 );
    my $hessian_elements = [
        "M\x91\x05hello\x04word\x06Beetlez",
        "Ot\x00\x0bexample.Car\x92\x05color\x05model",
        "o\x90\x03RED\x06ferari"
    ];

    my $processed_chunks = $filter->get($hessian_elements);
    my $map = $processed_chunks->[0];

   # $map contains:
   #     { 1 => 'hello', word => 'Beetle' },


    my $object = $processed_chunks->[2];
    my $color = $object->color();
    my $model = $object->model();

=head1 DESCRIPTION

The goal of POE::Filter::Hessian is to combine the versatility of POE
with the Hessian serialization protocol.  

As POE::Filter::Hessian is based on L<Hessian::Client> which is still in a fairly
experimental state, it can also be considered to be highly experimental.

=head1 INTERFACE

=head2 clone

=head2 get_one_start

Accepts a list of Hessian serialized strings. The list of strings is added to
the internal buffer.

=head2 get_one

If possible, parse one element from the buffer. Returns a single deserialized
datastructure or C<undef> if the buffer contains an incomplete message.

=head2 get

Greedily process as much of the buffer as possible.

=head2 put

Accepts a list of items to be serialized.  The result is an array reference
containing a list of Hessian strings representing the serialized
datastructures.

=head2 get_pending

