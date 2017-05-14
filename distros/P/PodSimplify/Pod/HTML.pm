package Pod::HTML;
=head1 NAME

Pod::HTML - Translate POD into HTML file

=head1 SYNOPSIS


	use Pod::HTML;

=head1 DESCRIPTION


=cut
package Pod::HTML;

sub import {}

use Pod::Simplify;
use HTML::AsSubs;
use HTML::Element;
use HTML::Entities;

=item findindex REF, PATH, [PATH, ...]

Find the index.

=cut
sub findindex {
	my(@a) = @_;
	shift @a;
	my(@look) = map(join("/",@$_),@a);
	my($match)=0;
	foreach(@look) {
		if($match = $idx{$_}) {
			last;
		}
	}
	$match;
}

=item flowed ARRAY

Translate the array of annotations into HTML. Recurses over
contained arrays.

For now, leave a tag ("{t}") for each type "t" to show the
translation rule for ambiguous constructs.

=cut
sub flowed {
	my(@out);	# contains pieces of HTML::Element
	foreach $i (@_) {
		if(ref $i eq "ARRAY") {
			my(@i) = (@$i);
			my($c) = shift @i;
			if($c eq "B") { # Bold
				push(@out, b(flowed(@i)));
			}
			elsif($c eq "I") { # italic
				push(@out, i(flowed(@i)));
			}
			elsif($c eq "V") { # Variable
				push(@out, "``", code({'type'=>'v'}, flowed(@i)), "''");
			}
			elsif($c eq "P") { # Procedure
				push(@out, i({'type'=>'p'}, flowed(@i)));
			}
			elsif($c eq "F") { # Filename
				push(@out, em({'type'=>'f'}, flowed(@i)));
			}
			elsif($c eq "S") { # Switch
				push(@out, b({'type'=>'s'}, flowed(@i)));
			}
			elsif($c eq "C") { # Code
				push(@out, code(flowed(@i)));
			}
			elsif($c eq "R") { # Reference
				my($id) = findindex(@i);
				my(@annotated) = flowed(@{$i[0]});
				if ( $id ) {
					push(@out, a({'href'=>($id->[2] ne "foo" ? $id->[2] : "")."#".$id->[0]},
							@annotated));
				} else {
					push(@out, @annotated);
				}
			}
			elsif($c eq "X") { # Index
				my($id) = findindex(@i);
				push(@out, a({'name'=>$id->[0]}, flowed(@{$i[0]})));
			} 
			elsif($c eq "E") { # Escape
				my($v) = "&".$i[0].";";
				decode_entities($v);
				push(@out, $v);
			}
			else {
				push(@out, "{$c:", flowed(@i),"}"); 
			}
		} else {
			# Simple text reference
			push(@out, &simpleText($i));
		}
	}
	return @out;
}

=item simpleText TEXT

Pick off the initial characters of the text, and apply
an outstanding index item to them. The deferred index
is in array @waitingindex.

Also, translate special characters. Return either a text item
or an array.


=cut
sub simpleText {
	my($i) = @_;
	my(@out);

	while(@waitingindex and length($i)) {
		my($c) = substr($i,0,1);
		push(@out, a({'name'=>(shift @waitingindex)}, $c));
		substr($i,0,1)="";
	}
	if ( @out ) {
		return (@out, $i);
	}
	return $i;
}

@listtype=();

$idx=0;

sub doindex {
	foreach (@_) {
		if(ref $_ eq "ARRAY") {
			my(@i) = @$_;
			my($i) = shift @i;
			if( $i eq "X") {
				shift @i; # discard printable block
				$idx++;
				$name = join("/",@{$i[0]});
				$name =~ s/([^A-Za-z0-9_])/ "%".sprintf("%.2X",ord($1)) /ge;
				foreach (@i) {
					$idx{join("/",@$_)} = [$name,$idx,"perlvar.pod"];
				}
				#print "Index: ",Simplify::dumpout([@i]),"\n";
			} else {
				doindex(@i);
			}
		}
	}
}

sub dump1 {
	my($par,$line,$pos,$cmd,$var1,$var2) = @_;
	
	# Save the parsed data for later processing
	push(@results,@_);
	
	if( $cmd =~ /^(item|head|flow|index)$/) {
		doindex(@$var2);
	}
}

=item comment COMMENTS

Create a comment HTML element.

Currently, will not be printed in normal HTML display.

=cut
sub comment {
	my $cmt = new HTML::Element 'comment';
	$cmt->push_content(@_);
	return $cmt;
}

@formatStack = ();

sub Format {
	my($par,$line,$pos,$cmd,$var1,$var2) = @_;

	#print "cmd = $cmd\n";
	
	if( $cmd eq "begin" ) {
		if($var1 eq "list") {
			my $f;
			if($var2 eq "bullet") {
				$f = ul();
			}
			elsif($var2 eq "number") {
				$f = ol();
			} else {
				$f = dl();
			}
			$formatted->push_content($f);
			push(@formatStack, $formatted);
			$formatted = $f;
		}
		elsif($var1 eq "pod") {
			$documentTitle = title();
			$documentTitle->push_content($var2->[0]);
			$documentHead = head($documentTitle);
			$documentBody = body();
			$document = html($documentBody);
	
			# $formatted retains the element pointer
			$formatted = $documentBody;
			@formatStack = ();
		}
	}
	elsif( $cmd eq "end" ) {
		if($var1 eq "list") {
			$formatted = pop(@formatStack);
		} elsif($var1 eq "pod") {
			print $document->as_HTML();
		}
	}
	elsif( $cmd eq "item") {
#		print "v=".Simplify::dumpout($var2)."\n";
		if($var1->[0] eq "bullet" or $var1->[0] eq "number") {
			$formatted->push_content(li(flowed(@$var2)));
		} else {
			$formatted->push_content(dt(strong(flowed(@$var2))));
			push(@formatStack, $formatted);
			$f = dd();
			$formatted->push_content($f);
			$formatted = $f;
		}
	}
	elsif( $cmd eq "head") {
		my($head) = new HTML::Element "h".$var1;
		$head->push_content(flowed(@$var2));
		if ( $var1 < 2 ) {
			$formatted->push_content(hr());
		}
		$formatted->push_content($head);
	}
	elsif( $cmd eq "verb") {
		$var1 =~ s/^/        /gm;
		my $pre = pre(simpleText($var1));
		$formatted->push_content($pre);
	}
	elsif( $cmd eq "flow") {
		@f = flowed(@$var2);
		if ( $formatted->tag eq 'dd' ) {
			# First element of definition.
			# Don't use a paragraph here
			$formatted->push_content(@f);
		} else {
			$formatted->push_content(p(@f));
		}
	}
	elsif( $cmd eq "comment" ) {
		$var1 =~ s/--/- -/g;
		$var1 =~ s/</lt/g;
		$var1 =~ s/>/gt/g;
		$formatted->push_content(comment($var1));
	}
	elsif( $cmd eq "index") {
		push(@waitingindex,map(join("/",@$_),@{$var2->[0]}));
	}
}

#$x->parse_from_file_by_name("newvar.pod",\&dump1);
#$x->parse_from_file_by_name($ARGV[0] || "newfunc.pod",\&dump2);

#write index
#foreach (sort keys %idx) {
#	print join(" ",$_,@{$idx{$_}}),"\n";
#}

#dump2(@_) while(@_=splice(@results,0,6));

1;
