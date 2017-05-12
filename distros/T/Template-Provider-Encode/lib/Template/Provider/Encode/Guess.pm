package Template::Provider::Encode::Guess;
use strict;
use warnings;

use base qw(Template::Provider);
use Encode;
use Encode::Guess;

our $VERSION = '0.02';
our $OUTPUT_ENCODING;
our @SUSPECTS;

sub new {
    my $class = shift;
    my $options = shift;

    $OUTPUT_ENCODING  = exists $options->{oe} ? $options->{oe} : undef; 
    delete $options->{oe};

    return $class->SUPER::new($options);
}

sub _load {
    my $self = shift;
    my ($data, $error) = $self->SUPER::_load(@_);

    unless ($OUTPUT_ENCODING and @SUSPECTS) {
        return ($data, $error);
    }

    my $enc = guess_encoding($data->{text}, @SUSPECTS);

    unless ( ref($enc) ) {
        return ($data, $error);
    }

    Encode::from_to($data->{text}, $enc->name, $OUTPUT_ENCODING );

    return ($data, $error);
}

sub import {
    my $pack = shift;
    @SUSPECTS = @_;
}
1;
__END__

=head1 NAME

Template::Provider::Encode::Guess - Encode templates by guessing for Template Toolkit

=head1 SYNOPSIS

  use Template::Provider::Encode::Guess qw/shiftjis euc-jp/;
  use Template;
  my $tt = Template->new(
      LOAD_TEMPLATES => [Template::Provider::Encode->new({oe => 'utf-8'})]
  );
  my $author = "\xe3\x81\x9b\xe3\x81\x8d\xe3\x82\x80\xe3\x82\x89";
  $tt->process('t/tmpl/SJIS.tt2', {author => $author});

=head1 DESCRIPTION

TWB

=head1 SEE ALSO

L<Encode>, L<Encode::Guess>, L<Template::Provider>

=head1 AUTHOR

Masayoshi Sekimura, E<lt>sekimura at gmail dot comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Masayoshi Sekimura

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
