#!/usr/bin/perl -w

use strict;
use Test::More tests => 9;

BEGIN {
    use_ok 'SVN::Notify::Filter::Markdown' or die;
}

my @log = <DATA>;

isa_ok my $n = SVN::Notify->new(
    to         => 'you@example.com',
    repos_path => '/foo/bar',
    revision   => 42,
    handler    => 'HTML',
    filters    => [ 'Markdown' ],
    smtp       => 'localhost',
), 'SVN::Notify::HTML', 'Create HTML notifier';

ok $n->message( [ @log ] ), 'Add our custom log message';
tie local(*FH), 'My::FH', \my $buf;
ok $n->output_log_message( *FH ), 'Output the log message';
like $buf, qr{<h1>Heading 1</h1>}, 'Check that the message is HTML';

# Now try non-HTML.
isa_ok $n = SVN::Notify->new(
    to         => 'you@example.com',
    repos_path => '/foo/bar',
    revision   => 42,
    filters    => [ 'Markdown' ],
    smtp       => 'localhost',
), 'SVN::Notify', 'Create non-HTML notifier';

ok $n->message( [ @log ] ), 'Add our custom log message';
tie local(*FH), 'My::FH', \my $out;
ok $n->output_log_message( *FH ), 'Output the log message';
like $out, qr{# Heading 1}, 'Check that the message is not HTML';


##############################################################################
# A simple File handle that just stores data in a scalar.
FH: {
    package My::FH;

    sub TIEHANDLE {
        my ($class, $buf) = @_;
        bless { buf => $buf } => $class;
    }

    sub PRINT {
        ${ shift->{buf} } .= join '', @_;
    }
}

##############################################################################
# The log message: a full Markdown example.

__DATA__
# Heading 1
## Heading 2
### Heading 3 ###

Other type of heading (level 2)
-------------------------------

And another one (level 1)
=========================

A paragraph, of *text*. 

  * UL item 1
  * UL item 2

Another paragraph \*Not bold text*.
  
  1. OL, item 1
  2. OL, item 2

A third paragraph

  * Second list, item 1
     * Sub list item 1
     * Sub list item 2
  * Second list, item 2

Within a paragraph `code block`, followed by one which needs ``extra escapeing` `` &copy; t0m.
& note **ampersands** and > or < _are_ escaped __properly__ in output

[testlink]: http://www.test.com/ "Test dot Com website"

[testlink2]: http://www.test2.com/

This paragraph has [a link] [testlink] and [another link] [testlink2].. This is [an example](http://example.com/ "Title") inline link.

[Google]: http://google.com/

Or, we could use <http://wuto-links.com/>. Or shortcut links like this: [Google][]

> block quoted text
>
> in multiple paragraphs
> and across multiple lines
>
> > and at
>> multiple levels.

    This is a code block here...
    
* * *

*****

- - -

un*fucking*believable - \*this text is surrounded by literal asterisks\*, but the text before that should be bold according to the docs, but isn't FIXME!

![Alt text](/path/to/img.jpg)

![Alt text2](/path/to/img2.jpg "Optional title")

[img]: url/to/image  "Optional title attribute"

![Alt text for ref mode][img]
