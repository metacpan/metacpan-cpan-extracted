package Socialtext::WikiObject;
use strict;
use warnings;
use Carp;
use Data::Dumper;

=head1 NAME

Socialtext::WikiObject - Represent wiki markup as a data structure and object

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

  use Socialtext::WikiObject;
  my $page = Socialtext::WikiObject->new(
                rester => $Socialtext_Rester,
                page => $wiki_page_name,
             );

=head1 DESCRIPTION

Socialtext::WikiObject is a package that attempts to fetch and parse some wiki
text into a perl data structure.  This makes it easier for tools to access
information stored on the wiki.

The goal of Socialtext::WikiObject is to create a structure that is 'good
enough' for most cases.

The wiki data is parsed into a data structure intended for easy access to the
data.  Headings, lists and text are supported.  Simple tables without multi-line
rows are parsed.

Subclass Socialtext::WikiObject to create a custom module for your data.  You
can provide accessors into the parsed wiki data.  

Subclasses can simply provide accessors into the data they wish to expose.

=head1 FUNCTIONS

=head2 new( %opts )

Create a new wiki object.  Options:

=over 4

=item rester

Users must provide a Socialtext::Resting object setup to use the desired 
workspace and server.

=item page

If the page is given, it will be loaded immediately.

=back

=cut

our $DEBUG = 0;

sub new {
   my ($class, %opts) = @_;
   croak "rester is mandatory!" unless $opts{rester};

   my $self = { %opts };
   bless $self, $class;
   
   $self->load_page if $self->{page};
   return $self;
}

=head2 load_page( $page_name )

Load the specified page.  Will fetch the wiki page and parse
it into a perl data structure.

=cut

sub load_page {
    my $self = shift;
    my $page = $self->{page} = shift || $self->{page};
    croak "Must supply a page to load!" unless $page;
    my $rester = $self->{rester};
    my $wikitext = $rester->get_page($page);
    return unless $wikitext;

    $self->parse_wikitext($wikitext);
}

=head2 parse_wikitext( $wikitext )

Parse the wikitext into a data structure.

=cut

sub parse_wikitext {
    my $self = shift;
    my $wikitext = shift;

    $self->_find_smallest_heading($wikitext);
    $self->{parent_stack} = [];
    $self->{base_obj} = $self;

    for my $line (split "\n", $wikitext) {
        # whitespace
	if ($line =~ /^\s*$/) {
            $self->_add_whitespace;
        }
        # Header line
	elsif ($line =~ m/^(\^\^*)\s+(.+?):?\s*$/) {
            $self->_add_heading($1, $2);
	}
        # Lists
	elsif ($line =~ m/^[#\*]\s+(.+)/) {
            $self->_add_list_item($1);
	}
        # Tables
        elsif ($line =~ m/^\|\s*(.+?)\s*\|$/) {
            $self->_add_table_row($1);
        }
        else {
            $self->_add_text($line);
        }
    }

    $self->_finish_parse;
    warn Dumper $self if $DEBUG;
}

sub _add_whitespace {}

sub _finish_parse {
    my $self = shift;

    delete $self->{current_heading};
    delete $self->{base_obj};
    delete $self->{heading_level_start};
    delete $self->{parent_stack};
}

sub _add_heading {
    my $self = shift;
    my $heading_level = length(shift || '') - $self->{heading_level_start};
    my $new_heading = shift;
    warn "hl=$heading_level hls=$self->{heading_level_start} ($new_heading)\n" if $DEBUG;
    push @{$self->{headings}}, $new_heading;

    my $cur_heading = $self->{current_heading};
    while (@{$self->{parent_stack}} > $heading_level) {
        warn "going down" if $DEBUG;
        # Down a header level
        pop @{$self->{parent_stack}};
    }
    if ($heading_level > @{$self->{parent_stack}}) {
        if ($cur_heading) {
            warn "going up $cur_heading ($new_heading)" if $DEBUG;
            # Down a header level
            # Up a level - create a new node
            push @{$self->{parent_stack}}, $cur_heading;
            my $old_obj = $self->{base_obj};
            $self->{base_obj} = { name => $cur_heading };
            $self->{base_obj}{text} = $old_obj->{$cur_heading} 
                if $cur_heading and $old_obj->{$cur_heading};

            # update previous base' - @items and direct pointers
            push @{ $old_obj->{items} }, $self->{base_obj};
            $old_obj->{$cur_heading} = $self->{base_obj};
            $old_obj->{lc($cur_heading)} = $self->{base_obj};
        }
        else {
            warn "Going up, no previous heading ($new_heading)\n" if $DEBUG;
        }
    }
    else {
        warn "Something... ($new_heading)\n" if $DEBUG;
        warn "ch=$cur_heading\n" if $DEBUG and $cur_heading;
        $self->{base_obj} = $self;
        for (@{$self->{parent_stack}}) {
            $self->{base_obj} = $self->{base_obj}{$_} || die "Can't find $_";
        }
    }
    $self->{current_heading} = $new_heading;
    warn "Current heading: $self->{current_heading}\n" if $DEBUG;
}

sub _add_text {
    my $self = shift;
    my $line = shift;

    # Text under a heading
    my $cur_heading = $self->{current_heading};
    if ($cur_heading) {
        if (ref($self->{base_obj}{$cur_heading}) eq 'ARRAY') {
            $self->{base_obj}{$cur_heading} = { 
                items => $self->{base_obj}{$cur_heading},
                text => "$line\n",
            }
        }
        elsif (ref($self->{base_obj}{$cur_heading}) eq 'HASH') {
            $self->{base_obj}{$cur_heading}{text} .= "$line\n";
        }
        else {
            $self->{base_obj}{$cur_heading} .= "$line\n";
        }
        $self->{base_obj}{lc($cur_heading)} = $self->{base_obj}{$cur_heading};
    }
    # Text without a heading
    else {
        $self->{base_obj}{text} .= "$line\n";
    }
}

sub _add_list_item {
    my $self = shift;
    my $item = shift;

    $self->_add_array_field('items', $item);
}

sub _add_table_row {
    my $self = shift;
    my $line = shift;

    my @cols = split /\s*\|\s*/, $line;
    $self->_add_array_field('table', \@cols);
}

sub _add_array_field {
    my $self = shift;
    my $field_name = shift;
    my $item = shift;

    my $field = $self->{current_heading} || $field_name;
    my $bobj = $self->{base_obj};
    if (! exists $bobj->{$field} or ref($bobj->{$field}) eq 'ARRAY') {
        push @{$bobj->{$field}}, $item;
    }
    elsif (ref($bobj->{$field}) eq 'HASH') {
        push @{$bobj->{$field}{$field_name}}, $item;
    }
    else {
        my $text = $bobj->{$field};
        $bobj->{$field} = {
            text => $text,
            $field_name => [ $item ],
        };
    }
    $bobj->{lc($field)} = $bobj->{$field};
}

sub _find_smallest_heading {
    my $self = shift;
    my $text = shift;

    my $big = 99;
    my $heading = $big;
    while ($text =~ m/^(\^+)\s/mg) {
        my $len = length($1);
        $heading = $len if $len < $heading;
    }
    $self->{heading_level_start} = $heading == $big ? 1 : $heading;
}

=head1 AUTHOR

Luke Closs, C<< <luke.closs at socialtext.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-socialtext-editpage at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Socialtext-Resting-Utils>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Socialtext::EditPage

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Socialtext-Resting-Utils>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Socialtext-Resting-Utils>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Socialtext-Resting-Utils>

=item * Search CPAN

L<http://search.cpan.org/dist/Socialtext-Resting-Utils>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Luke Closs, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
