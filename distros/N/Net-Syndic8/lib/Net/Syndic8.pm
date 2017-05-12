package Net::Syndic8;

use strict;
use warnings;
require RPC::XML;
require RPC::XML::Client;
use Net::Syndic8::RPCXML;
use Net::Syndic8::FeedsCollection;
use Net::Syndic8::Base;
our @ISA = qw(Net::Syndic8::Base);
our $VERSION = '0.04';
attributes (qw/Gate FeedsColl/);

sub _init { my $self=shift;$self->Init(@_);return 1}

sub Init {
my ($self)=@_;
$self->Gate(new Net::Syndic8::RPCXML:: ('http://www.syndic8.com/xmlrpc.php'));
$self->FeedsColl(
	new Net::Syndic8::FeedsCollection (
				cache=>{},
				gate=>$self->Gate()
				));
}

sub FindSites {
my $self=shift;
return $self->FeedsColl()->FindSites(@_);
}
sub FindFeeds {
my $self=shift;
return $self->FeedsColl()->FindFeeds(@_);
}
# Preloaded methods go here.

1;
__END__

=head1 NAME

Net::Syndic8 - Object-oriented Perl interface to access and change information within the Syndic8 site

=head1 SYNOPSIS

  use Net::Syndic8;
  my $obj= new Net::Syndic8::;
  my $res=$obj->FindFeeds('unix');
 ...
  foreach my $feed (@$res) {
	my $hash_ref=$feed->Data;
	print join "\t"=> $feed->ID, map { $hash_ref->{$_} } qw/siteurl sitename dataurl/;
	print "\n";
 }
 ...
  while (my @bulk=splice(@$res,0,10)) {     #splice by ten items
    $obj->FeedsColl()->Load(@bulk);         #for bulk load (by one query to Syndic8)
    foreach my $feed (@bulk) {              # it use syndic8.GetFeedInfo for array
	my $hash_ref=$feed->Data;
	print join "\t"=> $feed->ID, map { $hash_ref->{$_} } qw/siteurl sitename dataurl/;
	print "\n";
	}
	}
 ...

=head1 DESCRIPTION

Syndic8.com is the place to come to find RSS and Atom news feeds on a wide variety of topics.
It have XML-RPC web service calls, which can be used to access and change information within the Syndic8 site.


=head1 PUBLIC METHODS

=over 3

=item * FindFeeds (rpc function: syndic8.FindFeeds)

This function takes the given pattern, matches it against all of the text fields of each feed in the feed list,
optionally sorts, the results by the given field, and returns the FeedIDs of the matching feeds, optionally
restricted to the given limit. 

=item * FindSites (rpc function: syndic8.FindSites)

This function takes the given pattern, matches it against the SiteURL feed of each feed in the feed list,
and returns the FeedIDs of the matching feeds.

=back

=head1 SEE ALSO

http://www.syndic8.com/web_services/,

Net::Syndic8::FeedsCollection,

Net::Syndic8::RPCXML .

=head1 AUTHOR

Zahatski Aliaksandr, E<lt>zagap@users.sourceforge.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
