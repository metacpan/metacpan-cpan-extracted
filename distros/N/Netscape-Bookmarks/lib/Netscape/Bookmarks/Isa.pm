package Netscape::Bookmarks::Isa;

=encoding utf8

=head1 NAME

Netscape::Bookmarks::Isa - mixin methods for object identity

=head1 SYNOPSIS

	use base qw( Netscape::Bookmarks::Isa );

	my $bookmarks = Netscape::Bookmarks->new( $bookmarks_file );

	foreach my $element ( $bookmarks->elements )
		{
		print "Found category!\n" if $element->is_category;
		}

=head1 DESCRIPTION

THIS IS AN ABANDONED MODULE. THERE IS NO SUPPORT. YOU CAN ADOPT IT
IF YOU LIKE: https://pause.perl.org/pause/query?ACTION=pause_04about#takeover

This module is a base class for Netscape::Bookmarks modules. Each
object can respond to queries about its identity.  Use this module
as a mixin class.

=head2 METHODS

Methods return false unless otherwise noted.

=over 4

=item is_category

Returns true if the object is a Category.

=item is_link

Returns true if the object is a Link or alias to a Link.

=item is_alias

Returns true if the object is an Alias.

=item is_separator

Returns true if the object is a Separator.

=item is_collection

Returns true if the object is a Category.

=back

=head1 AUTHOR

brian d foy C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2002-2019, brian d foy <bdfoy@cpan.org>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.

=head1 SEE ALSO

L<Netscape::Bookmarks::Category>,
L<Netscape::Bookmarks::Link>,
L<Netscape::Bookmarks::Alias>,
L<Netscape::Bookmarks::Separator>.

=cut

use strict;
use vars qw( $VERSION );

$VERSION = "2.304";

my $Category  = 'Netscape::Bookmarks::Category';
my $Link      = 'Netscape::Bookmarks::Link';
my $Alias     = 'Netscape::Bookmarks::Alias';
my $Separator = 'Netscape::Bookmarks::Separator';

sub is_category {
	$_[0]->is_something( $Category );
	}

sub is_link {
	$_[0]->is_something( $Link, $Alias );
	}

sub is_alias {
	$_[0]->is_something( $Alias );
	}

sub is_separator {
	$_[0]->is_something( $Separator );
	}

sub is_collection {
	$_[0]->is_something( $Category );
	}

sub is_something {
	my $self = shift;

	foreach my $something ( @_ ) {
		return 1 if UNIVERSAL::isa( $self, $something );
		}

	return 0;
	}

1;
