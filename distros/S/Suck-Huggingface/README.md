# Suck::Huggingface

Clone repos from Huggingface and then download model files.

## TL;DR SUMMARY

    $ apt-get install git
    $ apt-get install wget
    $ sudo cpan JSON::MaybeXS
    $ sudo cpan File::Valet
    $ sudo cpan Time::TAI::Simple
    $ bin/suck-hug

The suck-hug utility will spew usage information at you and exit.  Should be 
fairly self-explanatory.

## DESCRIPTION

I got tired of manually downloading models and datasets from Huggingface.

So, I wrote this thinger to do it for me.

Huggingface exports models as git repos, similar to Github, but files above 
a certain size (like models, which is kind of the whole point) don't actually 
get downloaded when you clone a model repo.

They have to be downloaded separately.  Sometimes this is hundreds of files. 
It is a huge pain in the ass.

The bin/suck-hug utility will do this for you.  Give it a list of repo URLs 
and it will "git clone" the repos, scan them for files which need to be 
downloaded, and use wget to fetch them.

It really should check the download digests, but it doesn't.  There is some 
code in place for enabling that, but I just haven't gotten around to it yet.

## USAGE

    usage: bin/suck-hug [options] https://huggingface.co/bigscience/bloom [more urls ...]
    Will clone repos and download files too big to be included in repo
    General options:
      -h, --help       Show this usage and exit
      --exclude=xx,yy  Do not download external files with xx or yy in their name
      --rate-limit=#[KMG]  Set rate limiting for wget (default: unlimited)
      --sort           Order downloads by size; download smallest first.
      --too_big=###    Examine files smaller than this for download, bytes (default: 300)
      --retries=###    How many times to retry failed wget (default: 1000)
      --username=XXX   If Huggingface requires auth, use XXX for username.
      --password=YYY   If Huggingface requires auth, use YYY for password.
      -q               Suppress output
      -v               More verbose output
    Logging options:
      --log-dir=PATH   Write logfile in this directory (default: /var/tmp)
      --logfile=PNAME  Write logfile to this exact pathname (overrides --log-dir)
      --log-level=#    Set higher for more debug logging (default: 3, max: 7)
          level 0: only log CRITICAL records
          level 1: log CRITICAL, ERROR
          level 2: log CRITICAL, ERROR, WARNING
          level 3: log CRITICAL, ERROR, WARNING, INFO
          level 4+ log CRITICAL, ERROR, WARNING, INFO, DEBUG (many debug levels)
      --no-log         Suppress logging
      --no-logfile     Do not write log to file, can still show to stderr/stdout
      --show-log       Display log messages to stderr
      --show-log-to-stdout  Display log messages to stdout

## What about using the module?

    my $shug = Suck::Huggingface->new(%options);
    my ($ok, @result) = $shug->suck($url);
    if ($ok eq 'OK') {
       my ($n_dl, $n_bytes) = @result;
       print "yaay! downloaded $n_dl files summing $n_bytes bytes\n";
    } else {
       print "oh noes, errors!\n", join("\n", @result), "\n";
    }

That's basically it.  There are no other methods intended for end-user use.

The parameters to new() are just the same as the utility's command line 
options, but with hyphens turned into underscores, like:

    my $shug = Suck::Huggingface->new(log_level => 5, exclude => 'q2,q3,q5,q8')

## LOGGING

S:H uses a stripped-down version of my structured logger.  By default it 
will write log records to /var/tmp/suck-huggingface.log as newline- 
separated JSON arrays.  Use json2json or similar to pretty-format them 
to taste:

    $ tail -n 1 /var/tmp/suck-huggingface.log | json2json -l
    [ 1683950423.24891, "Fri May 12 21:01:00 2023", 16334, "INFO", 3, ["SKH:E0701EB9"],
      [ ["lib/Suck/Huggingface.pm", 145, "Suck::Huggingface::info"],
        ["bin/suck-hug", 38, "Suck::Huggingface::suck"],
        ["bin/suck-hug", 25, "main"]
      ],
      "done downloading files for this repo", {"total_size_bytes": 4437545, "n_downloaded": 1}
    ]

Those record elements are, in order:

* The TAI-10 time of the event as UNIX epoch seconds: 1683950423.24891
* The local time as a string: "Fri May 12 21:01:00 2023"
* The process id: 16334
* The log mode: "INFO" (can also be "CRITICAL", "ERROR", "WARNING", "DEBUG")
* The log record level: 3 (can be filtered with --log-level option)
* An array of trace identifiers, probably useless for this application
* An abbreviated stack trace: [filename, line number, method]
* An invariant description of the event: "done downloading files for this repo"
* The variant parts for the event: {"total_size_bytes": 4437545, "n_downloaded": 1}

Is this overkill for such a simple tool?  Hell yeah, but it's what I use for 
everything, and it's nice for monitoring the progress of long download tasks.

## OS SUPPORT

### LINUX

I've tested this on Slackware 15.0 and it works fine.

It does not work on CentOS 6 because Huggingface wants newer SSL capabilities 
than CentOS 6 git provides.

It *mostly* works on CentOS 7, but CentOS 7's git downloads large files too, 
which are supposed to be "pointers", so --exclude does not work as expected.

Will give it a go on Debian later.

If you try it on other distributions, please let me know how it goes.

### BSD

Totally should work.  Will test it eventually.

### MacOSX

Might work.  Might test it later.

### WINDOWS

Hahahahaha good luck!

## TO DO

  *  Test on more operating systems.

  *  More unit tests.

  *  Better download sorting -- git first, then scan pointer files to sum up sizes, then sort.

## CONTACT 

    ttk (at) ciar (dot) org

    https://old.reddit.com/u/ttkciar

    Libera IRC channels ##slackware-help or #perl

