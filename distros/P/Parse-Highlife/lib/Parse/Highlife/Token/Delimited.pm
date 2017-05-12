package Parse::Highlife::Token::Delimited;

use base qw(Parse::Highlife::Token);
use Parse::Highlife::Utils qw(params extend_match);
use Data::Dump qw(dump);

sub new
{
	my( $class, @args ) = @_;
	my $self = bless Parse::Highlife::Token->new( @args ), $class;
	return $self -> _init( @args );
}

sub _init
{
	my( $self, $start, $end, $escape )
		= params( \@_,
				-start => '',
				-end => '', 
				-escape => "\\",
			);
	$self->{'start'} = $start;
	$self->{'end'} = $end;
	$self->{'escape'} = $escape;
	return $self;
}

sub match
{
	my( $self, $string, $offset ) = @_;
	if( substr( $string, $offset, length $self->{'start'} ) eq $self->{'start'} ) {
		# string starts with start sequence
		# -> parse until end sequence is found
		my $ended = 0;
		my $c = $offset + length $self->{'start'}; # jump over start sequence
		while( $c < length $string ) {
			my $tail = substr $string, $c;
			if( substr( $tail, 0, length $self->{'end'} ) eq $self->{'end'} ) {
				# check if found end sequence is escaped
				my $head = substr $string, 0, $c;
				
				# count appearences of end-sequence from current offset backwards
				my $escapes = 0;
				my $c2 = $c;
				while( $c2 > 0 ) {
					my $before = substr $string, 0, $c2;
					if( substr( $before, - length $self->{'escape'} ) eq $self->{'escape'} ) {
						$escapes ++;
						$c2 -= length $self->{'escape'};
						next;
					}
					last;
				}

				# if number of escapes is even, they do not escape the current end-sequence				
				if( $escapes % 2 == 0 ) {
					$c += length $self->{'end'}; # jump over end sequence
					$ended = 1;
					last;
				}
			}
			$c++;
		}
		if( $ended ) {
			#my $old = substr( $string, $offset, $c - $offset );
			my $matched_substring = substr( $string, $offset, $c - $offset );
			#print "($old) -> ($matched_substring)\n";
			my $real_content = $matched_substring;
			   $real_content = substr( $real_content, length $self->{'start'} );
			   $real_content = substr( $real_content, 0, - length $self->{'end'} );			   
			return
				extend_match(
					$string,
					{
						'token-classname' 		=> ref $self,
						'matched-substring'		=> $matched_substring,
						'real-content'				=> $real_content,
						'first-offset'				=> $offset,
					}
				);
		}
	}
	return 0;
}

1;
