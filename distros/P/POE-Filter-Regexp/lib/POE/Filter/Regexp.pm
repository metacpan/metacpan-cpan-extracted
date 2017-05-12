

#!/usr/bin/perl
# -*- encoding: utf-8; mode: cperl -*-
package POE::Filter::Regexp;
use strict;
use vars qw($VERSION);

$VERSION='1.0';

sub new {
    my ($class,$re)=@_;
    $re ||= qr/\n/;
    die "Param in new must be a Regexp but this is a ".ref($re) unless ref $re eq 'Regexp';
    return bless [
		  '', # raw unparsed data
		  $re,
		 ], $class;
}


sub get {
    my ($self, $stream) = @_;
    my @ret;
    while($_=shift @$stream){
 	$self->[0].=$_;
	$_=''; #yah we'r cl'r mems !!!111 
	my $p=0;
	while($self->[0]=~/$self->[1]/gm) {
	    next unless $-[0]; #begin of stream
	    push @ret, substr($self->[0], $p, $-[0]-$p);
	    $p=$-[0];
	}
	substr($self->[0], 0, $p)='';
    }
    $self->[0]=''.$self->[0]; #Clean holes in string.
    return \@ret;
}


1;
__END__

=head1 NAME

    POE::Filter::Regexp - Fast spliting input stream
    
=head1 SYNOPSYS

use POE::Filter::ErrorProof;
my $wheel = POE::Wheel::ReadWrite->new(
    Driver => POE::Driver::SysRW->new( BlockSize =>16777216),
        #16M  OMG !
    Filter => POE::Filter::Regexp->new(qr/^HEAD:/),
        #each new chunk begins from /\nHEAD:/
);  

=head1 DESCRIPTION

This POE::Filter developed for reading large ammount of data from large files.
On each iteration POE reads BlockSize octets from stream and put it to filter, 
filter returns array of sliced chunks in one bundle, and InputEvent called for 
each of it without runing POE's internal loop doing anything else.
This construction blocks io but incredible fast on log processing, when main 
task of system - is parsing logs.
  

=head1 AUTHOR

Vany Serezhkin E<lt>ivan@serezhkin.comE<gt>


=cut