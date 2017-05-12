package P5U::Lib::TestPod;

use 5.010;
use strict;
use utf8;

BEGIN {
	$P5U::Command::TestPod::AUTHORITY = 'cpan:TOBYINK';
	$P5U::Command::TestPod::VERSION   = '0.100';
};

use Object::AUTHORITY;
use Path::Iterator::Rule;
use Test::More;
use Test::Pod;

sub _uniq
{
	my %already;
	grep { not $already{"$_"}++ } @_;
}

sub test_pod
{
	my $self = shift;
	
	my @files =
		_uniq
		map "Path::Tiny"->new($_),
		map {
			(-d $_)
				? Path::Iterator::Rule::->new->or(
					Path::Iterator::Rule::->new->perl_module,
					Path::Iterator::Rule::->new->perl_pod,
					Path::Iterator::Rule::->new->perl_script,
					)->all($_)
				: $_
		} @_;
	
	plan tests => scalar @files;
	pod_file_ok("$_", $_) for @files;
}

1;

__END__

=pod

=encoding utf-8

=for stopwords testpod

=head1 NAME

P5U::Lib::TestPod - support library implementing p5u's testpod command

=head1 SYNOPSIS

 use P5U::Lib::TestPod;
 P5U::Lib::TestPod->test_pod(@files);

=head1 DESCRIPTION

This is a support library for the testpod command.

=head2 Class Method

There's only one method (a class method, not an object method... this
isn't really an OO module) worth caring about:

=over

=item C<< test_pod(@files) >>

Tests the pod in given files. Writes TAP to STDOUT.

Actually, some of the files can be directories, in which case those
directories will be scanned for Perl modules, scripts and pod files.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=P5U>.

=head1 SEE ALSO

L<p5u>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

