use ExtUtils::MakeMaker;
use ExtUtils::Command qw(cp);

my $build_simplex = prompt("Do you wish to include some simple protocol extensions (pulls in Parse::RecDescent)? ",
    $ENV{OVERRIDE_DEFAULT_SX} ? $ENV{OVERRIDE_DEFAULT_SX} : "y");

if( $build_simplex =~ m/[Yy]/ ) {
    local @ARGV = qw(contrib/SimpleX.pod contrib/SimpleX.pm .);
    cp();
    open my $out, ">test_simplex" or die "unable to setup body-summary tests: $!";
    chmod 0444, qw(SimpleX.pod SimpleX.pm); # prevent myself from editing them without realizing it

=cut
SimpleX.%: contrib/SimpleX.%
	$(RM) $@; $(CP) $< $@ && $(CHMOD) 0444 $@

inc/slurp_fetchmailx.pm: inc/slurp_fetchmail.pm
	sed -e s/slurp_fetchmail/slurp_fetchmailx/ -e s/Net::IMAP::Simple/Net::IMAP::SimpleX/ $< > $@
=cut

} else {
    unlink qw(SimpleX.pod SimpleX.pm test_simplex);
}

WriteMakefile(
    'NAME'	       => 'Net::IMAP::Simple',
    'VERSION_FROM' => 'Simple.pm',
    AUTHOR         => 'Paul Miller <jettero@cpan.org>',

    PREREQ_PM => {
        'IO::Socket' => 0,
        'IO::Select' => 0,

        ( $build_simplex ? ('Parse::RecDescent'=>0) : () ),
    },

    ($ExtUtils::MakeMaker::VERSION ge '6.48'?
        (MIN_PERL_VERSION => 5.008,
            META_MERGE => {
                keywords => [qw(imap simple)],
                resources=> {
                    repository => 'http://github.com/jettero/net--imap--simple',
                },
            },

        LICENSE	=> 'Perl Artistic',

    ) : ()),
);
