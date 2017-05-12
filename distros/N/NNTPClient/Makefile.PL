use ExtUtils::MakeMaker;

WriteMakefile (
    NAME         => "News::NNTPClient",
    DISTNAME     => "NNTPClient",
    VERSION_FROM => "NNTPClient.pm",

    ($] >= 5.005 ?
       (
	ABSTRACT   => "Perl 5 module to talk to NNTP (RFC977) server",
        AUTHOR     => "Rodger V. Anderson (rodger\@boi.hp.com)"
       ) : ()
    ),

    dist => {
       COMPRESS  => "gzip -9f",
       SUFFIX    => "gz",
    }
);
