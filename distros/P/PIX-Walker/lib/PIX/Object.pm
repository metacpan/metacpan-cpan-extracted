package PIX::Object;

use strict;
use warnings;

use Carp;

our $VERSION = '1.10';

=pod

=head1 NAME

PIX::Object - Factory class for the various object-groups found in a PIX config
from a PIX::Walker object. This object is not meant to be instantiated directly.

=head1 SYNOPSIS

PIX::Walker uses this factory class to create perl objects for each object-group
found within a firewall configuration. Programs will interface with this object
but will practically never instantiate objects from this factory directly.

=head1 SEE ALSO

B<PIX::Object::network>, B<PIX::Object::service>, B<PIX::Object::protocol>

=head1 EXAMPLE

my $obj = new PIX::Object($type, $name, $conf_block, $pix_walker_ref);

=head1 METHODS

=over

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = { };
	my ($type, $name, $config, $walker) = @_;
	croak("Must provide the object-group type, name and config block") unless ($type and $name and $config);

	$class .= "::" . lc $type;
	$class =~ tr/-/_/;
	eval "require $class";
	if ($@) {
		die("Object subclass '$class' has compile time errors:\n$@\n");
	} 

	$self->{class} = $class;
	$self->{name} = $name;
	$self->{type} = $type;
	$self->{config} = [ @$config ];
	$self->{config_block} = [ @$config ];
	$self->{walker} = $walker;

	bless($self, $class);
	$self->_init;

	return $self;
}

=item B<type( )>

=over

Returns the type of the object group. One of "network", "service", "protocol",
or "icmp_type"

=back

=cut
sub type { $_[0]->{type} }

=item B<name( )>

=over

Returns the name of the object group as configured.

=back

=cut
sub name { $_[0]->{name} }

=item B<list( )>

=over

Returns a list of items from the object group. The structure of the list
returned will vary depending on the object-group type. See each sub-class for
more information. 

B<PIX::Object::network>, B<PIX::Object::service>, B<PIX::Object::protocol>

=back

=cut
sub list { undef }

=item B<first( )>

=over

Returns the first object from the object-group list.

=back

=cut
sub first {
	my ($self) = @_;
	my @list = $self->list;
	return @list ? $list[0] : undef;
}

=item B<alias($alias)>

=over

Returns the IP of the alias given in $alias. If no alias is found than the
string is returned unchanged. This simply deligates to the alias sub from the
PIX::Walker object as given in new().

=back

=cut
sub alias {
	my $self = shift;
	my $alias = shift;
	return defined $self->{walker} ? $self->{walker}->alias($alias) : $alias;
}

sub _init {
	my $self = shift;

	# It's possible for the config block to be an empty list, in which case
	# we don't count that as being invalid.
	if (@{$self->{config_block}} and
	    @{$self->{config_block}}[0] !~ /^object-group \S+ \S+/i) {
		carp("Invalid config block passed to $self->{class}");
		return undef;
	}
}

sub _nextline { shift @{$_[0]->{config_block}} }
sub _rewind { unshift @{$_[0]->{config_block}}, $_[1] }

1;

=pod

=head1 AUTHOR

Jason Morriss <lifo 101 at - gmail dot com>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-pix-walker at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PIX-Walker>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

    perldoc PIX::Walker

    perldoc PIX::Accesslist
    perldoc PIX::Accesslist::Line

    perldoc PIX::Object
    perldoc PIX::Object::network
    perldoc PIX::Object::service
    perldoc PIX::Object::protocol
    perldoc PIX::Object::icmp_type

=head1 COPYRIGHT & LICENSE

Copyright 2006-2008 Jason Morriss, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
