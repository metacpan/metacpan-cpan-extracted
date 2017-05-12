
use 5;
use ExtUtils::MakeMaker;

my $EUMM_VERSION = eval $ExtUtils::MakeMaker::VERSION;

WriteMakefile(
    NAME              => [% quote(name) %],
    VERSION_FROM      => 'lib/Template/Process.pm', 
    PREREQ_PM         => {
    [%- FOREACH p = requires %]
      [% p.key %] => [% p.value %]
    [%- END %]
    }, 
    EXE_FILES => [ qw(bin/tt) ],
    PL_FILES => {},
    ($] >= 5.005 ? (
      ABSTRACT_FROM  => 'lib/Template/Process.pm', 
[%- IF author %]
      AUTHOR         => [% quote(author.0) %],
[% END -%]
    ) : ()),
    ($EUMM_VERSION >= 6.31 ? (
      LICENSE => [% quote(license) %],
    ) : ()),
);
