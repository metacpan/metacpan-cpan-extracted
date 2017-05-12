package Net::OpenID::JanRain::Consumer::LinkParser;

use strict;
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(parseLinkAttrs parseOpenIDLinkRel);

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
}soxi;

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
}isox;

my $linkre = qr{
<link\b(?!:)
([^<>]*[^<>/])
/?>?
}six;


my $attrre = qr{
# Must start with a sequence of word-characters, followed by an equals sign
(\w+)=

# Then either a quoted or unquoted attribute
(?:

 # Match everything that is between matching quote marks
 (["'])(.*?)\2
|

 # If the value is not quoted, match up to whitespace
 ([^"'\s]+)
)
}sx;

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
    
sub parseLinkAttrs {
    my ($html) = @_;

    $html =~ s/$removere//;
    $html =~ $htmlre or return ();
    my $htmlcontents = $2;
    $htmlcontents =~ $headre or return ();
    my $head = $2;
    defined $head or return ();
    
    my @linkhashes;
    
    foreach my $linktag ($head =~ /$linkre/g) {
        my %linkhash;
        while ($linktag =~ /$attrre/g) {
            my ($k,$v) = ($1, $3 || $4);
            for my $pat (keys %replacements) {
                $k =~ s/&$pat;/$replacements{$pat}/g;
                $v =~ s/&$pat;/$replacements{$pat}/g;
            }
            $linkhash{lc($k)}=$v;
        }
        push @linkhashes, \%linkhash;
    }
    
    return @linkhashes;
}

sub parseOpenIDLinkRel {
    my $html = shift;
    
    my @linkhashes = parseLinkAttrs($html);

    my ($server, $delegate);
    for my $link (@linkhashes) {
        if (lc($link->{rel}) eq 'openid.server') {
            my %foo = %$link;
            $server = $link->{href};
        }
        if (lc($link->{rel}) eq 'openid.delegate') {
            $delegate = $link->{href};
        }
    }
    return ($delegate, $server);
}
