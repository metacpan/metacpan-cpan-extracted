package MongoDBx::Tiny::Cursor;
use strict;

=head1 NAME

MongoDBx::Tiny::Cursor - wrapper class of MongoDB::Cursor

=cut

use Carp qw(confess);

=head1 SUBROUTINES/METHODS

=head2 new

  $cursor = MongoDBx::Tiny::Cursor->new(
      tiny => $tiny, c_name => $c_name,cursor => $cursor
  );

=cut

sub new {
    my $class  = shift;
    my %param  = @_;
    return bless \%param, $class;
}

=head2 all

  @list = $cursor->all;

=cut

sub all  {
    my $self = shift;
    return map { $self->{tiny}->document_to_object($self->{c_name},$_) } $self->{cursor}->all;
}

=head2 array

  @list = $cursor->array;
  $list = $cursor->array;

=cut

sub array {
    my $self = shift;
    return wantarray ? $self->all:[$self->all];
}

=head2 next

  # get next object 
  $object = $cursor->next;

=cut

sub next {
    my $self     = shift;
    my $document = $self->{cursor}->next;
    return unless $document;
    return $self->{tiny}->document_to_object($self->{c_name},$document);
}

=head2 first

  [EXPERIMENTAL]

  $first_object = $cursor->first; # just call next..

=cut

sub first {
    my $self = shift;
    # xxx
    $self->next;
}

sub AUTOLOAD {
    my $self = shift;
    # xxx
    my $method = our $AUTOLOAD;
    $method =~ s/.*:://o;
    if ($method =~ /^(fields|sort|limit|skip|snapshot|hint)$/) {
	$self->{cursor}->$method(@_);
	return $self;
    } else {
	return $self->{cursor}->$method(@_);
    }
}


sub DESTROY {}


1;
__END__

=head1 AUTHOR

Naoto ISHIKAWA, C<< <toona at seesaa.co.jp> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Naoto ISHIKAWA.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

