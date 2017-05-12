package Pod::POM::View::Confluence;

use warnings;
use strict;

# most of the code below and until __END__
# was lifted from Pod::POM::View::Text

use Pod::POM::View;
use base qw( Pod::POM::View );
use vars qw( $VERSION $DEBUG $ERROR $AUTOLOAD $INDENT );
use Text::Wrap;
$VERSION = '0.01';
$DEBUG   = 0 unless defined $DEBUG;
$INDENT  = 0;


sub new {
    my $class = shift;
    my $args  = ref $_[0] eq 'HASH' ? shift : { @_ };
    bless { 
	INDENT => 0,
	%$args,
    }, $class;
}


sub view {
    my ($self, $type, $item) = @_;

    if ($type =~ s/^seq_//) {
	return $item;
    }
    elsif (UNIVERSAL::isa($item, 'HASH')) {
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


sub view_head1 {
    my ($self, $head1) = @_;
    my $title = $head1->title->present($self);
    
    my $output = "h1. $title\n" . $head1->content->present($self);
    return $output;
}


sub view_head2 {
    my ($self, $head2) = @_;
    my $title = $head2->title->present($self);

    my $output = "h2. $title\n" . $head2->content->present($self);

    return $output;
}


sub view_head3 {
    my ($self, $head3) = @_;
    my $title = $head3->title->present($self);

    my $output = "h3. $title\n" . $head3->content->present($self);

    return $output;
}


sub view_head4 {
    my ($self, $head4) = @_;
    my $title = $head4->title->present($self);

    my $output = "h4. $title\n" . $head4->content->present($self);

    return $output;
}


sub view_item {
    my ($self, $item) = @_;
    my $indent = ref $self ? \$self->{ INDENT } : \$INDENT;
    my $pad = '*' x $$indent;
    my $title = $item->title->present($self);
    $title =~ s/^\s*\*/'*'x($$indent+1)/e;
    $title =~ s/^\s*\d+/'#'x($$indent+1)/e;
    $$indent += 1;
    my $content = $item->content->present($self);
    $content =~ s/^\s+//;
    $content =~ s/\n+/\n/g;
    $$indent -= 1;
    
    $content =~ s/\n+\z//g;
    return "$title $content\n";
}


sub view_for {
    my ($self, $for) = @_;
    return '' unless $for->format() =~ /\bconfluence\b/;
    return $for->text()
	. "\n";
}

    
sub view_begin {
    my ($self, $begin) = @_;
    return '' unless $begin->format() =~ /\bconfluence\b/;
    return $begin->content->present($self);
}

    
sub view_textblock {
    my ($self, $text) = @_;
    $text =~ s/\s+/ /mg;
    $text =~ s/\s+\z//;
    return $text . "\n";
}


sub view_verbatim {
    my ($self, $text) = @_;
    return "{noformat}\n$text\n{noformat}\n";
}


sub view_seq_bold {
    my ($self, $text) = @_;
    return "*$text*";
}


sub view_seq_italic {
    my ($self, $text) = @_;
    return "_${text}_";
}


sub view_seq_code {
    my ($self, $text) = @_;
    return "{{$text}}";
}


sub view_seq_file {
    my ($self, $text) = @_;
    return "_${text}_";
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

sub view_seq_link {
    my ($self, $link) = @_;
	return "[$link]";
}
	
1;

__END__

=head1 NAME

Pod::POM::View::Confluence - Confluence view of a Pod Object Model

=head1 SYNOPSIS

    use Pod::POM::View::Confluence;
    my $view = 'Pod::POM::View::Confluence';
    
    $pom->present($view);

=head1 DESCRIPTION

I<Confluence> is an "entreprise wiki" published by Atlassian.
Pages can be edited either in I<Rich Text> or I<Wiki Markup>.
See L<http://www.atlassian.com/software/confluence/> for details.

This module provides a view for C<Pod::POM> that outputs the
information in the I<Confluence> I<Wiki Markup>.

Use it like any other C<Pod::POM::View> subclass.

Note that C<=for> and C<=begin> / C<=end> block will not output anything,
unless for format C<confluence>.

=head1 METHODS

Apart from the C<view_*> methods (see L<Pod::POM> for details), this
module supports the two following methods:

=over 4

=item new()

Constructor.

=item view( $type, $node )

Return the given Pod::POM node as formatted by the View.

=back

=head1 AUTHOR

Philippe Bruhat (BooK), C<< <book@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-pod-pom-view-confluence at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Pod-POM-View-Confluence>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Pod::POM::View::Confluence

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Pod-POM-View-Confluence>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Pod-POM-View-Confluence>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Pod-POM-View-Confluence>

=item * Search CPAN

L<http://search.cpan.org/dist/Pod-POM-View-Confluence>

=back


=head1 COPYRIGHT

Copyright 2008 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

