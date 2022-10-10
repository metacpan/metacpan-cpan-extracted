package Pod::LOL;

use 5.012;    # Pod::Simple, parent.
use strict;
use warnings;
use parent qw( Pod::Simple );
use Data::Dumper;

=head1 NAME

Pod::LOL - parse Pod into a list of lists (LOL)

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.11';
our $DEBUG   = 0;


=head1 SYNOPSIS

   % cat my.pod

   =head1 NAME

   Pod::LOL - parse Pod into a list of lists (LOL)


   % perl -MPod::LOL -MData::Dumper -e 'print Dumper( Pod::LOL->new_root("my.pod") )'

Returns:

   [
      [
         "head1",
         "NAME"
      ],
      [
         "Para",
         "Pod::LOL - parse Pod into a list of lists (LOL)"
      ],
   ]


=head1 DESCRIPTION

This class may be of interest to anyone writing a pod parser.

This module takes pod (as a file) and returns a list of lists (LOL) structure.

This is a subclass of L<Pod::Simple> and inherits all of its methods.

=head1 SUBROUTINES/METHODS

=head2 new_root

Convenience method to do (mostly) this:

   Pod::LOL->new->parse_file( $file )->{root};

=cut

sub new_root {
    my ( $class, $file ) = @_;
    if ( $DEBUG ) {
        printf STDERR "class=$class, file=$file, ref=%s\n", ref $file;
    }

    my $parser = $class->new;

    # Normally =for and =begin would otherwise be skipped.
    $parser->accept_targets( '*' );

    my $s = $parser->parse_file( $file );

    $s->{root};
}

=head2 _handle_element_start

Overrides Pod::Simple.
Executed when a new pod element starts such as:

   "head1"
   "Para"

=cut

sub _handle_element_start {
    my ( $s, $tag ) = @_;
    print STDERR "TAG_START: $tag" if $DEBUG;

    if ( $s->{_pos} ) {    # We already have a position.
        my $x =
          ( length( $tag ) == 1 ) ? [] : [$tag]; # Ignore single character tags.
        push @{ $s->{_pos}[0] }, $x;             # Append to root.
        unshift @{ $s->{_pos} }, $x;             # Set as current position.
    }
    else {
        my $x = [];
        $s->{root} = $x;                         # Set root.
        $s->{_pos} = [$x];                       # Set current position.
    }

    print STDERR "{_pos}: " . Dumper $s->{_pos} if $DEBUG;
}

=head2 _handle_text

Overrides Pod::Simple.
Executed for each text element such as:

   "NAME"
   "Pod::LOL - parse Pod into a list of lists (LOL)"

=cut

sub _handle_text {
    my ( $s, $text ) = @_;
    print STDERR "TEXT: $text" if $DEBUG;

    push @{ $s->{_pos}[0] }, $text;    # Add the new text.

    print STDERR "{_pos}: " . Dumper $s->{_pos} if $DEBUG;
}

=head2 _handle_element_end

Overrides Pod::Simple.
Executed when a pod element ends.
Such as when these tags end:

   "head1"
   "Para"

=cut

sub _handle_element_end {
    my ( $s, $tag ) = @_;
    print STDERR "TAG_END: $tag" if $DEBUG;
    shift @{ $s->{_pos} };

    if ( length $tag == 1 ) {

        # Single character tags (like L<>) should be on the same level as text.
        $s->{_pos}[0][-1] = join "", @{ $s->{_pos}[0][-1] };
        print STDERR "TAG_END_TEXT: @{[ $s->{_pos}[0][-1] ]}" if $DEBUG;
    }
    elsif ( $tag eq "Para" ) {

        # Should only have 2 elements: tag, entire text
        my ( $_tag, @text ) = @{ $s->{_pos}[0][-1] };
        my $text = join "", @text;
        @{ $s->{_pos}[0][-1] } = ( $_tag, $text );
    }

    print STDERR "{_pos}: " . Dumper $s->{_pos} if $DEBUG;
}


=head1 SEE ALSO

L<App::Pod>

L<Pod::Query>

L<Pod::Simple>


=head1 AUTHOR

Tim Potapov, C<< <tim.potapov[AT]gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/poti1/pod-lol/issues>.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Pod::LOL


You can also look for information at:

L<https://metacpan.org/pod/Pod::LOL>
L<https://github.com/poti1/pod-lol>


=head1 ACKNOWLEDGEMENTS

TBD

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by Tim Potapov.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;    # End of Pod::LOL
