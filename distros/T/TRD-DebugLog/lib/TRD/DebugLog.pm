package TRD::DebugLog;

#use warnings;
use strict;

=head1 NAME

TRD::DebugLog - debug log

=head1 VERSION

Version 0.0.9

=cut

our $VERSION = '0.0.9';
our $enabled = 0;
our $timestamp = 1;
our $file = undef;
our $timeformat = 'YYYY/MM/DD HH24:MI:SS ';
our $cutpackage = 'main';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use TRD::DebugLog;
    $TRD::DebugLog::enabled = 1;
    dlog( "this is debug log" );

  or

    use TRD::DebugLog { enabled=>1, timeformat='YYYY-MM-DD HH24:MI:SS' };
    dlog( "this is debug log" );

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 dlog( log )

   show debug log.

   $TRD::DebugLog::enabled
    default: 0
       = 1 : enable debug log
       = 0 : disable debug log

   $TRD::DebugLog::timestamp
    default: 1
       = 1 : show timestamp enable
       = 0 : show timestamp disable

   $TRD::DebugLog::file
    default: undef
       debug log append to file

   $TRD::DebugLog::timeformat
     default: YYYY/MM/DD HH24:MI:SS
       YYYY : 4digit Year
       YY   : 2digit Year
       MM   : 2digit Month
       DD   : 2digit Day
       HH24 : 24hour 2digit Hour
       MI   : 2digit Min
       SS   : 2digit Sec

   $TRD::DebugLog::cutpackage
     default: main (cut 'main::' only)
            : all

=cut

#======================================================================
sub dlog($)
{
	my( $log ) = @_;

	my $buff = undef;

	if( $TRD::DebugLog::enabled ){
		my( $source, $line, $func );
		( $source, $line ) = (caller 0)[1,2];
		( $func ) = (caller 1)[3];
		if( $cutpackage eq 'main' ){
			$func =~s/^main:://;
		} elsif( $cutpackage eq 'all' ){
			$func = ( split( '::', $func ) )[-1];
		}

		$buff = "${source}(${line}):${func}:${log}\n";

		if( $TRD::DebugLog::timestamp ){
			my $timestr = &getTimeStr();
			$buff = $timestr. $buff;
		}

		if( $TRD::DebugLog::file ){
			open( my $fh, ">>", "${file}" ) || die $!;
			print $fh $buff;
			close( $fh );
		} else {
			print STDERR $buff;
		}
	}
	return $buff;
}

=head2 Exception( log )

    show exception log

=cut
#======================================================================
sub Exception
{
	my( $log ) = @_;
	my( $p, $f, $l ) = caller(0);
	my( $s ) = (caller(1))[3];

	print STDERR "TRD::DebugLog::Exception: ${log}\n";
	my $i=0;
	while(1){
		my( $package, $filename, $line ) = (caller $i)[0,1,2];
		my( $subroutine ) = (caller $i+1)[3];
		$package .= '::';
		$package = '' if( $package eq 'main::' );
		print STDERR "\tat ${filename}(${line})\t${package}${subroutine}\n";
		$i++;
		if( !defined( $subroutine ) ){
			last;
		}
	}
}

=head2 getTimeStr( time )

    make timestr

    my $timestr = &TRD::DebugLog::getTimeStr( time );

=cut

#======================================================================
sub getTimeStr
{
	my $time = (@_) ? shift : time;
	my( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) =
		localtime( $time );

	my $timestr = $timeformat;
	$timestr=~s/YYYY/sprintf( "%04d", $year + 1900)/eg;
	$timestr=~s/YY/sprintf( "%02d", $year - 100 )/eg;
	$timestr=~s/MM/sprintf( "%02d", $mon + 1 )/eg;
	$timestr=~s/DD/sprintf( "%02d", $mday )/eg;
	$timestr=~s/HH24/sprintf( "%02d", $hour )/eg;
	$timestr=~s/MI/sprintf( "%02d", $min )/eg;
	$timestr=~s/SS/sprintf( "%02d", $sec )/eg;

	return $timestr;
}

=head2 import

    import module

=cut
#======================================================================
sub import
{
	my $package = shift;
	my $callerpkg = (caller(0))[0];
	no strict qw(refs);
	*{"$callerpkg\::dlog"} = *{"TRD\::DebugLog\::dlog"};

	my( @param ) = @_;

	foreach my $p ( @param ){
		foreach my $key ( keys(%{$p}) ){
			if( $key eq 'enabled' ){
				$enabled = $p->{$key};
			} elsif( $key eq 'timestamp' ){
				$timestamp = $p->{$key};
			} elsif( $key eq 'file' ){
				$file = $p->{$key};
				$file = undef if( $file eq '' );
			} elsif( $key eq 'timeformat' ){
				$timeformat = $p->{$key};
			}
		}
	}
}

=head1 AUTHOR

Takuya Ichikawa, C<< <trd.ichi at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-trd-debuglog at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=TRD-DebugLog>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc TRD::DebugLog


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=TRD-DebugLog>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/TRD-DebugLog>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/TRD-DebugLog>

=item * Search CPAN

L<http://search.cpan.org/dist/TRD-DebugLog>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Takuya Ichikawa, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of TRD::DebugLog
