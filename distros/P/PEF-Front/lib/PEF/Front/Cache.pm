package PEF::Front::Cache;
use strict;
use warnings;
use PEF::Front::Config;
use Data::Dumper;

use base 'Exporter';
our @EXPORT;

my $dumper;

BEGIN {
	@EXPORT = qw{
		get_cache
		make_request_cache_key
		remove_cache_key
		set_cache
	};
	$dumper = Data::Dumper->new([]);
	$dumper->Indent(0);
	$dumper->Pair(":");
	$dumper->Useqq(1);
	$dumper->Terse(1);
	$dumper->Deepcopy(1);
	$dumper->Sortkeys(1);
	my $module = cfg_cache_module();

	if ($module !~ /::/) {
		$module = "PEF::Front::Cache::$module";
	}
	my $module_file = $module;
	$module_file =~ s|::|/|g;
	$module_file .= ".pm";
	if (grep {/AppFrontConfig\.pm$/} keys %INC) {
		eval {require $module_file};
		if ($@) {
			die {
				result      => 'INTERR',
				answer      => 'Unknown cache provider $1',
				answer_args => [$module]
			};
		}
		my $mp = __PACKAGE__;
		for my $method (@EXPORT) {
			my $cref = "$module"->can($method);
			if ($cref) {
				no strict 'refs';
				*{$mp . "::$method"} = $cref;
			}
		}
	}
}

sub make_request_cache_key {
	my ($vreq, $cache_attr) = @_;
	$cache_attr = {key => 'method', expires => $cache_attr} if not ref $cache_attr;
	my @keys;
	if (ref($cache_attr->{key}) eq 'ARRAY') {
		@keys = grep {exists $vreq->{$_}} @{$cache_attr->{key}};
	} elsif (not exists $cache_attr->{key}) {
		@keys = ('method');
	} else {
		@keys = ($cache_attr->{key});
	}
	$dumper->Values([{map {$_ => $vreq->{$_}} @keys}]);
	return $dumper->Dump;
}

1;

__END__

=head1 NAME

B<PEF::Front::Cache> - Data cache

=head1 DESCRIPTION

This class is used to store cached method responses and 
any other information.

=head1 FUNCTIONS

=head2 make_request_cache_key($vreq, $cache_attr)

Makes key string for caching model method response.

=head2 get_cache($key_string)

Returns value from cache for given C<$key_string>.

=head2 set_cache($key_string, $value)

Sets value in cache for given C<$key_string>.

=head2 remove_cache_key($key_string)

Deletes cache value for given C<$key_string> if exists.

=head1 AUTHOR
 
This module was written and is maintained by Anton Petrusevich.

=head1 Copyright and License
 
Copyright (c) 2016 Anton Petrusevich. Some Rights Reserved.
 
This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
