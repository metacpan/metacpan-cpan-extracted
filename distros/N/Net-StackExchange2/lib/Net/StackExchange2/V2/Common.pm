package Net::StackExchange2::V2::Common;

use 5.006;
use strict;
use Data::Dumper;
use JSON qw(decode_json);
use Carp;
use LWP::UserAgent;
use warnings FATAL => 'all';
use constant BASE_URL => "https://api.stackexchange.com/2.1/";
our @ISA = qw(Exporter);
our @EXPORT = qw(query no_params one_param two_params);


our $VERSION = "0.05";

sub query {
	my $queryStrHash = pop @_;
#	print Dumper(@_);
	my $url = join("/",@_);
	my @params = ();
	while ( my ($key, $value) = each(%$queryStrHash) ) {
		push @params, $key."=".$value;
    }
	my $query = '?'.join '&',@params;
	my $finalUrl = BASE_URL.$url.$query;
	print $finalUrl;
	my $ua = LWP::UserAgent->new;
	my $response = $ua->get($finalUrl);
	return	decode_json($response->decoded_content);
	#StackExchange2 already returns error codes for 
	#incorrect params and requests 
	
	# if ($response->is_success) {
	# 	return	decode_json($response->decoded_content); 
	# }
	# else {
	# 	croak $response->status_line;
	# }
}
sub query_post {
	my $queryStrHash = pop @_;
#	print Dumper(%$queryStrHash);
#for the purposes of POST we need all the excess query str stuff to go into POST form data
	my $url = join("/",@_);
	my $finalUrl = BASE_URL.$url;
	print $finalUrl;
	my $ua = LWP::UserAgent->new;
	#apprantly the second param in the post has to be a hash inside an array
	my $response = $ua->post($finalUrl, [%$queryStrHash]);
	return	decode_json($response->decoded_content);
}
sub no_params {
	my $param = shift;
	my $config = shift;
	return sub {
		my $self = shift;
		my $queryStr = pop @_;
		if(defined($queryStr)) {
		# copy current method keys and vals
			while(my($key,$val) = each(%$queryStr))
			{
				$self->{$key} = $val;
			}
		}
		if (defined($config) and $config->{no_site} == 1) {
			$self->{site} = '';
		}
		return query($param, $self);
	}
}

sub one_param {
	my $param1 = shift;
	my $param2 = shift;
	my $config = shift;
	return sub {
		my $self = shift;
		my $ids = shift;
		#you should check if this param is NOT null/empty
		my $q = shift;
		
		if(defined($q)) {
		# copy current method keys and vals
			while(my($key,$val) = each(%$q))
			{
				$self->{$key} = $val;
			}
		}
		my $ids_str = "";
		if (ref($ids) eq 'ARRAY') {
			 $ids_str = join(";",@$ids);
		} else {
			$ids_str = $ids."";
		}
#		print Dumper($q);
		if (defined($config)) { 
			if(exists $config->{no_site} and $config->{no_site} == 1) {
				$self->{site} = '';
			}
			if(exists $config->{post} and $config->{post} == 1) {
				#this is a little icky, but should do for now.
				print Dumper($self);
				if (not defined($param2)) {
					return query_post($param1, $ids_str , $self);
				} else {
					return query_post($param1, $ids_str, $param2, $self);
				}
			}
		}
		if (not defined($param2)) {
			return query($param1, $ids_str , $self);
		} else {
			return query($param1, $ids_str, $param2, $self);
		}
	}
}
sub two_params {
	my $param1 = shift;
	my $param2 = shift;
	my $param3 = shift;
	return sub {
		my $self = shift;
		my $ids = shift;
		my $ids_2 = shift;
		my $q = shift;
		
		if(defined($q)) {
		# copy current method keys and vals
			while(my($key,$val) = each(%$q))
			{
				$self->{$key} = $val;
			}
		}
		my $ids_str = "";
		if (ref($ids) eq 'ARRAY') {
			 $ids_str = join(";",@$ids);
		} else {
			$ids_str = $ids."";
		}
		my $ids_str_2 = "";
		if (ref($ids_2) eq 'ARRAY') {
			 $ids_str_2 = join(";",@$ids_2);
		} else {
			$ids_str_2 = $ids_2."";
		}
#		print Dumper($q);
		# if (defined($config) and $config->{no_site} == 1) {
		# 	$self->{site} = '';
		# }
		if (not defined($param3)) {
			return query($param1, $ids_str, $param2, $ids_str_2, $self);
		} else {
			return query($param1, $ids_str, $param2, $ids_str_2, $param3, $self);
		}
	}
}
1; # End of Net::StackExchange2::V2::Common
__END__


=head1 NAME

Net::StackExchange2::V2::Common - Internal module used to create urls

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

This module is an internal set of common methods that are used to generate urls. The methods generate an anonymous method that actually makes the call.

=head1 AUTHOR

Gideon Israel Dsouza, C<< <gideon at cpan.org> >>

=head1 BUGS

See L<Net::StackExchange2>.

=head1 SUPPORT

See L<Net::StackExchange2>.

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Gideon Israel Dsouza.

This library is distributed under the freebsd license:

L<http://opensource.org/licenses/BSD-3-Clause> 
See FreeBsd in TLDR : L<http://www.tldrlegal.com/license/bsd-3-clause-license-(revised)>
