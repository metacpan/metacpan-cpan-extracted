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

WriteMakefile(
	NAME      => 'Speech::Speakup',
	VERSION_FROM => 'Speakup.pm',
	AUTHOR    => 'PJB, Peter Billam, www.pjb.com.au/comp/contact.html',
	ABSTRACT  => 'Get and set the parameters of the Speakup screen-reader',
	dist      => {COMPRESS=>'gzip -9f', SUFFIX => 'gz'},
);
