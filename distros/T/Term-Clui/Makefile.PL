use ExtUtils::MakeMaker;

my $have_Term_ReadKey = 1;
eval 'require "Term/ReadKey.pm"';
if ($@) { $have_Term_ReadKey = 0; }

my $have_Term_Size = 1;
eval 'require "Term/Size.pm"';
if ($@) { $have_Term_Size = 0; }

if (!$have_Term_ReadKey) { print <<'EOT'; }
The CPAN module Term::ReadKey is not installed;
it's optional, but it should improve portability.

EOT

if (!$have_Term_Size && !$have_Term_ReadKey) { print <<'EOT'; }
The CPAN module Term::Size is not installed either;
again, it's optional, but it should improve portability.

EOT

WriteMakefile(
	NAME      => 'Term::Clui',
	VERSION_FROM => 'Clui.pm',
	AUTHOR    => 'PJB, Peter Billam, www.pjb.com.au/comp/contact.html',
	ABSTRACT  => 'Command-Line User Interface on /dev/tty',
	dist      => {COMPRESS=>'gzip -9f', SUFFIX => 'gz'},
);
