package Net::Safari::Response::Section;

=head1 NAME

Net::Safari::Response::Section - Section node returned by Safari

=head1 SYNOPSIS

  use Net::Safari::Response::Section;
  my $book = Net::Safari::Response::Section->new(%book_ref);

  my @sections = $response->book->sections;

  print $section->title;

=head1 DESCRIPTION 

See Net::Safari for general usage info.

In most cases this object is created for you by Net::Safari::Response after a Net::Safari->search() call.

=head1 ACCESSORS
The accessor descriptions are mostly pulled from the official spec:
http://safari.oreilly.com/affiliates/?p=response

=head2 title()

Section title.

=head2 heading()

Name of the section's heading, i.e. "Chapter 2"

=head2 extract()

Text preview of the area surrounding the match.

=head2 search_term_matches()

Terms that matched in this node. Corresponds to h1hit in the spec.

=head2 preview()

HTML preview of the requested section. Only available on by "id" matches.

=head2 url()

URL to this section on Safari. 

=head2 type()

Section type. Not documented. Ex: "chapter." Not sure what other possibilities
are.

=cut


use strict;

our $VERSION = 0.01;

use LWP::UserAgent;
use URI::Escape;
use Class::Accessor;
use Class::Fields;
use Data::Dumper;

use base qw(Class::Accessor Class::Fields);

our @BASIC_FIELDS = qw(
              url
              title
              heading
              extract
              search_term_matches
              preview
              type
); 

use fields @BASIC_FIELDS;
Net::Safari::Response::Section->mk_accessors(@BASIC_FIELDS);

=head1 METHODS

=head2 new()

$book = Net::Safari::Response::Section->new($ref);

Takes a hash represenation of the XML returned by Safari. Normally this is
taken care of by Net::Safari::Response::Book.

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

    #Heading
    $self->heading($args{heading});

    #Extract
    #TODO - find out why content is an array
    #TODO - interleave content and hlhit
    if (ref $args{extract} eq "HASH")
    {
        my $extract = "";
        my $i; 
        for ($i = 0; $i < @{$args{extract}->{hlhit}}; $i++)
        {
            $extract .= $args{extract}->{content}->[$i]
                        . $args{extract}->{hlhit}->[$i];
        }
        if ($args{extract}->{content}->[$i]) 
        {
            $extract .= $args{extract}->{content}->[$i];
        }

        $self->extract($extract);
    }
    else 
    {
        $self->extract($args{extract});
    }
    
    #Preview
    $self->preview($args{preview});


    #URL
    $self->url($args{url});

    #Type
    $self->type($args{type});
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

