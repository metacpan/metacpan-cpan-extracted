package PICA::Modification::Request;
{
  $PICA::Modification::Request::VERSION = '0.16';
}
#ABSTRACT: Request for modification of an identified PICA+ record

use strict;
use warnings;
use v5.10;

use parent 'PICA::Modification';
use Time::Stamp gmstamp => { format => 'easy', tz => '' };

our @ATTRIBUTES = qw(id iln epn del add request creator status updated created);

sub new {
    my $self = PICA::Modification::new( @_ );
    
	$self->{created} //= gmstamp;
    $self->{status}  //= 0;

    $self;
}

sub update {
	my ($self, $status) = @_;

	$self->{status}  = $status;
	$self->{updated} = gmstamp;
}

1;



__END__
=pod

=head1 NAME

PICA::Modification::Request - Request for modification of an identified PICA+ record

=head1 VERSION

version 0.16

=head1 DESCRIPTION

PICA::Modification::Request extends L<PICA::Modification> with the following
attributes:

=over 4

=item request

Unique identifier of the request.

=item creator

Optional string to identify the creator of the request.

=item status

Status of the modification requests, which is 0 for unprocessed, 1 for
applied, and -1 for rejected.

=item created

Timestamp when the modification request was created (set automatically).

=item updated

Timestamp when the modification request was last updated (set automatically).

=back

All timestamps are GMT with format C<YYYY-MM-DD HH:MM::SS>.

=head1 METHODS

=head2 update ( $status )

Updates the status and sets the updated timestamp.

=encoding utf-8

=head1 AUTHOR

Jakob Voß <voss@gbv.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

