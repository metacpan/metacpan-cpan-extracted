package Pod::Usage::CGI;

use strict;
use Exporter;
use vars qw($VERSION @ISA @EXPORT);
$VERSION = sprintf'%d.%03d', q$Revision: 1.10 $ =~ /: (\d+)\.(\d+)/;
@ISA=qw(Exporter);
@EXPORT=qw(pod2usage);

sub pod2usage
{
	my %options = @_;
	my $message = '<div class="message">'._html_escape($options{message})."</div>\n" || $options{raw_message};
	my $css = delete $options{css};
	$css = [$css] if($css && ref $css ne 'array');
	my $file = ($0 eq '-e')? undef : $0;

	require Pod::Xhtml;
	my $parser = new Pod::Xhtml(%options, StringMode => 1);
	if($css) {
		$parser->addHeadText(qq[<link rel="stylesheet" href="$_"/>\n]) for @$css;
	}
	$parser->addBodyOpenText($message) if($message);
	my $usage = "";
	if($file) {
		$parser->parse_from_file($file);
		$usage = $parser->asString;
	}

	if($ENV{MOD_PERL}) {
		# Although Apache::Registry would do this for us
		# we do this to support any variants that may not
		require Apache;
		my $r = Apache->request;
		$r->content_type("text/html");
		$r->send_http_header;
		$r->print($usage);
		Apache::exit();					
	} else {
		require CGI;
		print CGI::header();
		print $usage;
		exit;
	}

}

sub _html_escape 
{
	my $str = shift;
	return '' unless length $str;
	$str =~ s/&/&amp;/g;
	$str =~ s/</&lt;/g;
	$str =~ s/>/&gt;/g;
	$str =~ s/'/&apos;/g;
	$str =~ s/\"/&quot;/g;
	return $str;
}

1;

=head1 NAME

Pod::Usage::CGI - generate usage message for CGI scripts

=head1 SYNOPSIS

	use CGI;
	use Pod::Usage::CGI;

	#Message is HTML-escaped
	my $necessary = CGI::param(foo) || pod2usage(message => "you forgot >>foo<<");

	#Raw message is not escaped
	my $another   = CGI::param(bar) || pod2usage(raw_message => "you forgot <b>bar</b>");

=head1 DESCRIPTION

Provides pod2usage exit from CGI scripts.  You may optionally supply a message.
By default the message text is escaped to prevent cross-site scripting injection attacks and placed in a div container of class "message" that you can optionally format with a CSS.
You can use the C<raw_message> directive if you want to write HTML out into the page and manage your own escaping.

The module works fine under Apache::Registry but will not work in any environments where $0 is not defined.

=head1 FUNCTIONS

=over 4

=item pod2usage(%options)

Displays usage and exits.  Valid options are:

	message - message (will be automatically escaped)
	raw_message - message (not escaped)
	css - one or more CSS URLs to be applied to the page (either a scalar or an arrayref)

=back

=head1 DEPENDENCIES

L<Pod::XHtml> and either L<Apache> or L<CGI> are loaded on demand if required

=head1 SEE ALSO

=over 4

=item L<Pod::Usage>

Generates usage messages for command line scripts

=back

=head1 VERSION

$Revision: 1.10 $ on $Date: 2005/07/15 11:25:22 $ by $Author: simonf $

=head1 AUTHOR

John Alden E<lt>cpan _at_ bbc _dot_ co _dot_ ukE<gt>

=head1 COPYRIGHT

(c) BBC 2005. This program is free software; you can redistribute it and/or modify it under the GNU GPL.
See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt

=cut
