package Regexp::Chinese::TradSimp;

use strict;

use Encode::HanConvert;

our $VERSION = '0.01';

=encoding utf8

=head1 NAME

Regexp::Chinese::TradSimp - Take a string containing Chinese text, and turn it
into a traditional-simplified-insensitive regexp.

=head1 SYNOPSIS

  #!/usr/bin/perl -w
  use strict;
  use utf8;

  my $regexp = Regexp::Chinese::TradSimp->make_regexp( "鳳爪" );

  my $text = "豉汁蒸凤爪";
  if ( $text =~ $regexp ) {
    print "Chicken feet detected!\n";
  }

  # Alternatively:
  my $tradsimp = Regexp::Chinese::TradSimp->new;
  my $regexp = $tradsimp->make_regexp( "鳳爪" );

=head1 DESCRIPTION

Given a string containing Chinese text, transforms it into a regexp that can
be used to match both the simplified and the traditional version of the
text.  The distribution also includes a commandline tool, C<dets>
(B<de>sensitise B<t>raditional-B<s>implified).

=head1 METHODS

=over

=item B<make_regexp>

  # This returns /[凤鳳]爪/.
  my $regexp = Regexp::Chinese::TradSimp->make_regexp( "鳳爪" );

  # This returns /[水虾蝦][饺餃]/
  my $regexp = Regexp::Chinese::TradSimp->make_regexp( "[水蝦]餃" );

  # This returns /([虾蝦]|[带帶]子)[饺餃]/
  my $regexp = Regexp::Chinese::TradSimp->make_regexp( "(虾|带子)饺" );

C<make_regexp> attempts to create a regular expression that will match its
argument in a traditional-simplified-insensitive way.  The argument should
be a string of Chinese characters, but you can include certain other aspects
of regular expressions such as character classes and bracketed groupings.
Arguments of forms other than those shown above are not guaranteed to work.

=item B<desensitise>

Does exactly the same as C<make_regexp> but returns a string instead of a
regexp, e.g. "[凤鳳]爪" rather than /[凤鳳]爪/.

We are also -ise/-ize agnostic:

  # These do the same thing.
  my $regexp = $tradsimp->desensitise( qr/叉燒包/ );
  my $regexp = $tradsimp->desensitize( qr/叉燒包/ );

=back

=cut

sub new {
    my ( $class, @args ) = @_;
    my $self = { };
    bless $self, $class;
    return $self;
}

sub desensitise {
    my $self = shift;
    my $text = shift;
    my ( @characters, $inclass );

    foreach my $character ( split //, $text ) {
        # This is hairy and fragile.
        if ( $character eq "[" ) {
            $inclass++;
        } elsif ( $character eq "]" ) {
            $inclass--;
        }
        my $trad = trad_to_simp( $character );
        my $simp = simp_to_trad( $character );
        if ( $trad eq $simp ) {
            push @characters, $character;
        } elsif ( $inclass ) {
            push @characters, "$trad$simp";
        } else {
            push @characters, "[$trad$simp]";
        }
    }

    $text = join( "", @characters );
    return $text;
}

sub desensitize {
    return desensitise( @_ );
}

sub make_regexp {
    my $text = desensitise( @_ );
    return qr/$text/;
}

=head1 AUTHOR

Kake L Pugh <kake@earth.li>

=head1 COPYRIGHT

Copyright (C) 2010 Kake L Pugh.  All Rights Reserved.

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
