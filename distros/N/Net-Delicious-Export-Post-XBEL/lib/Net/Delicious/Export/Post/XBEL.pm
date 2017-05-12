use strict;

package Net::Delicious::Export::Post::XBEL;
use base qw (Net::Delicious::Export);

# $Id: XBEL.pm,v 1.10 2005/12/11 19:17:00 asc Exp $

=head1 NAME

Net::Delicious::Export::Post::XBEL - export your del.icio.us posts as 
XBEL SAX events

=head1 SYNOPSIS

 use Net::Delicious;
 use Net::Delicious::Export::Post::XBEL;

 use IO::AtomicFile;
 use XML::SAX::Writer;

 my $fh     = IO::AtomicFile->open("/my/posts.xbel","w");
 my $writer = XML::SAX::Writer->new(Output=>$fh);

 my $del = Net::Delicious->new({...});
 my $exp = Net::Delicious::Export::Post::XBEL->new(Handler=>$writer);

 my $it = $del->posts();
 $exp->by_date($it);

=head1 DESCRIPTION
 
Export your del.icio.us posts as XBEL SAX events.

This package subclasses I<Net::Delicious::Export>.

=cut

use vars qw ($VERSION);
$VERSION = '1.4';

use Net::Delicious::Export::Post qw (group_by_tag
				     mk_bookmarkid);

use String::Random qw (random_string);

=head1 PACKAGE METHODS

=cut

=head2 __PACKAGE__->new(\%args)

Valid arguments are :

=over 4

=item * 

B<Handler>

A valid handler for I<Net::Delicious::Export>, which is really just
a thin wrapper around I<XML::SAX::Base>

=back

Returns a I<Net::Delicious::Export::Post::XBEL> object. Woot!

=cut

# Inherited from Net::Delicious::Export

=head1 OBJECT METHODS

=cut

=head2 $obj->by_date(\%args)

Valid args are

=over 4

=item *

B<posts> I<required>

A I<Net::Delicios::Iterator> object containing the posts you
want to export.

=item *

B<title>

String.

=back

Returns whatever the handler passed to the object
contructor sends back.

=cut

sub by_date {
    my $self  = shift;
    my $args  = shift;

    $self->start_document($args->{title});

    #

    my $last_date = undef;
    my $folder    = 0;

    while (my $bm = $args->{posts}->next()) {

	$bm->time() =~ /(\d{4}-\d{2}-\d{2})T/;
	my $this_date = $1;

	#

	if ($this_date ne $last_date) {

	    if ($folder) {
		$self->end_folder();
		$folder = 0;
	    }

	    $self->start_folder($this_date);

	    $last_date = $this_date;
	    $folder    = 1;
	}

	#

	$self->bookmark($bm);
    }

    #

    $self->end_folder();
    $self->end_document();

    return 1;
}

=head2 $obj->by_tag(\%args)

Valid args are

=over 4

=item *

B<posts> I<required>

A I<Net::Delicios::Iterator> object containing the posts you
want to export.

=item *

B<title>

String.

=item *

B<sort>

Code reference, used as an argument for passing to 
Perl's I<sort> function.

The default behaviour is to sort tags alphabetically.

=back

Bookmarks with multiple tags will be added once; subsequent
instances of the same bookmark will use XBEL's <alias> element
to refer back to the first URL.

Bookmarks for any given tag set will be ordered by their 
timestamp.

Tags which use del.icio.us' "hierarchical tag" structure will
be rendered as nested <folder> elements.

Multiple tags for a bookmark will be ordered alphabetically or
using the same I<sort> argument passed to the method.

Returns whatever the handler passed to the object
contructor sends back.

=cut

sub by_tag {
    my $self  = shift;
    my $args  = shift;

    my $sort = sub {$a cmp $b};

    if (ref($args->{sort}) eq "CODE") {
	$sort = $args->{sort};
    }

    # use Data::Denter;
    # print Indent(&group_by_tag($args->{posts},$sort));
    # exit;

    #

    $self->start_document($args->{title});

    $self->tags(&group_by_tag($args->{posts},$sort),$sort);

    $self->end_document();
    return 1;
}

sub tags {
    my $self = shift;
    my $dict = shift;
    my $sort = shift;

    foreach my $tag (sort $sort keys %$dict) {

	$self->start_folder($tag);
	
	my $item = $dict->{$tag};
	my $ref  = ref($item);

	if ($ref eq "ARRAY") {
	    
	    map { 
		if (ref($_) eq "Net::Delicious::Post") {
		    $self->bookmark($_);
		}

		elsif (ref($_) eq "Net::Delicious::Export::Post::Bookmarkid") {
		    $self->alias($_);
		}

		else {}
		    
	    } @$item;
	    
	}
	
	elsif ($ref eq "HASH") {
	    $self->tags($item,$sort);
	}
	
	else {}

	$self->end_folder();
    }

    return 1;
}

sub start_folder {
    my $self  = shift;
    my $title = shift;

    $self->start_element({Name => "folder",
			  Attributes => {"{}id" => {Name         => "id",
						    LocalName    => "id",
						    Prefix       => "",
						    NamespaceURI => "",
						    Value        => $self->_folderid($title)},}});

    $self->start_element({Name => "title"});
    $self->characters({Data=>$title});
    $self->end_element({Name => "title"});
    
    return 1;
}

sub end_folder {
    my $self = shift;

    $self->end_element({Name => "folder"});
    return 1;
}

sub bookmark {
    my $self = shift;
    my $bm   = shift;

    $self->start_element({Name => "bookmark",
			  Attributes => { "{}id" => {Name         => "id",
						     LocalName    => "id",
						     Prefix       => "",
						     NamespaceURI => "",
						     Value        => &mk_bookmarkid($bm)},
					  "{}href" => {Name        => "href",
						      LocalName    => "href",
						      Prefix       => "",
						      NamespaceURI => "",
						      Value        => $bm->href() } ,
					  "{}visited" => {Name         => "visited",
							  LocalName    => "visited",
							  Prefix       => "",
							  NamespaceURI => "",
							  Value        => $bm->time() } }});
    
    if (my $txt = $bm->description()) {
	$self->start_element({Name => "title"});
	$self->characters({Data=> $txt});
	$self->end_element({Name => "title"});
    }
    
    if (my $txt = $bm->extended()) {
	$self->start_element({Name => "desc"});
	$self->characters({Data=> $txt});
	$self->end_element({Name => "desc"});
    }
    
    $self->end_element({Name => "bookmark"});
    return 1;
}

sub alias {
    my $self = shift;
    my $ref  = shift;

    $self->start_element({Name => "alias",
			  Attributes => { "{}ref" => {Name         => "ref",
						      LocalName    => "ref",
						      Prefix       => "",
						      NamespaceURI => "",
						      Value        => $ref}}});

    $self->end_element({Name => "alias"});
    return 1;
}


sub start_document {
    my $self  = shift;
    my $title = shift;

    $title ||= "del.icio.us posts";

    $self->SUPER::start_document();
    $self->SUPER::xml_decl({Version=>"1.0",Encoding=>"UTF-8"});

    $self->start_element({Name => "xbel"});
    $self->start_element({Name => "title"});
    $self->characters({Data=>$title});
    $self->end_element({Name => "title"});

    $self->start_element({Name => "desc"});
    $self->characters({Data=>"Created by ".__PACKAGE__.", $VERSION"});
    $self->end_element({Name => "desc"});

    return 1;
}

sub end_document {
    my $self = shift;

    #

    $self->end_element({Name => "xbel"});
    $self->SUPER::end_document();

    return 1;
}

sub _folderid {
    my $self  = shift;
    my $title = shift;

    if (! $self->_hasfolderid($title)) {
	push @{$self->{"__folders"}}, $title;
	return $title;
    }

    $self->_folderid(join(":","GENID",&random_string("ccccccccccccc")));
}

sub _hasfolderid {
    my $self = shift;
    my $id   = shift;
    
    foreach (@{$self->{"__folders"}}) {
	if ($_ =~ /^($id)$/) {
	    return 1;
	}
    } 

    return 0;
}

=head1 VERSION

1.4

=head1 DATE

$Date: 2005/12/11 19:17:00 $

=head1 AUTHOR

Aaron Straup Cope <ascope@cpan.org>

=head1 SEE AlSO

L<Net::Delicious>

L<Net::Delicious::Export>

http://pyxml.sourceforge.net/topics/xbel/

=head1 LICENSE

Copyright (c) 2004 Aaron Straup Cope. All Rights Reserved.

This is free software, you may use it and distribute it under the
same terms as Perl itself.

=cut

return 1;
