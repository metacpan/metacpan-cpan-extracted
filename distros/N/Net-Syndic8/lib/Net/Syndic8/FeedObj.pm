package Net::Syndic8::FeedObj;
use 5.008002;
use strict;
use warnings;
use Net::Syndic8::Base;
our @ISA = qw(Net::Syndic8::Base);
our $VERSION = '0.01';
attributes (qw/ID Collection Loaded _data/);
# Preloaded methods go here.

sub _init { my $self=shift;$self->Init(@_);return 1}

sub Init {
my($self,%arg)=@_;
my ($id,$coll)=@arg{qw/id collection/};
Collection $self $coll;
ID $self $id;
Loaded $self undef;
}

sub Data {
my ($self,$par)=@_;
if ($par) {
	_data $self $par;
	Loaded $self 1;
	} elsif ( not $self->Loaded ){
		$self->Collection()->Load($self)
	}
return $self->_data
}
1;
__END__

=head1 NAME

Net::Syndic8::FeedObj - Class for incapsulate results of requests.

=head1 SYNOPSIS

 use Net::Syndic8::FeedObj;

=head1 DESCRIPTION

Net::Syndic8::FeedObj - Class for incapsulate results of requests.
It have method I<DATA> for access to fetched results and support LazyLoad.

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
