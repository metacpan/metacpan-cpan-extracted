# $Id: /mirror/Senna-Perl/lib/Senna/Index.pm 6103 2007-03-16T16:45:50.914799Z daisuke  $
#
# Copyright (c) 2005-2006 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package Senna::Index;
use strict;
use Senna;
use Senna::Constants;

BEGIN
{
    my @methods = qw(key_size flags initial_n_segments encoding nrecords_keys file_size_keys nrecords_lexicon file_size_lexicon inv_seg_size inv_chunk_size);
    foreach my $i (0.. $#methods) {
        my $code = sprintf(<<'        EOSUB', $methods[$i], $i);
            sub %s {
                my $self = shift;
                return ($self->info)[%d];
            }
        EOSUB

        eval $code;
        die if $@;
    }
}

sub create
{
    my $class = shift;
    my %args  = @_;

    $args{key_size} ||= &Senna::Constants::SEN_VARCHAR_KEY;
    $args{flags} ||= 0;
    $args{initial_n_segments} ||= 0;
    $args{encoding} ||= &Senna::Constants::SEN_ENC_DEFAULT;

    $class->xs_create(@args{qw(path key_size flags initial_n_segments encoding)});
}

sub open
{
    my $class = shift;
    my %args  = @_;

    $class->xs_open($args{path});
}

sub rename
{
    my $self = shift;
    my %args = @_;

    $args{path} || Carp::croak("path required for rename()");
    $self->xs_rename(@args{qw(path)});
}

sub select
{
    my $self = shift;
    my %args = (query => undef, records => undef, op => undef, optarg => undef, @_);

    $args{query} || Carp::croak("query required for select");
    $self->xs_select(@args{qw(query records op optarg)});
}

sub update
{
    my $self = shift;
    my %args = (key => undef, old => undef, new => undef, section => 0, @_);

    # Call xs_update if using Senna::Values
    if (eval {
            (defined $args{old} ? $args{old}->isa('Senna::Values') : 1) && 
            (defined $args{new} ? $args{new}->isa('Senna::Values') : 1)
    }) {
        $self->xs_update(@args{qw(key section old new)});
    } else {
        $self->xs_upd(@args{qw(key old new)});
    }
}

sub insert
{
    my $self = shift;
    my %args = @_;
    $self->update(
        key => $args{key},
        new => $args{value},
        old => undef,
    );
}

sub delete 
{
    my $self = shift;
    my %args = @_;
    $self->update(
        key => $args{key},
        old => $args{value}
    );
}

# XXX - Naming?
sub query_exec
{
    my $self = shift;
    my %args = @_;
    $self->xs_query_exec(@args{qw(query op)});
}


sub DESTROY {
    my $self = shift;
    $self->close();
}

1;

__END__

=head1 NAME

Senna::Index - Interface to Senna's Index

=head1 SYNOPSIS

  use Senna::Index;

  my $index = Senna::Index->new(path => '/path/to/index');
  # $index = Senna::Index->open(pth => '/path/to/index');

  $rc = $index->insert(key => $key, value => $new);
  $rc = $index->delete(key => $key, value => $old_value);
  $rc = $index->update(key => $key, new => $new, old => $old, section => $s);

  $path = $index->path;

  my ($key_size, $flags, $initial_n_segments, $encoding,
      $nrecords_keys, $file_size_keys, $nrecords_lexicon,
      $file_size_lexicon, $inv_seg_size, $inv_chunk_size) = 
        $index->info;

  $index->key_size;
  $index->flags;
  $index->initial_n_segments;
  $index->encoding;
  $index->nrecords_keys;
  $index->file_size_keys;
  $index->nrecords_lexicon;
  $index->file_size_lexicon;
  $index->inv_seg_size;
  $index->inv_chunk_size;

  $index->close;
  $index->remove;

=head1 DESCRIPTION

Senna::Index is an interface to the index struct in Senna (http://qwik.jp/senna).

=head1 METHODS

=head2 delete

=head2 file_size_keys

=head2 file_size_lexicon

=head2 info

=head2 insert

=head2 inv_chunk_size

=head2 inv_seg_size

=head2 nrecords_keys

=head2 nrecords_lexicon

=head2 path

=head2 query_exec

=head2 rename

=head2 select

=head2 update

=head2 close

=head2 create

=head2 encoding

=head2 flags

=head2 initial_n_segments

=head2 key_size

=head2 open

=head2 remove

=head1 AUTHOR

Copyright (C) 2005-2006 by Daisuke Maki <dmaki@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

Development funded by Brazil Ltd. E<lt>http://qwik.jp/senna/E<gt>

=head1 SEE ALSO

http://qwik.jp/senna - Senna Development Homepage

=cut