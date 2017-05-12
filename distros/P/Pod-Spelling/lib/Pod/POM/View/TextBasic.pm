use strict;
use warnings;

package Pod::POM::View::TextBasic;
our $VERSION = 0.2;

use base 'Pod::POM::View::Text';

our $DROPS = 1;

sub view_for { return maybe_stopwords(@_); }

sub view_begin { return maybe_stopwords(@_); }

sub maybe_stopwords {
    my ($format, $text) = $_[1] =~ /^\s*\=\w+\s+(\S+)\s+(.*?)\s*$/si;
    $text =~ s/\s+/ /g;
    return $format =~ /^(stopwords?|spelling|allow|allow_words|allowed_words)$/gi? $text : '';
}

sub view_seq_bold { return $_[1]; }

sub view_seq_italic { return $_[1]; }

sub view_seq_code { return $DROPS? '' : $_[1] }

sub view_seq_file { return $DROPS? '' : $_[1] }

sub view_seq_link {
	return $DROPS? '' : $_[1];
    my ($self, $link) = @_;
    return ($link =~ m/^(.*?)\|/) ?
    	$1 : $link;
}
	
sub view_verbatim { return $DROPS? '' : $_[1] }

1;

=head1 NAME

Pod::POM::View::TextBasic - Pod::POM::View::Text without sequence formatting

=head1 SYNOPSIS

	Pod::POM->default_view( 'Pod::POM::View::TextBasic' )
		or die $Pod::POM::ERROR;
	my $p = Pod::POM->new;
	$p->parse_file(...);
	
=head1 DESCRIPTION

A sub-class of L<Pod::POM::View::Text|Pod::POM::View::Text> 
that does not ornament inline sequences to indicate their presence.

This class was developed to aid spell-checking POD: for that reason,
verbatim blocks, inline code sequences, and the bodies of links are ignored 
unless C<Pod::POM::View::TextBasic::DROPS> is set to a false value by the user.

=head1 AUTHOR

Lee Goddard (C<lgoddard-at-cpan.org>).

=head1 COPYRIGHT 

Copyright (C) 2011, Lee Goddard. All Rights Reserved.



