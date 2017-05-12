package PerlIO::via::Skip;

#use 5.008004;
use strict;
use warnings;
#use Data::Dumper;

require Exporter;

our $VERSION = '0.06';
use constant DEFAULTS  => ( start          =>  undef  , 
                            end            =>  undef  , 
			    maxlines       =>  undef  ,
			    skippatterns   =>  undef  ,
			    skipblanklines =>  0      ,
			    skipcomments   =>  0      ,
			    after          =>  0      ,
                            nread_         =>  0      , 
                            nwrite_        =>  0      , 
                            n_             =>  0      ,
			    bipolar        => sub {
			       my $obj = shift;
			       ($_[0]..$_[1]) ? ++$obj->{n_} : ($obj->{n_}=0);
			       ($obj->{n_} > ($obj->{after}||0)) ? return 1 :0;
			    }, ); 


sub PUSHED {
	my ($class, $mode, $fh) = @_ ;
	($mode =~ /^[rwa]$/)  or return -1  ;
	my $obj = (defined $ENV{ viaSKIP})  
				 ? bless { DEFAULTS, %{$ENV{ viaSKIP}} }
				 : bless { DEFAULTS } ;
	# init stuff
	reset;
	$obj->{qr_} = [compile_patterns( $obj->{skippatterns} ) ];
	$obj->{skipblanklines} and ($obj->{qr_} = [ qr/^\s*$/, @{$obj->{qr_}}]);
	$obj->{skipcomments}   and ($obj->{qr_} = [ qr/^\s*#/, @{$obj->{qr_}}]);
	($obj->{bipolar})->( $obj, 0, 1 );
	(defined $obj->{start})   ? ($obj->{start} = qr/\s*$obj->{start}\s*/)
			          : ($obj->{start} = qr/^/ );
	(defined $obj->{ end })   ? ($obj->{ end } = qr/\s*$obj->{ end }\s*/)
			          : ($obj->{ end } = qr/^.\A/ );
	$obj;
}

sub compile_patterns {
	my $pats = shift;
	return unless $pats;
	return qr/$pats/  unless ref $pats;
	map {qr/$_/}  @$pats;
}



sub FILL {
        my ($obj, $fh) = @_ ;

	# stop output if maxlines will be exceeded
	(defined $obj->{maxlines})           && 
	($obj->{nread_} >= $obj->{maxlines}) && return;
        local $_ = <$fh>;
        return undef  unless (defined $_);
	my ($s, $e) = ( $obj->{start} , $obj->{end} );
        until ( pattern_check( $obj , $_ )   &&
		($obj->{bipolar})->( $obj, scalar (?$s?), scalar (/$e/) ) 
	      ){
	      $_ = <$fh>;
	      $. =  $obj->{nread_};
	      return undef  unless (defined $_);
	}
	# update stats
	$. = ++ $obj->{nread_};
        $_;
}


sub pattern_check {
        # return FALSE if line should be ignored
	my ($obj, $line) = @_ ;
	return 1 unless @{$obj->{qr_}};
	for (@{$obj->{qr_}} ) {
		return 0 if  $line =~ $_ ;
	}
	1;
}


sub WRITE {
	my ($obj, $buf, $fh) = @_ ;
	local $_ = $buf; 

	return 0  if      (defined $obj->{maxlines})  && 
			  ($obj->{nwrite_} >= $obj->{maxlines});
	return 0  unless  pattern_check( $obj , $_ );
	my $s  = ?$obj->{start}? ;
	my $e =  /$obj->{end}/   ;
#print qq (write: "$_"\n);
	return 0  unless  ($obj->{bipolar})->( $obj , $s , $e );
	printf $fh  "%s", $buf;
	++ $obj->{nwrite_};
	length ;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

PerlIO::via::Skip - PerlIO layer for skipping lines

=head1 SYNOPSIS

  use PerlIO::via::Skip;

  $ENV{ viaSKIP} = { start=>'Fiat', end=>'Reno' };
  open my $i ,'<:via(Skip)', 'cars'  or die $!;


  $ENV{ viaSKIP} = { start          =>  'Fiat'       , 
		     end            =>   undef       ,
		     maxlines       =>     10        ,
		     after          =>      0        ,
		     skippatterns   =>   [qw( a e )] ,
		     skipcomments   =>      1        ,
		     skipblanklines =>      1        , }
  open my $i ,'<:via(Skip)', 'cars'  or die $!;


=head1 DESCRIPTION

This module implements a PerlIO layer that discards lines from
IO streams. By default, all lines are accepted and passed-through
as if no filters are present.  Input filters discard input lines, 
and output filters discard output lines; therefore, input lines 
(that meet user's criteria) are excluded from input, and in a similar
manner when specified, output lines are omitted from output.

 The code is re-entrant. Multiple filters can be
stacked together without interfering with one another.
These filters were designed for read, write, and append handles
( 'r', 'w', 'a'), but will refuse installation
for read-write mode.

=head1 CONFIGURATION

In order to stay re-entrant, configuration is done by setting the
global variable $ENV{viaSKIP} .  While other PerlIO modules are
usually configured via class variables through import(), I choose 
to sacrifice pretty syntax for data integrity. During the call to 
open(), or during binmode(), the filter reads its configuration
from the $ENV{viaSKIP} variable; since this is a dynamic value, you
probably want to change it before the open(), or binmode() if other 
filters should read a different configurations.

  The env variable 'viaSKIP' takes the form of a hash reference. 
  For example: $ENV{ viaSKIP } = { maxlines=> 10, start=>'apple' };

Where 'maxlines', and 'start' are configuration parameters.  Here are
all the parameters that allow you to alter the characteristics of
the filter:

 maxlines        limit the maximum number of input (or output) lines
 skippatterns    skip lines containing one of these patterns
 skipblanklines  skip whitespace lines
 skipcomments    skip lines with (leading) comments
 start           Start a bipolar vibrator. Skip leading lines
                 until a certain pattern
 end             End a bipolar vibrator. Skip remaining lines
                 after a certain pattern.
 after           Used with a bipolar vibrator. Skip more leading lines,
                 after you find the start pattern.


=head2 EXPORT

None by default.


=head1 SEE ALSO

Consult the documentation of the range operator,
when in scalar context for a description on how 
the bipolar vibrator operates. Note, however,
that in this implementation the bipolar is designed
for only full one cycle. (Will need to change
the range operator from a a m?? regex to a m// regex
if you need infinite cycles.)


=head1 AUTHOR

Ioannis Tambouras E<lt>ioannis@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Ioannis Tambouras

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
