package NET::IPFilterSimple;

use strict;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use NET::IPFilterSimple ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	isValid
	_init
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	isValid
	_init
);

our $VERSION = '1.2';


sub new(){

	my $class   	= shift;
	my %args 	= ref($_[0])?%{$_[0]}:@_;
	my $self 	= \%args;
	bless $self, $class;
	$self->_init();
	return $self;
		
}; # sub new(){


sub isValid(){

	my $self 		= shift;
	my $IPtoCheck		= shift; 
	my $RangesArrayRef	= $self->{'_IPRANGES_ARRAY_REF'};
	my $howmany		= scalar( @{$RangesArrayRef} );

	$IPtoCheck 		=~ s/\.//g;

	for ( my $count=0; $count<=$howmany; $count++) {
		
		my ($RangFrom, $RangTo) = split("-", $RangesArrayRef->[$count]);
	
		if ( $IPtoCheck >= $RangFrom && $IPtoCheck <= $RangTo ) {
			return 0;
		};

	}; # for ( my $count=0; $count<=$howmany; $count++) {

	return 1;	# if ip not found in ipfilter.dat its valid

}; # sub isValid(){



sub _init(){

	my $self 	= shift;
	my $file	= $self->{'ipfilter'};
	die "$self->_init() - Fatal Error no ipfilter.dat given" if ( length $file < 1 );

	my @IP_Ranges 	= ();

	open(RH,"<$file") or die("$self -> _init( $file ) Reading Failed");
	while (defined( my $entry = <RH>)) {
		chomp($entry);
		
		next if ( $entry =~ /^#/g || $entry =~ /#/g );
		my ($IPRange, undef, $DESC) 	= split(",", $entry);
		next if ( $DESC =~ /\[BG\]FreeSP/ig );	# ignore not used ips
		my ($IP_Start,$IP_End) 		= split("-", $IPRange );
		
		$IP_Start =~ s/^\s+//;
		$IP_Start =~ s/\s+$//;	
		$IP_End =~ s/^\s+//;
		$IP_End =~ s/\s+$//;				
		
		$IP_Start 	=~ s/\.//g;
		$IP_End		=~ s/\.//g;
		
		push(@IP_Ranges, "$IP_Start-$IP_End");


	}; # while (defined( my $entry = <RH>)) {
	close RH;
	
	$self->{'_IPRANGES_ARRAY_REF'} = \@IP_Ranges;

	return $self;

}; # sub _init(){



# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

NET::IPFilterSimple - Perl extension accessing ipfilter.dat files the very simple way
Warning: Please Update your Sources. Current Version fixed a very critical bug that prevents Program from working correctly.

=head1 SYNOPSIS

  use NET::IPFilterSimple;
  my $obj      = NET::IPFilterSimple->new( ipfilter => '/home/thecerial/firewall/ipfilter.dat' );
  my $IP       = "199.196.016.200";
  my $isValid  = $obj->isValid($IP);	#  1 not to be blocked | 0 to be blocked

=head2 DEPENDENCIE

use strict;

Because it uses no more modules ( in contrast to NET::IPFiler ) it is easily portable to Windows, MAC, Solaris. You only need to give a valid path as ipfilter parameter to the new constructor.

=head1 DESCRIPTION

Perl Module for accessing ipfilter.dat files the easy way. IPs from the ranges of ipfilter.dat
there are the dots removed and these ranges are then saved in an array. later a given ip is 
checked against the ranges in the array

=head2 EXPORT

isValid() - Checks given ip against ipfilter.dat range

=head1 SEE ALSO

eMule | BitTorrent | Torrent Sites using ipfilter.dat perl modules 

http://www.zoozle.net

http://www.zoozle.org

http://www.zoozle.biz

http://search.cpan.org/author/SENGER/

NET::IPFilterSimple
NET::IPFilter

=head1 AUTHOR

Sebastian Enger, bigfish82 |ät! gmail?com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Sebastian Enger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
