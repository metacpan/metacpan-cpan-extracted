#!/usr/local/bin/perl -w

use strict ;
use Carp ;

use YAML ;

my @markup = (

	      {
	       'search'  => 'M<[^<>]+>',
	       'replace' => sub {
		       my ( $text ) = @_;

		       $text =~ s|M<([^<>]+)>|<SPAN CLASS="stem">$1</SPAN>|sg;

		       $text;
	       },

	      },

	      {
	       'search'  => 'QUOTE<(.*?)>',
	       'replace' => sub {
		       my ( $text ) = @_;

		       $text =~ /QUOTE<(.*?)>/gs;

		       my $before = $`;
		       my $after  = $';
		       my $quote  = $1;

		       $quote =~ s/\\/<BR>/sg;

		       $before .
		       "<P><TABLE BORDER='0' ALIGN='CENTER' CELLPADDING='3'" .
		       " CELLSPACING='0' BGCOLOR='FORESTGREEN'><TR><TD>" .
		       "<TABLE WIDTH='100%' CELLPADDING='3' CELLSPACING='2'" .
		       " BORDER='0' BGCOLOR='#CFE7CF'><TR><TH> $quote" .
		       "</TH></TR></TABLE></TD></TR></TABLE>" .
		       $after;
	       },
	      },

	     );


my (
    @sections,

    $header_text,

    $page_title_base
);

set_header_text() ;

process_faq_text() ;

process_sections() ;

print_section_page() ;

exit ;


sub process_faq_text {

	my ( $section, $quest_text, $answer_text, $curr_faq ) ;

	while( <> ) {

		next if /^\s*$/ ;
		s/\n/ /;

		if ( /^([SQ]):\s*(.+)$/ ) {


			if ( $curr_faq ) {


				$curr_faq->{'answer'} = 
				    markup_text( $answer_text ) ;

				$answer_text = '' ;

				unless ( $curr_faq->{'question'} &&
					 $curr_faq->{'answer'} ) {


					die

				 "bad FAQ entry before line $. in $ARGV\n" ;
				}

				push( @{$section->{'faqs'}}, $curr_faq ) ;
				$curr_faq = undef ;
			}

			if ( $1 eq 'S' ) {

				my $section_title = $2 ;

				push( @sections, $section ) if $section ;

				$section = {

					'plain_title' => $section_title,
					'title'       => markup_text( $section_title ),
				} ;

				next ;
			}

			$quest_text = $2 ;

			next ;
		}

		if ( /^A:\s*(.+)$/ ) {

			$answer_text = markup_text( $1 ) ;

			$curr_faq = {
				'question' => markup_text( $quest_text ),
			} ;

			$quest_text = '' ;
			next ;
		}

		if ( $quest_text ) {

			$quest_text .= $_ ;
			next ;
		}

		$answer_text .= $_ ;
	}

	push( @sections, $section ) ;
}


sub process_sections {


	my $sect_num = 1 ;

	foreach my $sect_ref ( @sections ) {


		my $title = $sect_ref->{'title'} ;

		$sect_ref->{'num'} = $sect_num ;

		my $link = <<LINK ;
$sect_num <A HREF="faq$sect_num.html">$title</A>
LINK

		$sect_ref->{'link'} = $link ;

		my $quest_num = 1 ;

		foreach my $faq_ref ( @{$sect_ref->{'faqs'}} ) {

			my $quest  = $faq_ref->{'question'} ;

			my $answer = $faq_ref->{'answer'} ;

			$faq_ref->{'num'} = $quest_num ;
			$faq_ref->{'index'} = "$sect_num.$quest_num" ;

			$faq_ref->{'link'} = <<LINK ;
$sect_num.$quest_num <A HREF="faq$sect_num.html#FAQ$quest_num">$quest</A>
LINK

			$quest_num++ ;
		}

		$sect_num++ ;
	}
}


sub print_section_page {

	my $page_text = <<HTML ;
<%attr>
        title => "$page_title_base"
</%attr>

<A HREF="index.html">Home</A> &gt <B>FAQ</B>

<HR CLASS="sep">

<H1>Frequently Asked Questions</H1>

<UL STYLE="list-style-type:none">
HTML

	foreach my $sect_ref ( @sections ) {

		my $link = $sect_ref->{'link'} ;

		$page_text .= "<LI>$link" ;

		print_faq_pages( $sect_ref ) ;
	}

	$page_text .= "</UL>";

	write_file( 'faq.html', $page_text ) ;

}

sub print_faq_pages {

	my ( $sect_ref ) = @_ ;

	my $quest_list ;

	my $faq_text ;

	my $plain_title = $sect_ref->{'plain_title'} ;
	my $title = $sect_ref->{'title'} ;
	my $sect_num = $sect_ref->{'num'} ;

	my $page_text = <<HTML ;
<%attr>
        title => "$page_title_base &gt; $plain_title"
</%attr>

<A HREF="index.html">Home</A> &gt <A HREF="faq.html">FAQ</A> &gt; <B>$title</B>

<HR CLASS="sep">

<H1><A NAME="top">$title</A></H1>

<HR CLASS="sep">

HTML


	$quest_list .= <<HTML ;
<UL STYLE="list-style-type:none">
HTML

	foreach my $faq_ref ( @{$sect_ref->{'faqs'}} ) {

		my $quest = $faq_ref->{'question'} ;
		my $answer = $faq_ref->{'answer'} ;

		my $faq_num = $faq_ref->{'num'} ;
		my $faq_ind = $faq_ref->{'index'} ;

		$quest_list .= <<HTML ;
<LI>$faq_ref->{'link'}
HTML


		$faq_text .= <<HTML ;

<A NAME="FAQ$faq_num"></A>

<H3>$quest</H3>
    <BLOCKQUOTE>
$answer
    </BLOCKQUOTE>

<DIV CLASS="toplink"><A HREF="#top">Top</A></DIV>

<HR CLASS="sep">

HTML

	}

	$quest_list .= "</UL>" ;


	my $section_list = '<UL STYLE="list-style-type:none">' ;

	foreach my $s_ref ( @sections ) {

		$section_list .= <<HTML ;
<LI>$s_ref->{'link'}
HTML

		if ( $s_ref == $sect_ref ) {

			$section_list .= $quest_list ;
		}

	}

	$section_list .= "</UL>" ;

	$page_text .= $section_list ;

	$page_text .= $faq_text ;

	write_file( "faq$sect_num.html", $page_text ) ;
}


sub set_header_text {

	$page_title_base = 'Stem Systems, Inc. &gt; Stem &gt; FAQ'
}


sub write_file {

	my( $file_name ) = shift ;

	local( *FH ) ;

	open( FH, ">$file_name" ) || carp "can't create $file_name $!" ;

	print FH @_ ;
}



sub markup_text {

	my ( $text ) = @_;

	map {

		if ($text =~ /$_->{'search'}/s) {

			$text = $_->{'replace'}->($text);
		}

	} @markup;

	return $text;

}


__END__


