# $Id: /mirror/Senna-Perl/lib/Senna/Snippet.pm 2832 2006-08-24T05:08:04.287241Z daisuke  $
#
# Copyright (c) 2005-2006 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package Senna::Snippet;
use strict;
use Senna;

*new = \&open;
sub open
{
    my $class = shift;
    my %args  = @_;

    $args{default_open_tag} ||= '{';
    $args{default_close_tag} ||= '}';
    $args{width} ||= 200;
    $args{max_results} ||= 3;
    $args{flags} ||= 0;
    if (! exists $args{mapping}) { $args{mapping} = -1 }

    $class->xs_open(@args{qw(encoding flags width max_results default_open_tag default_close_tag mapping)});
}

sub add_cond
{
    my $self = shift;
    my %args = @_;

    $args{keyword} || die "keyword must be specified";

    $self->xs_add_cond(@args{qw(keyword open_tag close_tag)});
}

sub exec
{
    my $self = shift;
    my %args = @_;

    $self->xs_exec(@args{qw(string)});
}

1;

__END__

=head1 NAME

Senna::Snippet - Wrapper Around sen_snip

=head1 SYNOPSIS

  use Senna::Constants qw(SEN_ENC_EUCJP);
  use Senna::Snippet;

  my $snip = Senna::Snippet->new(
    encoding    => SEN_ENC_EUCJP,
    width       => 100, # width of snippet
    max_results => 10, # max number of results returned on exec()
    default_open_tag => '<b>', # default '{'
    default_close_tag => '</b>'
  );

  $snip->add_cond(key => "poop", open_tag => "<s>", close_tag => "</s>");
  $snip->add_cond(...);

  my @text = $snip->exec( string => $text_to_be_snipped );

=head1 DESCRIPTION

Senna::Snippet allows you to extract out KWIC text, much like
how Google and other search engines hilight the queried text in the
search result.

=head1 METHODS

=head2 new

=head2 open

Alias to new().

=head2 add_cond

=head2 exec

=head1 AUTHOR

Copyright (C) 2005 - 2006 by Daisuke Maki <dmaki@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

Development funded by Brazil Ltd. E<lt>http://dev.razil.jp/project/senna/E<gt>

=cut
