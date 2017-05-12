package Pod::Simple::Text::Termcap;

use warnings;
use strict;

use Pod::Simple::Text ();
use Term::Cap;
use vars qw/@ISA $VERSION %BOLD %ITALIC/;
@ISA     = qw(Pod::Simple::Text);
$VERSION = '0.01';
@BOLD{qw/B head1 head2 head3 head4/} = ();
@ITALIC{qw/F I/}                     = ();

sub _handle_element_start {
    my ( $parser, $element_name, $attr_hash_r ) = @_;
    my $self = shift;
  my @ret  = wantarray
    ? $self->SUPER::_handle_element_start(@_)
    : scalar( $self->SUPER::_handle_element_start(@_) );
    $self->{'Thispara'} .= $self->{_BOLD} if exists $BOLD{$element_name};
    $self->{'Thispara'} .= $self->{_UNDL} if exists $ITALIC{$element_name};
    return @ret;
}

sub _handle_element_end {
    my ( $parser, $element_name ) = @_;
    $_[0]->{'Thispara'} .= $_[0]->{_NORM}
    if exists $BOLD{$element_name} || exists $ITALIC{$element_name};
    goto \&{ $_[0]->can('SUPER::_handle_element_end') };
}

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    bless $self, $class;

  # Fall back on the ANSI escape sequences if Term::Cap doesn't work.
    my $term;
    eval { $term = Tgetent Term::Cap { TERM => undef, OSPEED => 9600 } };
    $$self{_BOLD} = $$term{_md} || "\e[1m";
    $$self{_UNDL} = $$term{_us} || "\e[4m";
    $$self{_NORM} = $$term{_me} || "\e[m";

    $self;
}

=head1 NAME

Pod::Simple::Text::Termcap - Convert POD data to ASCII text with format escapes

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Convert POD data to ASCII text with format escapes

  ( my $pod_text = <<'__POD__' ) =~ s/^[ \t]+//mg;
    =head1 Some pod

    F<foo> bla bla B<bar>
    Some more text

    =cut
  __POD__

  #
  use Pod::Simple::Text::Termcap;
  my $parser = Pod::Simple::Text::Termcap->new;
  $parser->parse_string_document( $pod_text);
  $parser->output_string( \my $out );
  print($out);


  # use it as a filter
  use Pod::Simple::Text::Termcap;
  Pod::Simple::Text::Termcap->filter( \$pod_text );

=head1 DESCRIPTION

C<Pod::Simple::Text::Termcap> is a subclass of C<Pod::Simple::Text>. 
This module is just a drop in replacement for Pod::Simple::Text.
C<Pod::Simple::Text::Termcap> prints headlines and C<< BE<lt>E<gt> >> tags
bold. C<< IE<lt>E<gt> >> and C<< FE<lt>E<gt> >> tags are underlined.

Thats all. Pretty close to what C<Pod::Text::Termcap> do for C<Pod::Text>.

=head1 NOTES

This module uses Term::Cap to retrieve the formatting escape sequences
for the current terminal, and falls back on the ECMA-48 (the same in
this regard as ANSI X3.64 and ISO 6429, the escape codes also used by
DEC VT100 terminals) if the bold, underline, and reset codes aren't set
in the termcap information.

=head1 SEE ALSO

C<Pod::Simple>, C<Pod::Simple::Text>, C<Pod::Text>, C<Pod::Text::Termcap>

=head1 EXPORT

Nothing

=head1 AUTHOR

Boris Zentner, C<< <bzm@2bz.de> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-pod-simple-text-termcap@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Pod-Simple-Text-Termcap>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Parts stolen from Russ Allbery's C<Pod::Text::Termcap>. 

=head1 COPYRIGHT & LICENSE

Copyright 2005 Boris Zentner, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Pod::Simple::Text::Termcap
