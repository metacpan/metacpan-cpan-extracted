#!/usr/bin/perl

package StupidMarkov;

use strict;
use warnings;

our $VERSION = "0.002";


sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {
        "_probabilities" => {},
        "_prev_item" => undef,
        "_first_item" => undef,
        "_item_count" => 0,
        "_state" => undef,
    };

    bless $self, $class;
}

sub get_item_count {
    my $self = shift;
    return $self->{"_item_count"};
}

sub get_probabilities {
    my $self = shift;
    return $self->{"_probabilities"};
}

sub get_state {
    my $self = shift;
    return $self->{"_state"};
}

sub add_item {
    my $self = shift;
    my $item = shift;
    my $prev_item = $self->{"_prev_item"};
    my $probabilities = $self->{"_probabilities"};

    if (defined($prev_item)) {
        if (!defined($probabilities->{$prev_item})) {
            $probabilities->{$prev_item} = { $item => 1 };
        } else {
            $probabilities->{$prev_item}->{$item}++;
        }
    } else {
        $self->{"_first_item"} = $item;
    }

    $self->{"_prev_item"} = $item;
    $self->{"_item_count"}++;
}

sub _get_probable_next_item {
    my $self = shift;
    my $state = $self->{"_state"};
    my $probabilities = $self->{"_probabilities"};
    my $items = [];

    foreach my $next_state (keys(%{$probabilities->{$state}})) {
        foreach (0 .. $probabilities->{$state}->{$next_state}) {
            push(@{$items}, $next_state);
        }
    }

    return $items->[int(rand(@{$items}))];
}

sub get_next_item {
    my $self = shift;
    my $ext_state = shift;
    my $probabilities = $self->{"_probabilities"};

    if (defined($ext_state)) {
        return undef if (!defined($probabilities->{$ext_state}));
        $self->{"_state"} = $ext_state if (!defined($self->{"_state"}));
    } elsif (!defined($self->{"_state"})) {
        $self->{"_state"} = $self->{"_first_item"};
    }

    $self->{"_state"} = $self->_get_probable_next_item();
    return $self->{"_state"};
}


1;
__END__


=head1 NAME

StupidMarkov - A stupid Markov chain implementation.

=head1 SYNOPSIS

  use StupidMarkov;

  my $mm = StupidMarkov->new();

  while (my $line = <>) {
      chomp $line;
      next if !defined $line;

      foreach my $word (split(/ /, $line)) {
          $mm->add_item($word);
      }
  }

  print $mm->get_next_item(), " " for (0 .. $mm->get_item_count());

=head1 DESCRIPTION

BIG FAT NOTE: THIS IS A /REALLY/ STUPID IMPLEMENTATION! It works (for
the most part) for me. I didn't write it to be a complete
implementation, or even a sane one. If you're looking for something
other than a toy, please check the SEE ALSO section for ideas, or
search CPAN for something else. =o)

StupidMarkov is a really simply and really stupid implementaiton of a
Markov chain that I wrote in a fit of insomnia at midnight, after
realizing I'd never understood what a Markov chain was, spending five
minutes reading the Wikipedia entry on it, and then taking ten minutes
to implement it. The output using the above synopsis and this
paragraph results in output like the following:

  "is a fit of insomnia at midnight, after realizing I'd never
  understood what a really stupid implementaiton of insomnia at
  midnight, after realizing I'd never understood what a Markov chain
  that I wrote in a Markov chain that I wrote in a Markov chain that I
  wrote in output like the Wikipedia entry on it, and this paragraph
  results in a Markov chain that I wrote"

=head1 METHODS

=over 4

=item new

Create a new StupidMarkov chain.

=item get_item_count

Return the number of items that have been added to the chain. Note
that this number is cumulative, and does not count uniqueness.

=item get_probabilities

Return a reference to the internal probability hash of items to
hash of next items to integer probabilities. Probably not very
useful.

=item get_state

Return the current item that is used as the internal state.

=item add_item

Add an item to the Markov chain.

=item get_next_item

Generate the next item in the Markov chain. Takes an optional argument
that represents the start state. If no argument is provided, the first
item passed to add_item is used instead.

=back

=head1 REFERENCES

Wikipedia: http://en.wikipedia.org/Markov_chain

=head1 REVISION HISTORY

=over 8

=item 0.002

2009-05-10: Integrating apeiron's camel case is evil patch. Note that
this represents an API change.

=item 0.001

2009-05-02: First implementation and insomnia effect.

=back

=head1 SEE ALSO

Please consider using the below, as they are much better
implementations than StupidMarkov could ever hope to be.

=over 4

=item Decision::Markov

=item Algorithm::MarkovChain

=item Algorithm::MarkovChain::GHash

=back

=head1 AUTHOR

June R. Tate-Gans C<< <june@theonelab.com> >>

=head1 LICENSE

Copyright 2009 June R. Tate-Gans, all rights reserved.

StupidMarkov is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNEESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details. 

You should have recieved a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
USA.

=head1 BUGS

Please report any bugs or feature requests to C<bug-stupidmarkov at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=StupidMarkov>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc StupidMarkov

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=StupidMarkov>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/StupidMarkov>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/StupidMarkov>

=item * Search CPAN

L<http://search.cpan.org/dist/StupidMarkov>

=back

=cut
