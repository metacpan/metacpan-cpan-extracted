package PulseAudio::Types;
use MooseX::Types -declare => [qw(PA_Volume PA_Bool PA_Index PA_Name)];
use feature ':5.10';
use strict;
use warnings;

use MooseX::Types::Moose qw/Int Str Bool Object/;

use constant FULL_VOLUME => 0x10000;

subtype PA_Volume , as Int , where { $_ >= 0 && $_ <= FULL_VOLUME };

subtype PA_Bool , as Bool;

subtype PA_Index , as Int , where { $_ >= 0 };
subtype PA_Name , as Str;

## per `man pulse-cli-syntax`
## Note that any boolean arguments can be given positively as '1', 'on' or any
## word starting with the letters 't' or 'y'. Likewise,  negative  values can be
## given as '0', 'off' or any word starting with the letters 'f' or 'n'. Case is
## ignored.
coerce PA_Bool
	, from Str
	, via {
		my $arg;
		given ( $_ ) {
			when ( qr/on/i )    { $arg = 1 }
			when ( qr/off/i )   { $arg = 0 }
			when ( qr/^[ty]/i ) { $arg = 1 }
			when ( qr/^[fn]/i ) { $arg = 0 }
			default { $_ }
		};
		$arg;
	}
;

## This permits you to send in the actual SINK or SOURCe
coerce PA_Index
	, from Object
	, via {
		my $obj = shift;
		die "Invalid Index" unless $obj->meta->has_attribute('index');
		return $obj->index;
	}
;

coerce PA_Name
	, from Object
	, via {
		my $obj = shift;
		die "Invalid Index" unless $obj->meta->has_attribute('name');
		return $obj->name;
	}
;

## Furthers the volume functionality
coerce PA_Volume
	, from Str , via {
		my $ratio;
		given ( $_ ) {
			when ( 'MAX' )  { $ratio = FULL_VOLUME }
			when ( 'HALF' ) { $ratio = 0.50 * FULL_VOLUME }
			when ( 'MUTE' ) { $ratio = 0 }
			when ( 'MIN' )  { $ratio = 0 }
			when ( '' )     {
				local $Carp::CarpLevel = 4;
				Carp::croak 'Invalid PA_Volume (empty string)'
			}
			when ( $_ =~ qr/^(\d+)[%]$/ ) {
				$ratio = int($1/100 * FULL_VOLUME );
			}
		}
		return $ratio;
	}
;

1;

__END__

=head1 NAME

PulseAudio::Types

=head1 DESCRIPTION

This module provides PulseAudio types using L<MooseX::Types>. All types have
both an B<is_> and B<to_> shorthand per L<MooseX::Types>.

=head2 Types provided

=over 4

=item PA_Volume

This type coerces from percents B<'50%'> and from the shorthands B<MAX>,
B<HALF>, B<MUTE> (0), and B<MIN> (0).

=item PA_Bool

Simple type coerces from on/off/true/false/y*/n*.

=item PA_Index

Takes an int, or an object that has an B<index> attribute (like
L<PulseAudio::Sink> and L<PulseAudio::Source>) resolving to the index stored in
the attribute.

=item PA_Name

Takes an str, or an object that has an B<name> attribute (like
L<PulseAudio::Samples>) resolving to the index stored in the attribute.

=back
