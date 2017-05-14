# $Id: /mirror/Senna-Perl/lib/Senna/Record.pm 2879 2006-08-31T03:08:01.291533Z daisuke  $
#
# Copyright (c) 2005-2006 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package Senna::Record;
use strict;

sub new
{
    my $class = shift;
    my %args  = @_;

    my %hash;
    foreach my $k qw(key score pos section n_subrecs) {
        $hash{$k} = $args{$k};
    }
    my $self = bless \%hash, $class;
    return $self;
}

sub _elem
{
    my $self  = shift;
    my $field = shift;
    my $old  = $self->{$field};
    if (@_) {
        $self->{$field} = shift @_;
    }
    return $old;
}

sub key       { shift->_elem('key', @_) }
sub score     { shift->_elem('score', @_) }
sub pos       { shift->_elem('pos', @_) }
sub section   { shift->_elem('section', @_) }
sub n_subrecs { shift->_elem('n_subrecs', @_) }

1;

__END__

=head1 NAME

Senna::Record - Senna Search Record 

=head1 SYNOPSIS

  my $r = $cursor->next;
  $r->key;
  $r->score;
  $r->pos;
  $r->section;
  $r->n_subrecs;

=head1 DESCRIPTION

Senna::Record represents a single Senna search result.

=head1 METHODS

=head2 new

Create a new Senna::Record object. You normally do not need to call this
yourself, as a result object will be returned from a Senna::Cursor.

=head2 key

Returns the key value of the search hit.

=head2 score

Returns the score of the search hit.

=head2 pos

=head2 section

=head2 n_subrecs

=head1 AUTHOR

Copyright (C) 2005 by Daisuke Maki <dmaki@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

Development funded by Brazil Ltd. E<lt>http://dev.razil.jp/project/senna/E<gt>

=cut