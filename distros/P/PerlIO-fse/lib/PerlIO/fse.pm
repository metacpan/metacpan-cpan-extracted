package PerlIO::fse;

use 5.008_001;
use strict;

our $VERSION = '0.02';

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

use Encode ();

sub import{
	my $class = shift;

	if(@_){
		$class->set_fse(@_);
	}
}

1;
__END__

=encoding utf-8

=head1 NAME

PerlIO::fse - Deals with Filesystem Encoding

=for test_synopsis my($file);

=head1 SYNOPSIS

	use utf8;

	# for Windows (including Cygwin)
	open my $in,  '<:fse', $file;

	# Other systems requires explicit fse
	$ENV{PERLIO_FSE} = 'utf8'; # UTF-8 is default
	# or
	use PerlIO::fse 'utf8';


=head1 DESCRIPTION

C<PerlIO::fse> mediates encodings between Perl and Filesystem. It converts
filenames into native forms if the filenames are utf8-flagged. Otherwise,
C<PerlIO::fse> does nothing, looking on it as native forms.

C<PerlIO::fse> attempts to get the filesystem encoding(C<fse>)
from C<$ENV{PERLIO_FSE}>, and if defined, it will be used. Or you can
C<use PerlIO::fse $encoding> directive to set C<fse>.

If you use Windows (including Cygwin), you need not to set C<$ENV{PERLIO_FSE}>
because the current codepage is detected automatically.
However, if C<$ENV{PERLIO_FSE}> is set, C<PerlIO::fse> will give it
priority.

When there is no encoding available, C<UTF-8> will be used.

This layer uses C<Encode> internally to convert encodings.

=head1 METHODS

=head2 C<< PerlIO::fse->get_fse() >>

=head2 C<< PerlIO::fse->set_fse($encoding) >>

=head1 HISTORY

This module started in a part of C<PerlIO::Util>, but now is an independent
distribution. There are two reasons for this.

First, C<PerlIO::fse> is unstable. I have seen segmentation fault in the test
suit in some perls, but could not find what causes the problem. This problem
should be resolved.

Second, authough automatic encoding detection is available in Windows system,
it can be implemented in non-Windows, and it should be. This feature may require
many tests, but I don't want to increment the version of C<PerlIO::Util>.


=head1 SEE ALSO

L<PerlIO::Util>.

L<Encode>.

=head1 AUTHOR

Goro Fuji (藤 吾郎) E<lt>gfuji (at) cpan.orgE<gt>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008-2009, Goro Fuji E<lt>gfuji (at) cpan.orgE<gt>. Some rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
