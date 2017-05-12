#
# Search::Namazu.pm
#
# Copyright (C) 1999,2001-2003,2005  NOKUBI Takatsugu All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
# 02111-1307, USA
#
# $Id: Namazu.pm 269 2006-06-09 05:56:14Z knok $
#

package Search::Namazu;

=head1 NAME

Search::Namazu - Namazu library module for perl

=head1 SYNOPSIS

  use Search::Namazu;

  @hlists = Search::Namazu::Search(index => '/usr/local/namazu/index',
				query => 'foo');

  foreach my $hlist (@hlists) {
      print ($hlist->score, $hlist->uri, $hlist->date, $hlist->rank);
  }

  $x = Search::Namazu::Search(index => '/usr/local/namazu/index',
				query => 'foo',
				fields => ["uri", "from"]);

  foreach my $rxs (@$x) {
      print ($rxs->get("uri"), $rxs->score, $rxs->get("from"));
  }

=head1 DESCRIPTION

This module is an interface for Namazu library. Namazu is an implement
of full text retrieval search system. It is available at:
http://www.namazu.org/

=head2 OVERVIEW

The module implements Search::Namazu::Search function for searching.
When the function is called, it will return the results as an array of
Search::Namazu::Result object.

Search::Namazu::Result object has the score, URI, date and ranking as
results of searching.

=head2 Search::Namazu::Search

Search::Namazu::Search function has a reference of hash value as 
the argument. Keys for the hash are the following:

=head3 index

Specify a path of index. If you want to specify a index, you will need
to specify the path as a scalar value. However, if you want to specify
some indices, you will need to specify the paths as an array reference.

For example:

  @result = Search::Namazu::Search(
  	index => ['/var/www/index/site1', '/var/www/index/site2'],
        query => 'foo'
        );

  $resultref = Search::Namazu::Search(
  	index => ['/var/www/index/site1', '/var/www/index/site2'],
        query => 'bar', returnas => 'reference'
        );

=head3 query

Specify a query expression as string. Expression syntax is same as
namazu command.

=head3 sortMethod

Specify sort method of results. You can use the following values:

=over 4

=item B<NMZ_SORTBYDATE>

Order by date.

=item B<NMZ_SORTBYSCORE>

Order by score.

=item  B<NMZ_SORTBYFIELD>

Order by fields.

=back

If you ommit this option, it is treated as same as NMZ_SORTBYDATE.

=head3 sortOrder

Specify sort order of results. You can use the following values:

=over 4

=item B<NMZ_DESCENDSORT>

Descend order.

=item B<NMZ_ASCENDSORT>

Ascend order.

=back

If you ommit this option, it is treated as same as NMZ_DESCENDSORT.

=head3 sortField

Specify field name when you specified sortMethod as NMZ_SORTBYFIELD.

=head3 lang

Specify language.

=head3 maxhit

Speciry maximum numbers of hits. Same as MaxHit directive in namazurc.

=head3 maxget

Speciry result object numbers of hits to limit too many results.
If the parameter was omitted, it is assumed same value as maxhit.

=head3 returnas

Specify return method, if the parameter is set as 'reference', it
returns a reference of array as a result.

=head3 fields

Specify you want to get fields as a refrence of array. In the case,
the result is returned as a reference of array, contains
Search::Namazu::ResultXS objects.

=head2 Search::Namazu::Result

Search::Namazu::Result object is for keeping result information.
It has the following methods:

=head3 score

It returns score.

=head3 uri

It returns URI.

=head3 date

It returns date.

=head3 rank

It returns ranking number.

=head3 summary

It returns summary.

=head3 title

It returns title.

=head3 author

It returns author.

=head3 size

It returns size.

=head2 Search::Namazu::ResultXS

Search::Namazu::ResultXS object is also for keeping result information.
It has the following methods:

=head3 score

It returns score.

=head3 date

It returns date.

=head3 rank

It returns ranking number.

=head3 docid

It returns id of document.

=head3 idxid

It returns id of index.

=head3 get

It returns specified value of field.

=head1 COPYRIGHT

Copyright 1999,2000,2001,2002 NOKUBI Takatsugu All rights reserved.
This is free software with ABSOLUTELY NO WARRANTY.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
02111-1307, USA

=cut

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);

@EXPORT = qw(NMZ_SORTBYDATE NMZ_SORTBYSCORE NMZ_SORTBYFIELD
NMZ_ASCENDSORT NMZ_DESCENDSORT
NMZ_NOT_SPECIFIED_INDEX NMZ_ERR_INDEX NMZ_ERR_EMPTY_QUERY
NMZ_ERR_RESULT_EXCEEDED);
# %EXPORT_TAGS = (all => [qw()]);

$VERSION = '0.96';

bootstrap Search::Namazu $VERSION;

use Carp;

sub NMZ_SORTBYDATE { return 1; }
sub NMZ_SORTBYSCORE { return 2; }
sub NMZ_SORTBYFIELD { return 3; }
sub NMZ_ASCENDSORT { return 16; }
sub NMZ_DESCENDSORT { return 32; }

sub NMZ_NOT_SPECIFIED_INDEX { return -1; }
sub NMZ_ERR_INDEX { return -2; }
sub NMZ_ERR_EMPTY_QUERY { return -3; }
sub NMZ_ERR_RESULT_EXCEEDED { return -4; }

# nmz_stat
sub NMZ_SUCCESS { return 0; }
sub NMZ_ERR_TOO_MUCH_HIT { return 6; }

sub Search {
    my %args = @_;
    my $index = $args{'index'};
    my $sortmeth = $args{'sortMethod'} || -1;
    my $sortord = $args{'sortOrder'} || -1;
    my $sortfield = $args{'sortField'} || -1;
    my $lang = $args{'lang'};
    my $query = $args{'query'};
    my $maxhit = $args{'maxhit'} || 10000;
    my $returnas = $args{'returnas'};
    my $maxget = $args{'maxget'} || $maxhit;
    my $fields = $args{'fields'};

# initialize

    if (! defined $index) {
	return NMZ_NOT_SPECIFIED_INDEX;
    }
    my @indices;
    if (ref($index)) {
	for my $idx (@$index) {
	    push @indices, $idx;
	}
    } else {
	@indices = ($index);
    }
    for my $idx (@indices) {
	if (nmz_addindex($idx) < 0) {
	    return NMZ_ERR_INDEX;
	}
    }

# set paramater

    if ( $sortmeth == NMZ_SORTBYDATE) {
	nmz_sortbydate();
    } elsif ($sortmeth == NMZ_SORTBYSCORE) {
	nmz_sortbyscore();
    } elsif ($sortfield && $sortmeth == NMZ_SORTBYFIELD) {
	nmz_setsortfield($sortfield);
	nmz_sortbyfield();
    } else {
	nmz_sortbydate();
    }

    if ($sortord == NMZ_DESCENDSORT) {
	nmz_descendingsort();
    } elsif ($sortord == NMZ_ASCENDSORT) {
	nmz_ascendingsort();
    } else {
	nmz_descendingsort();
    }

    if (defined $lang) {
	nmz_setlang($lang);
    }
    nmz_setmaxhit($maxhit);

# query and get hlist

    if (!defined $query) {
	return NMZ_ERR_RESULT_EXCEEDED;
    }

# create Search::Namazu::Result object

    if (ref($fields) eq "ARRAY") {
	my $hlistref = call_search_main_fields($query, $maxget, $fields);
	my $status = nmz_getstatus();
	if ($status != NMZ_SUCCESS) {
	    return $status;
	}
	# return objects
	return $hlistref;
    } elsif ($returnas eq 'reference') {
	my $hlistref = call_search_main_ref($query, $maxget);
	my $status = nmz_getstatus();
	if ($status != NMZ_SUCCESS) {
	    return $status;
	}
	# return objects
	return $hlistref;
    } else {
	my @hlists = call_search_main($query, $maxget);
	my $status = nmz_getstatus();
	if ($status != NMZ_SUCCESS) {
	    return $status;
	}
	# return objects
	return @hlists;
    }
}

package Search::Namazu::Result;

sub new {
    my $self = {};
    $self->{'score'} = -1;
    $self->{'uri'} = '';
    $self->{'date'} = 0;
    $self->{'rank'} = -1;
    bless $self;
    return $self;
}

sub set {
    my ($self, $score, $uri, $date, $rank, $summary, $title, $author,
	$size) = @_;
    $self->{score} = $score;
    $self->{uri} = $uri;
    $self->{date} = $date;
    $self->{rank} = $rank;
    $self->{summary} = $summary;
    $self->{title} = $title;
    $self->{author} = $author;
    $self->{size} = $size;
}

sub score {
    my $self = shift;
    if (@_) {
	my $score = shift;
	$self->{'score'} = $score;
    }
    $self->{'score'};
}

sub uri {
    my $self = shift;
    if (@_) {
	my $uri = shift;
	$self->{'uri'} = $uri;
    }
    $self->{'uri'};
}

sub date {
    my $self = shift;
    if (@_) {
	my $date = shift;
	$self->{'date'} = $date;
    }
    $self->{'date'};
}

sub rank {
    my $self = shift;
    if (@_) {
	my $rank = shift;
	$self->{'rank'} = $rank;
    }
    $self->{'rank'};
}

sub summary {
    my $self = shift;
    if (@_) {
	my $summary = shift;
	$self->{'summary'} = $summary;
    }
    $self->{'summary'};
}

sub title {
    my $self = shift;
    if (@_) {
	my $title = shift;
	$self->{'title'} = $title;
    }
    $self->{'title'};
}

sub author {
    my $self = shift;
    if (@_) {
	my $author = shift;
	$self->{'author'} = $author;
    }
    $self->{'author'};
}

sub size {
    my $self = shift;
    if (@_) {
	my $size = shift;
	$self->{'size'} = $size;
    }
    $self->{'size'};
}

1;
__END__

