package Search::QueryBuilder;

use 5.008007;
use strict;
use warnings;
use Data::Dumper;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw( testme getTokenizedString tokenizeString 
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';


# Preloaded methods go here.

sub new {
	my $package = shift;
 	my $self= {
           _booleantags=> undef,
                 };
	#return bless({}, $package);
	return bless ($self,$package);
}

sub tags{
       my ( $self, @tags) = @_;
	   my @defaulttags=("AND","OR","NOT");
       @{$self->{_booleantags}} = @tags if @tags ;
       if( defined(@{$self->{_booleantags}})) {
		   return @{$self->{_booleantags}};
	   } else { 
		   return @defaulttags;
	   };
}


sub getTokenizedString {
	my ($self,$query)=@_;

	my @temp;
	my @temp2;
	my @temp3;
	my @tagbag=$self->tags;
	push(@temp2,tokenizeString($query,@temp));
	#temp2 currently represents a tokenized string

	my $previous="";
	# this cleans out most obvious mistakes 

	# Uppercase the tagbag tags...
	for(my $i=0;$i<$#temp2;$i++){
		my $test=uc($temp2[$i]);
		if((grep /^$test$/,@tagbag)>0){
			$temp2[$i]=uc($temp2[$i]);
			
		}
	}
	foreach my $tempvar (@temp2){
		# get rid of duplicates
		if($previous eq $tempvar){
			
		# or multiple commands (ie AND AND or NOT AND)
		} elsif((grep /^$previous$/,@tagbag)>0 && (grep /^$tempvar$/,@tagbag)>0){
		
		}else {
			push(@temp3,$tempvar);
		}
		$previous=$tempvar;
	}

	# Look for and remove dangling AND OR and NOT
	my $poss=($temp3[$#temp3]);
	while((grep /^$poss$/, @tagbag) >0){
		# Remove ands ors and nots from the end, where they are a bit meaningless 
		pop(@temp3);
		$poss=($temp3[$#temp3]);
	}
	
	return @temp3;
}

sub testme {
	#my $myfoo="    Bah     FOOOO GRAH BLITHER    ";
	#print ltrim($myfoo)."\n";
	#print rtrim($myfoo)."\n";
	#print atrim($myfoo)."\n";
	#print removeAll($myfoo, "A")."\n";
	#print findNearestPrevious("I am a quite long string",12,'q')."\n";
	#print tokenizeString("I am a \"fish\" and so are you")."\n";
	#print tokenizeString("I am a \"fish and so are you")."\n";
	#print tokenizeString("I am a -\"fish +\"and so\" are you")."\n";
	#print tokenizeString("I am a +\"fish +\"and so\" are you")."\n";
	#print tokenizeString("-I +am a fish and so are you too ")."\n";
	#print tokenizeString("I am a -\"fish\"and so\" are you")."\n";
	my @temp;
	my @temp2;
	push(@temp2,tokenizeString("  +\"I am\" a -\"fishy character\" and so\" is Bob",@temp));
	#print "Result: ".Data::Dumper->Dump([@temp2])."\n";
	print "Result: ".join(" ",@temp2)."\n";
}
sub atrim {
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}
# Left trim function to remove leading whitespace
sub ltrim {
	my $string = shift;
	$string =~ s/^\s+//;
	return $string;
}
# Right trim function to remove trailing whitespace
sub rtrim {
	my $string = shift;
	$string =~ s/\s+$//;
	return $string;
}

sub removeAll{
	my ($source,$replaceme)=@_;	
	$source=~s/$replaceme//g;
	return $source;
}

sub findNearestPrevious {
	my ($string, $currentidx,$char)=@_;
	my $tmpvar=$currentidx;
	my @charsinstring=split(//,$string);
	while($tmpvar>-1){
		if($charsinstring[$tmpvar] eq $char){
			return $tmpvar;
		}
		$tmpvar--;
	}
	return $tmpvar;
	
}

sub tokenizeString {
	my ($query,@response)=@_;
	$query=removeAll($query,"\'");
	atrim($query);
	my @tempresponse;
	if($query eq ""){
		return @response;
	}
	if(index($query,"\"")<0){
		# Oh jolly good, no quotation marks
		my @splitterms=split(/ /,$query);
	
		foreach my $termlet (@splitterms){
			if(substr($termlet,0,1) eq '-'){
				push(@tempresponse,"NOT");
				push(@tempresponse,substr($termlet,1,length($termlet)));

			} elsif (substr($termlet,0,1) eq '+'){
				push(@tempresponse,"AND");
				push(@tempresponse,substr($termlet,1,length($termlet)));
			} else { 
				push(@tempresponse,$termlet);
			}
			#print "Current contents: ".join(Data::Dumper->Dump([@response]),",");
			# print "Current contents: ".join(",",@response)."\n";
		}
		
	} else {
		# bugger. We have quotation marks - repeat, we have quotation marks
		my $firstIndex=index($query,"\"");
		my $secondIndex=index($query,"\"",$firstIndex+1);
		my $testVar=$secondIndex-$firstIndex;
		if($testVar>-1 && $testVar<2){ # empty quotes?! - sod it
	 	} elsif($testVar<0){ # ... lone lost little quote in middle of nowhere. Put it out of misery
			$query=removeAll($query,"\"");
			push(@tempresponse,tokenizeString($query,@response));
		} elsif ($firstIndex<1){ # first quote at beginning of string...
			push(@tempresponse, substr($query,$firstIndex+1,$testVar-1));
			if($secondIndex<length($query)){
				#push(@response,tokenizeString(substr($query,$secondIndex+1,length($query)-$secondIndex+1),@response));
				push(@tempresponse,tokenizeString(substr($query,$secondIndex+1,length($query)-$secondIndex+1),@response));
			}
		} else { # first quote not at beginning of string. First quote somewhere random
			my $firstminusone=$firstIndex-1;
			if(substr($query,$firstIndex-1,1)  eq " "){ 
					# this is fine for most instances, but sometimes there's a - or a + in the way
					# deal with the most instances first
				push(@tempresponse,tokenizeString(substr($query,0,$firstIndex)));
				push(@tempresponse,substr($query,$firstIndex+1,$testVar-1));
				if($secondIndex<length($query)){
					push(@tempresponse,tokenizeString(substr($query,$secondIndex+1,length($query)-$secondIndex)));
				}

			} else { # there' s a - or + before the "!! the (*&£$(*&!'s!
				my $thirdIndex=findNearestPrevious($query,$firstIndex," ");

				if($thirdIndex<0){ # no space start of query
					if(substr($query,0,1) eq "-"){
						push(@tempresponse,"NOT");
						push(@tempresponse,substr($query,2,$testVar-1));
					} elsif(substr($query,0,1) eq "+"){
						push(@tempresponse,"AND");
						push(@tempresponse,substr($query,2,$testVar-1));
					} else {
						push(@tempresponse,substr($query,0,$testVar-1));
						
					}

						
				} else { # there's a - or + before the ", and we are not at the start of the string...
					# push(@response,substr($query,0,$thirdIndex));
					push(@tempresponse,tokenizeString(substr($query,0,$thirdIndex),@response));
					if(substr($query,$thirdIndex+1,1) eq '-'){ # oh look, a -
						push(@tempresponse,"NOT");
						$thirdIndex++;
					}elsif(substr($query,$thirdIndex+1,1) eq '+'){
						push(@tempresponse,"AND");
						$thirdIndex++;
					}	
					push(@tempresponse,substr($query,$thirdIndex+2,$secondIndex-$thirdIndex-2));
					
					
				}
				if($secondIndex<length($query)){
					# yet more to play with?
					push(@tempresponse,tokenizeString(substr($query,$secondIndex+2,length($query)-$secondIndex),@response));
				
			
				}
			}



		}


	}
	return @tempresponse;
}

sub build{
	my $self = shift;
	return;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Search::QueryBuilder - Perl extension for tokenising search strings and building queries

=head1 SYNOPSIS

  use Search::QueryBuilder;
  my $querybuild=new QueryBuilder;  
  # $querystring contains a query along the lines of "A key phrase" -"keyword" AND keyword +keyword
  my @responsearr=$querybuild->getTokenizedString($querystring);
  # @responsearr contains the keywords and phrases, plus booleans where provided
  
  If you intend to use more than the basic booleans, add them as follows:
  my @mytaglist=("AND","OR","NOT","XOR");
  $querybuild->tags(@mytaglist);

=head1 DESCRIPTION

QueryBuilder is a very simple tokeniser, designed to decode a query string 
into something you can create a database query from (into SQL, Cheshire, that 
sort of thing).

It tries to do a little sanity checking, but is still in active development 
so expect changes. The creation of queries from the resulting string is 
partly merged into the module, but expect this interface to change.

=head2 EXPORT

None by default.


=head1 SEE ALSO

There are actually several other modules out there that are related - 
for example, String::Tokeniser, String::Tokenizer, Parse::Tokens and 
Text::Tokenizer. 

This one is designed specifically for use as part of a search system, and is 
likely to evolve in that direction (handling of prefixes, building up search 
queries in various formats and so forth).

Other approaches to this include Search::Circa and Search::QueryParser. 


=head1 AUTHOR

E Tonkin, E<lt>cselt@users.sourceforge.net<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by E Tonkin 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
