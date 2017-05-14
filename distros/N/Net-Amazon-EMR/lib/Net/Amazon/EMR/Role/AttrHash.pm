package Net::Amazon::EMR::Role::AttrHash;

# turns attributes of a Moose object into a hash

use Moose::Role;

sub as_hash {
    my $self = shift;
    return { 
        map { my $n = $_->name; 
              my $v = $self->$n;
              if ($_->type_constraint->is_a_type_of('Net::Amazon::EMR::Type::Bool')) {
                  $n => $v ? 'true' : 'false'
              }
              elsif (! defined($v)) {
              }
              elsif (ref($v) eq 'ARRAY' && ref($v->[0]) =~ m/Net::Amazon::EMR::/ ) {
                  $n => [ map { $_->as_hash } @$v ];
              }
              elsif (ref($v) =~ m/Net::Amazon::EMR::/) {
                  $n => $v->as_hash;
              }
              elsif (ref($v) eq 'DateTime') {
                  $n => "$v"
              }
              else {
                  $n => $v;
              }
        } $self->meta->get_all_attributes
    };
}

sub TO_JSON {
    my ($self) = @_;
    return $self->as_hash;
}

1;

__END__

=head1 NAME

Net::Amazon::EMR::Role::AttrHash

=head1 DESCRIPTION

Provides a L<Moose::Role> that facilitates turning the various Net::Amazon::EMR::* data types into plain hashes.

=head1 AUTHOR

Jon Schutz 

L<http://notes.jschutz.net>

=head1 DOCUMENTATION, LICENSE AND COPYRIGHT

See L<Net::Amazon::EMR>.

=cut
