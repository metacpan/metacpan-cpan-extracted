# Slack::BlockKit

Almost any time you want to send content to [Slack](https://slack.com/), and
you want to end up in front of a human, you will want to use Block Kit.  You
can get away without using Block Kit if you're only sending plain text or
"mrkdwn" text, but even then, the lack of an escaping mechanism in mrkdwn can
be a problem.

The Block Kit system lets you build quite a few different pieces of
presentation, but it's fiddly and the error reporting is *terrible* if you get
something wrong.  This library is meant to make it *easy* to write Block Kit
content, and to provide client-side validation of constructed blocks with
better (well, less awful) errors when you make a mistake.

The library you're most likely to want to use is
[Slack::BlockKit::Sugar](https://metacpan.org/pod/Slack::BlockKit::Sugar),
which exports a bunch of functions that can be combined to produce valid Block
Kit structures.  Each of those functions will produce an object, or maybe
several.  You shouldn't really need to build any of those objects by hand, but
you can.  To find more about the classes shipped with Slack::Block Kit, look at
the docs for the Sugar library and follow the links from there.

For example, to produce something roughly equivalent to this Markdown:

```markdown
Here is a *safe* link: **[click me](https://rjbs.cloud/)**
* it will be fun
* it will be cool 🙂
* it will be enough
```

You can write this code:

```perl
use Slack::BlockKit::Sugar -all => { -prefix => 'bk_' };

bk_blocks(
  bk_richblock(
    bk_richsection(
      "Here is a ", bk_italic("safe"), " link: ",
      bk_link("https://fastmail.com/", "click me", { style => { bold => 1 } }),
    ),
    bk_ulist(
      "it will be fun",
      bk_richsection("it will be cool", bk_emoji('smile')),
      "it will be enough",
    ),
  )
);
```
