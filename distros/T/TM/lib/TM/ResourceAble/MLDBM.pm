package TM::ResourceAble::MLDBM;

use TM;
use base qw (TM);
use Class::Trait qw(TM::ResourceAble);

use Data::Dumper;

use BerkeleyDB ;
use MLDBM qw(BerkeleyDB::Hash Storable) ;
#use MLDBM qw(BerkeleyDB::Hash Data::Dumper) ;
#use MLDBM qw(BerkeleyDB::Hash Data::Dumper) ;
use Fcntl;

=pod

=head1 NAME

TM::ResourceAble::MLDBM - Topic Maps, DBM Storage (synchronous)

=head1 SYNOPSIS

    use TM::ResourceAble::MLDBM;
   {
    my $tm = new TM::ResourceAble::MLDBM (file => '/tmp/map.dbm');
    # modify the map here.....

    } # it goes out of scope here, and all changes are written back automagically

   # later in the game
   {
    my $tm = new TM::ResourceAble::MLDBM (file => '/tmp/map.dbm');
    # we are back in business, no sync necessary
    }

=head1 DESCRIPTION

This package just implements L<TM> with a BerkeleyDB store. Unlike L<TM::Materialized::MLDBM> this
module does not need explicit synchronisation with the external resource (the DBM file here).  It
ties content-wise with the DBM file at constructor time and unties at DESTROY time.

This implementation technique is not so memory-efficient as I had thought. Whenever an assertion
or a toplet is referenced, the whole block of toplets, resp. assertions, is loaded from the DB database.
For small maps this is really fast, but it can become a drag for larger maps. See L<TM::ResourceAble::BDB>
for a more efficient solution.

B<NOTE>: Be careful to use this together with L<TM::Index::*>. The indices will be held as part of the
map, and so will be stored along side. If you heavily use the map, this can result in many swapin/swapouts.
Better to look at L<TM::IndexAble> for that matter.

=head1 INTERFACE

=head2 Constructor

The constructor expects a hash with the following keys:

=over

=item B<file> (no default)

This contains the file name of the DBM file to tie to.

=back

=cut

sub new {
    my $class = shift;
    my %options = @_;

    my $file = delete $options{file} or die $TM::log->logdie ("no file specified");
    my $whatever = $class->SUPER::new (%options, url => 'file:'.$file);             # this ensures that we have a proper url component

    my %self;                                                                       # forget about the object itself, make a new one

#warn "file exists $file?";
    if (-e $file && -s $file) {                                                     # file does exist already (and is not empty)
	tie %self, 'MLDBM', -Filename => $file
	    or $TM::log->logdie ( "Cannot create DBM file '$file: $!");
                                                                                    # oh, we are done now
    } else {                                                                        # no file yet
#warn "file not exists $file!";
	tie %self, 'MLDBM', -Filename => $file,                                     # bind to one
                            -Flags    => DB_CREATE                                  # which we create here
	    or $TM::log->logdie ( "Cannot create DBM file '$file: $!");

	foreach (keys %$whatever) {                                                 # clone all components
	    next if /indices|rindex/;                                               # we do not want these
	    $self{$_} = $whatever->{$_};                                            # this makes sure that Berkeley'ed tie picks it up
	}
    }
    return bless \%self, $class;                                                    # give the reference a blessing
}

sub DESTROY {                                                                       # if an object went out of scope
    my $self = shift;
    untie %$self;                                                                   # release the tie with the underlying resource
}

=pod

=head1 SEE ALSO

L<TM>, L<TM::Materialized::MLDBM>

=head1 AUTHOR INFORMATION

Copyright 200[68], Robert Barta <drrho@cpan.org>, All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.  http://www.perl.com/perl/misc/Artistic.html

=cut

our $VERSION  = '0.03';

1;

__END__
