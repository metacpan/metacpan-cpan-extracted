package SPOPS::Iterator::WrapList;

# $Id: WrapList.pm,v 3.4 2004/06/02 00:48:23 lachoy Exp $

use strict;
use base  qw( SPOPS::Iterator );
use Log::Log4perl qw( get_logger );

use SPOPS;
use SPOPS::Iterator qw( ITER_IS_DONE ITER_FINISHED );

my $log = get_logger();

$SPOPS::Iterator::WrapList::VERSION   = sprintf("%d.%02d", q$Revision: 3.4 $ =~ /(\d+)\.(\d+)/);

sub initialize {
    my ( $self, $p ) = @_;
    $self->{_WRAP_LIST}      = $p->{object_list};
    $self->{_WRAP_OFFSET}    = $p->{offset};
    $self->{_WRAP_MAX}       = $p->{max} || scalar @{ $p->{object_list} };
    $self->{_WRAP_COUNT}     = 1;
    $self->{_WRAP_RAW_COUNT} = 0;
}

sub fetch_object {
    my ( $self ) = @_;

    # If we're using min/max, check them

    if ( $self->{_WRAP_OFFSET} and
         ( $self->{_WRAP_COUNT} < $self->{_WRAP_OFFSET} ) ) {
        $self->{_WRAP_COUNT}++;
        $self->{_WRAP_RAW_COUNT}++;
        return $self->fetch_object;
    }

    # Oops, we've gone past the max. Finish up.

    if ( $self->{_WRAP_MAX} and
         ( $self->{_WRAP_COUNT} > $self->{_WRAP_MAX} ) ) {
        return ITER_IS_DONE;
    }

    my $send_idx = $self->{_WRAP_RAW_COUNT};
    $self->{_WRAP_COUNT}++;
    $self->{_WRAP_RAW_COUNT}++;
    return ( $self->{_WRAP_LIST}->[ $send_idx ], $self->{_WRAP_COUNT} );
}

sub finish {
    my ( $self ) = @_;
    $self->{_WRAP_LIST} = undef;
    return $self->{ ITER_FINISHED() } = 1;
}

1;

__END__

=pod

=head1 NAME

SPOPS::Iterator::WrapList - SPOPS::Iterator wrapper around object lists

=head1 SYNOPSIS

  my $list = My::SPOPS->fetch_group({
                             skip_security => 1,
                             where         => 'package = ?',
                             value         => [ 'base_theme' ],
                             order         => 'name' });
  my $iter = SPOPS::Iterator->from_list( $list );
  while ( $iter->has_next ) {
      my $template = $iter->get_next;
      print "Item ", $iter->position, ": $template->{package} / $template->{name}";
      print " (", $iter->is_first, ") (", $iter->is_last, ")\n";
  }

=head1 DESCRIPTION

This is an implementation of the L<SPOPS::Iterator|SPOPS::Iterator>
interface so that we can use a common interface no matter whether an
SPOPS implementation supports iterators or not. You can also ensure
that display or other classes can be coded to only one interface since
it is so simple to wrap a list in an iterator.

=head1 METHODS

B<initialize()>

B<fetch_object()>

B<finish()>

=head1 SEE ALSO

L<SPOPS::Iterator|SPOPS::Iterator>

L<SPOPS::DBI|SPOPS::DBI>

=head1 COPYRIGHT

Copyright (c) 2001-2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>

=cut
