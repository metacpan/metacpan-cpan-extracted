package POE::Filter::Audio::Mad::Stdio;
require 5.6.0;

use strict;
use warnings;

use POE;
use POE::Filter;

our $VERSION = '0.2';

sub new {
	my ($class) = @_;
	
	return bless (\(my $temp), $class);
}

sub get {
	my ($self, $stream) = @_;

	my ($pos, $index, @record) = (0, undef);
	${$self} .= join('', @{$stream});

	while (($index = index(${$self}, "\n\n")) > -1) {
		(my $raw, ${$self}) = split(/\n\n/, ${$self}, 2);
		my @cmd = split(/\n/, $raw);

		my $msg = { id => shift(@cmd), data => {} };
		for (@cmd) {
			my ($k, $v) = split(/\s+/, $_, 2);
			$msg->{data}->{$k} = $v;
		}
		
		push(@record, $msg);
	}
	
	return \@record;
}

sub put {
	my ($self, $data) = @_;
	
	my @record;
	
	for (@{$data}) {
		my $raw = "$_->{id}\n";
		if (defined($_->{data}) && ref($_->{data}) eq 'HASH') {
			while (my ($k, $v) = each(%{$_->{data}})) { $raw .= "$k $v\n" }
		} elsif (defined($_->{data}) && $_->{data} ne '') {
			$raw .= "$_->{data}\n";
		}
		$raw .= "\n";
		
		push(@record, $raw);
	}
	
	return \@record;
}

##############################################################################
=pod

=head1 NAME

POE::Filter::Audio::Mad - Simple filter support POE::Component::Audio::Mad::Handle

=head1 SYNOPSIS

	## could be any wheel,  really..
	my $wheel = POE::Wheel::ReadWrite->new(
		Filter => POE::Filter::Audio::Mad->new(),
		## other options..
	);
	
=head1 DESCRIPTION

  POE::Filter::Audio::Mad is a simple filter designed to translate streams
  of characters into structured command packets.  This is a fairly simple
  filter,  as such,  it places certain restrictions on the format of
  the data passed through it.  However,  the input and output of this
  filter are very similar and have the same restrictions.
  
  Input is achived by translating textual input into command packets;  
  command packets are hashrefs with two fields:  'id' and 'data'.  The 
  'id' field is interpreted as a string,  and contains the name of the 
  command to execute.  The 'data' field is interpreted as a list of 
  named options,  similar to a hash,  but you are not allowed to use 
  any whitespace characters in your keys.
  
  To start a command,  you send the command name followed by a newline.
  If you wish to include any named paramaters,  include them each on
  their own line.  place the name of the parmater first on the line,
  followed by whitespace and then the value of that paramater followed
  by a newline.  To finish the command,  send a blank line follwed by
  a newline.
  
  For example,  to create a command packet with an id of 'open' and
  two named parmaters:  'filename' that contains a path to a file,
  and 'play' which is a boolean you would send:
  
open
filename /path/to/some/stream.mp3
play 1


  Output is achived almost through exactly the same rules,  except 
  of course,  reversed.  Status packets are sent to the filter as
  hashrefs with two fields 'id' and 'data',  id is the name of
  the status message and data is a hashref possibly containing 
  key/value pairs for named values.
  
  The filter will then translate the status packet into a text
  string for output to wherever.  The string starts with the
  'id' field of the status packet followed by a newline.  Then
  each key/value pair in the 'data' field is sent.  The key is
  sent first and is guaranteed not to contain any whitespace,
  then a single space and the value is sent followed by a
  newline.  The entire packet is followed by a blank line and
  a newline.
  
  For example,  a status packet packet with an id field containing 
  'DECODER_STATUS_DATA' and the data field containing the 
  named paramaters:  'played' containing the value 50,  and
  'progress' containing the value 10 would be translated to:
  
DECODER_STATUS_DATA
played 50
progress 10

  This filter is a bit simplistic,  but intentionally so.  It's
  meant to provide an incredibly simple interface to the 
  POE::Wheel::Audio::Mad decoder core.  You could just as well
  use the POE::Filter::Reference filter to communicate more
  easily with another perl process.  This is meant to be used
  with thin clients.
  
=head1 SEE ALSO

perl(1)

POE::Component::Audio::Mad::Handle(3)

Audio::Mad(3)
Audio::OSS(3)

=head1 AUTHOR

Mark McConnell, E<lt>mischke@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Mark McConnell

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself with the exception that you
must also feel bad if you don't email me with your opinions of
this module.
            
=cut	

1;
__END__
