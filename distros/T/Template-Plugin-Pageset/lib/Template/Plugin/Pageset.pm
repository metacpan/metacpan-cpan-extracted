package Template::Plugin::Pageset;

use strict;
use vars qw($VERSION);
use Data::Page::Pageset;
use Template::Plugin;
use base qw(Template::Plugin);

our $VERSION = sprintf "%d.%02d", q$Revision: 1.02 $ =~ /: (\d+)\.(\d+)/;

sub new {
	my ($proto, $context, $page, $param ) = @_;
	my $class = ref($proto) || $proto;

	($page, $param) = ($context, $page, $param )
		unless ref($context) =~ /^Template::/;

	my $pageset = Data::Page::Pageset->new( $page, $param );	
	return $pageset;
}

1;

=head1 NAME

Template::Plugin::Pageset - wrapper for Data::Page::Pageset

=head1 SYNOPSIS

 # pager is a Data::Page object
 [% USE pageset = Pageset( pager ) %] # pages_per_set is using default 10
 [% USE pageset = Pageset( pager, 7 ) %] # pages_per_set is 7
 [% USE pageset = Pageset( pager, { pages_per_set => 12 } ) %] # set max_pagesets to be 12
 [% USE pageset = Pageset( pager, { max_pagesets => 4 } ) %] # set max_pagesets to be 4

=head1 DESCRIPTION

	[% IF pageset.previous_pageset %]
		<a href="JavaScript:goto_page('[% pageset.previous_pageset.middle %]');">Previous Pageset</a>&nbsp;
	[% END %]

	[% FOREACH chunk = pageset.total_pagesets %]
		[% IF chunk.is_current %]
			[% FOREACH num = [ chunk.first .. chunk.last ] %]
				[% IF num == pager.current_page %]
					<b>[% num %]</b>
				[% ELSE %]
					<a href="JavaScript:goto_page('[% num %]');">[% num %]</a>
				[% END %]
			[% END %]
		[% ELSE %]
			<a href="JavaScript:goto_page('[% chunk.first %]');">[% chunk %]</a>
		[% END %]
	[% END %]

	[% IF pageset.next_pageset %]
		<a href="JavaScript:goto_page('[% pageset.next_pageset.middle %]');">Next Pageset</a>&nbsp;
	[% END %]

=head1 See Also

L<Data::Page::Pageset|Data::Page::Pageset> is the core one, more methods see that pod.

=head1 AUTHOR

Chun Sheng, <me@chunzi.org>

=head1 COPYRIGHT

Copyright (C) 2004-2005, Chun Sheng

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=cut
