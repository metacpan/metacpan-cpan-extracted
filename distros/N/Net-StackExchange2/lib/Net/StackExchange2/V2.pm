package Net::StackExchange2::V2;


use 5.006;
use strict;
use warnings FATAL => 'all';
use Data::Dumper;
use Net::StackExchange2::V2::Answers;
use Net::StackExchange2::V2::AccessTokens;
use Net::StackExchange2::V2::Badges;
use Net::StackExchange2::V2::Comments;
use Net::StackExchange2::V2::Errors;
use Net::StackExchange2::V2::Events;
use Net::StackExchange2::V2::Info;
use Net::StackExchange2::V2::Posts;
use Net::StackExchange2::V2::Privileges;
use Net::StackExchange2::V2::Questions;
use Net::StackExchange2::V2::Revisions;
use Net::StackExchange2::V2::Search;
use Net::StackExchange2::V2::Sites;
use Net::StackExchange2::V2::SuggestedEdits;
use Net::StackExchange2::V2::Tags;
use Net::StackExchange2::V2::Users;
use Net::StackExchange2::V2::Filters;
use Net::StackExchange2::V2::Inbox;
use Net::StackExchange2::V2::Notifications;

our $VERSION = "0.05";

sub new {
	my ($class, $params) = @_;
	my $self = undef;
	if($params) {
		$self =  $params;
	} else {
		$self = {};
	}
	bless $self, $class;
	return $self;
}
sub answers {
	my $self = shift;
	return Net::StackExchange2::V2::Answers->new({ %$self });
}
sub access_tokens {
	my $self = shift;
	return Net::StackExchange2::V2::AccessTokens->new({ %$self });
}
sub badges {
	my $self = shift;
	return Net::StackExchange2::V2::Badges->new({ %$self });
}
sub comments {
	my $self = shift;
	return Net::StackExchange2::V2::Comments->new({ %$self });
}
sub info {
	my $self = shift;
	print "info...\n";
	print Dumper($self);
	return Net::StackExchange2::V2::Info->new({ %$self });
}
sub posts {
	my $self = shift;
	return Net::StackExchange2::V2::Posts->new({ %$self});
}
sub privileges {
	my $self = shift;
	return Net::StackExchange2::V2::Privileges->new({ %$self });	
}
sub questions {
	my $self = shift;
	return Net::StackExchange2::V2::Questions->new( { %$self });	
}
sub revisions {
	my $self = shift;
	return Net::StackExchange2::V2::Revisions->new({ %$self });	
}
sub search {
	my $self = shift;
	return Net::StackExchange2::V2::Search->new({ %$self });
}
sub sites {
	my $self = shift;
	return Net::StackExchange2::V2::Sites->new({ %$self });	
}
sub errors {
	my $self = shift;
	return Net::StackExchange2::V2::Errors->new({ %$self });
}
sub suggested_edits {
	my $self = shift;
	return Net::StackExchange2::V2::SuggestedEdits->new({ %$self });
}
sub tags {
	my $self = shift;
	return Net::StackExchange2::V2::Tags->new({ %$self });
}
sub users {
	my $self = shift;
	return Net::StackExchange2::V2::Users->new({ %$self });
}
sub events {
	my $self = shift;
	return Net::StackExchange2::V2::Events->new({ %$self });
}
sub filters {
	my $self = shift;
	return Net::StackExchange2::V2::Filters->new({ %$self });
}
sub inbox {
	my $self = shift;
	return Net::StackExchange2::V2::Inbox->new({ %$self });
}
sub notifications {
	my $self = shift;
	return Net::StackExchange2::V2::Notifications->new({ %$self });
}
1; #End of StackExchange2::V2
__END__

=head1 NAME

Net::StackExchange2::V2 - StackExchange API V2

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

    use Net::StackExchange2;

	#For read-only methods.
    my $se = Net::StackExchange2->new({site => 'stackoverflow'});
	

=head1 Description

This module is an underlying wrapper for the various sub-modules for each stackexchange entitiy. 
Please see L<http://api.stackexchange.com/docs/> for information about the methods and their parameters

=head2 MODULES

This distibution contains the following modules, each correspond to a entity/type in the stackexchange api. Individual methods are documented 
inside the module itself. Ideally if you read the docs on L<Net::StackExchange2> you should be able to infer the methods inside a module from the 
stackexchange docs.

This wrapper contains the following modules, I've only included quick notes on each module here:

=head3 Answer

Stackoverflow answers.

=head3 Badges

Badges. They come in bronze, silver and gold. They support sort by rank, gold being the highest.

=head3 Comments

This contains two write methods to delete and edit comments. They require authentication. (access_token and key)

=head3 Events

Requires authentication. Gets a stream of events that happened on the site.

=head3 Info

Gets the site info. Reads the site parameter you passed in.

=head3 Posts

Stackexchange posts. By default does not include the body. Use filters for this.

=head3 Privileges

Contains one method to fetch all privileges on the site.

=head3 Questions

Also doesn't include body like posts and comments.

=head3 Revisions

Revisions take a guid as their id

=head3 Search

Has regular search, advanced search and similar search(by title) methods.

=head3 Suggested-Edits

Just gets suggested ids.

=head3 Tags

Note this doesn't have a tags([many tags]) method. The method is named tag_info(["perl", "javascript"])

=head3 Users

Contains MANY methods to get all sorts of information about the user

=head3 Network Methods

=head3 Access-Tokens

Has methods to dispose and inspect access_tokens

=head3 Applications

Has one method to de-authenticate

=head3 Errors

Gets information about error ids. Useful for debugging.

=head3 Filters

Has methods to create and inspect filters, like the docs say, you should only use this for debugging.

=head3 Inbox

Methods to get the users inbox and unread items. Authentication required on both methods.

=head3 Notifications

Gets the users notifications across sites. This method unloads

=head3 Sites

Gets information about all sites on the stackexchange network.


=head1 AUTHOR

Gideon Israel Dsouza, C<< <gideon at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-stackexchange2 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-StackExchange2>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

See L<Net::StackExchange2>.

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Gideon Israel Dsouza.

This library is distributed under the freebsd license:

L<http://opensource.org/licenses/BSD-3-Clause> 
See FreeBsd in TLDR : L<http://www.tldrlegal.com/license/bsd-3-clause-license-(revised)>
