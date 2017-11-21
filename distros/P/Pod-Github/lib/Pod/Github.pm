package Pod::Github;
use strict;
use warnings;
use Carp qw(croak);
use Encode;
use File::Slurp qw(read_file);
use parent 'Pod::Markdown';

our $VERSION = '0.03';

my $DATA_KEY = '_Pod_Github_';

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new();
    $self->{$DATA_KEY} = \%args;

    return $self;
}

sub _should_exclude_section {
    my ($self, $heading) = @_;
    my @include = @{$self->{$DATA_KEY}{include} || []};
    my @exclude = @{$self->{$DATA_KEY}{exclude} || []};

    if (@include) {
        return not grep { $_ eq $heading } @include; 
    }
    else {
        return grep { $_ eq $heading } @exclude;
    }
}

sub _should_inline_section {
    my ($self, $heading) = @_;
    my @inline = @{$self->{$DATA_KEY}{inline} || []};

    return grep { $_ eq $heading } @inline;
}

# Output markdown content $name if configured via the '$name' or '${name}-file' options
# We assume UTF-8.
# Outputting a header may break meta_tags, but these are not supported.
sub _include_markdown {
    my ($self, $name) = @_;

    my $conf = $self->{$DATA_KEY};

    my $content = $conf->{$name}           ? $conf->{$name}
                : $conf->{$name . '-file'} ? scalar read_file($conf->{$name . '-file'})
                                           : undef
                                           ;

    if (defined $content) {
        print { $self->{output_fh} } Encode::encode('UTF-8', $content);
    }
}

# Called when rendering an indented block. Detect if it's a code block and convert
# to Github Flavored Markdown.
sub _indent_verbatim {
    my ($self, $paragraph) = @_;

    $paragraph = $self->SUPER::_indent_verbatim($paragraph);

    if ($self->{$DATA_KEY}{'syntax-highlight'}) {
        # Github code blocks don't need indentation, so we can remove it.
        $paragraph = join "\n", map { s/^\s{4}//; $_ } split /\n/, $paragraph;

        # Enclose the paragraph in ``` and specify the language
        $paragraph = sprintf( "```%s\n%s\n```", $self->_syntax($paragraph), $paragraph );
    }

    return $paragraph;
}

# Called just before output. We carry out most operations here:
#  - Skipping or inlining headings
#  - Converting headings to title case
#  - Codifying OPTIONS, METHODS etc.
#  - Adding header and/or footer
sub end_Document {
    my ($self) = @_;

    # We are about to output the finished markdown, but do our custom
    # processing first.  The text resides in $self->_private->{stacks}->[0]
    @{ $self->_private->{stacks} } == 1 or die "Invalid state: stacks > 1";

    my $conf = $self->{$DATA_KEY};

    my @stack = @{ $self->_private->{stacks}[0] };
    my @new;
    my $skip_until_level = 0;

    for my $para (@stack) {
        # Is this paragraph a heading?
        if ($para =~ /^(#+) (.*)/) {
            my ($level, $heading) = (length $1, $2);

            if ($skip_until_level) {
                # We are skipping over everything until we reach a heading of level
                # $skip_until_level
                if ($level > $skip_until_level) {
                    next;
                }
                else {
                    # Not skipping anymore.
                    $skip_until_level = 0;
                }
            }

            if ($self->_should_exclude_section($heading)) {
                $skip_until_level = $level;
            }
            elsif ($self->_should_inline_section($heading)) {
                # Remove the header (first line), but keep the content
                $para =~ s/^.*(\n|$)//;
                push @new, $para if $para ne "\n";
            }
            else {
                if ($conf->{'title-case'}) {
                    $heading = _title_case($heading);
                }

                if ($conf->{'shift-headings'}) {
                    $level += $conf->{'shift-headings'};
                }

                my $new_heading = ('#' x $level) . ' ' . $heading;
                $para =~ s/^.*(?=\n|$)/$new_heading/;

                push @new, $para;
            }
        }
        else {
            # Non-heading content
            push @new, $para unless $skip_until_level;
        }
    }

    $self->_private->{stacks}[0] = \@new;
    $self->_private->{states}[-1]{blocks} = scalar @new;

    $self->_include_markdown('header');

    $self->SUPER::end_Document;

    $self->_include_markdown('footer');
}

# Syntax guesser, lifted from Pod::Markdown::Github
sub _syntax {
    my ($self, $paragraph) = @_;

    return ( $paragraph =~ /(\b(sub|my|use|shift)\b|\$self|\=\>|\$_|\@_)/ )
        ? 'perl'
        : '';
}

# Uses John Gruber's TitleCase.pl under MIT license.
sub _title_case {
    my @small_words = qw( (?<!q&)a an and as at(?!&t) but by en for if in of on or the to v[.]? via vs[.]? );
    my $small_re = join '|', @small_words;

    my $apos = qr/ (?: ['’] [[:lower:]]* )? /x;

    $_ = shift;

	s{\A\s+}{}, s{\s+\z}{};
	$_ = lc $_ if not /[[:lower:]]/;
	s{
		\b (_*) (?:
			( (?<=[ ][/\\]) [[:alpha:]]+ [-_[:alpha:]/\\]+ |   # file path or
			  [-_[:alpha:]]+ [@.:] [-_[:alpha:]@.:/]+ $apos )  # URL, domain, or email
			|
			( (?i: $small_re ) $apos )                         # or small word (case-insensitive)
			|
			( [[:alpha:]] [[:lower:]'’()\[\]{}]* $apos )       # or word w/o internal caps
			|
			( [[:alpha:]] [[:alpha:]'’()\[\]{}]* $apos )       # or some other word
		) (_*) \b
	}{
		$1 . (
		  defined $2 ? $2         # preserve URL, domain, or email
		: defined $3 ? "\L$3"     # lowercase small word
		: defined $4 ? "\u\L$4"   # capitalize word w/o internal caps
		: $5                      # preserve other kinds of word
		) . $6
	}xeg;


	# Exceptions for small words: capitalize at start and end of title
	s{
		(  \A [[:punct:]]*         # start of title...
		|  [:.;?!][ ]+             # or of subsentence...
		|  [ ]['"“‘(\[][ ]*     )  # or of inserted subphrase...
		( $small_re ) \b           # ... followed by small word
	}{$1\u\L$2}xig;

	s{
		\b ( $small_re )      # small word...
		(?= [[:punct:]]* \Z   # ... at the end of the title...
		|   ['"’”)\]] [ ] )   # ... or of an inserted subphrase?
	}{\u\L$1}xig;

	# Exceptions for small words in hyphenated compound words
	## e.g. "in-flight" -> In-Flight
	s{
		\b
		(?<! -)					# Negative lookbehind for a hyphen; we don't want to match man-in-the-middle but do want (in-flight)
		( $small_re )
		(?= -[[:alpha:]]+)		# lookahead for "-someword"
	}{\u\L$1}xig;

	## # e.g. "Stand-in" -> "Stand-In" (Stand is already capped at this point)
	s{
		\b
		(?<!…)					# Negative lookbehind for a hyphen; we don't want to match man-in-the-middle but do want (stand-in)
		( [[:alpha:]]+- )		# $1 = first word and hyphen, should already be properly capped
		( $small_re )           # ... followed by small word
		(?!	- )					# Negative lookahead for another '-'
	}{$1\u$2}xig;

    return $_;
}

1;

__END__

=head1 NAME

 Pod::Github - convert POD to Github markdown

=head1 SYNOPSIS

 my $parser = Pod::Github->new(%opts);
 $parser->output_fh(\*STDOUT);
 $parser->parse_file(\*ARGV);

=head1 DESCRIPTION

Subclass of C<Pod::Simple> that accepts POD and outputs Github Flavored
Markdown (GFM). Optionally inlines or removes headings and/or prettifies
the markdown to look better as a GitHub readme.

=head1 METHODS

=over

=item new (%opts)

Accepts the arguments in the same form as the binary C<bin/pod2github>
(i.e. with dashes, not underscores). C<include>, C<exclude> and C<inline>
should be arrayrefs of section names rather than a CSV string.

=item output_fh (fh)

Set the filehandle for Markdown output.

=item output_string (stringref)

Sets the string that $parser's output will be sent to, instead of a
filehandle.

=item parse_file (fh)

Read POD from the given filehandle and output Markdown to C<output_fh>.

=item parse_string_document (string)

Works like C<parse_file> except it reads the POD from a string already
in memory.

=item parse_lines (list)

Works like C<parse_file> except it reads the POD from a list of strings,
each containing exactly one line of content.

=back
