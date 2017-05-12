package Silki::HTML::FormatText;
{
  $Silki::HTML::FormatText::VERSION = '0.29';
}

use strict;
use warnings;

use base 'HTML::FormatText';

# If these subs don't return true, the formatter won't recurse into the node
# for text/etc.

sub a_start {
    my $self = shift;
    my $node = shift;

    $self->{uri_for_a} = $node->attr('href');

    return 1;
}

sub a_end {
    my $self = shift;
    my $node = shift;

    $self->out( ' (' . $self->{uri_for_a} . ')' )
        if $self->{uri_for_a};

    delete $self->{uri_for_a};

    return 1;
}

1;

# ABSTRACT: A subclass of HTML::FormatText that also handles links


__END__
=pod

=head1 NAME

Silki::HTML::FormatText - A subclass of HTML::FormatText that also handles links

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

