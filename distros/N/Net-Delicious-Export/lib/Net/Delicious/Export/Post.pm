use strict;

package Net::Delicious::Export::Post;
use base qw (Exporter);

# $Id: Post.pm,v 1.6 2005/12/11 19:40:53 asc Exp $

=head1 NAME

Net::Delicious::Export::Post - shared functions for exporting del.icio.us posts

=head1 SYNOPSIS

 use Net::Delicious;
 use Net::Delicious::Export::Post qw (group_by_tag);

 my $del = Net::Delicious->new({...});
 my $it  = $del->recent_posts();

 my $hr_ordered = group_by_tag($it);
 
=head1 DESCRIPTION

Shared function for exporting del.icio.us posts.

=cut

use vars qw ($VERSION @EXPORT_OK);

$VERSION = '1.1';

@EXPORT_OK = qw (group_by_tag
		 mk_bookmarkid);

# used by &_addbm

my $by_time = sub {
    $a->time() cmp $b->time();
};


=head1 FUNCTIONS

=cut

=head2 &group_by_tag(Net::Delicious::Iterator,\&sort_function)

Build a nested hash reference of posts grouped by tag. This
function will DWIM with "hierarchical" tags.

Posts for any given tag set will be grouped as an array 
reference. They will be ordered by their timestamp.

Valid arguments are :

=over 4

=item *

B<Net::Delicious::Iterator> I<required>

An iterator object of I<Net::Delicious::Post> objects.

=item *

B<CODE reference>

Used as an argument for passing to Perl's I<sort> function.

The default behaviour is to sort tags alphabetically.

=back

Returns a hash reference.

=cut

sub group_by_tag {
    my $posts = shift;
    my $sort  = shift;

    my %ordered = ();

    while (my $bm = $posts->next()) {

	# Create a list of tags

	my $tag = $bm->tag() || "unsorted";
	$tag =~ s/\s{2,*}/ /g;

	my @tags = sort $sort split(/[\s,]/,$tag);

	# Pull the first tag off the list
	# and use it as the actual bookmark

	&_addtag(\%ordered, shift @tags, $bm);

	# Everything else is just an alias

	map { 
	    &_addtag(\%ordered, $_, &mk_bookmarkid($bm));
	} @tags;
    }

    return \%ordered;
}

=head2 &mk_bookmarkid(Net::Delicious::Post)

Returns a I<Net::Delicious::Export::Post::Bookmarkid> object.

The object subclasses I<Net::Delicious::Post> but since its 
I<stringify> method is overloaded to return the value of its
B<bookmarkid> method you can, pretty much, just treat it like
a string.

=cut

sub mk_bookmarkid {
    return Net::Delicious::Export::Post::Bookmarkid->new($_[0]);
}


sub _addtag {
    my $dict = shift;
    my $tag  = shift;
    my $bm   = shift;

    # print STDERR "[add tag] '$tag' '$bm'\n";

    my @tree  = ($tag =~ m!/!) ? grep { /^\w/ } split("/",$tag) : ($tag);
    my $count = scalar(@tree);

    if ($count == 1) {
	$dict->{$tag} ||= [];
	&_addbm($dict->{$tag}, $bm);
	return;
    }

    my $ref     = $dict;
    my $current = 1;

    map {

      if ($current == $count) {
	  $ref->{$_} ||= [];
	  &_addbm($ref->{$_},$bm);
      }

      else {
	$ref->{$_} ||= {};
	$ref = $ref->{$_};
      }
      
      $current++;

    } @tree;
}

sub _addbm {
    my $list = shift;
    my $bm   = shift;
    
    @$list = sort $by_time (@$list,$bm);
}

package Net::Delicious::Export::Post::Bookmarkid;
use base qw (Net::Delicious::Post);

use MD5;

use overload q("") => sub { shift->bookmarkid() };

sub new {
    my $pkg = shift;
    my $bm  = shift;

    my %id = %$bm;
    $id{bookmarkid} = MD5->hexhash($bm->href());

    return bless \%id, $pkg;
}

sub bookmarkid {
    my $self = shift;
    return $self->{bookmarkid};
}

=head1 VERSION

1.1

=head1 DATE

$Date: 2005/12/11 19:40:53 $

=head1 AUTHOR

Aaron Straup Cope <ascope@cpan.org>

=head1 SEE AlSO

L<Net::Delicious::Export>

=head1 LICENSE

Copyright (c) 2004 Aaron Straup Cope. All Rights Reserved.

This is free software, you may use it and distribute it under the
same terms as Perl itself.

=cut

return 1;
