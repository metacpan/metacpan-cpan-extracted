package TM::Synchronizable::MLDBM;

use Class::Trait 'base';
use Class::Trait 'TM::Synchronizable';

use Data::Dumper;

use MLDBM qw(MLDBM::Sync::SDBM_File Storable);
use MLDBM::Sync;
use Fcntl qw(:DEFAULT);

=pod

=head1 NAME

TM::Synchronizable::MLDBM - Topic Maps, trait for DBM Storage, synchronous

=head1 DESCRIPTION

This package subclasses L<TM::Synchronizable> with a MLDBM store.  The methods C<source_in> and
C<source_out> do the obvious things of copying between the DBM file and the in-memory
representation. Only during the synchronisation the DBM file is locked. Otherwise the two copies are
independent.  The synchronisation is quite performant, certainly faster than using a text
representation of the map.

=cut

sub source_in {
    my $self = shift;
    my $url  = $self->url;
    $TM::log->logdie (scalar __PACKAGE__ . ": url '$url' is not pointing to a file") unless $url =~ /^file:/;
    (my $filename = $self->url) =~ s/^file://;                                     # get rid of this
#warn "source in  '$filename'";
    my %map;
    my $sync_dbm = tie %map, 'MLDBM::Sync', $filename, O_RDWR|O_CREAT, 0600 or $TM::log->logdie (scalar __PACKAGE__ .": $!");
    $sync_dbm->Lock;
    %{$self} = %{$map{data}};
    $sync_dbm->UnLock;
}

sub source_out {
    my $self = shift;
    my $url  = $self->url;
    $TM::log->logdie (scalar __PACKAGE__ . ": url '$url' is not pointing to a file") unless $url =~ /^file:/;
    (my $filename = $self->url) =~ s/^file://;                                     # get rid of this
#warn "source out  '$filename'";
    my %map;
    my $sync_dbm = tie %map, 'MLDBM::Sync', $filename, O_CREAT|O_RDWR, 0600 or $TM::log->logdie (scalar __PACKAGE__ .": $!");
    $sync_dbm->Lock;
    $map{data} = $self;
    $sync_dbm->UnLock;
}

=pod

=head1 SEE ALSO

L<TM::ResourceAble>, L<TM::Synchronizable>

=head1 AUTHOR INFORMATION

Copyright 200[68], Robert Barta <drrho@cpan.org>, All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.  http://www.perl.com/perl/misc/Artistic.html

=cut

our $VERSION  = '0.03';
our $REVISION = '$Id$';

1;

__END__
