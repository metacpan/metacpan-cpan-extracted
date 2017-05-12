package PERLANCAR::Module::List;

our $DATE = '2016-03-17'; # DATE
our $VERSION = '0.003005'; # VERSION

#IFUNBUILT
# use strict;
# use warnings;
#END IFUNBUILT

sub list_modules($$) {
	my($prefix, $options) = @_;
	my $trivial_syntax = $options->{trivial_syntax};
	my($root_leaf_rx, $root_notleaf_rx);
	my($notroot_leaf_rx, $notroot_notleaf_rx);
	if($trivial_syntax) {
		$root_leaf_rx = $notroot_leaf_rx = qr#:?(?:[^/:]+:)*[^/:]+:?#;
		$root_notleaf_rx = $notroot_notleaf_rx =
			qr#:?(?:[^/:]+:)*[^/:]+#;
	} else {
		$root_leaf_rx = $root_notleaf_rx = qr/[a-zA-Z_][0-9a-zA-Z_]*/;
		$notroot_leaf_rx = $notroot_notleaf_rx = qr/[0-9a-zA-Z_]+/;
	}
	die "bad module name prefix `$prefix'"
		unless $prefix =~ /\A(?:${root_notleaf_rx}::
					 (?:${notroot_notleaf_rx}::)*)?\z/x &&
			 $prefix !~ /(?:\A|[^:]::)\.\.?::/;
	my $list_modules = $options->{list_modules};
	my $list_prefixes = $options->{list_prefixes};
	my $list_pod = $options->{list_pod};
	my $use_pod_dir = $options->{use_pod_dir};
	return {} unless $list_modules || $list_prefixes || $list_pod;
	my $recurse = $options->{recurse};
	my $return_path = $options->{return_path};
	my $all = $options->{all};
	my @prefixes = ($prefix);
	my %seen_prefixes;
	my %results;
	while(@prefixes) {
		my $prefix = pop(@prefixes);
		my @dir_suffix = split(/::/, $prefix);
		my $module_rx =
			$prefix eq "" ? $root_leaf_rx : $notroot_leaf_rx;
		my $pm_rx = qr/\A($module_rx)\.pmc?\z/;
		my $pod_rx = qr/\A($module_rx)\.pod\z/;
		my $dir_rx =
			$prefix eq "" ? $root_notleaf_rx : $notroot_notleaf_rx;
		$dir_rx = qr/\A$dir_rx\z/;
		foreach my $incdir (@INC) {
			my $dir = join("/", $incdir, @dir_suffix);
			opendir(my $dh, $dir) or next;
			while(defined(my $entry = readdir($dh))) {
				if(($list_modules && $entry =~ $pm_rx) ||
						($list_pod &&
							$entry =~ $pod_rx)) {
                                            $results{$prefix.$1} = $return_path ? ($all ? [@{ $results{$prefix.$1} || [] }, "$dir/$entry"] : "$dir/$entry") : undef
						if $all && $return_path || !exists($results{$prefix.$1});
				} elsif(($list_prefixes || $recurse) &&
						($entry ne '.' && $entry ne '..') &&
						$entry =~ $dir_rx &&
						-d join("/", $dir,
							$entry)) {
					my $newpfx = $prefix.$entry."::";
					next if exists $seen_prefixes{$newpfx};
					$results{$newpfx} = $return_path ? ($all ? [@{ $results{$newpfx} || [] }, "$dir/$entry/"] : "$dir/$entry/") : undef
						if ($all && $return_path || !exists($results{$newpfx})) && $list_prefixes;
					push @prefixes, $newpfx if $recurse;
				}
			}
			next unless $list_pod && $use_pod_dir;
			$dir = join("/", $dir, "pod");
			opendir($dh, $dir) or next;
			while(defined(my $entry = readdir($dh))) {
				if($entry =~ $pod_rx) {
					$results{$prefix.$1} = $return_path ? ($all ? [@{ $results{$prefix.$1} || [] }, "$dir/$entry"] : "$dir/$entry") : undef;
				}
			}
		}
	}
	return \%results;
}

1;
# ABSTRACT: A fork of Module::List

__END__

=pod

=encoding UTF-8

=head1 NAME

PERLANCAR::Module::List - A fork of Module::List

=head1 VERSION

This document describes version 0.003005 of PERLANCAR::Module::List (from Perl distribution PERLANCAR-Module-List), released on 2016-03-17.

=head1 DESCRIPTION

This module is a fork of L<Module::List> 0.003. It's exactly like Module::List,
except for the following differences:

=over

=item * lower startup overhead (with some caveats)

It strips the usage of L<Exporter>, L<IO::Dir>, L<Carp>, L<File::Spec>, with the
goal of saving a few milliseconds (a casual test on my PC results in 11ms vs
39ms).

Path separator is hard-coded as C</>.

=item * Recognize C<return_path> option

Normally the returned hash has C<undef> as the values. With this option set to
true, the values will contain the path instead. Useful if you want to collect
all the paths, instead of having to use L<Module::Path> or L<Module::Path::More>
for each module again.

=item * Recognize C<all> option

If set to true and C<return_path> is also set to true, will return all found
paths for each module instead of just the first found one. The values of result
will be an arrayref containing all found paths.

=back

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/PERLANCAR-Module-List>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-PERLANCAR-Module-List>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=PERLANCAR-Module-List>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Module::List>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
