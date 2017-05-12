package PPI::HTML::Fragment;

# A HTML fragment object is a small object that contains a string due to
# become HTML content, and a simple rule for it's display, such as a class
# name.

use strict;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.08';
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class  = ref $_[0] ? ref shift : shift;
	my $string = defined $_[0] ? shift : return undef;
	my $css    = shift or return undef;

	# Create the basic object
	my $self = bless {
		string => $string,
		css    => $css,
		}, $class;

	$self;
}

sub string { $_[0]->{string} }
sub css    { $_[0]->{css}    }





#####################################################################
# Main Methods

# Does the segment end with a newline?
sub ends_line { $_[0]->string =~ /\n$/ }

# Render to HTML
sub html {
	my $self = shift;
	my $html = $self->_escape( $self->string );
	return $html unless $self->css;
	$self->_tagpair( 'span', { class => $self->css }, $html );
}

sub concat {
	my $self = shift;
	my $string = defined $_[0] ? shift : return undef;
	$self->{string} .= $string;
	1;
}

sub clear {
	my $self = shift;
	delete $self->{css};
	1;
}





#####################################################################
# Support Methods

# Embedding some HTML stuff until I find a suitably lightweight dependency
sub _escape {
	my $html = defined $_[1] ? "$_[1]" : return '';
	$html =~ s/&/&amp;/g;
	$html =~ s/</&lt;/g;
	$html =~ s/>/&gt;/g;
	$html =~ s/\"/&quot;/g;
	$html =~ s/(\015{1,2}\012|\015|\012)/<br>\n/g;
	$html;
}

sub _tagpair {
	my $class = shift;
	my $tag   = shift or return undef;
	my %attr  = ref $_[0] eq 'HASH' ? %{shift()} : ();
	my $start = join( ' ', $tag,
		map { defined $attr{$_} ? qq($_="$attr{$_}") : "$_" }
		sort keys %attr );
	"<$start>" . join('', @_) . "</$tag>";
}

1;
