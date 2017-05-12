package Template::Provider::Encode;
use strict;
use warnings;

use base qw(Template::Provider);
use Encode;

our $VERSION = '0.02';
our $INPUT_ENCODING;
our $OUTPUT_ENCODING;

sub new {
    my $class = shift;
    my $options = shift;

    $INPUT_ENCODING  = exists $options->{ie} ? $options->{ie} : undef; 
    $OUTPUT_ENCODING = exists $options->{oe} ? $options->{oe} : undef; 
    delete $options->{ie};
    delete $options->{oe};

    return $class->SUPER::new($options);
}

sub _load {
    my $self = shift;
    my ($data, $error) = $self->SUPER::_load(@_);

    if ($INPUT_ENCODING and $OUTPUT_ENCODING) {
        Encode::from_to($data->{text}, $INPUT_ENCODING, $OUTPUT_ENCODING );
    }

    return ($data, $error);
}

1;
__END__

=head1 NAME

Template::Provider::Encode - Encode templates for Template Toolkit

=head1 SYNOPSIS

  use Template::Provider::Encode;
  use Template;
  my $tt = Template->new(
      LOAD_TEMPLATES => [Template::Provider::Encode::UTF8->new({ie=>'shiftjis'
                                                                oe=>'utf8'})]
  );
  my $author = "\xe3\x81\x9b\xe3\x81\x8d\xe3\x82\x80\xe3\x82\x89";
  $tt->process('t/tmpl/SJIS.tt2', {author => $author});

=head1 DESCRIPTION

TBW

=head1 SEE ALSO

L<Encode>, L<Template::Provider>

=head1 AUTHOR

Masayoshi Sekimura, E<lt>sekimura at gmail dot comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Masayoshi Sekimura

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
