package Netscape::Bookmarks::Alias;

=encoding utf8

=head1 NAME

Netscape::Bookmarks::Alias - object for an Alias in a Netscape Bookmarks file

=head1 SYNOPSIS

	use Netscape::Bookmarks;
	use Netscape::Bookmarks::Alias;

	my $bookmarks = Netscape::Bookmarks->new();

	my $alias = Netscape::Bookmarks::Alias->new();

	$bookmarks->add( $alias );
	# ... and other Netscape::Bookmark::Category methods

=head1 DESCRIPTION

THIS IS AN ABANDONED MODULE. THERE IS NO SUPPORT. YOU CAN ADOPT IT
IF YOU LIKE: https://pause.perl.org/pause/query?ACTION=pause_04about#takeover

This module provides an abstraction for an Alias object in a Netscape
Bookmarks file. An alias is simply a reference to another link in the
Bookmarks file, henceforth called the target. If you change the alias,
the target link also changes.

=over 4

=cut

use strict;

use base qw( Netscape::Bookmarks::AcceptVisitor Netscape::Bookmarks::Isa );
use subs qw();
use vars qw($VERSION $ERROR %aliases);

$VERSION = "2.304";

=item $obj = Netscape::Bookmarks::Alias->new( ALIASID )

Creates a new C<Netscape::Bookmarks::Alias> object with the ALIASOF
attribute value of ALIASID.  This object relies on a corresponding
C<Netscape::Bookmarks::Link> object with the same ALIASID, although
C<new> does not check to see if that object exists (although it probably
should).

=cut

sub new {
	my $class  = shift;
	my $param  = shift;

	my $self = {};

	bless $self, $class;

	$self->{'alias_of'} = $param;

	$self;
	}

=item $obj->alias_of()

Returns the alias key for this C<Netscape::Bookmarks::Alias> object.

=cut

sub alias_of {
	my $self = shift;

	return $self->{'alias_of'};
	}

=item $obj->target( ALIAS_KEY )

Returns the target Link of the given alias key.  The return value
is a C<Netscape::Bookmarks::Link> object if the target exists, or
C<undef> in scalar context or the empty list in list context if the
target does not exist. If you want to simply check to see if a
target exists, use C<target_exists>.

=cut

sub target {
	my $self     = shift;

	return $aliases{$self->{'alias_of'}};
	}

=item add_target( $link_obj, ALIAS_KEY )

Adds a target link for the given ALIAS_KEY. You can add target
links before the Alias is created.

=cut

# this should really be in Link.pm right?
sub add_target {
	my $target   = shift; #link reference
	my $alias_id = shift;

	$target->aliasid($alias_id);
	$aliases{$alias_id} = $target;
	}

=item target_exists( TARGET_KEY )

For the given target key returns TRUE or FALSE if the target
exists.

=cut

sub target_exists {
	my $target = shift;

	exists $aliases{$target} ? 1 : 0;
	}

=item $obj->as_string()

Returns a string representation on the alias.  This is
almost identical from the representation of the link which
is aliases except that the ALIASID attribute is changed
to the ALIASOF attribute.

=cut

sub as_string {
	my $self = shift;

	my $string = $self->target->as_string;

	$string =~ s/ALIASID/ALIASOF/;

	return $string;
	}

=item $obj->title()

Returns the tile of the Alias.

=cut

sub title {
	my $self = shift;

	return "Alias: " . $self->target->title;
	}

=item $obj->remove()

Performs any clean up necessary to remove this object from the
Bookmarks tree. Although this method does not affect the Link object
which is its target, it probably should.

=cut

sub remove {
	my $self = shift;

	return 1;
	}

"if you want to believe everything you read, so be it.";

=back

=head1 AUTHOR

brian d foy C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2002-2019, brian d foy <bdfoy@cpan.org>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.

=head1 SEE ALSO

L<Netscape::Bookmarks>, L<Netscape::Bookmarks::Link>

=cut

__END__
