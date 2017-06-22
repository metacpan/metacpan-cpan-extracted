use ExtUtils::MakeMaker;
use ExtUtils::Command qw(cp);

=cut
SimpleX.%: contrib/SimpleX.%
	$(RM) $@; $(CP) $< $@ && $(CHMOD) 0444 $@

inc/slurp_fetchmailx.pm: inc/slurp_fetchmail.pm
	sed -e s/slurp_fetchmail/slurp_fetchmailx/ -e s/Net::IMAP::Simple/Net::IMAP::SimpleX/ $< > $@
=cut

WriteMakefile(
    'NAME'	       => 'Net::IMAP::Simple',
    'VERSION_FROM' => 'lib/Net/IMAP/Simple.pm',
    AUTHOR         => 'Paul Miller <jettero@cpan.org>',

    PREREQ_PM => {
        'IO::Socket' => 0,
        'IO::Select' => 0,
        'Parse::RecDescent' => 0,
    },

    ($ExtUtils::MakeMaker::VERSION ge '6.48'?
        (MIN_PERL_VERSION => 5.008,
            META_MERGE => {
                keywords => [qw(imap simple)],
                resources=> {
                    repository => 'http://github.com/jettero/net--imap--simple',
                },
            },

        LICENSE	=> 'perl_5'

    ) : ()),
);
