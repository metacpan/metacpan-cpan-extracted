package PPI::HTML;

=pod

=head1 NAME

PPI::HTML - Generate syntax-hightlighted HTML for Perl using PPI

=head1 SYNOPSIS

  use PPI;
  use PPI::HTML;
  
  # Load your Perl file
  my $Document = PPI::Document->load( 'script.pl' );
  
  # Create a reusable syntax highlighter
  my $Highlight = PPI::HTML->new( line_numbers => 1 );
  
  # Spit out the HTML
  print $Highlight->html( $Document );

=head1 DESCRIPTION

PPI::HTML converts Perl documents into syntax highlighted HTML pages.

=head1 HISTORY

PPI::HTML is the successor to the now-redundant PPI::Format::HTML.

While early on it was thought that the same formatting code might be able
to be used for a variety of different types of things (ANSI and HTML for
example) later developments with the here-doc code and the need for
independantly written serializers meant that this idea had to be discarded.

In addition, the old module only made use of the Tokenizer, and had a
pretty shit API to boot.

=head2 API Overview

The new module is much cleaner. Simply create an object with the options
you want, pass L<PPI::Document> objects to the C<html> method,
and you get strings of HTML that you can do whatever you want with.

=head1 METHODS

=cut

use 5.005;
use strict;
use CSS::Tiny           ();
use PPI::Document       ();
use PPI::HTML::Fragment ();
use Params::Util '_HASH', '_INSTANCE';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.08';
}





#####################################################################
# Constructor and Accessors

=pod

=head2 new %args

The C<new> constructor takes a simple set of key/value pairs to define
the formatting options for the HTML.

=over

=item page

Is the C<page> option is enabled, the generator will wrap the generated
HTML fragment in a basic but complete page.

=item line_numbers

At the present time, the only option available. If set to true, line
numbers are added to the output.

=item colors | colours

For cases where you don't want to use an external stylesheet, you
can provide C<colors> as a hash reference where the keys are CSS classes
(generally matching the token name) and the values are colours.

This allows basic colouring without the need for a whole stylesheet.

=item css

The C<css> option lets you provide a custom L<CSS::Tiny> object containing
any CSS you want to apply to the page (if you are using page mode).

If both the C<colors> and C<css> options are used, the colour CSS entries
will overwrite anything contained in the L<CSS::Tiny> object. The object
will also be cloned if it to be modified, to prevent destroying any CSS
objects passed in.

=back

Returns a new L<PPI::HTML> object

=cut

sub new {
	my $class = ref $_[0] ? ref shift : shift;
	my %args  = @_;

	# Create the basic object
	my $self = bless {
		line_numbers => !! $args{line_numbers},
		page         => !! $args{page},
		# colors     => undef,
		# css        => undef,
		}, $class;

	# Manually specify the class colours and custom CSS
	$args{colors}   = delete $args{colours} if $args{colours};
	$self->{colors} = $args{colors}         if _HASH($args{colors});
	$self->{css}    = $args{css}            if _INSTANCE($args{css}, 'CSS::Tiny');

	$self;
}

=pod

=head2 css

The C<css> accessor returns the L<CSS::Tiny> object originally provided
to the constructor.

=cut

sub css { $_[0]->{css} }





#####################################################################
# Main Methods

=pod

=head2 html $Document | $file | \$source

The main method for the class, the C<html> method takes a single
L<PPI::Document> object, or anything that can be turned into a
L<PPI::Document> via its C<new> method, and returns a string of HTML
formatted based on the arguments given to the C<PPI::HTML> constructor.

Returns a string, or C<undef> on error.

=cut

sub html {
	my $self     = shift;
	my $Document = $self->_Document(shift) or return undef;

	# Build the basic set of fragments
	$self->_build_fragments($Document) or return undef;

	# Interleave the line numbers
	$self->_build_line_numbers or return undef;

	# Optimise
	$self->_optimize_fragments or return undef;

	# Merge and stringify the fragments
	$self->_build_html or return undef;

	# Return the final HTML
	delete $self->{html};
}

# Create the basic list of fragments
sub _build_fragments {
	my ($self, $Document) = @_;

	# Convert the list of tokens to a list of fragments
	$self->{fragments}      = [];
	$self->{heredoc_buffer} = undef;
	foreach my $Token ( $Document->tokens ) {
		# Find the Fragments for the token
		my @fragments = ();
		if ( _INSTANCE($Token, 'PPI::Token::HereDoc') ) {
			@fragments = $self->_heredoc_fragments($Token) or return undef;
		} else {
			@fragments = $self->_simple_fragments($Token) or return undef;
		}

		# Add the fragments
		foreach my $Fragment ( @fragments ) {
			$self->_add_fragment( $Fragment ) or return undef;
		}
	}

	# Are there any trailing heredoc lines to add?
	if ( $self->{heredoc_buffer} ) {
		# Unless the last line ends in a newline, add one
		unless ( $self->{fragments}->[-1]->ends_line ) {
			my $Fragment = PPI::HTML::Fragment->new( "\n" ) or return undef;
			push @{$self->{fragments}}, $Fragment;
		}

		# Add the remaining buffer lines
		push @{$self->{fragments}}, @{$self->{heredoc_buffer}};
	}

	# We don't need the heredoc buffer any more
	delete $self->{heredoc_buffer};

	1;
}

sub _simple_fragments {
	my ($self, $Token) = @_;

	# Split the token content into strings
	my @strings = grep { defined $_ and length $_ } split /(?<=\n)/, $Token->content;

	# Convert each string to a fragment
	my @fragments = ();
	my $css_class = $self->_css_class( $Token );
	foreach my $string ( @strings ) {
		my $Fragment = PPI::HTML::Fragment->new( $string, $css_class ) or return ();
		push @fragments, $Fragment;
	}

	@fragments;
}

sub _heredoc_fragments {
	my ($self, $Token) = @_;

	# First, create the heredoc content lines and add them
	# to the buffer
	foreach my $line ( $Token->heredoc ) {
		$self->_add_heredoc( $line,
			'heredoc_content' ) or return ();
	}

	# Add the terminator line
	$self->_add_heredoc( $Token->terminator . "\n",
		'heredoc_terminator' ) or return ();

	# Return a single fragment for the main content part
	my $Fragment = PPI::HTML::Fragment->new( $Token->content,
		$self->_css_class( $Token ) ) or return ();

	$Fragment;
}

sub _build_line_numbers {
	my $self = shift;
	return 1 unless $self->{line_numbers};

	# Find the width of the highest line number, so that
	# we can pad the line numbers
	my $max     = 1 + scalar map { $_->ends_line } @{$self->{fragments}};
	my $width   = length("$max");
	my $pattern = "\%${width}s: ";

	# Iterate over the existing array, and insert new line
	# fragments after each newline.
	my $line = 1;
	my @fragments = map {
		$_->ends_line
			? ($_, $self->_line_fragment( sprintf($pattern, ++$line) ))
			: ($_)
		} @{$self->{fragments}};

	# Add the fragment for line 1 to the beginning
	unshift @fragments, $self->_line_fragment( sprintf($pattern, 1) );

	$self->{fragments} = \@fragments;

	1;
}

sub _build_html {
	my $self = shift;

	# Iterate over the loop, stringifying and merging
	my $html = '';
	foreach my $Fragment ( @{$self->{fragments}} ) {
		$html .= $Fragment->html;
	}

	# Page wrap if needed
	if ( $self->{page} ) {
		my $css = $self->_css_html;

		$html = <<END_HTML;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN">
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
  <meta name="robots" content="noarchive">
$css
</head>
<body bgcolor="#FFFFFF" text="#000000"><pre>$html</pre></body>
</html>
END_HTML
	}

	# Replace the fragments array with the HTML
	$self->{html} = $html;
	delete $self->{fragments};

	1;
}

sub _optimize_fragments {
	my $self = shift;

	# Iterate through and do the simplest optimisation layer,
	# when is joining identical adjacent fragments.
	my $current = $self->{fragments};
	my @fragments = ( shift @$current );
	foreach my $Fragment ( @$current ) {
		if ( $Fragment->css and $fragments[-1]->css and $Fragment->css eq $fragments[-1]->css ) {
			$fragments[-1]->concat( $Fragment->string );
		} else {
			push @fragments, $Fragment;
		}
	}

	# Remove the class from all whitespace
	foreach my $Fragment ( @fragments ) {
		my $css = $Fragment->css or next;
		$Fragment->clear if $css eq 'whitespace';
	}

	# If we know what classes are coloured, strip the style
	# from everything that doesn't have a colour.
	if ( $self->{colors} ) {
		my $colors = $self->{colors};
		foreach my $Fragment ( @fragments ) {
			my $css = $Fragment->css or next;
			next if $colors->{$css};
			$Fragment->clear;
		}
	}

	# Overwrite the fragments list
	$self->{fragments} = \@fragments;

	1;
}

# For a set of colors, generate the relevant CSS
sub _css_html {
	my $self = shift;

	# Create and fill a CSS object
	my $css = $self->{css}
		? $self->{css}->clone
		: CSS::Tiny->new;
	foreach my $key ( sort keys %{$self->{colors}} ) {
		$css->{".$key"}->{color} = $self->{colors}->{$key};
	}

	keys %$css ? $css->html : '';
}





#####################################################################
# Support Methods

# Create a Document from anything we can
sub _Document {
	my $class = shift;
	_INSTANCE( $_[0], 'PPI::Document' )
		? $_[0]                        # Already a Document
		: PPI::Document->new( @_ ); # Make a Document
}

# Create a Fragment from anything we can
sub _Fragment {
	my $class = shift;
	_INSTANCE( $_[0], 'PPI::HTML::Fragment' )
		? $_[0] 
		: PPI::HTML::Fragment->new( @_ );
}

sub _add_fragment {
	my $self     = shift;
	my $Fragment = $self->_Fragment(@_) or return undef;

	# Add the fragment itself
	push @{$self->{fragments}}, $Fragment;

	# If the fragment ends a line, add
	# anything that is in the heredoc buffer.
	if ( $self->{heredoc_buffer} and $Fragment->ends_line ) {
		push @{$self->{fragments}}, @{$self->{heredoc_buffer}};
		$self->{heredoc_buffer} = undef;
	}

	1;
}

sub _add_heredoc {
	my $self     = shift;
	my $Fragment = $self->_Fragment(@_) or return undef;
	$self->{heredoc_buffer} ||= [];
	push @{$self->{heredoc_buffer}}, $Fragment;
	1;
}

sub _line_fragment {
	my ($self, $line) = @_;
	PPI::HTML::Fragment->new( $line, 'line_number' );
}

sub _css_class {
	my ($self, $Token) = @_;
	if ( $Token->isa('PPI::Token::Word') ) {
		# There are some words we can be very confident are
		# being used as keywords
		my $content = $Token->content;

		unless ( $Token->snext_sibling and $Token->snext_sibling->content eq '=>' ) {
			if ( $content eq 'sub' ) {
				return 'keyword';
			} elsif ( $content eq 'return' ) {
				return 'keyword';
			} elsif ( $content eq 'undef' ) {
				return 'core';
			} elsif ( $content eq 'shift' ) {
				return 'core';
			} elsif ( $content eq 'defined' ) {
				return 'core';
			}
		}

		my $parent = $Token->parent;
		if ( $parent->isa('PPI::Statement::Include') ) {
			if ( $content =~ /^(?:use|no)$/ ) {
				return 'keyword';
			}
			if ( $content eq $parent->pragma ) {
				return 'pragma';
			}
		} elsif ( $parent->isa('PPI::Statement::Variable') ) {
			if ( $content =~ /^(?:my|local|our)$/ ) {
				return 'keyword';
			}
		} elsif ( $parent->isa('PPI::Statement::Compound') ) {
			if ( $content =~ /^(?:if|else|elsif|unless|for|foreach|while|my)$/ ) {
				return 'keyword';
			}
		} elsif ( $parent->isa('PPI::Statement::Given') ) {
			if ( $content eq 'given' ) {
				return 'keyword';
			}
		} elsif ( $parent->isa('PPI::Statement::When') ) {
			if ( $content =~ /^(?:when|default)$/ ) {
				return 'keyword';
			}
		} elsif ( $parent->isa('PPI::Statement::Package') ) {
			if ( $content eq 'package' ) {
				return 'keyword';
			}
		} elsif ( $parent->isa('PPI::Statement::Scheduled') ) {
			return 'keyword';
		}
	}

	# Normal colouring
	my $css = lc ref $Token;
	$css =~ s/^.+:://;
	$css;
}

1;

=pod

=head1 SUPPORT

Bugs should always be submitted via the CPAN bug tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PPI-HTML>

For other issues, contact the maintainer

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

Funding provided by The Perl Foundation

=head1 SEE ALSO

L<http://ali.as/>, L<PPI>

=head1 COPYRIGHT

Copyright 2005 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
