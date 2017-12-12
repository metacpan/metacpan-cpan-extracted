use 5.016001;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Module::Metadata;

WriteMakefile(
    NAME              => 'POSIX::Run::Capture',
    VERSION_FROM      => 'lib/POSIX/Run/Capture.pm',
    LICENSE           =>  'gpl_3',
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    MIN_PERL_VERSION  => 5.006,
    ABSTRACT_FROM     => 'lib/POSIX/Run/Capture.pm',
    AUTHOR            => 'Sergey Poznyakoff <gray@gnu.org>',
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '',
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
    OBJECT            => '$(O_FILES)',
    MYEXTLIB          => 'runcap/libruncap.a',
    META_MERGE        => {
	'meta-spec' => { version => 2 },
        resources => {
	    repository => {
		type => 'git',
                url => 'git://git.gnu.org.ua/posixruncapture.git',
		web => 'http://git.gnu.org.ua/cgit/posixruncapture.git/',
	    },
	},
	provides => Module::Metadata->provides(version => '1.4',
					       dir => 'lib')
    }
);

package MY;

sub test {
    my $val = shift->SUPER::test(@_);
    open(my $fd, '<', \$val);
    my @ret;
    my $ignore;
    while (<$fd>) {
	chomp;
	if (/^(subdirs-test_.+?)\s*:.*$/) {
	    push @ret, "$1:: subdirs-test-prepare", '';
	    $ignore = 1;
	} elsif ($ignore) {
	    if (/^$/) {
		$ignore = 0;
	    } elsif (/^\S/) {
		$ignore = 0;
		push @ret, $_;
	    }
	} else {
	    push @ret, $_;
	}
    }
    close $fd;

    push @ret, '',
         "subdirs-test-prepare::",
         "\t\@\$(MAKE) -C runcap/t genout O='\$(CCFLAGS)'",
         '',
         'check: test',
         '';
    
    return join("\n", @ret);
}

sub postamble {
'    
$(MYEXTLIB): runcap/configure
	cd runcap && \
         ./configure CFLAGS="$(CCFLAGS) $(CCCDLFLAGS)" && \
         $(MAKE)

runcap/configure: runcap/configure.ac
	RUNCAP_BUILD=static autoreconf -f -i -s -I. runcap
'
}

