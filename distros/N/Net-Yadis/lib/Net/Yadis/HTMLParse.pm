package Net::Yadis::HTMLParse;

use strict;
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(parseMetaTags);

my $htmlre = qr{
# Starts with the tag name at a word boundary, where the tag name is
# not a namespace
<html\b(?!:)

# All of the stuff up to a ">", hopefully attributes.
([^>]*?)

(?: # Match a short tag
    />

|   # Match a full tag
    >

    # contents
    (.*?)

    # Closed by
    (?: # One of the specified close tags
        </?html\s*>

        # End of the string
    |   \Z

    )

)
}isox;

my $headre = qr{
# Starts with the tag name at a word boundary, where the tag name is
# not a namespace
<head\b(?!:)

# All of the stuff up to a ">", hopefully attributes.
([^>]*?)

(?: # Match a short tag
    />

|   # Match a full tag
    >

    # match the contents of the full tag
    (.*?)

    # Closed by
    (?: # One of the specified close tags
        </?(?:head|body)\s*>

        # End of the string
    |   \Z

    )

)
}soxi;

# http-equiv = $2 || $3
# content = $5 || $6
my $tagre = qr{
<meta\s+http-equiv=
(?:
# between matching quote marks
(["'])(.*?)\1
|
# or up to whitespace
([^"'\s]+)
)
\s*
content=
(?:
# between matching quote marks
(["'])(.*?)\4
|
# or up to whitespace
([^"'\s]+)
)
\s*
/?>?
}sixo;


my $removere = qr{
  # Comments
  <!--.*?-->

  # CDATA blocks
| <!\[CDATA\[.*?\]\]>

  # script blocks
| <script\b

  # make sure script is not an XML namespace
  (?!:)

  [^>]*>.*?</script>
}soix;

my %replacements = (
    'amp'   => '&',
    'lt'    => '<',
    'gt'    => '>',
    'quot'  => '"',
    );
    
sub parseMetaTags {
    my ($html) = @_;

    $html =~ s/$removere//;
    $html =~ $htmlre or return ();
    my $htmlcontents = $2;
    $htmlcontents =~ $headre or return ();
    my $head = $2;
    defined $head or return ();
    
    my %headerhash;
    foreach my $tag ($head =~ /$tagre/g) {
        my ($httpequiv,$content) = ($2 || $3, $5 || $6);
        for my $pat (keys %replacements) {
            $httpequiv =~ s/&$pat;/$replacements{$pat}/g;
            $content =~ s/&$pat;/$replacements{$pat}/g;
        }
        $headerhash{lc($httpequiv)}=$content;
    }
    
    return \%headerhash;
}

