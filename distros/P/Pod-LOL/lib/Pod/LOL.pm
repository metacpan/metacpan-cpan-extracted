package Pod::LOL;

use 5.030;
use strict;
use warnings;
use Mojo::Base qw/ -base Pod::Simple -signatures /;
use Mojo::Util qw/ dumper /;

=head1 NAME

Pod::LOL - Transform POD into a list of lists

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';
our $DEBUG   = 0;

has [qw/ _pos root /];

=head1 SYNOPSIS

Transform POD into a list of lists (lol)

   use Pod::LOL;
	my $lol = Pod::LOL->new->parse_file($path)->root;

$lol contains:

    [
	  [
	    "head1",
	    "NAME"
	  ],
	  [
	    "Para",
	    "Pod::LOL - Transform POD into a list of lists"
	  ],
	  [
	    "head1",
	    "VERSION"
	  ],
	  ...
	],

Inline (Debugging)

    perl -Ilib -MPod::LOL -MMojo::Util=dumper -E "say dumper(Pod::LOL->new->parse_file('lib/Pod/LOL.pm')->root)"

=head1 DESCRIPTION

This module takes a path a extracts the pod information
into a list of lists.

=head1 METHODS

This module overwrites the following methods
from Pod::Simple:

=head2 _handle_element_start

Executed when a new pod element starts.

=cut

sub _handle_element_start ( $s, $tag, $attr ) {
   $DEBUG and say "TAG_START: $tag";

   if ( $s->_pos ) {
      my $x =
        ( length( $tag ) == 1 ) ? [] : [$tag];    # Ignore single character tags
      push $s->_pos->[0]->@*, $x;                 # Append to root
      unshift $s->_pos->@*, $x;                   # Set as current position
   }
   else {
      my $x = [];
      $s->root( $x );                             # Set root
      $s->_pos( [$x] );                           # Set current position
   }

   $DEBUG and say "_pos: ", dumper $s->_pos;
}

=head2 _handle_text

Executed for each text element.

=cut

sub _handle_text ( $s, $text ) {
   $DEBUG and say "TEXT: $text";

   push $s->_pos->[0]->@*, $text;    # Add text

   $DEBUG and say "_pos: ", dumper $s->_pos;
}

=head2 _handle_element_end

Executed when a pod element ends.

=cut

sub _handle_element_end {
   my ( $s, $tag ) = @_;
   $DEBUG and say "TAG_END: $tag";
   shift $s->_pos->@*;

   if ( length $tag == 1 ) {

      # Single character tags (like L<>) should be on the same level as text.
      $s->_pos->[0][-1] = join "", $s->_pos->[0][-1]->@*;
      $DEBUG and say "TAG_END_TEXT: @{[ $s->_pos->[0][-1] ]}";
   }
   elsif ( $tag eq "Para" ) {

      # Should only have 2 elements: tag, entire text
      my ( $_tag, @text ) = $s->_pos->[0][-1]->@*;
      my $text = join "", @text;
      $s->_pos->[0][-1]->@* = ( $_tag, $text );
   }

   $DEBUG and say "_pos: ", dumper $s->_pos;
}

=head1 SEE ALSO

L<Module::Functions>

=head1 AUTHOR

Tim Potapov, C<< <tim.potapov[AT]gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-pod-lol at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Pod-LOL>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Pod::LOL

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Pod-LOL>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Pod-LOL>

=item * Search CPAN

L<https://metacpan.org/release/Pod-LOL>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by Tim Potapov.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;    # End of Pod::LOL
