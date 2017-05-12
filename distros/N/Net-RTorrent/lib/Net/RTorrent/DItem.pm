#$Id: DItem.pm 355 2008-10-05 11:20:30Z zag $

package Net::RTorrent::DItem;

=head1 NAME

Net::RTorrent::DItem - Class of rtorrent item.

=head1 SYNOPSIS

  my $obj =  new Net::RTorrent:: 'http://10.100.0.1:8080/scgitest';
  my $dloads = $obj->get_downloads('complete');
  my $keys = $dloads->list_ids;
  my $ditem = $dloads->get_one( $key);
  if ( $ditem->attr->{left_bytes} ) {
    $ditem->stop
  }


=head1 ABSTRACT
 
Net::RTorrent::DItem - Class of rtorrent item.

=head1 DESCRIPTION

Net::RTorrent::DItem - Class of rtorrent item.

=cut

use strict;
use warnings;
use Carp;
use Data::Dumper;
use Collection::Utl::Base;
use Collection::Utl::Item;
use 5.005;
__PACKAGE__->attributes(qw / _cli/);
our @ISA     = qw(Collection::Utl::Item);
our $VERSION = '0.01';
sub _changed { return 0 }

=head1 METHODS

=cut

=head2  attr

Attributes for torrent.

=cut

sub attr {
    return $_[0]->_attr;
}

sub init {
    my $self = shift;
    $self->_cli(shift);
    return $self->SUPER::init(@_);
}

=head2 stop

Stop torrent

=cut

sub stop {
    my $self = shift;
    $self->_cli->send_request();
}

1;
__END__

=head1 SEE ALSO

Collection::Utl::Item

=head1 AUTHOR

Zahatski Aliaksandr, E<lt>zag@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
