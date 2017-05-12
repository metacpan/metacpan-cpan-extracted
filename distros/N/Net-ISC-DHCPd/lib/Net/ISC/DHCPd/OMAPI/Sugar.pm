package Net::ISC::DHCPd::OMAPI::Sugar;

=head1 NAME

Net::ISC::DHCPd::OMAPI::Sugar - Moose sugar for omapi classes

=head1 SYNOPSIS

 use Net::ISC::DHCPd::OMAPI::Sugar; # not use Moose

 omapi_attr foo => ( isa => State, ... );

=cut

use Moose;
use Net::ISC::DHCPd::Types ':all';
use Moose::Exporter;

my @types = Net::ISC::DHCPd::Types->get_type_list;

=head1 FUNCTIONS

=head2 omapi_attr

 omapi_attr $name => %attr;

C<%attr> is by default:

 (
   is => "rw",
   predicate => "has_$name",
   traits => [qw/Net::ISC::DHCPd::OMAPI::Meta::Attribute/],
 )

It will also set "coerce => 1", when "isa" is one of L<Moose>
types from L<Net::ISC::DHCPd::Types>.

=cut

sub omapi_attr {
    my $class = shift;
    my $names = ref $_[0] eq 'ARRAY' ? shift : [shift];
    my %opts  = @_;
    my $to_raw;

    if(my $type = $opts{'isa'}) {
        if($type =~ /^Net::ISC::DHCPd::Types/ and $type->coercion) {
            $type =~ s/Net::ISC::DHCPd::Types:://;
            $opts{'coerce'} = 1;
            $to_raw = Net::ISC::DHCPd::Types->can("from_$type");
        }
    }
    else {
        confess '"isa" is required for omapi_attr()';
    }

    for my $name (@$names) {
        $class->meta->add_attribute($name => (
            is => 'rw',
            predicate => "has_$name",
            clearer => "clear_$name",
            traits => [qw/Net::ISC::DHCPd::OMAPI::Meta::Attribute/],
            %opts,
        ));
        $class->meta->add_method("raw_$name" =>
            $to_raw ? sub { shift->$to_raw($name) } : sub { shift->$name }
        );
    }
}

Moose::Exporter->setup_import_methods(
    with_caller => [qw/omapi_attr/],
    as_is => \@types,
);

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<Net::ISC::DHCPd>.

=cut
__PACKAGE__->meta->make_immutable;
1;
