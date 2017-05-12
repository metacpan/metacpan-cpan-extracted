package PPI::Document;
use strict;
use warnings;

sub index_offsets {
    my $self   = shift;
    my $offset = 0;
    foreach my $token ( $self->tokens ) {
        my $content = $token->content;
        my $length  = length($content);
        
        $token->{__start_offset} = $offset;
        $token->{__stop_offset}  = $offset + $length;
        $offset += $length;
    }
}

package PPI::Token;
use strict;
use warnings;

sub start_offset {
    my $self = shift;
    return $self->{__start_offset};
}

sub stop_offset {
    my $self = shift;
    return $self->{__stop_offset};
}

package PPIx::IndexOffsets;
use strict;
use warnings;
use PPI;
our $VERSION = '0.32';

1;

__END__

=head1 NAME

PPIx::IndexOffsets - Index offsets for tokens in PPI

=head1 SYNOPSIS

  my $document = PPI::Document->new( 'hello.pl' );
  $document->index_offsets;

  my @tokens = $document->tokens;
  foreach my $token (  $document->tokens  ) {
      my $start_offset = $token->start_offset;
      my $stop_offset  = $token->stop_offset;
      print "$start_offset .. $stop_offset $token\n";
  }

=head1 DESCRIPTION

L<PPIx::IndexOffsets> is a module which indexes the start and stop
offsets for all the tokens in a PPI document tree.

=head1 SEE ALSO

L<PPI>.

=head1 AUTHOR

Leon Brocard, C<< <acme@astray.com> >>

=head1 COPYRIGHT

Copyright (C) 2008, Leon Brocard

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

