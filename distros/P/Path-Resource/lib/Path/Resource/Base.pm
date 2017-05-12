package Path::Resource::Base;

use warnings;
use strict;

=head1 NAME

Path::Resource::Base - A resource base for a Path::Resource object

=cut

use Path::Abstract qw/--no_0_093_warning/;
use Path::Class();
use Scalar::Util qw/blessed/;
use URI;

use base qw/Class::Accessor::Fast/;
__PACKAGE__->mk_accessors(qw/_dir _loc _uri/);

=head1 DESCRIPTION

No need to use this class directly, see Path::Resource for more information.

=head1 METHODS

=over 4

=item $base = Path::Resource::Base->new( dir => $dir, uri => $uri, [ loc => $loc ] )

Create a new Path::Resource::Base object with the given $dir, $uri, and (optional) $loc

=cut

sub new {
	my $self = bless {}, shift;
	local %_ = @_;

	my $dir = $_{dir};
	$dir = Path::Class::dir($dir) unless blessed $dir && $dir->isa("Path::Class::Dir");

    # Extract $uri->path from $uri in order to combine with $loc later
	my $uri = $_{uri};
	$uri = URI->new($uri) unless blessed $uri && $uri->isa("URI");
	my $uri_path = $uri->path;

    # If $loc is relative or ($loc is not defined && $uri_path is empty),
    # this will give us a proper $loc below in any event
    $uri_path = "/" unless length $uri_path;

#   # Set $uri->path to empty, since we'll be using $loc
#   $uri->path('');

	my $loc;
	if (defined $_{loc}) {
		$loc = $_{loc};
		$loc = Path::Abstract->new($loc) unless blessed $loc && $loc->isa("Path::Abstract");
		if ($loc->is_branch) {
            # Combine $loc and $uri_path if $loc is relative
			$loc = Path::Abstract->new($uri_path, $loc->path);
		}
	}
	else {
		$loc = Path::Abstract->new($uri_path);
	}

	$self->_dir($dir);
	$self->_loc($loc);
	$self->_uri($uri);
	return $self;
}

=item $new_base = $base->clone

Return a new Path::Resource::Base object that is a clone of $base

=cut

sub clone {
	my $self = shift;
	return __PACKAGE__->new(dir => $self->dir, loc => $self->loc->clone, uri => $self->uri->clone);
}

=item $base->uri

=item $base->uri( $uri )

Return the original $uri, optionally changing it by passing in a new $uri

$uri is a URI object, but if you pass in a valid URI string it will Do The Right Thing(tm) and convert it

=cut

sub uri {
    my $self = shift;
    return $self->_uri unless @_;
    return $self->_uri($_[0]) if blessed $_[0] && $_[0]->isa("URI");
    return $self->_uri(URI->new(@_));
    # TODO What if $_[0] is undef?
}

=item $base->loc

=item $base->loc( $loc )

Return the calculated $loc, optionally changing it by passing in a new $loc

$loc is a Path::Abstract object, but if you pass in a valid Path::Abstract string it will Do The Right Thing(tm) and convert it

=cut

sub loc {
    my $self = shift;
    return $self->_loc unless @_;
    return $self->_loc($_[0]) if 1 == @_ && blessed $_[0] && $_[0]->isa("Path::Abstract");
    return $self->_loc(Path::Abstract->new(@_));
    # TODO What if $_[0] is undef?
}

=item $base->dir

=item $base->dir( $dir )

Return the original $dir, optionally changing it by passing in a new $dir

$dir is a Path::Class::Dir object, but if you pass in a valid Path::Class::Dir string it will Do The Right Thing(tm) and convert it

=cut

sub dir {
    my $self = shift;
    return $self->_dir unless @_;
    return $self->_dir($_[0]) if 1 == @_ && blessed $_[0] && $_[0]->isa("Path::Class::Dir");
    return $self->_dir(Path::Class::Dir->new(@_));
    # TODO What if $_[0] is undef?
}

1;
