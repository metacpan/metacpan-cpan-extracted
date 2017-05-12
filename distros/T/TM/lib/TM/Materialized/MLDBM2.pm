package TM::Materialized::MLDBM2;

use TM;
use base qw (TM);
use Class::Trait qw(TM::ResourceAble);

use Data::Dumper;

use BerkeleyDB ;
use MLDBM qw(BerkeleyDB::Hash) ;
use Fcntl;

=pod

=head1 NAME

TM::Materialized::MLDBM2 - Topic Maps, DBM Storage (synchronous)

=head1 SYNOPSIS

   NOTE: THIS PACKAGE IS NOW DEPRECATED
   NOTE: USE TM::ResourceAble::MLDBM INSTEAD

   use TM::Materialized::MLDBM2;
   {
    my $tm = new TM::Materialized::MLDBM2 (file => '/tmp/map.dbm');
    # modify the map here.....

    } # it goes out of scope here, and all changes are written back automagically

   # later in the game
   {
    my $tm = new TM::Materialized::MLDBM2 (file => '/tmp/map.dbm');
    # we are back in business, no sync necessary
    }

=head1 DESCRIPTION

This package just implements L<TM> with a BerkeleyDB store. Unlike L<TM::Materialized::MLDBM> this
module does not need explicit synchronisation with the external resource (the DBM file here).  It
ties content-wise with the DBM file at constructor time and unties at DESTROY time.

The advantage of this storage form is that there is little memory usage. Only those fractions of the
map are loaded which are actually needed. If one has very intense interactions with the map (as a
query processor has), then this storage technique is not optimal.

=head1 INTERFACE

=head2 Constructor

The constructor expects a hash with the following keys:

=over

=item B<file> (no default)

This contains the file name of the DBM file to tie to.

=back

=cut

sub new {

    $TM::log->warn (__PACKAGE__ ': this package is deprecated, use TM::ResourceAble::MLDBM instead ');
    my $class = shift;
    my %options = @_;

    my $file = delete $options{file} or die $TM::log->logdie ("no file specified");
    my $whatever = $class->SUPER::new (%options, url => 'file:'.$file);             # this ensures that we have a proper url component

    my %self;                                                                       # forget about the object itself, make a new one

#warn "file exists $file?";
    if (-e $file) {                                                                 # file does exist already
	tie %self, 'MLDBM', -Filename => $file
	    or $TM::log->logdie ( "Cannot create DBM file '$file: $!");
                                                                                    # oh, we are done now
    } else {                                                                        # no file yet
#warn "file not exists $file!";
	tie %self, 'MLDBM', -Filename => $file,                                     # bind to one
                            -Flags    => DB_CREATE                                  # which we create here
	    or $TM::log->logdie ( "Cannot create DBM file '$file: $!");

	foreach (keys %$whatever) {                                                 # clone all components
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

our $VERSION  = '0.02';
our $REVISION = '$Id: MLDBM2.pm,v 1.3 2006/11/13 08:02:34 rho Exp $';

1;

__END__
