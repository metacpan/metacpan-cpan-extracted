package Netscape::Bookmarks::Link;

=encoding utf8

=head1 NAME

Netscape::Bookmarks::Link - manipulate, or create Netscape Bookmarks links

=head1 SYNOPSIS

  use Netscape::Bookmarks::Link;

  my $category = new Netscape::Bookmarks::Category { ... };
  my $link = new Netscape::Bookmarks::Link {
  		TITLE         => 'this is the title',
  		DESCRIPTION   => 'this is the description',
  		HREF          => 'http://www.perl.org',
  		ADD_DATE      => 937862073,
  		LAST_VISIT    => 937862073,
  		LAST_MODIFIED => 937862073,
  		ALIAS_ID      => 4,
  		}

  $category->add($link);


  #print a Netscape compatible file
  print $link->as_string;

=head1 DESCRIPTION

THIS IS AN ABANDONED MODULE. THERE IS NO SUPPORT. YOU CAN ADOPT IT
IF YOU LIKE: https://pause.perl.org/pause/query?ACTION=pause_04about#takeover

The Netscape bookmarks file has several basic components:

	title
	folders (henceforth called categories)
	links
	aliases
	separators

On disk, Netscape browsers store this information in HTML. In the browser,
it is displayed under the "Bookmarks" menu.  The data can be manipulated
through the browser interface.

This module allows one to manipulate the links in for a Netscape bookmarks
file.  A link has these attributes, only some of which may be present:

	title
	description
	HREF (i.e. URL)
	ADD_DATE
	LAST_MODIFIED
	LAST_VISIT
	ALIAS_OF
	ALIAS_ID

Additionally, Mozilla (the open source version of Navigator) uses these
attributes:

	SHORTCUTURL
	ICON
	SCHEDULE
	LAST_PING
	LAST_CHARSET
	PING_CONTENT_LEN
	PING_STATUS

=head1 METHODS

=over 4

=cut

use strict;

use base qw( Netscape::Bookmarks::AcceptVisitor Netscape::Bookmarks::Isa );
use subs qw();
use vars qw( $DEBUG $VERSION $ERROR );

use URI;

$VERSION = "2.304";

=item Netscape::Bookmarks::Link-E<gt>new( \%hash )

Creates a new Link object. The hash reference argument
can have the following keys to set the properties of the
link:

	HREF
	ADD_DATE
	LAST_MODIFIED
	LAST_VISIT
	ALIASID
	ALIASOF

	SHORTCUTURL
	ICON
	LAST_CHARSET

=cut

sub new {
	my $class  = shift;
	my $param  = shift;

	my $self = {};
	bless $self, $class;

	my $url = URI->new( $param->{HREF} );
	unless( ref $url ) {
		$ERROR = "[$$param{HREF}] is not a valid URL";
		return -1;
		}
	$self->{HREF} = $url;

	foreach my $k ( qw(SHORTCUTURL ICON LAST_CHARSET SCHEDULE PING_STATUS) ) {
		$self->{$k} = $param->{$k};
		}

	foreach my $k ( qw(ADD_DATE LAST_MODIFIED LAST_VISIT ALIASID ALIASOF
		LAST_PING PING_CONTENT_LEN) ) {
		if( defined $param->{$k} and $param->{$k} =~ /\D/ ) {
			$ERROR = "[$$param{$k}] is not a valid $k";
			return -2;
			}
		$self->{$k} = $param->{$k};
		}

	unless( $param->{'TITLE'} ) {
		$ERROR = "The TITLE cannot be null.";
		return -3;
		}

	$self->{'TITLE'} = $param->{'TITLE'};

	$self->{'DESCRIPTION'} = $param->{'DESCRIPTION'};

	$self;
	}


=item $obj->href

Returns the URL of the link.  The URL appears in the HREF attribute of
the anchor tag.

=cut

sub href {
	my $self = shift;

	$self->{'HREF'}->as_string
	}

=item $obj->add_date

Returns the date when the link was added, in Unix epoch time.

=cut

sub add_date {
	my $self = shift;

	$self->{'ADD_DATE'}
	}

=item $obj->last_modified

Returns the date when the link was last modified, in Unix epoch time.  Returns
zero if no information is available.

=cut

sub last_modified {
	my $self = shift;

	$self->{'LAST_MODIFIED'}
	}

=item $obj->last_visit

Returns the date when the link was last vistied, in Unix epoch time. Returns
zero if no information is available.

=cut

sub last_visit {
	my $self = shift;

	$self->{'LAST_VISIT'}
	}

=item $obj->title( [ TITLE ] )

Sets the link title with the given argument, and returns the link title.
If the argument is not defined (e.g. not specified), returns the current
link title.

=cut

sub title {
	my( $self, $title ) = @_;

	$self->{'TITLE'} = $title if defined $title;

	$self->{'TITLE'}
	}

=item $obj->description( [ DESCRIPTION ] )

Sets the link description with the given argument, and returns the link
description. If the argument is not defined (e.g. not specified),
returns the current link description.

=cut

sub description {
	my( $self, $description ) = @_;

	$self->{'DESCRIPTION'} = $description if defined $description;

	$self->{'DESCRIPTION'}
	}

=item $obj->alias_id

Returns the alias id of a link. Links with aliases are assigned an ALIAS_ID which
associates them with the alias.  The alias contains the same value in it's ALIAS_OF
field.  The Netscape::Bookmarks::Alias module handles aliases as references to
Netscape::Bookmarks::Link objects.

=cut

sub aliasid {
	my $self = shift;
	my $data = shift;

	$self->{'ALIASID'} = $data if defined $data;

	$self->{'ALIASID'}
	}

=item $obj->shortcuturl

=cut

sub shortcuturl {
	my( $self, $shortcuturl ) = @_;

	$self->{'SHORTCUTURL'} = $shortcuturl if defined $shortcuturl;

	$self->{'SHORTCUTURL'}
	}

=item $obj->icon

=cut

sub icon {
	my( $self, $icon ) = @_;

	$self->{'ICON'} = $icon if defined $icon;

	$self->{'ICON'}
	}

=item $obj->schedule

=cut

sub schedule {
	my( $self, $schedule ) = @_;

	$self->{'SCHEDULE'} = $schedule if defined $schedule;

	$self->{'SCHEDULE'}
	}

=item $obj->last_ping

=cut

sub last_ping {
	my( $self, $last_ping ) = @_;

	$self->{'LAST_PING'} = $last_ping if defined $last_ping;

	$self->{'LAST_PING'}
	}

=item $obj->ping_content_len

=cut

sub ping_content_len {
	my( $self, $ping_content_len ) = @_;

	$self->{'PING_CONTENT_LEN'} = $ping_content_len if defined $ping_content_len;

	$self->{'PING_CONTENT_LEN'}
	}

=item $obj->ping_status

=cut

sub ping_status
	{
	my( $self, $ping_status ) = @_;

	$self->{'PING_STATUS'} = $ping_status if defined $ping_status;

	$self->{'PING_STATUS'}
	}

=item $obj->last_charset

=cut

sub last_charset {
	my( $self, $charset ) = @_;

	$self->{'LAST_CHARSET'} = $charset if defined $charset;

	$self->{'LAST_CHARSET'}
	}

# =item $obj->alias_of
#
# Returns the target id of a link. Links with aliases are assigned an ALIAS_ID which
# associates them with the alias.  The alias contains the same value in it's ALIAS_OF
# field.  The Netscape::Bookmarks::Alias module handles aliases as references to
# Netscape::Bookmarks::Link objects.
#
# =cut

sub aliasof {
	my $self = shift;

	$self->{'ALIASOF'}
	}

# =item $obj->append_title
#
# Adds to the title - used mostly for the HTML parser, although it can
# be used to add a title if none exists (which is an error, though).
#
# =cut

sub append_title {
	my $self = shift;
	my $text = shift;

	$self->{'TITLE'} .= $text;
	}

# =item $obj->append_description
#
# Adds to the description - used mostly for the HTML parser, although
# it can be used to add a description if none exists.
#
# =cut
#
sub append_description {
	my $self = shift;
	my $text = shift;

	$self->{'DESCRIPTION'} .= $text;
	}

#  just show me what you think is in the link.  i use this for
#  debugging.
#
sub print_dump {
	my $self = shift;

	print <<"HERE";
$$self{TITLE}
@{[($$self{HREF})->as_string]}
	$$self{ADD_DATE}
	$$self{LAST_MODIFIED}
	$$self{LAST_VISIT}
	$$self{ALIASID}

HERE

	}

=item $obj->as_string

Returns a Netscape compatible bookmarks file based on the Bookmarks object.

=cut

sub as_string {
	my $self = shift;

	my $link              = $self->href;
	my $title             = $self->title;
	my $aliasid           = $self->aliasid;
	my $aliasof           = $self->aliasof;
	my $add_date          = $self->add_date;
	my $last_visit        = $self->last_visit;
	my $last_modified     = $self->last_modified;
	my $shortcuturl       = $self->shortcuturl;
	my $icon              = $self->icon;
	my $last_charset      = $self->last_charset;
	my $schedule          = $self->schedule;
	my $last_ping         = $self->last_ping;
	my $ping_content_len  = $self->ping_content_len;
	my $ping_status       = $self->ping_status;

	$aliasid       = defined $aliasid ? qq|ALIASID="$aliasid"|        : '';
	$aliasof       = defined $aliasof ? qq|ALIASOF="$aliasof"|        : '';
	$add_date      = $add_date        ? qq|ADD_DATE="$add_date"|      : '';
	$last_visit    = $last_visit      ? qq|LAST_VISIT="$last_visit"|  : '';
	$last_modified = $last_modified   ? qq|LAST_MODIFIED="$last_modified"| : '';

	$shortcuturl   = $shortcuturl  ? qq|SHORTCUTURL="$shortcuturl"|   : '';
	$icon          = $icon         ? qq|ICON="$icon"|                 : '';
	$last_charset  = $last_charset ? qq|LAST_CHARSET="$last_charset"| : '';

	$schedule         = $schedule         ? qq|SCHEDULE="$schedule"|                 : '';
	$last_ping        = $last_ping        ? qq|LAST_PING="$last_ping"|               : '';
	$ping_content_len = $ping_content_len ? qq|PING_CONTENT_LEN="$ping_content_len"| : '';
	$ping_status      = $ping_status      ? qq|PING_STATUS="$ping_status"|           : '';

	my $attr = join " ", grep( $_ ne '', ($aliasid, $aliasof, $add_date, $last_visit,
		$last_modified, $icon, $schedule, $last_ping, $shortcuturl, $last_charset,
		$ping_content_len, $ping_status,   ) );

	$attr = " " . $attr if $attr;

	my $desc = '';
	$desc  = "\n\t<DD>" . $self->description if $self->description;

	#XXX: when the parser gets the Link description, it also picks up
	#the incidental whitespace between the description and the
	#next item, so we need to remove this before we print it.
	#
	#this is just a kludge though, since we should solve the
	#actual problem as it happens.  however, since this is a
	#stream  parser and we don't know when the description ends
	#until the next thing starts (since there is no closing DD tag,
	#we don't know when to strip whitespace.
	$desc =~ s/\s+$//;

	return qq|<A HREF="$link"$attr>$title</A>$desc|;
	}

=item $obj->remove

Performs any clean up necessary to remove this object from the
Bookmarks tree. Although this method does not remove Alias objects
which point to the Link, it probably should.

=cut

sub remove {
	my $self = shift;

	return 1;
	}

"if you want to believe everything you read, so be it."

__END__

=back

=head1 TO DO

	* Add methods for manipulating attributes

=head1 AUTHOR

brian d foy C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2002-2019, brian d foy <bdfoy@cpan.org>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.

=head1 SEE ALSO

L<Netscape::Bookmarks>

=cut
