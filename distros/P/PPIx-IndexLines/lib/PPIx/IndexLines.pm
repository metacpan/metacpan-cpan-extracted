package PPIx::IndexLines;

# ABSTRACT: Given a line number, returns some basic information about where in the perl document you are

use strict;

use PPI;
use Scalar::Util 'blessed';

our $VERSION = 0.05;  # VERSION

sub new { bless { 'document' => PPI::Document->new( $_[ 1 ] ) }, $_[ 0 ] }

sub index_lines {

  my $self     = shift;
  my $document = $self->{ 'document' };

  my $package = 'main';
  my $info;

  my %lookup = (

    'PPI::Statement::Data'      => sub { '__DATA__' },
    'PPI::Statement::End'       => sub { '__END__' },
    'PPI::Statement::Package'   => sub { $package = $_[ 0 ]->namespace },
    'PPI::Statement::Scheduled' => sub { $_[ 0 ]->type },
    'PPI::Statement::Sub'       => sub { sprintf '%s::%s', $package, $_[ 0 ]->name },

    # Is this interesting enough to include?
    #'PPI::Token::Comment'       => sub { sprintf '%s (%s)', $package, 'comment' },

    'PPI::Token::Pod' => sub { 'POD' },

  );

  my $last_line_number = 0;

  for my $e ( $document->elements ) {

    my $line_number = $e->line_number;

    next if exists $self->{ 'line' }{ $line_number };

    $self->{ 'line' }{ $_ } = $info for $last_line_number + 1 .. $line_number - 1;

    $last_line_number = $line_number;

    my $node_type = ref $e;

    $self->{ 'line' }{ $line_number } = $info = exists $lookup{ $node_type } ? $lookup{ $node_type }->( $e ) : $package;

  }
} ## end sub index_lines

sub line_type { $_[ 0 ]->{ 'line' }{ $_[ 1 ] } || '' }

1;

__END__

=pod

=head1 NAME

PPIx::IndexLines - Given a line number, returns some basic information about where in the perl document you are

=head1 VERSION

version 0.05

=head1 SYNOPSIS

  #!/usr/bin/perl
  use strict;
  use warnings;
  use PPIx::IndexLines;
  my $document = PPIx::IndexLines->new( +shift );
  $document->index_lines;
  print $document->line_type( +shift );

=head1 METHODS

=head2 new

Accepts either a scalar or a scalar reference.  This is passed directly to
PPI::Document::new, so the same rules as in that method apply.

Basically, if you pass in a scalar, it will be assumed to be a filename and
said file will be loaded and parsed.

Otherwise, a scalar reference is assumed to be a PPI document and will be
parsed directly.

=head2 index_lines

Call this method to index the lines for the new PPI::Document.

=head2 line_type

Call this method with a line number, it will return one of

  BEGIN CHECK UNITCHECK INIT END POD __DATA__ __END__

or

  <PackageName>::<SubName>

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<PPIx::IndexOffsets>

=item *

L<PPIx::LineToSub>

=back

=head1 AUTHOR

Alan Young <harleypig@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alan Young.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
