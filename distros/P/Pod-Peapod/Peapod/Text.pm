package Pod::Peapod::Text;

use 5.008;
use strict;
use warnings;

use Data::Dumper;
use Text::Wrap;

use  Pod::Peapod;

our @ISA;
BEGIN { push(@ISA,'Pod::Peapod'); }


#######################################################################
sub New
#######################################################################
{
	my $class = shift(@_);
	my $parser = $class->SUPER::New(@_);
	my %attributes = @_;
	while(my($key,$val)=each(%attributes))
		{
		$parser->{$key}=$val;
		}

	unless(exists($parser->{_text_width}))
		{$parser->{_text_width}=72;}

	$parser->{_character_column}=0;
	
	return $parser;
}


#######################################################################
sub parse_string_document
#######################################################################
{
	my ($parser, $string)=@_;

	# call method to clear any preexisting document

	$parser->SUPER::parse_string_document($string);

	# call method to post process
	print "\n";
}

#######################################################################
sub FormatText
#######################################################################
{
	my $parser=shift(@_);
	my $text = $parser->GetAttribute('_text_string');

	# if xml_space attribute exists (comes from Pod::Simple) then get it.
	my $xml_space='';
	if($parser->ExistsAttribute('xml:space'))
		{
		$xml_space = $parser->GetAttribute('xml:space');
		}

	# if preserve spacing, print string and return.
	if($xml_space eq 'preserve')
		{
		print $text;
		my @lines = split($text,"\n");
		$text = $lines[-1];
		my $column = length($text);
		$parser->{_character_column}=$column;
		return;
		}



	my @lines = split("\n", $text);

	while(@lines)
		{
		my $line = shift(@lines);
		while(length($line))
			{
			$parser->FixLeftMargin;

			my $width = $parser->{_text_width};
			my $column = $parser->{_character_column};
			my $max_char = $width - $column;

			if($max_char ==0)
				{ 
				$parser->OutputPodSingleNewLine; 
				redo;
				}
			# get substring to end of this line and print it.
			my $substr = substr($line,0,$max_char,'');

			# did it already occur on a boundary?
			my $test = substr($substr,-1,1) . substr($line,0,1);

			if(length($line) or ($test=~m{\w\w}) )
				{
				if($substr=~s{(\W\w+?)$}{})
					{ 
					my $reaffix=$1; 
					$line = $reaffix . $line;
					}
				}



			print $substr;

			# if there is more text in this line
			if(length($line))
				{ $parser->OutputPodSingleNewLine; }

			# or no more text in this line 
			# but there are other lines.
			elsif(scalar(@lines))
				{ $parser->OutputPodSingleNewLine; }

			# or no more text, no more lines,
			# but input string ended in \n
			elsif($text =~ m{\n$}m)
				{ $parser->OutputPodSingleNewLine; }

			else
				{
				$parser->{_character_column} += length($substr);
				}
			}
		continue
			{
			$line =~ s{^\s*}{};
			}
		}
	

}

#######################################################################
sub FixLeftMargin
#######################################################################
{
	my $parser=shift(@_);

	my $cur_col = $parser->{_character_column};

	my $left_margin=0;
	if($parser->ExistsAttribute('_left_margin'))
		{
		$left_margin = $parser->GetAttribute('_left_margin');
		}

	my $diff = $left_margin - $cur_col;

	if($diff>0)
		{
		my $prefix = ' 'x($diff);
		print $prefix;
		$parser->{_character_column}=$left_margin;
		}
}

#######################################################################
sub OutputPodSingleNewLine
#######################################################################
{
	my $parser=shift(@_);
	print "\n";
	$parser->{_character_column}=0;
	$parser->FixLeftMargin;
}


#######################################################################
sub OutputPodNewLine
#######################################################################
{
	my $parser=shift(@_);
	print "\n\n";
	$parser->{_character_column}=0;
	$parser->FixLeftMargin;
}

#######################################################################
sub OutputPodText
#######################################################################
{
	my $parser=shift(@_);

	#warn Dumper $parser->{_current_attributes}->[-1];

	$parser->FormatText;
}


#######################################################################
sub OutputTocText
#######################################################################
{

}

#######################################################################
sub OutputTocNewLine
#######################################################################
{

}



