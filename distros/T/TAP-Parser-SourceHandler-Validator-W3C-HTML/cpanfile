#FIXME: This is gross.
#
# XML::Parser fails to install because the expat libraries reside in a
# non-standard architecture-dependent path in Debian and EUMM is unable
# to cope with it.  I tried passing options to EUMM via PERL_MM_OPT, but
# it didn't work out.  The first problem I ran into was EUMM's inability
# to properly handle quoted arguments, which made it impossible to pass
# both -L and -l flags in the LIBS option a la:
#
#	PERL_MM_OPT='LIBS="-L/usr/lib/x86_64-linux-gnu -lexpat1"'
#
# ExtUtils::MakeMaker 6.74 replaced the code that parses the PERL_MM_OPT
# environment variable with code based on Text::ParseWords.  The correct
# flags are present in the Makefile for XML::Parser, but are absent from
# the Makefile for XML::Parser::Expat.  The reason looks to be that EUMM
# doesn't parse PERL_MM_OPT when processing child Makefiles.  If we add
# the following snippet at line 601 of ExtUtils::MakeMaker, the Makefile
# for XML::Parser::Expat inherits the appropriate bits.
#
#	parse_args($self, _shellwords($ENV{PERL_MM_OPT} || ''));
#
# I'm not sure what the repercussions of doing this are, since the EUMM
# internals are largely a black box to me.
#
# Barring this change, though, we have to find some other way to get our
# library paths into the Makefile.  I'm not sure there's another way to
# tickle the EUMM bits from this distance, so we'll see if there's a way
# to directly influence the build args.  Carton doesn't provide a way of
# overriding build args, but cpanm 1.7 does.  We can take advantage of
# the fact that our cpanfile is eval()ed and call out to cpanm just like
# Carton::Builder->run_cpanm does...
#
# For more information:
#
# https://rt.cpan.org/Public/Bug/Display.html?id=76754
# https://rt.cpan.org/Public/Bug/Display.html?id=76753
# https://rt.cpan.org/Public/Bug/Display.html?id=69318
# https://rt.cpan.org/Public/Bug/Display.html?id=3081

unless ($0 =~ /carton/) {
	# XXX: grossly irreverent and blissfully ignores any build path you
	# might have set via carton's --path argument

	print "installing XML::Parser with expat path override...\n";
	system $^X, $0, qw(--quiet --notest -L local --save-dists local/cache --configure-args EXPATLIBPATH=/usr/lib/x86_64-linux-gnu XML::Parser)
}

#requires 'TAP::Formatter::Bamboo';
requires 'TAP::Formatter::JUnit';
requires 'Test::Builder';
requires 'WWW::Robot';
requires 'WebService::Validator::HTML::W3C';
requires 'XML::XPath';

