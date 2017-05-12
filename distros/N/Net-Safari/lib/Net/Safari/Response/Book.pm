package Net::Safari::Response::Book;

=head1 NAME

Net::Safari::Response::Book - Book object returned by Safari

=head1 SYNOPSIS

  use Net::Safari::Response::Book;
  my $book = Net::Safari::Response::Book->new(%book_ref);

  print $book->title;

  my @sections = $book->sections

=head1 DESCRIPTION 

See Net::Safari for general usage info.

In most cases this object is created for you from the Net::Safari::Response::books() method after a Net::Safari->search() call.

=head1 ACCESSORS
The accessor descriptions are mostly pulled from the official spec:
http://safari.oreilly.com/affiliates/?p=response

=head2 title()

Book title.

=head2 isbn()

Unformatted ISBN, i.e. there's no dashes, just numbers and occassionally an X.

=head2 edition()

A text description of the edition, i.e. "First," "Second" ...

=head2 authors()

Returns an array of Net::Safari::Response::Author objects.

=head2 pagenums()

Number of pages in book.

=head2 pubdate()

String representation of the pubdate. There's no guarantees about the format of
the date. At the very least expect "July 14, 2004" and "April 1978." If you
need a consistent format, use pub_timepiece().

=head2 pub_timepiece

Time::Piece object representing the publish date. Module tries to be smart
about parsing the date so that you can rely on a consistent format.

=head2 subjects()

An array of subject classification. TODO: get some more info on what these are.

=head2 imprint()

The name of the division publishing the book. This is what's on the cover. For
some books, like Programming Perl, imprint() and publisher() are the same
(O'Reilly). For other books, like Mac OS X: The Missing Manual, they're
different (publisher=O'Reilly and imprint=Pogue Press).

=head2 publisher()

The parent company publishing the book. Normally you want imprint().

=head2 description()

paragraph describing the book.

=head2 msrp()

Suggested retail price in the United States.

=head2 slots()

The number of slots that this book occupies in a Safari subscription.

=head2 imagesmall()

URL to small cover image.

=head2 imagemedium()

URL to medium cover image.

=head2 imagelarge()

URL to large cover image.
TODO: do these images have consistent sizes.

=head2 buyprint()

URL to buy a print copy of the book.

=head2 sections()

An array of Net::Safari::Response::Section objects.

=head2 toc()

TODO: not sure what this looks like.

=head2 url()

URL to the book on Safari. This isn't documented in the API, so I can't
guarantee that it will always work.

=cut


use strict;

our $VERSION = 0.01;

use XML::Simple;
use LWP::UserAgent;
use URI::Escape;
use Class::Accessor;
use Class::Fields;
use Date::Parse;
use Time::Piece;
use Data::Dumper;
use Net::Safari::Response::Section;
use Net::Safari::Response::Author;

use base qw(Class::Accessor Class::Fields);

our @BASIC_FIELDS = qw(
              pagenums 
              pubdate 
              pub_timepiece
              imagemedium 
              url
              edition
              isbn
              publisher
              imprint
              imagesmall
              msrp
              description
              imagelarge
              buyprint
              title
              slots
); 

our @CUSTOM_FIELDS = qw(
              authors
              sections
              subjects
);

use fields @BASIC_FIELDS, @CUSTOM_FIELDS;
Net::Safari::Response::Book->mk_accessors(@BASIC_FIELDS);

=head1 METHODS

=head2 new()

$book = Net::Safari::Response::Book->new($ref);

Takes a hash represenation of the XML returned by Safari. Normally this is
taken care of by Net::Safari::Response.

=cut

sub new
{
	my ($class, %args) = @_;

	my $self = bless ({}, ref ($class) || $class);

    $self->_init(%args);

	return ($self);
}

sub _init {
    my $self = shift;
    my %args = @_;
    
    #Title
    $self->title($args{title});
    
    #ISBN
    $args{isbn} =~ s/-//g;
    $self->isbn($args{isbn});

    #Edition
    $self->edition($args{edition});
    
    #Authors
    $self->_set_authors($args{authorgroup});
    
    #PageNums
    $self->pagenums($args{pagenums});

    #PubDate
    $self->pubdate($args{pubdate}); 
    
    #Pub Time::Piece
    $self->_set_pub_timepiece();
 
    #Subjects
    $self->_set_subjects($args{subjectset}); 

    #Publisher
    $self->publisher($args{publisher}->{publishername});

    #Imprint
    $self->imprint($args{publisher}->{imprint});

    #Description
    $self->description($args{description});

    #MSRP
    $self->msrp($args{msrp});

    #ImageSmall
    $self->imagesmall($args{imagesmall});

    #ImageMedium
    $self->imagemedium($args{imagemedium});

    #ImageLarge 
    $self->imagelarge($args{imagelarge});

    #BuyPrint    
    $self->buyprint($args{buyprint});

    #Sections
    $self->_set_sections($args{section});

    #Table of Contents
    #toc

    #URL
    $self->url($args{url});
}

sub _set_sections {
    my $self = shift;
    my $section_ref = shift;

    my @sections;
    if (ref($section_ref) eq "HASH") {
        push(@sections, Net::Safari::Response::Section->new(%$section_ref));
    }
    elsif (ref($section_ref) eq "ARRAY") {
        foreach my $section (@$section_ref) {
            push(@sections, Net::Safari::Response::Section->new(%$section));
        }
    }

    $self->{sections} = \@sections;
}

sub sections {
    my $self = shift;

    return @{$self->{sections}};
}

sub _set_subjects {
    my $self = shift;
    my $subjects_ref = shift;

    my @subjects;

    if (ref($subjects_ref) eq "HASH") {
        push(@subjects, @{$subjects_ref->{subject}});
    }
    elsif (ref($subjects_ref) eq "ARRAY") {
        foreach my $subject (@$subjects_ref) {
            push(@subjects, @{$subjects_ref->{subject}});
        }
    }
    $self->{subjects} = \@subjects;
}

sub subjects {
    my $self = shift;

    return @{$self->{subjects}};
}

sub _set_pub_timepiece {
    my $self = shift;
    my $date_string = $self->pubdate;

    #Default to the first of the month
    $date_string =~ s/^(\w+)\s*(\d{4})$/$1 1, $2/;

    #Date should be like: April 30, 1978
    my $time = str2time($date_string);

    $self->pub_timepiece( Time::Piece->strptime($time, "%s") );
}

sub _set_authors {
    my $self = shift;
    my $authorgroup = shift;

    my @authors;

    # TODO - why is author an array? Because we specified it in XMLin. But that
    # code was taken from the Safari example. Why?
    if (ref($authorgroup) eq "HASH") {
        push (@authors, 
              Net::Safari::Response::Author->new(%{$authorgroup->{author}->[0]}));    
    }
    elsif (ref($authorgroup) eq "ARRAY") {
        foreach my $author (@$authorgroup) {
            push (@authors, 
                  Net::Safari::Response::Author->new(%{$author->{author}->[0]}));    
        }
    }
    $self->{authors} = \@authors;
}

sub authors {
    my $self = shift;

    return @{$self->{authors}};
}

=head1 BUGS

None yet.

=head1 SUPPORT

If you find a bug in the code or find that the code doesn't match Safari API, please send me a line.

If the Safari API is down or has bugs, please contact Safari directly:
affiliates@safaribooksonline.com

=head1 ACKNOWLEDGMENTS

Adapted from the design of Net::Amazon by Mike Schilli. 

Some documentation based on the source Safari documentation:
http://safari.oreilly.com/affiliates/?p=web_services

=head1 AUTHOR

    Tony Stubblebine	
    tonys@oreilly.com

=head1 COPYRIGHT

Copyright 2004 by Tony Stubblebine (tonys@oreilly.com)

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut



1; #this line is important and will help the module return a true value
__END__

