package Pod::POM::View::Trac;

our $VERSION = '0.02';
our $INDENT = 4;

use strict;
use warnings;

use Text::Wrap;
use base 'Pod::POM::View::Text';

#---------------------------------------------------------------------------
# Public Methods
#---------------------------------------------------------------------------

sub view_head1 {
    my ($self, $head1) = @_;

    my $title = $head1->title->present($self);
    my $output = "= $title =\n\n" . $head1->content->present($self);

    return $output;

}

sub view_head2 {
    my ($self, $head2) = @_;

    my $title = $head2->title->present($self);
    my $output = "== $title ==\n\n" . $head2->content->present($self);

    return $output;

}

sub view_head3 {
    my ($self, $head3) = @_;

    my $title = $head3->title->present($self);
    my $output = "=== $title ===\n\n" . $head3->content->present($self);

    return $output;

}

sub view_head4 {
    my ($self, $head4) = @_;

    my $title = $head4->title->present($self);
    my $output = "==== $title ====\n\n" . $head4->content->present($self);

    return $output;

}

#------------------------------------------------------------------------
# view_over($self, $over)
#
# Present an =over block - this is a blockquote if there are no =items
# within the block.
#------------------------------------------------------------------------

sub view_over {
    my ($self, $over) = @_;

    if (@{$over->item}) {

        return $over->content->present($self);

    } else {

        my $indent = ref $self ? \$self->{INDENT} : \$INDENT;
        my $pad = ' ' x $$indent;
        my $text = $over->content->present($self);

        local $Text::Wrap::unexpand = 0;

        my $content =  wrap($pad, $pad, $text) . "\n\n";

        return $content;

    }

}

sub view_item {
    my ($self, $item) = @_;

    my $title = $item->title->present($self);
    my $text  = $item->content->present($self);

    my $indent = ref $self ? \$self->{INDENT} : \$INDENT;
    my $pad = ' ' x $$indent;

    local $Text::Wrap::unexpand = 0;

    my $content =  wrap($pad, $pad, $text) . "\n";

    return "$title\n\n$content";

}

sub view_for {
    my ($self, $for) = @_;

    return '' unless $for->format() =~ /\btrac\b/;
    return $for->text() . "\n\n";

}

sub view_begin {
    my ($self, $begin) = @_;

    return '' unless $begin->format() =~ /\btrac\b/;
    return $begin->content->present($self);

}

sub view_textblock {
    my ($self, $text) = @_;

    $text =~ s/\s+/ /mg;

    my $pad = '';

    local $Text::Wrap::unexpand = 0;

    return wrap($pad, $pad, $text) . "\n\n";

}

sub view_verbatim {
    my ($self, $text) = @_;

    return "{{{\n$text\n}}}\n";

}

sub view_seq_bold {
    my ($self, $text) = @_;

    return "'''$text'''";

}

sub view_seq_italic {
    my ($self, $text) = @_;

    return "''$text''";

}

sub view_seq_code {
    my ($self, $text) = @_;

    my $output = "`$text`";

    return $output;

}

sub view_seq_file {
    my ($self, $text) = @_;

    return "source:$text";

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

sub view_seq_index {

    return '';

}

sub view_seq_link {
    my ($self, $link) = @_;

    # full-blown URL's are emitted as-is

    if ($link =~ /^\w+:\/\// ) {

        # check to see if there is title

        if (my ($text, $name) = $link =~ m/^(.*)\|(.*)/) {

            return "[$name $text]"; 

        }

        return $link;

    }

    # links to other modules are parsed out

    if (my ($text, $name) = $link =~ m/^(.*)\|(.*)/) {

        if ($name =~ /::/) {

            # make it wiki CamelCase link

            my @parts = split('::', $name);
            @parts = map {lc $_ } @parts;
            @parts = map {ucfirst $_} @parts;

            $name = join('', @parts);

        }

        return "[wiki:$name $text]"; 

    }

    # otherwise return it verbatim

    return "[wiki:$link]";

}

1;

__END__
  
=head1 NAME

Pod::POM::View::Trac - Convert POD to trac wiki markup

=head1 SYNOPSIS

This module inherits from L<Pod::POM::View::Text>.

This module will convert pod to the trac wiki format. The formatting is 
consistent with other wiki pages. The best usage of the module is to modify
pom2 to search for this module. Once that is done, then you can use this like 
this:

    # pom2 trac Pom::POD::View::Trac

=head1 METHODS

Please see L<Pom::POD::View> for complete documentation.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Pod::POM::View::Trac

=head1 SEE ALSO

=over 4

=item L<Pod::POM>

=item L<Pod::POM::View>

=item L<Pod::POM::View::Text>

=back

=head1 AUTHOR

Kevin L. Esteb, C<< <kevin at kesteb.us> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Kevin L. Esteb.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<Perl License|http://dev.perl.org/licenses/> for more information.

=cut
