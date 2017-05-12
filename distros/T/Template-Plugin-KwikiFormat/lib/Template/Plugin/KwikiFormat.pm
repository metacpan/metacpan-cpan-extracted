package Template::Plugin::KwikiFormat;
use strict;
use warnings;
use Kwiki;
use Kwiki::Formatter;
use base 'Template::Plugin';
use vars qw($VERSION $FILTER_NAME);

$VERSION = '1.04';
$FILTER_NAME = 'kwiki';

sub new {
    my ($self, $context, @args) = @_;
    my $name = $args[0] || $FILTER_NAME;
    $context->define_filter($name, \&kwiki, 0);
    return $self;
}

use constant USE_CLASS_COMPLIENT => Kwiki->VERSION < 0.38;

my $kwiki;
if (USE_CLASS_COMPLIENT) {
    $kwiki = Kwiki->new;
    $kwiki->load_hub({formatter_class => 'Kwiki::Formatter' });
    $kwiki->use_class('formatter');
}
else {
    $kwiki = Kwiki::Formatter->new;
}

sub kwiki {
    my $text=shift;
    return USE_CLASS_COMPLIENT
        ? $kwiki->formatter->text_to_html($text)
        : $kwiki->text_to_html($text);
}

{
    no warnings;

    sub Kwiki::Formatter::ForcedLink::pattern_start {
	return qr/\[([\w\s\/\.\-]+)\]/;
    }
    sub Kwiki::Formatter::ForcedLink::html {
	my $self=shift;
	my $text = $self->escape_html($self->matched);
	$text=~s/\[|\]//g;
	my @text=split(/\s+/,$text);
	my ($target,@title);
	foreach my $frag (@text) {
	    if ($frag=~m{^\w+://}) {
		$target=$frag;
	    } elsif ($frag=~m{^/}) {
		$target=$frag;
	    } else {
		push(@title,$frag);
	    }
	}
	my $title=join(' ',@title);
	return $title unless $target;

	$title = $target unless $title =~ /\S/;
	return qq(<a href="$target">$title</a>);
    }

    sub Kwiki::Formatter::WikiLink::html {
	my $self=shift;
	return $self->matched
    }

    sub Kwiki::Formatter::TitledWikiLink::html {
	my $self=shift;
	return $self->matched
    }
}


1;

__END__

=pod

=head1 NAME

Template::Plugin::KwikiFormat - filter to convert kwiki formatted text to html

=head1 SYNOPSIS

  [% USE KwikiFormat %]
  
  [% FILTER kwiki %]
  
  == title
  
  *bold* /italic/
  
  [% END %]

=head1 DESCRIPTION

A wrapper around Kwiki::Formatter.

Template::Plugin::KwikiFormat allows you to use KwikiFormats in data
displayed by Template::Toolkit.

=head2 MARKUP SYNTAX

See here:

http://www.kwiki.org/?KwikiFormattingRules

BUT:

WikiLinks don't work without a kwiki, so we need some magic / dirty
tricks to make it work (i.e.: subroutine redefinition at runtime)

ANOTHER BUT:

I slightly altered the meaning of ForcedLinks. In Kwiki, something like this

  [SomePage see here]

results in a link to the Kwiki-Page "SomePage" labeld with "see here".

With Template::Plugin::KwikiFormat, you can (ab)use this syntax for
local (relative) links. i.e.:

  [/some/page.html see here]

gets rendered as a link to "/some/page.html" labled with "see here".

One of the fragments inside the square bracktes needs to start with a
slash for this to work.


=head2 METHODS

=head3 new

generate new plugin

=head3 kwiki

convert text

=head1 AUTHOR

Thomas Klausner, domm@zsi.at, http://domm.zsi.at

With a lot of thanks to Jon Åslund (Jooon) from #kwiki for coming up
with how to do it.

Additional thanks to Ian Langworth.

From March 2006, this module is taken over and maintained by Satoshi
Tanimoto E<lt>tanimoto@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2004, Thomas Klausner, ZSI

You may use, modify, and distribute this package under the same terms
as Perl itself.

=cut
