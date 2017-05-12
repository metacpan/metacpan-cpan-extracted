package Net::Kubernetes::Resource::ServiceAccount;
# ABSTRACT: Object representatioon of a Kubernetes service account
$Net::Kubernetes::Resource::ServiceAccount::VERSION = '1.03';
use Moose;

extends 'Net::Kubernetes::Resource';

has secrets => (
    is      => 'ro',
    isa     => 'ArrayRef[HashRef]',
);

has imagePullSecrets => (
    is      => 'ro',
    isa     => 'ArrayRef[HashRef]',
);

return 42;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Kubernetes::Resource::ServiceAccount - Object representatioon of a Kubernetes service account

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
