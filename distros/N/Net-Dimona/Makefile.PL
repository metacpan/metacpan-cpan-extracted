require 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => "Net::Dimona",
   VERSION_FROM => "lib/Net/Dimona.pm",
   ABSTRACT_FROM => "lib/Net/Dimona.pm",
   AUTHOR => 'Breno G. de Oliveira <garu@cpan.org>',
   LICENSE => "perl",
   MIN_PERL_VERSION => 5.006,
   PREREQ_PM => {
       'JSON::MaybeXS'        => 0,
       'LWP::UserAgent'       => 0,
       'LWP::Protocol::https' => 0,
   },
   META_MERGE => {
       resources => {
           repository  => 'http://github.com/garu/Net-Dimona',
           license     => 'http://dev.perl.org/licenses/',
           bugtracker  => 'https://github.com/garu/Net-Dimona/issues/',
       },
   },
   BUILD_REQUIRES => {
       'Test::More' => 0,
   },
);

BEGIN {
    # compatibility with older versions of MakeMaker
    my $developer = -d "eg";
    my %mm_req = (
        LICENCE => 6.31,
        META_MERGE => 6.45,
        META_ADD => 6.45,
        MIN_PERL_VERSION => 6.48,
        BUILD_REQUIRES => 6.56,
    );
    undef(*WriteMakefile);
    *WriteMakefile = sub {
        my %arg = @_;
        for (keys %mm_req) {
            unless (eval { ExtUtils::MakeMaker->VERSION($mm_req{$_}) }) {
                warn "$_ $@" if $developer;
                delete $arg{$_};
            }
        }
        ExtUtils::MakeMaker::WriteMakefile(%arg);
    };
}
