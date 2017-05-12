package Pod::POM::View::TOC;

use warnings;
use strict;

=head1 NAME

Pod::POM::View::TOC - Generate the TOC of a POD with Pod::POM

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

  my $source = "TOC.pm";
  my $toc;
  my $parser = Pod::POM->new( warn => 0 );
  Pod::POM->default_view("Pod::POM::View::TOC");
  my $pom = $parser->parse_file( $source );
  $toc = $view->print($pom);

=head2 Format of C<$toc> for this document:

  NAME
  VERSION
  SYNOPSIS
  	Format of $toc
  AUTHOR
  SUPPORT
  ACKNOWLEDGEMENTS
  COPYRIGHT & LICENSE

There is a line break after each section. Subsections begin with tabulars
to represent their depth.

=head1 AUTHOR

Moritz Onken, C<< <onken at houseofdesign.de> >>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Pod::POM::View::TOC


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Pod-POM-View-TOC>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Pod-POM-View-TOC>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Pod-POM-View-TOC>

=item * Search CPAN

L<http://search.cpan.org/dist/Pod-POM-View-TOC>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to Andy Wardley and his great L<Pod::Pom> module.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Moritz Onken, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

require 5.004;

use strict;
use Pod::POM::Nodes;
use Pod::POM::View;
use base qw( Pod::POM::View );
use vars qw( $VERSION $DEBUG $ERROR $AUTOLOAD $MARKUP );

$VERSION = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0 unless defined $DEBUG;

# create reverse lookup table mapping method name to original sequence
$MARKUP = {
    map { ( $Pod::POM::Node::Sequence::NAME{ $_ } => $_ ) } 
       keys %Pod::POM::Node::Sequence::NAME,
};


sub view_head1 {
    my ($self, $head1) = @_;
    my $title = $head1->title->present($self);
    return "$title\n". $head1->content->present($self);;
}


sub view_head2 {
    my ($self, $head2) = @_;
    my $title = $head2->title->present($self);
    return "\t$title\n". $head2->content->present($self);;
}


sub view_head3 {
    my ($self, $head3) = @_;
    my $title = $head3->title->present($self);
    return "\t\t$title\n". $head3->content->present($self);;
}


sub view_head4 {
    my ($self, $head4) = @_;
    my $title = $head4->title->present($self);
    return "\t\t\t$title\n". $head4->content->present($self);;
}



sub view {
    my ($self, $type, $item) = @_;

    if ($type =~ s/^seq_//) {
	if ($type eq 'text') {
	    return "$item";
	}
	if ($type = $MARKUP->{ $type }) {
	    return "$item";
	}
    }
    elsif (ref $item eq 'HASH') {
	if (defined $item->{ content }) {
	    return $item->{ content }->present($self);
	}
	elsif (defined $item->{ text }) {
	    my $text = $item->{ text };
	    return ref $text ? $text->present($self) : $text;
	}
	else {
	    return '';
	}
    }
    elsif (! ref $item) {
	return $item;
    }
    else {
	return '';
    }
}


sub view_pod {
    my ($self, $pod) = @_;
    return $pod->content->present($self);
}


*view_over = *view_item = *view_for = *view_begin = *view_meta = \&view_pod;



sub view_textblock {
    my ($self, $text) = @_;
    return "";
}


sub view_verbatim {
    my ($self, $text) = @_;
    return "";
}

my $entities = {
    gt   => '>',
    lt   => '<',
    amp  => '&',
    quot => '"',
};


sub view_seq_entity {
    my ($self, $entity) = @_;
    return $entities->{ $entity } || $entity;
}


1;


