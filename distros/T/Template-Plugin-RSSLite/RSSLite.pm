package Template::Plugin::RSSLite;

use 5.006;
use strict;
use warnings;
use base qw( Template::Plugin );
use Template::Plugin;
use XML::RSSLite;

our $VERSION = '0.03';

sub new {
	my $class   = shift;
	my $context = shift;
	my $file = shift || return $class->error("Line ".__LINE__." Usage error, see documenatation for usage information.");
	my $result = {};
	open F, $file or return $class->error("Line ".__LINE__." ".$!);
	my $data = join("",(<F>));
	close F;
	XML::RSSLite::parseXML($result,\$data);
#	use Data::Dumper;print Dumper $result;
   	return $class->error("Line ".__LINE__." ".$!) unless ($result->{'rdf:RDF'}{'channel'}{'title'});
	bless $result, $class;
}

1;
__END__
=head1 NAME

Template::Plugin::RSSLite - Module to use XML::RSSLite as a Template::Toolkit plugin.

=head1 SYNOPSIS

  [% USE rss = RSSLite('filename') %]
  [% rss.title %]
  [% FOREACH rss.item %]
   * [% title %]
     [% link %]
  [% END %]

=head1 DESCRIPTION

See documentation for XML::RSSLite for more info.

A good way to learn more about what this module returns is to try this:

  [% USE rss = RSSLite('filename') %]
  [% USE Dumper %]
  [% Dumper.dump(rss) %]

=head1 AUTHOR

Kenneth Ekdahl E<lt>sensei@sensei.nuE<gt>

=head1 SEE ALSO

L<perl>, L<XML::RSSLite>, L<Template>.

=cut
