package Net::Kubernetes::Resource::Role::Spec;
# ABSTRACT: Resource role for types that have a spec
$Net::Kubernetes::Resource::Role::Spec::VERSION = '1.03';
use Moose::Role;

has spec => (
	is       => 'rw',
	isa      => 'HashRef',
	required => 1
);

around "as_hashref" => sub {
	my ($orig, $self) = @_;
	my $ref = $self->$orig;
	$ref->{spec} = $self->spec;
	return $ref;
};

return 42;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Kubernetes::Resource::Role::Spec - Resource role for types that have a spec

=head1 VERSION

version 1.03

=head1 AUTHOR

Dave Mueller <dave@perljedi.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Dave Mueller.

This is free software, licensed under:

  The MIT (X11) License

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Net::Kubernetes|Net::Kubernetes>

=back

=cut
