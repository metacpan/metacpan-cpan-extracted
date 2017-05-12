use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Net::LDAP::HTMLWidget',
    'VERSION_FROM' => 'lib/Net/LDAP/HTMLWidget.pm',
    'PREREQ_PM'    => {
        HTML::Widget        => 1.11,
        Net::LDAP	    => 0,
    },
);
