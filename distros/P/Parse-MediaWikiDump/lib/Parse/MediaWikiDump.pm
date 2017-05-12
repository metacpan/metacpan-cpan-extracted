package Parse::MediaWikiDump;
our $VERSION = '1.0.6';

use Parse::MediaWikiDump::XML;
use Parse::MediaWikiDump::Revisions;
use Parse::MediaWikiDump::Pages;
use Parse::MediaWikiDump::page;
use Parse::MediaWikiDump::Links;
use Parse::MediaWikiDump::link;
use Parse::MediaWikiDump::CategoryLinks;
use Parse::MediaWikiDump::category_link;

#the POD is at the end of this file

sub new {
	my ($class) = @_;
	return bless({}, $class);
}

sub pages {
	shift(@_);
	return Parse::MediaWikiDump::Pages->new(@_);
}

sub revisions {
	shift(@_);
	return Parse::MediaWikiDump::Revisions->new(@_);
}

sub links {
	shift(@_);
	return Parse::MediaWikiDump::Links->new(@_);
}

#just a place holder for something that might be used in the future
#package Parse::MediaWikiDump::ExternalLinks;
#
#use strict;
#use warnings;
#
#sub new {
#	my ($class, $source) = @_;
#	my $self = {};
#
#	$$self{BUFFER} = [];
#	$$self{BYTE} = 0;
#
#	bless($self, $class);
#
#	$self->open($source);
#	$self->init;
#
#	return $self;
#}
#
#sub next {
#	my ($self) = @_;
#	my $buffer = $$self{BUFFER};
#	my $link;
#
#	while(1) {
#		if (defined($link = pop(@$buffer))) {
#			last;
#		}
#
#		#signals end of input
#		return undef unless $self->parse_more;
#	}
#
#	return Parse::MediaWikiDump::external_link->new($link);
#}
#
##private functions with OO interface
#sub parse_more {
#	my ($self) = @_;
#	my $source = $$self{SOURCE};
#	my $need_data = 1;
#	
#	while($need_data) {
#		my $line = <$source>;
#
#		last unless defined($line);
#
#		$$self{BYTE} += length($line);
#
#		while($line =~ m/\((\d+),'(.*?)','(.*?)'\)[;,]/g) {
#			push(@{$$self{BUFFER}}, [$1, $2, $3]);
#			$need_data = 0;
#		}
#	}
#
#	#if we still need data and we are here it means we ran out of input
#	if ($need_data) {
#		return 0;
#	}
#	
#	return 1;
#}
#
#sub open {
#	my ($self, $source) = @_;
#
#	if (ref($source) ne 'GLOB') {
#		die "could not open $source: $!" unless
#			open($$self{SOURCE}, $source);
#
#		$$self{SOURCE_FILE} = $source;
#	} else {
#		$$self{SOURCE} = $source;
#	}
#
#	binmode($$self{SOURCE}, ':utf8');
#
#	return 1;
#}
#
#sub init {
#	my ($self) = @_;
#	my $source = $$self{SOURCE};
#	my $found = 0;
#	
#	while(<$source>) {
#		if (m/^LOCK TABLES `externallinks` WRITE;/) {
#			$found = 1;
#			last;
#		}
#	}
#
#	die "not a MediaWiki link dump file" unless $found;
#}
#
#sub current_byte {
#	my ($self) = @_;
#
#	return $$self{BYTE};
#}
#
#sub size {
#	my ($self) = @_;
#	
#	return undef unless defined $$self{SOURCE_FILE};
#
#	my @stat = stat($$self{SOURCE_FILE});
#
#	return $stat[7];
#}
#
#package Parse::MediaWikiDump::external_link;
#
##you must pass in a fully populated link array reference
#sub new {
#	my ($class, $self) = @_;
#
#	bless($self, $class);
#
#	return $self;
#}
#
#sub from {
#	my ($self) = @_;
#	return $$self[0];
#}
#
#sub to {
#	my ($self) = @_;
#	return $$self[1];
#}
#
#sub index {
#	my ($self) = @_;
#	return $$self[2];
#}
#
#sub timestamp {
#	my ($self) = @_;
#	return $$self[3];
#


1;

__END__

=head1 NAME

Parse::MediaWikiDump - Tools to process MediaWiki dump files

=head1 SYNOPSIS

  use Parse::MediaWikiDump;
  
  $pmwd = Parse::MediaWikiDump->new;

  $pages = $pmwd->pages('pages-articles.xml');
  $revisions = $pmwd->revisions('pages-articles.xml');
  $links = $pmwd->links('links.sql');

=head1 DESCRIPTION

This software suite provides the tools needed to process the contents of the XML page 
dump files and the SQL based links dump file.

=head1 STATUS

This software is being RETIRED - MediaWiki::DumpFile is the official successor to
Parse::MediaWikiDump and includes a compatibility library called MediaWiki::DumpFile::Compat
that is 100% API compatible and is a near perfect standin for this module. It is faster
in all instances where it counts and is actively maintained. Any undocumented deviation
of MediaWiki::DumpFile::Compat from Parse::MediaWikiDump is considered a bug and will
be fixed. 

=head2 Migration

Please begin using MediaWiki::DumpFile::Compat immediately as a replacement for this
module. There will be no more features added to this software suite and bugs may not
be fixed. Parse::MediaWikiDump::Pages used to check the version of the dump file it is
parsing and reject versions it does not know about; this behavior has been removed. The
parser will now continue in this instance and hope for the best. This way this software
will continue to run into the future with out requiring further adjustment for as long
as the upstream fileformat remains compatible. 

In the event there is an unfixable bug or the dump file format changes in an incompatible 
way the Parse::MediaWikiDump module as a whole wil be replaced with a stub that brings in
MediaWiki::DumpFile::Compat - this may never need to happen but it is the plan for when it
does. Migrating on your terms instead of being forced to if this happens is suggested. 

=head1 USAGE

This module is a factory class that allows you to create instances of the individual 
parser objects. 

=over 4

=item $pmwd->pages

Returns a Parse::MediaWikiDump::Pages object capable of parsing an article XML dump file with one revision per each article.

=item $pmwd->revisions

Returns a Parse::MediaWikiDump::Revisions object capable of parsing an article XML dump file with multiple revisions per each article.

=item $pmwd->links

Returns a Parse::MediaWikiDump::Links object capable of parsing an article links SQL dump file.

=back

=head2 General

All parser creation invocations require a location of source data
to parse; this argument can be either a filename or a reference to an already
open filehandle. This entire software suite will die() upon errors in the file or if internal inconsistencies
have been detected. If this concerns you then you can wrap the portion of your code that uses these calls with eval().

=head1 AUTHOR

This module was created, documented, and is maintained by 
Tyler Riddle E<lt>triddle@gmail.comE<gt>. 

Fix for bug 36255 "Parse::MediaWikiDump::page::namespace may return a string
which is not really a namespace" provided by Amir E. Aharoni.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-parse-mediawikidump@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Parse-MediaWikiDump>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head2 Known Bugs

No known bugs at this time. 

=head1 COPYRIGHT & LICENSE

Copyright 2005 Tyler Riddle, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

