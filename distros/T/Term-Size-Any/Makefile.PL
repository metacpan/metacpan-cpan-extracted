
use 5.006;
use strict;
use warnings;

use ExtUtils::MakeMaker 6.31; # XXX yes, that's not a nice thing to do

# one of Term::Size, Term::Size::Perl, Term::Size::ReadKey, 
# or Term::Size::Win32 should be available

my %prereqs;
if ( $^O eq 'MSWin32' ) {
    %prereqs = ( 'Term::Size::Win32' => 0 );

} else {
    #my @modules = qw( Term::Size::Perl Term::Size Term::Size::ReadKey );
    my @modules = qw( Term::Size::Perl );
    %prereqs = map { $_ => 0 } @modules;
    ## FIXME yep, I know - we don't need all these three

}

WriteMakefile(
    NAME => 'Term::Size::Any',
    VERSION_FROM => 'lib/Term/Size/Any.pm',
    PREREQ_PM => {
        #Best                        => 0,
        %prereqs,

        # build_requires
        'Test::More'                => 0,
        'Module::Load::Conditional' => 0,
        'Devel::Hide'               => 0,
    },
    #recommends => {
    #    'Test::Pod::Coverage' => 1.04,
    #    'Test::Pod'           => 1.18,
    #}
    ABSTRACT_FROM => 'lib/Term/Size/Any.pod',
    AUTHOR => 'Adriano R. Ferreira <ferreira@cpan.org>',
    LICENSE => 'perl',

);
