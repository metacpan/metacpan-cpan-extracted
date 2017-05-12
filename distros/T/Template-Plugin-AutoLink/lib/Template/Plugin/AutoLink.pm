package Template::Plugin::AutoLink;

use strict;
use vars qw($VERSION $TextRe $TagRe $TagRe_ $UrlRe);
$VERSION = '0.03';

use Template::Plugin::Filter;
use base qw( Template::Plugin::Filter );

$TextRe = q{[^<]*};
$TagRe_ = q{[^"'<>]*(?:"[^"]*"[^"'<>]*|'[^']*'[^"'<>]*)*(?:>|(?=<)|$(?!\n))}; #'}}}};
my $comment_tag_re = '<!(?:--[^-]*-(?:[^-]+-)*?-(?:[^>-]*(?:-[^>-]+)*?)??)*(?:>|$(?!\n)|--.*$)';
$TagRe = qq{$comment_tag_re|<$TagRe_};

my $http_url_re =
q{\b(?:https?|shttp)://(?:(?:[-_.!~*'()a-zA-Z0-9;:&=+$,]|%[0-9A-Fa-f} .
q{][0-9A-Fa-f])*@)?(?:(?:[a-zA-Z0-9](?:[-a-zA-Z0-9]*[a-zA-Z0-9])?\.)} .
q{*[a-zA-Z](?:[-a-zA-Z0-9]*[a-zA-Z0-9])?\.?|[0-9]+\.[0-9]+\.[0-9]+\.} .
q{[0-9]+)(?::[0-9]*)?(?:/(?:[-_.!~*'()a-zA-Z0-9:@&=+$,]|%[0-9A-Fa-f]} .
q{[0-9A-Fa-f])*(?:;(?:[-_.!~*'()a-zA-Z0-9:@&=+$,]|%[0-9A-Fa-f][0-9A-} .
q{Fa-f])*)*(?:/(?:[-_.!~*'()a-zA-Z0-9:@&=+$,]|%[0-9A-Fa-f][0-9A-Fa-f} .
q{])*(?:;(?:[-_.!~*'()a-zA-Z0-9:@&=+$,]|%[0-9A-Fa-f][0-9A-Fa-f])*)*)} .
q{*)?(?:\?(?:[-_.!~*'()a-zA-Z0-9;/?:@&=+$,]|%[0-9A-Fa-f][0-9A-Fa-f])} .
q{*)?(?:#(?:[-_.!~*'()a-zA-Z0-9;/?:@&=+$,]|%[0-9A-Fa-f][0-9A-Fa-f])*} .
q{)?};

my $ftp_url_re =
q{\bftp://(?:(?:[-_.!~*'()a-zA-Z0-9;&=+$,]|%[0-9A-Fa-f][0-9A-Fa-f])*} .
q{(?::(?:[-_.!~*'()a-zA-Z0-9;&=+$,]|%[0-9A-Fa-f][0-9A-Fa-f])*)?@)?(?} .
q{:(?:[a-zA-Z0-9](?:[-a-zA-Z0-9]*[a-zA-Z0-9])?\.)*[a-zA-Z](?:[-a-zA-} .
q{Z0-9]*[a-zA-Z0-9])?\.?|[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)(?::[0-9]*)?} .
q{(?:/(?:[-_.!~*'()a-zA-Z0-9:@&=+$,]|%[0-9A-Fa-f][0-9A-Fa-f])*(?:/(?} .
q{:[-_.!~*'()a-zA-Z0-9:@&=+$,]|%[0-9A-Fa-f][0-9A-Fa-f])*)*(?:;type=[} .
q{AIDaid])?)?(?:\?(?:[-_.!~*'()a-zA-Z0-9;/?:@&=+$,]|%[0-9A-Fa-f][0-9} .
q{A-Fa-f])*)?(?:#(?:[-_.!~*'()a-zA-Z0-9;/?:@&=+$,]|%[0-9A-Fa-f][0-9A} .
q{-Fa-f])*)?};

my $mail_re =
q{(?:[^(\040)<>@,;:".\\\\\[\]\000-\037\x80-\xff]+(?![^(\040)<>@,;:".\\\\} .
q{\[\]\000-\037\x80-\xff])|"[^\\\\\x80-\xff\n\015"]*(?:\\\\[^\x80-\xff][} .
q{^\\\\\x80-\xff\n\015"]*)*")(?:\.(?:[^(\040)<>@,;:".\\\\\[\]\000-\037\x} .
q{80-\xff]+(?![^(\040)<>@,;:".\\\\\[\]\000-\037\x80-\xff])|"[^\\\\\x80-} .
q{\xff\n\015"]*(?:\\\\[^\x80-\xff][^\\\\\x80-\xff\n\015"]*)*"))*@(?:[^(} .
q{\040)<>@,;:".\\\\\[\]\000-\037\x80-\xff]+(?![^(\040)<>@,;:".\\\\\[\]\0} .
q{00-\037\x80-\xff])|\[(?:[^\\\\\x80-\xff\n\015\[\]]|\\\\[^\x80-\xff])*} .
q{\])(?:\.(?:[^(\040)<>@,;:".\\\\\[\]\000-\037\x80-\xff]+(?![^(\040)<>@,} .
q{;:".\\\\\[\]\000-\037\x80-\xff])|\[(?:[^\\\\\x80-\xff\n\015\[\]]|\\\\[} .
q{^\x80-\xff])*\]))*};

$UrlRe = "($http_url_re|$ftp_url_re|($mail_re))";

sub init {
    my $self = shift;
    $self->{_DYNAMIC} = 1;
    $self->install_filter('auto_link');
    return $self;
}

sub filter {
    my ($self, $str, $args, $config) = @_;

    $config = $self->merge_config($config);
	my $anchor = sprintf '<a %s href="',
		join ' ', map {qq|$_="$config->{$_}"|} keys %{$config};

	my $result = '';
	my $skip = 0;
	while ($str =~ /($TextRe)($TagRe)?/gso) {
		last if $1 eq '' and $2 eq '';
		my $text_tmp = $1;
		my $tag_tmp = $2;
		if ($skip) {
			$result .= $text_tmp . $tag_tmp;
			$skip = 0 if $tag_tmp =~ /^<\/[aA](?![0-9A-Za-z])/;
		} else {
			$text_tmp =~ s{$UrlRe}
				{my($org, $mail) = ($1, $2);
				 (my $tmp = $org) =~ s/"/&quot;/g;
			$anchor . ($mail ne '' ? 'mailto:' : '') . "$tmp\">$org</a>"}ego;
			$result .= $text_tmp . $tag_tmp;
			$skip = 1 if $tag_tmp =~ /^<[aA](?![0-9A-Za-z])/;
			if ($tag_tmp =~ /^<(XMP|PLAINTEXT|SCRIPT)(?![0-9A-Za-z])/i) {
				$str =~ /(.*?(?:<\/$1(?![0-9A-Za-z])$TagRe_|$))/gsi;
				$result .= $1;
			}
		}
	}
	return $result;
}

1;
__END__

=head1 NAME

Template::Plugin::AutoLink - TT filter plugin to replace URL and e-mail address with hyperlink automatically.

=head1 SYNOPSIS

 # in template

 [% use AutoLink %]

 [% FILTER auto_link target='_blank'  %]

 Search here
 http://www.google.com

 [% END %]

 # result in
 Search here
 <a href="http://www.google.com" target="_blank">http://www.google.com</a>

=head1 DESCRIPTION

Template::Plugin::AutoLink is filter plugin for TT, which replace URL and e-mail address with hyperlink automatically.

=head1 AUTHOR

Yasuhiro Horiuchi E<lt>yasuhiro@hori-uchi.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
