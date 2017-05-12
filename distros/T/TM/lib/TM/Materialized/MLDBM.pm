package TM::Materialized::MLDBM;

use TM;
use base qw (TM);
use Class::Trait qw(TM::Synchronizable::MLDBM);

=pod

=head1 NAME

TM::Materialized::MLDBM - Topic Maps, DBM Storage (asynchronous)

=head1 SYNOPSIS

    use TM::Materialized::MLDBM;
    my $tm = new TM::Materialized::MLDBM (file => '/tmp/map.dbm');
    # modify the map here.....
    # and flush everything onto the file
    $tm->sync_out;

    # later in this game, get it back from file
    my $tm2 = new TM::Materialized::MLDBM (file => '/tmp/map.dbm');
    $tm2->sync_in;


=head1 DESCRIPTION

This package just implements a materialized map with a MLDBM store.

=head1 INTERFACE

=head2 Constructor

The constructor expects to see the following option(s):

=over

=item B<file> (no default)

The name of the DBM file. It is an error not to specify that.

=item B<url> (no default)

Alternatively, this can be a C<file:> URL.

=back

=cut

sub new {
    my $class = shift;
    my %options = @_;

    if ($options{url}) {
	die "URL must have the protocol file: " unless $options{url} =~ /^file:/;
	return bless $class->SUPER::new (%options), $class;
    } else {
	my $file = delete $options{file} or $TM::log->logdie ("no file specified");
	return bless $class->SUPER::new (%options, url => 'file:'.$file), $class;
    }
}

=pod

=head1 SEE ALSO

L<TM>, L<TM::Synchronizable::MLDBM>

=head1 AUTHOR INFORMATION

Copyright 200[6], Robert Barta <drrho@cpan.org>, All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.  http://www.perl.com/perl/misc/Artistic.html

=cut

our $VERSION  = '0.02';
our $REVISION = '$Id: MLDBM.pm,v 1.5 2006/11/23 10:02:55 rho Exp $';

1;

__END__
