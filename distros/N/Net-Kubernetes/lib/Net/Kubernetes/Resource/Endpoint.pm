package Net::Kubernetes::Resource::Endpoint;
# ABSTRACT: Object representatioon of a Kubernetes Endpoint
$Net::Kubernetes::Resource::Endpoint::VERSION = '1.03';
use Moose;

extends 'Net::Kubernetes::Resource';

has subsets => (
    is    => 'ro',
    isa   => 'ArrayRef[HashRef]',
);

augment as_hashref => sub {
    my($self) = @_;
    return ( subsets =>$self->subsets );
};

return 42;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Kubernetes::Resource::Endpoint - Object representatioon of a Kubernetes Endpoint

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
