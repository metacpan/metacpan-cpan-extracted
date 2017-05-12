package Module::List::WithPath;

our $DATE = '2015-06-28'; # DATE
our $VERSION = '0.003002'; # VERSION

{ use 5.006; }
use warnings;
use strict;

use Carp qw(croak);
use File::Spec;
use IO::Dir 1.03;

use parent "Exporter";
our @EXPORT_OK = qw(list_modules);

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
	croak "bad module name prefix `$prefix'"
		unless $prefix =~ /\A(?:${root_notleaf_rx}::
					 (?:${notroot_notleaf_rx}::)*)?\z/x &&
			 $prefix !~ /(?:\A|[^:]::)\.\.?::/;
	my $list_modules = $options->{list_modules};
	my $list_prefixes = $options->{list_prefixes};
	my $list_pod = $options->{list_pod};
	my $use_pod_dir = $options->{use_pod_dir};
	return {} unless $list_modules || $list_prefixes || $list_pod;
	my $recurse = $options->{recurse};
	my @prefixes = ($prefix);
	my %seen_prefixes;
	my %results;
        my $code_add_result = sub {
            my ($key, $val) = @_;
            if (ref($results{$key}) eq 'ARRAY') {
                push @{ $results{$key} }, $val
                    unless grep { $_ eq $val } @{ $results{$key} };
            } elsif (defined $results{$key}) {
                $results{$key} = [$results{$key}, $val]
                    unless $val eq $results{$key};
            } else {
                $results{$key} = $val;
            }
        };
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
			my $dir = File::Spec->catdir($incdir, @dir_suffix);
			my $dh = IO::Dir->new($dir) or next;
			while(defined(my $entry = $dh->read)) {
				if(($list_modules && $entry =~ $pm_rx) ||
						($list_pod &&
							$entry =~ $pod_rx)) {
					$code_add_result->($prefix.$1, File::Spec->catdir($dir, $entry));
				} elsif(($list_prefixes || $recurse) &&
						File::Spec
							->no_upwards($entry) &&
						$entry =~ $dir_rx &&
						-d File::Spec->catdir($dir,
							$entry)) {
					my $newpfx = $prefix.$entry."::";
					next if exists $seen_prefixes{$newpfx};
					$code_add_result->($newpfx, File::Spec->catdir($dir, $entry))
						if $list_prefixes;
					push @prefixes, $newpfx if $recurse;
				}
			}
			next unless $list_pod && $use_pod_dir;
			$dir = File::Spec->catdir($dir, "pod");
			$dh = IO::Dir->new($dir) or next;
			while(defined(my $entry = $dh->read)) {
				if($entry =~ $pod_rx) {
					$code_add_result->($prefix.$1, File::Spec->catdir($dir, $entry));
				}
			}
		}
	}
	return \%results;
}

1;
# ABSTRACT: Like Module::List, but set hash values with paths

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::List::WithPath - Like Module::List, but set hash values with paths

=head1 VERSION

This document describes version 0.003002 of Module::List::WithPath (from Perl distribution Module-List-WithPath), released on 2015-06-28.

=head1 DESCRIPTION

This module is a fork of L<Module::List> 0.003. It's exactly like Module::List,
except that it sets the resulting hash values with paths (or array of paths, if
more than one paths are found).

=for Pod::Coverage .+

=head1 SEE ALSO

L<Module::List>

L<Complete::Module>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Module-List-WithPath>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Module-List-WithPath>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Module-List-WithPath>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
