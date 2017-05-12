package Net::Syndic8::FeedsCollection;
use 5.008002;
use strict;
use warnings;
use Data::Dumper;
use Net::Syndic8::FeedObj;
use Net::Syndic8::Base;
our @ISA = qw(Net::Syndic8::Base);
our $VERSION = '0.01';
attributes (qw/Gate Cache/);

sub _init { my $self=shift;$self->Init(@_);return 1}

sub Init {
my($self,%arg)=@_;
my ($gate,$cache)=@arg{qw/gate cache/};
Gate $self $gate;
Cache $self $cache;
}

sub FindSites {
my ($self,$pattern)=@_;
my @found=@{$self->Gate->NewReq('syndic8.FindSites')->string($pattern)->value};
return $self->GetFeedsByID(@found)
}
sub FindFeeds {
my ($self,$pattern)=@_;
my @found=@{$self->Gate->NewReq('syndic8.FindFeeds')->string($pattern)->value};
return $self->GetFeedsByID(@found)
}

sub GetFeedsByID {
my ($self,@ids)=@_;
my $cache=$self->Cache();
return [map {
	$cache->{$_} = new Net::Syndic8::FeedObj (id=>$_,collection=>$self) 
					unless exists $cache->{$_};
	$cache->{$_}
	} @ids]
}

sub Load {
my ($self,@par)=@_;
my %fetch=map {($_->ID,$_) } grep {not $_->Loaded}  @par;
if (%fetch) {
	my %feeds_info;
	my @ids=keys %fetch;
	@feeds_info{@ids}=@{$self
	->Gate
	->NewReq('syndic8.GetFeedInfo')
	->array(@ids)
	->value};
	map {$fetch{$_}->Data($feeds_info{$_})} @ids;
	}
}

# Preloaded methods go here.

1;
__END__

=head1 NAME

Net::Syndic8::FeedsCollection - Class  with xml-rpc calls and for maintain collection of results.

=head1 SYNOPSIS

	use Net::Syndic8::FeedsCollection;
	use Net::Syndic8::RPCXML;
	my $obj= new Net::Syndic8::FeedsCollection (
			cache=>{},
			gate=>new Net::Syndic8::RPCXML:: ('http://www.syndic8.com/xmlrpc.php')
				));

=head1 DESCRIPTION

Net::Syndic8::FeedsCollection - Class  with xml-rpc calls and for maintain collection of results.
It ised internally by  Net::Syndic8;

=head1 SEE ALSO

Net::Syndic8,

Net::Syndic8::RPCXML,

http://www.syndic8.com/web_services/


=head1 AUTHOR

Zahatski Aliaksandr, E<lt>zagap@users.sourceforge.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
