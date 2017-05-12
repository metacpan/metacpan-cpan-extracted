package Net::Kubernetes::Resource::Event;
# ABSTRACT: Object representatioon of a Kubernetes event
$Net::Kubernetes::Resource::Event::VERSION = '1.03';
use Moose;

extends 'Net::Kubernetes::Resource';

has reason => (
	is       => 'ro',
	isa      => 'Str',
	required => 0
);

has message => (
	is       => 'ro',
	isa      => 'Str',
	required => 0
);

has firstTimestamp => (
	is       => 'ro',
	isa      => 'Str',
	required => 0
);

has lastTimestamp => (
	is       => 'ro',
	isa      => 'Str',
	required => 0
);

has count => (
	is       => 'ro',
	isa      => 'Int',
	required => 0
);

has source => (
	is       => 'ro',
	isa      => 'HashRef',
	required => 0
);


has involvedObject => (
	is       => 'ro',
	isa      => 'HashRef',
	required => 0
);

return 42;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Kubernetes::Resource::Event - Object representatioon of a Kubernetes event

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
