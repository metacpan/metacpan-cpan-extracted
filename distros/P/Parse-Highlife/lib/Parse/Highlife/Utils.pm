package Parse::Highlife::Utils;

use Data::Dump qw(dump);

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = 
	qw(
		params 
		offset_to_coordinate 
		get_source_info 
		extend_match
		dump_tokens
		dump_ast
	); 

sub dump_ast
{
	my( $ast, $level ) = @_;
	$level = 0 unless defined $level;
	
	if( $ast->{'category'} eq 'group' ) {
		print ''.('.   ' x $level)."".$ast->{'rulename'}.":\n";
		map { dump_ast( $_, $level + 1 ) } @{$ast->{'children'}};
	}
	elsif( $ast->{'category'} eq 'leaf' ) {
		my $value = $ast->{'children'};
		   $value =~ s/\n/\\n/g;
		   $value =~ s/\r/\\r/g;
		   $value =~ s/\t/\\t/g;
		print ''.('.   ' x $level)."".$ast->{'rulename'}." '".$value."'\n";
	}
}

sub dump_tokens
{
	my( $tokens, $hide_ignored_tokens ) = @_;
	$hide_ignored_tokens = 0 unless defined $hide_ignored_tokens;
	print "#".scalar(@{$tokens})." tokens (\n";
	my $t = 0;
	foreach my $token (@{$tokens}) {
		if( $hide_ignored_tokens && $token->{'is-ignored'} ) {
			$t ++;
			next;
		}
		my $classname = $token->{'token-classname'};
		   $classname =~ s/^.*\://g;
		my $head = 
			sprintf('%4d', $t).'. chars '.
			sprintf('%4d',$token->{'first-offset'}).'..'.
			sprintf('%-4d',$token->{'last-offset'}).
			' <'.$classname.">: ";
		my $value = $token->{'matched-substring'};
		   $value =~ s/\n/\\n/g;
		   $value =~ s/\r/\\r/g;
		   $value =~ s/\t/\\t/g;
		my $head2 = sprintf('%-40s',$head)."'".$value."'";
		print sprintf('%-65s',$head2).' = '.$token->{'token-name'}."\n";
		$t ++;
	}
	print ")\n";
}

# extend a token match with some generic info that makes it easier
# to handle by the tokenizer
sub extend_match
{
	my( $string, $match ) = @_;
	$match->{'last-offset'} = $match->{'first-offset'} + length($match->{'matched-substring'}) - 1;
	$match->{'first-line'} = 0;
	$match->{'last-line'} = 0;
	$match->{'offset-after-match'} = $match->{'last-offset'} + 1;
	if( exists $match->{'real-content'} ) {
		$match->{'matched-substring'} = $match->{'real-content'};
	}
	return $match;
}

sub params
{
	my( $arglist, @defs ) = @_;
	my( $self, %args ) = @{$arglist};
	my @values;
	for( my $i = 0; $i < @defs; $i += 2 ) {
		my $key = $defs[$i];
		push @values, ( exists $args{$key} ? $args{$key} : $defs[$i+1] );
	}
	return( $self, @values );
}

# converts an offset into a line/column coordinate
sub offset_to_coordinate
{
	my( $string, $offset ) = @_;
	my $head = substr $string, 0, $offset;
	my $c = 0;
	my $line = 0;
	my $last_line_end = 0;
	while( $c < length $head ) {
		if( substr( $head, $c, 1 ) eq "\n" ) {
			$line ++;
			$last_line_end = $c;
		}
		$c++;
	}
	return ($line + 1, length substr( $head, $last_line_end ));
}

# returns a dump of a string with a mark at a special position
sub get_source_info
{
	my( $string, $offset ) = @_;
	my( $line, $column ) = offset_to_coordinate( $string, $offset );
	$line --;
	my $s = '';
	my $l = 0;
	foreach my $src_line (split /\n/, $string) {
		if( $l > $line - 10 && $l <= $line ) {
			$s .= sprintf('%4d',$l+1)." | ".$src_line."\n";
		}
		$l ++;
	}
	$s .= "       ".(' ' x ($column - 1));
	$s .= "^ don't know how to handle '".substr($string,$offset,1)."'\n";
	return $s;
}

1;
