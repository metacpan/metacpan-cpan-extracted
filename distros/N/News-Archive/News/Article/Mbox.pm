$VERSION = 0.02;
package News::Article::Mbox;
our $VERSION = 0.02;

# -*- Perl -*-		# Thu Apr 29 12:06:38 CDT 2004 
###############################################################################
# Written by Tim Skirvin <tskirvin@killfile.org>.  Copyright 2004, Tim Skirvin. 
# Redistribution terms are below.
###############################################################################

=head1 NAME

News::Article::Mbox - combines News::Article and Mail::Mbox::MessageParser

=head1 SYNOPSIS

  use News::Article::Mbox;
  my @articles = News::Article::Mbox->read_mbox( \*STDIN );

=head1 DESCRIPTION

News::Article is capable of reading in individual messages from STDIN or
other sources to make into Article objects.  However, it is often helpful
to be able to read many Articles out of an mbox-class storage format, as
created by many newsreader programs.  This package adds a single function,
read_mbox(), to News::Article which makes this easy and accurate, using
the functionality of Mail::Mbox::MessageParser.

=head1 USAGE

Mostly the same as News::Article, except with the following function:

=cut

###############################################################################
### main() ####################################################################
###############################################################################

use strict;
use News::Article;		# CPAN
use Mail::Mbox::MessageParser;	# CPAN
use Carp;			# Perl Distribution
use Exporter;
use File::Temp qw/tempfile/;

use vars qw( @ISA @EXPORT @EXPORT_OK );
@ISA = qw ( News::Article );
@EXPORT_OK = qw ( read_mbox );

=over 4

=item read_mbox ( SOURCE [, MAXSIZE, MAXHEAD] )

Acts like B<News::Article::read()>, except that it loads a large number of
articles instead of each one.  C<SOURCE> is parsed with
C<Mail::Mbox::MessageParser>; if it turns out to only be a single news
message and not a full mbox, then this is bypassed and that message is
parsed.  All messages make B<News::Article> references.  Returns an array
or arrayref of articles.

This function is exportable, but is not exported by default.

=back

=cut

sub read_mbox {
  my ($self, $source, $maxsize, $maxhead) = @_;

  # Set up the data source, same as News::Article's read()
  $source = News::Article::source_init($source);
  ( my ($fh, $file_name) ) = tempfile(UNLINK => 1) 
	or croak "Could not create temporary file: $!";
  return undef unless defined $source;
  my @lines;
  while ( my $line = &$source ) { print $fh $line; push @lines, $line; }

  my @articles;
  my $parser = Mail::Mbox::MessageParser->new({ 'file_name' => $file_name,
						'enable_cache' => 0 });

  if (ref $parser) { 
    while (! $parser->end_of_file) {
      my $mailref = $parser->read_next_email;  
      my @lines = split("\n", $$mailref);
      my $article = News::Article->new(\@lines, $maxsize, $maxhead);
      $$article{TIMESTAMP} = $lines[0];
      push @articles, $article if $article;
    }
  } else {
    my $article = News::Article->new(\@lines, $maxsize, $maxhead); 
    push @articles, $article if $article;
  }
  
  wantarray ? @articles : [ @articles ];
}

1;

=head1 REQUIREMENTS

B<News::Article>, B<File::Temp>, B<Mail::Mbox::MessageParser>

=head1 SEE ALSO

B<News::Article>

=head1 TODO

This actually works pretty much the way it's supposed to.

It might be nice if we didn't have to use File::Temp...

=head1 AUTHOR

Tim Skirvin <tskirvin@killfile.org>

=head1 HOMEPAGE

B<http://www.killfile.org/~tskirvin/software/news-archive/>

B<http://www.killfile.org/~tskirvin/software/newslib/>

=head1 LICENSE

This code may be redistributed under the same terms as Perl itself.

=head1 COPYRIGHT

Copyright 2004, Tim Skirvin.

=cut

###############################################################################
##### Version History #########################################################
###############################################################################
# v0.01		Mon Apr 26 13:31:00 CDT 2004 
### First version.  Documentation is coming with it.  Will be a part of 
### News::Archive, not newslib or anything like that.
# v0.02		Thu Apr 29 12:06:15 CDT 2004 
### If the file turns out to not be an mbox, try just loading it as a
### single article.
