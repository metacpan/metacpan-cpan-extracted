package Review::Helper::Manual;
use v5.36;

our $VERSION = '0.001';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Review::Helper::Manual - How to review your AI agent's code with review-helper.

=head1 EARLY VERSION

This is a very early version. Some key features are still to come, and it is
not ready for daily use. Expect changes between releases, including to the
commands, the review page and the review file format; a review built with
one release may not open in the next.

=head1 DESCRIPTION

review-helper helps you review code an AI agent wrote. Instead of reading a
raw diff, you read the change top-down in a local web page: a summary of the
whole change, then each commit, file, and sub, each with a short explanation
the agent wrote. You open a diff or the code only when a summary looks wrong
or the details matter.

The workflow:

=over 4

=item 1.

While coding, the agent records B<notes>: wrong assumptions, deviations from
the plan, surprises, and anything else you should look at.

=item 2.

When the work is committed, the agent B<builds a review> of the commit range
and fills in explanations, a reading order, where each note belongs, and a
short guided tour.

=item 3.

The agent starts the review's server and gives you its link; you review in
your browser. Notes that ask for your judgment show as B<flags> beside the
lines they concern, yellow or red; the rest are listed in the B<journal> at
the end of the page. You leave B<feedback> and B<requests>.

=item 4.

The agent reads your feedback, changes the code in new commits, and adds a
new B<iteration> to the same review, with a response to each item.

=back

Your agent does steps 1, 2, and 4 through the agent skills that ship with
review-helper, and starts the server for you. You only review.

The other primary use is B<reviewing a whole project>, or one area of it, as
it finally lands. No notes were recorded and you do not want to walk every
commit, so the agent deduces points of interest from the history, docs,
tests, and issues, and builds one combined review with a guided tour of the
final code. It works as well for learning a codebase. See
L</REVIEWING A WHOLE PROJECT>.

=head1 QUICK START

You need Perl 5.36 or newer, git, and a web browser.

=over 4

=item 1. Install

    cpanm Review::Helper

=item 2. Install the agent skills

Link each skill into your agent's skills directory, or ask your agent to
install them. See L</Installing the skills>.

=item 3. Record notes while coding

Before your agent starts a change, tell it to use the B<review-notes> skill.
In Claude Code you can type C</review-notes>; in any agent you can say "use
the review-notes skill". The agent records notes as it works.

=item 4. Build the review

When the change is committed, tell the agent to use B<review-build>, for
example "build a review of this branch with review-build". It starts the
review's server in the background and gives you the link to open. Ask it to
share the review with others on your network and it serves it there instead,
giving you a link with a token to pass on (see L</Reviewing from another
machine>); it stops the server when the review is closed, or when you ask.

=item 5. Open it

Open the link. To serve a review yourself instead:

    review-helper .git/review-helper/my-change.sqlite --open

This starts a local server, prints its URL, and opens your browser. Without
C<--open> it only prints the URL. Stop the server with Ctrl-C when you are
done.

=back

C<review-helper list> shows the reviews in the current repository if you lose
track of a file.

=head1 REVIEWING IN THE BROWSER

The page is one long column with an index tree on the left.

=head2 Summary and commits

The page starts with the review summary: what the change does, why, and how.
It also lists the flags, linked to their places, grouped by color, red
first; each group starts collapsed to its counts. Below it comes one section
per commit, in commit order, each with its own what, why, and how. Each commit
is meant to fit on one screen. A merge shows as one entry that groups the
commits it brought in; it has no diff of its own.

The header shows whose review it is and which repository (C<user@host ·
repo>), the review title, a link to the pull request when the review is of
one, and an iteration selector. The latest iteration is the default. When
the window is too narrow for everything on one line, the controls move to a
second line.

A browser tab remembers which review it showed. If the server on that port
is later serving another review (say, after a restart), the page says so in
a banner; B<Continue with this review> accepts it and starts from the top.

=head2 The tree

The tree lists the summary and each commit. It starts closed: open it with
the tall B<< > >> tab on the page's left edge, and close it with the B<< < >>
tab on its right edge. The page remembers whether you left it open. As you
scroll, the current commit opens to show its files and the tree follows
along. Click a node to jump to it. Drag the tree's edge to resize it.

=head2 Opening files and sections

A commit opens downward. Below its summary, every file is listed as a
compact, outlined row with just its path, line counts and flags, like a
file's section rows; hover the path for its status, or expand the file for
its summary. Click a row to expand that file in place; the other files
stay listed, and any number can be open at once. A line down the left ties
each open level to the head above it, like an L. A merge lists its commits
instead, as rows the same way: open one and it expands in place, the
merge's other commits staying listed. Each level has its own color, so a
merge and the commits in it are told apart at a glance. A merge
that resolved conflicts carries a B<resolved conflicts> badge and a
B<resolution> tab, which shows how the conflicts were resolved (what
C<git show --remerge-diff> shows). A commit that renamed files counts them
under its revision, for example B<Renamed> C<3 files (2 changed)>.

Each commit's head has tabs, like the B<Unified> and B<Side by side> switch:
B<list> and B<diff>, and B<resolution> on a merge that resolved conflicts. A
merge has no B<diff> tab, as its commits carry its changes, so a merge that
resolved no conflicts has no tabs, nor does a commit with no files. B<list>,
the default, shows the files (or a merge's commits) as rows; B<diff> shows
the whole commit's diff in their place, right under the commit's summary.
The tab shown is checked; the arrow keys move between tabs. Back on
B<list>, the files and sections you had expanded are as you left them.
Going to a file, section or line in that commit, from the tree, the guide, a
flag link or the flag walker, switches the commit to B<list> so you see it.

=over 4

=item *

A file shows what changed in it, its object system and style (such as
Object::HashBase, OOP, exporter), its line counts, and its sections. Its head
has tabs like a commit's: B<list>, B<diff> and B<file>. B<list>, the
default, shows its sections; B<diff> shows the file's diff and B<file> the
whole file after the commit in their place, and back on B<list> the sections
are as you left them. A file with no sections to list has no B<list> tab and
opens on B<diff>. A deleted file has no B<file> tab, and a binary file no
tabs at all. A renamed file shows its old and new paths, C<old/path →
new/path>, with a B<renamed> badge, or B<renamed + changed> when its content
changed too; a file only renamed has no sections. Going to a section, from
the tree or the guide, switches the file to B<list>. Click its head (anywhere but its buttons) to collapse it to
its row again.

=item *

Each section is listed as a collapsed row with its name, kind, line counts,
and flags. Click a row to expand it in place: its summary next to its
documentation, with its diff below. Click its head again to collapse it. Any
number of sections can be open at once, so you can read several side by
side. The agent that built the review chose the sections while reading the
code: subs, methods, functions and other named blocks (such as
C<< subtest name => sub {...}; >>), CSS rules, and Markdown or POD headings,
each with the comments and documentation that belong to it, and sometimes a
part of a long sub that needs its own explanation. The file's main package
or class and control flow (an C<if>, a loop, C<map>) are not sections; a
short second package or class in the same file may be one section, named
C<package Foo::Bar>. The agent names every part of the file, the header and
code between subs too; blank lines go with the section before them. Only
sections the commit changed are listed. A file the agent has not split yet says so and lists none; a file it
left whole lists none either: read its diff. A section's diff shows the
whole sub and its whole documentation, changes marked, as two parts, even
when the documentation is far below (after C<__END__>); POD beside the
summary is shown formatted. Feedback and requests given on a section that a
later split took away show on its file, noting the section they were on.

=item *

Click a commit in the tree to collapse everything under it, or use the
browser's back button. A commit opened from a merge, and a whole file a guide
step shows, close the same way files do: click their head. The view
lives in the URL, so back, forward, and reload all work.

=back

File names are colored by change: green for new, red for deleted, blue for
an existing file whose content changed, whatever its size did.

=head2 Diff and view file

Each section has a B<diff> button, showing the diff for that section only,
and a B<file> button, showing the whole file after the commit with syntax
highlighting and the section marked. A commit shows its whole diff on its
B<diff> tab, and a file its diff and the whole file on its B<diff> and
B<file> tabs.

An SVG file is diffed as text; its B<file> tab also shows the picture before
and after the commit, side by side, above the source. An image's B<diff> tab
shows it before and after, its B<file> tab as it is after the commit.

Diffs are B<Unified> or B<Side by side>. The toggle in the header applies
everywhere and is remembered by your browser.

=head2 Reading order and A-Z

The agent orders each commit's files so that a file comes after the files
you need to understand it. The header toggle switches between B<Reading
order> (the default) and B<A-Z>. Until the agent fills the order, the toggle
shows it as pending and files sort A-Z. Commits always stay in commit order.

=head2 Flags

A flag is the agent telling you about something it wants you to judge.
It has one of two colors:

=over 4

=item yellow: a reviewer may object

A decision the agent made, a deviation from the plan, or a problem it solved
in a way you may not accept.

=item red: probably a problem

Something still unsolved. Nothing the agent solved is red.

=back

Each flag also has a kind (deviation, assumption, self-review, test-revealed,
note or other), a one-line sentence, and sometimes a detail. Only the agent
sets a color; when it changes one, it says why, and the popup shows that
reason. There is no unflagging: a red flag needs action, and a yellow one you
accept is settled once you have seen it; comment on it otherwise.

A flag icon sits in the gutter of diffs and file views, with a bar of its
color on the rest of its lines. Hover over it for what its color means and
its sentence; click it for the popup: color, kind, sentence, detail, the
reason for its last color change, and its comments. A small eye on the icon
means you have seen the flag, and a speech mark that it has comments.
Opening a flag's popup, following a link to it, or commenting on it counts as
seeing it; the popup's B<Mark unseen> undoes that, to come back to it later.

Tree nodes and file and section rows show a count of the flags inside them,
red when any of them is, with a small dot when you have not seen some of
them. Seen flags stay shown and counted.

The popup lists the flag's comments and has a box to add one. Comments are
feedback like any other: the agent responds to them, and they stay with the
flag in later iterations. What you type in the popup stays until you send it
or clear it, even when the popup redraws or you close it and open it again.
When the agent retires a flag, its comments move to
its file (its commit, for a flag on the whole commit), marked "was on flag".

A card lists the flags none of its rows carry, under its summary, whatever
tab is open: a file's flags on the whole file and on lines in none of its
listed sections, and a commit's flags on the whole commit and on files it
did not change. Each line shows the flag's icon, kind and sentence; click it
for the same popup as the gutter icon, or click its lines to go to them.

A flag link in the summary, or a step of the flag walker, takes you to the
flag and marks it there: its lines stand out in the flag's color, with the
flag's sentence in a box right above them. A flag on the whole file or
commit, or one whose lines cannot be shown (on a binary file or an image),
marks its line on the card instead. The box or line pulses briefly as you
arrive. The mark goes away when you go anywhere else.

=head2 The flag walker

The flag walker steps through the flags in the guide bar, red first, then
in commit, path and line order. Start it from the header or above
the summary's flag list: B<Walk new (N)> walks the N flags you have not seen,
so starting it again picks up where you stopped; B<Walk all (M)> walks all M
flags, seen ones too, from the first. Each color group in the summary has
the same two buttons for its own flags. A button with nothing to
walk is disabled. Each step opens the flag's place and shows its sentence.
Moving on, with next or back, marks the flag you leave as seen, and so does
leaving the walk, by its exit button, another walk or the browser's Back. A
flag you marked seen or unseen by hand while the walk showed it keeps your
choice for the rest of the walk. B<Mark seen> and B<Mark unseen> set the
current flag by hand.

Seen marks are yours: each one records who you are and when. Marks other
reviewers made in the same review file show in the bar ("Seen by Bob") but do
not change your walk. The summary's flag list shows who has seen each flag.

A new iteration keeps a flag, with its comments and everyone's seen marks,
while the code under it is unchanged, even if it moved. When that code
changed, the flag comes back unseen, and the agent decides whether to keep it,
recolor it or retire it; until then its popup says so. A flag on a file the
change no longer touches (a change to it was reverted) comes back unseen the
same way, even if its lines read the same; once kept, it carries on as before.
A yellow flag the agent turns red comes back unseen for everyone.

=head2 The journal

The B<Journal> section, at the very end of the page, lists what the agent
noted while working that probably needs no attention: things worth knowing
that are not flags. Click an entry to open it: its kind, the file it is
about (a link to the file, when the iteration changed it) and the unit, a
button to read it aloud, and its detail. Journal entries take no comments,
have no badges and are not walked. Each belongs to the iteration it was
recorded for; a new iteration does not carry it.

=head2 The guide

The guide is the agent's short guided tour of the change. Start it with the
B<Play guide> button in the header. The guide bar at the bottom shows each
step's commentary with buttons to read it aloud, the step number, and back,
replay, next, speech, and exit buttons.
B<next topic> skips to the first later step on another topic, and
B<previous topic> goes back to the first step of the topic before; in a
review not split into topics they say "commit" and go by commit. A guide
that comes back to a topic later counts that visit as a topic of its own.
Each button hides when there is nowhere to go.

Each step moves the real page: it opens the right commit, file, section, or
diff and highlights the lines it talks about. Nothing advances on its own;
only B<next> and B<back> move. You can explore by hand at any time and press
B<next> to carry on. Moving to another step, or exiting the guide, undoes
what the step you leave changed: a file or section it expanded collapses, a
diff or file view it opened closes, and a commit or file it switched to
another tab goes back to the tab you had. Anything you had open before the step, and
anything you opened yourself elsewhere, stays as it was, even after a
reload. The guide is hidden when an iteration has none.

=head2 Speech

Your browser's built-in speech can read the agent's writing aloud. Every block
of it has two small buttons: the summary's and each commit's what, why and
how, the iteration note, a file's or section's what changed, a flag in its
popup and on its card line (its sentence, then its detail), and the guide
bar's step. B<▶> reads the block, two bars pause it where it is, and B<▶>
again carries on from the sentence it paused in. The black square stops it and
goes back to the start. Playing another block pauses the one playing, which
keeps its place, and so does closing or collapsing the block being read. Code
marks in the text are not read out, and C<::> and C<< -> >> read as a short
pause: C<Foo::Bar> reads as "Foo, Bar".

Nothing is read by itself except in the guide bar, and only when you turn
on its B<speech> toggle: then the guide reads each step as it shows. The
flag walker has a toggle of its own, which reads each flag's sentence and
detail as it arrives. Both are off by default. Moving to another step stops
the reading of the one you leave.

The speech menu (the speaker icon in the header) holds the voice and the
speed (0.75x to 1.5x) for all of it. The voice list shows voices on your
device first, and those are the default. Voices marked "(online: text leaves
this machine)" send the text to an online service, and are never chosen for
you: when your browser has only online voices, playing anything opens the
menu to pick one, and reading starts once you do. Your choices are
remembered by your browser. When your browser has no voices, the menu says
why, and the guide bar's toggle stays in view, disabled; on Linux the
browser needs speech-dispatcher for voices.

=head2 Feedback

The summary and every commit, file, and section have a B<feedback> button
for a comment on that item. Its form, and a B<request> button's, opens right
under the header you clicked, which stays where it is. To comment on one line, click its line number in
a diff or file view; in a side-by-side diff, click the old or the new side's
number.

Feedback shows inline where you left it, with who wrote it. After the agent
responds, each item shows its status (open, addressed, or declined) and the
agent's response. Feedback from earlier iterations shows the iteration that
resolved it.

=head2 Who is reviewing

The page records who you are on the feedback, requests and seen marks
you make, so a review file passed between several people says who left what.
By default you are C<< Name <email> >> from git's C<user.name> and
C<user.email> for the repository, or your login name when git has neither
(C<unknown> when there is no login name either). Set
C<REVIEW_HELPER_REVIEWER>, or start the server with C<--reviewer NAME>, to use
another name. Hover over the header's identity line to see the name in use.

Only the person who wrote a piece of feedback can edit it or change its
status; on anyone else's there is no B<edit> button, so answer it with
feedback of your own. Feedback written before reviewers were recorded names
no one, and anyone can edit it.

=head2 Requests: debate and split

The B<request> button asks the agent for deeper work:

=over 4

=item debate

On a commit, a file, or a section. Two separate agents argue,
one for the code as written and one against it or for an alternative. Both
cases show side by side under the item.

=item split

For a file its commit added or whose lines it changed; a file only
renamed, or only made executable, has nothing to split. The agent splits the
file into sections again, taking your note into account: for example to
give a long sub's parts their own explanations, or to split a file it left
whole. It explains the new sections afresh.

=back

Add a note to say what you want.

=head2 Handing feedback to the agent

Tell your agent the review has feedback and to use B<review-feedback>. It
reads your open feedback and requests straight from the review file.

B<Download feedback> saves the same data as a JSON file, for an agent that
cannot reach the repository.

When the agent has added a new iteration, reload the page. Explanations,
reading order, and flags carry over for commits that did not change. In a
squashed review, flags carry over, and explanations of files that did not
change, but only while the base stays the same: an iteration on a new
C<--base> starts with no flags or explanations. Files keep their topic, a
topic whose files all read the same keeps its explanation, and new files wait
for the agent to put them in a topic, listed as "Not in a topic yet". Your
feedback on a topic shows under the topic of that name in every iteration.
When the agent's topics remove the topic you commented on, or split the whole
change you commented on before its first topics, your feedback moves to the
summary, noting the topic it was on ("was on: the whole change" for the
latter, "was on: not in a topic yet" for the files waiting for a topic). The
summary also lists, under "Not shown in this iteration", feedback that no card
of the iteration you are looking at can show: its commit, its topic, its file
or its section is not there, such as an earlier iteration's feedback on a
topic the agent has since renamed, on a file a narrower iteration left out, or
on a section the file's new split does not have. When a topic's files all
leave the change, its flags move to the first topic; a flag on the whole topic
keeps your seen mark but no longer says which topic it was about.

=head2 Close review

B<Close review> marks the review finished. Closed reviews lose their pinned
commits on the next C<review-helper prune>, so earlier iterations may no
longer show their diffs after that. The review file itself is kept.

=head2 Privacy

By default the server listens only on your own machine (127.0.0.1) and needs
no password: anyone logged in to the same machine can open it, so use it
where the other users are people you trust. Web pages, including ones served
from other local ports, cannot read it or change your feedback.

=head2 Reviewing from another machine

To run review-helper on a shared dev server and review from a browser on your
laptop, listen on the network:

    review-helper .git/review-helper/my-change.sqlite --listen 0.0.0.0

It prints two URLs: one with the server's name (its fully qualified name) and
a token, for your laptop, and the usual 127.0.0.1 one. Open the first on your
laptop; the page then keeps the token in a cookie for that browser and drops
it from the address bar. Other machines without the token get an error page.
The 127.0.0.1 URL needs no token, as before. Use C<--listen ::> to listen on
IPv6 as well, or give one address or host name of the server to listen there
alone. Set C<REVIEW_HELPER_LISTEN> to do this every time, and use C<--port> or
C<--port-command> for a port your laptop can reach through any firewall.

The page answers to the server's hostname, its fully qualified name, the
addresses those names resolve to, and the address its outgoing traffic uses.
If you reach it by another name or address, such as a DNS alias or the address
of a VPN, add C<--allow-host NAME> (repeatable), or list the names,
comma-separated, in C<REVIEW_HELPER_ALLOW_HOSTS>. Any other name gets an error
page; this is what keeps hostile web pages from reaching the review through a
name of their own.

B<Anyone with the token URL can read the review, including the code it
shows, and post feedback,> and so can anyone logged in to the server, with
no token at all. The server says so when it starts. Do not put a reverse
proxy (nginx, Caddy, ...) on the server in front of it: the proxy connects
from the server itself, so everyone who can reach the proxy gets in without
the token. To review together, give the token URL only to people you trust
with the code, directly; do not paste it into a ticket or a public channel.
The token is new each time the server starts. Over plain http, someone watching
the network could read it, so do this only on a network you trust, such as a
work network behind a firewall, and stop the server when you are done.

=head1 WORKING WITH AN AGENT

review-helper ships nine skills: instructions your agent follows (see
L</Installing the skills>). Invoke a skill by name, for example
C</review-build> in Claude Code, or "use the review-build skill" in any
agent.

=over 4

=item review-notes

Use it B<before the agent writes any code> and keep it in effect for the
whole task. The agent records a note whenever an assumption proves wrong, it
deviates from the plan, a test exposes a misunderstanding, self-review
corrects something, or a point deserves your attention. A note you may
object to, or a problem still unsolved, becomes a flag; anything else goes
in the journal. No review file is needed yet.

=item review-build

Use it when the work is committed. The agent cleans up old refs, builds a
review of the commit range, and fills in summaries, reading order, note
placement, and the guide. It asks you for the range if it is unclear.

=item review-feedback

Use it after you leave feedback. The agent fixes the code in new commits,
adds a new iteration, and answers each feedback item as addressed or
declined, with a reason. It handles open requests first.

=item review-requests

Use it when you made debate or split requests. The agent runs each debate
with two independent sub-agents and records both cases, and splits files
again.

=item review-cleanup

Use it to remove the pinned refs of closed reviews and of reviews whose file
is gone. It never deletes review files.

=item review-pr

Use it to review someone else's pull request. See
L</REVIEWING SOMEONE ELSE'S PULL REQUEST>.

=item review-project

Use it to review a whole project, or one area of it, as it lands, or to
learn a codebase. See L</REVIEWING A WHOLE PROJECT>.

=item review-add-notes

Use it for a second opinion on a built review. Another agent reads the
change and adds its own flags; it changes nothing else.
Reload the page to see them.

=item review-publish

Use it to post your feedback to the pull or merge request. The agent shows
you exactly what it will post and posts nothing until you agree. Your text is
posted word for word, under your own account. Line feedback becomes a line
comment where its line still stands at the same place in the request's
diff and the forge accepts one, otherwise a general comment starting with
its file, line, and commit. Each posted item is marked so it is never
posted twice. The agent posts with the tools it has for your forge, such as
its command-line tool or an MCP server.

=back

=head2 Installing the skills

C<review-helper skills path> prints the directory the skills ship in, one
subdirectory per skill. Link the skills you use into your agent's skills
directory, one line per skill:

    ln -s "$(review-helper skills path)/SKILL" ~/.claude/skills/    # Claude Code
    ln -s "$(review-helper skills path)/SKILL" ~/.agents/skills/    # Codex

Replace C<SKILL> with the skill's name, such as C<review-build>, and create
the directory first if it does not exist. Or ask your agent to install the
review-helper skills. Linked skills follow the installed review-helper, so
upgrading it updates them.

Both agents load a skill whose directory is a symlink. In Claude Code, an
auto-update once removed symlinked skills
(L<https://github.com/anthropics/claude-code/issues/50052>); link them again
if they disappear. Its C</skills> menu may not list symlinked skills, though
they still load (L<https://github.com/anthropics/claude-code/issues/14836>).

=head2 Granting the skills' commands

Each skill's C<allowed-tools> line pre-grants only C<review-helper> and
read-only C<git> commands. B<review-pr> is also pre-granted C<git fetch>,
which writes fetched objects and refs. Everything else a skill runs follows
your normal approvals: the forge tools of B<review-pr>, B<review-project>
and B<review-publish>, the commits B<review-feedback> makes, and the posts
of B<review-publish>.

In Claude Code, a skill's commands are allowed only for the turn that invoked
it. To stop later prompts, allow C<Bash(review-helper *)> in your settings
(F<~/.claude/settings.json>, or F<.claude/settings.json> in a project):

    {
        "permissions": {
            "allow": ["Bash(review-helper *)"]
        }
    }

In Codex, add a rule to F<~/.codex/rules/default.rules>:

    prefix_rule(pattern = ["review-helper"], decision = "allow")

Narrower rules work too. B<review-notes> needs only
C<Bash(review-helper note *)>, and B<review-cleanup> needs only C<Bash(review-helper prune)> and
C<Bash(review-helper prune *)>, which are safe to allow outright: C<prune>
takes no arguments that pick what to delete and never removes review files.

Forge writes are the posts of B<review-publish>; approve each one as it
comes rather than allowing your forge's tools outright.

=head1 INTEGRATING WITH A PROJECT

=head2 Where review files live

By default a review file is stored in the worktree's git directory:
F<.git/review-helper/NAME.sqlite> in a main checkout, or
F<.git/worktrees/WT/review-helper/NAME.sqlite> in a linked worktree.
It never shows up as an untracked file. C<review-helper build --file PATH>
puts it anywhere inside the worktree instead; keep it out of your commits,
for example by ignoring it.

The review file holds only review data: explanations, flags, feedback, and
the commits each iteration covers. Diffs and file contents are read from
git when you open the page, so the file only works inside its repository.

Review files are never upgraded. A file of another format version is
refused. A file an earlier build of the same format version wrote may fail
with database errors instead; build the review again, to a new file or after
removing the old one, or open it with the version that built it. An export
that lacks a table or column this version has is refused: export it again
with this version, or import it with the version that built it.

The agent's notes are kept per worktree too, in
F<review-helper/journal.jsonl> beside the review files, until a build places
them into a review.

=head2 Worktrees

Each worktree has its own reviews and notes. Record notes, build, and open
the review in the worktree where the work was done, one review per worktree
at a time: notes from other work there share the journal, and agents place
only the notes they recognize. C<review-helper list>
shows every review registered in the repository, from any worktree.

If you remove a worktree, its review files go with it. C<prune> then cleans
up the refs those reviews left behind.

=head2 Pinned refs

Each iteration pins its head commit at
C<refs/review-helper/REVIEW-ID/N>. Iterations often follow a rebase or an
amend, which would otherwise leave the earlier commits to git's garbage
collector. The pins keep earlier iterations viewable. They are shared by all
worktrees of the repository.

=head2 Cleaning up

    review-helper prune --dry-run
    review-helper prune

C<prune> deletes the refs of closed reviews and of reviews whose file no
longer exists. It takes no ref or path arguments and never deletes review
files. The review-build skill runs it before every build. Delete a review
file yourself when you no longer want it.

=head2 Sharing a review

A review file stays on your machine. To give a review to another reviewer,
export it and commit the export on the branch under review, or attach it to
the pull request:

    review-helper export FILE --out .review-helper/NAME.json

The export is JSON text with everything the review file holds except
feedback, requests and seen marks: each reviewer keeps their own. Another
reviewer checks out the branch and runs

    review-helper import .review-helper/NAME.json

which creates their own review file, open whatever state the export
records, and prints its path. It names any commit the export covers that
their clone lacks; fetch it to view that iteration. Importing a newer export
of the same review merges it into that file: new iterations and fresh
explanations arrive, your feedback and requests stay, and every iteration
whose commit you have fetched since is pinned. It replaces the iterations
the export carries, so import the latest export.

=head2 Telling your agents

Add this section to the project instruction file your agents read at
startup. That is F<AGENTS.md> at the repository root for Codex, and
F<CLAUDE.md> for Claude Code. Use both if you use both.

    ## Code review

    This project reviews agent work with review-helper.

    - Before writing code for any change, read the review-notes skill and
      record notes as it describes for the whole task.
    - When the change is committed, build a review with the review-build
      skill and give me the link to open it.
    - When I say a review has feedback, use the review-feedback skill.

=head1 REVIEWING SOMEONE ELSE'S PULL REQUEST

The B<review-pr> skill prepares another person's pull or merge request for
you. Give your agent the PR URL and ask it to use review-pr.

The agent reads the PR description, its discussion and reviews, and the issues
it links. It fetches the PR's commits, builds a review with a link back to the
PR, and fills it in. Nobody recorded author notes, so the agent flags what you
should check: suspected problems and gaps between what the PR claims or the
issue asked and what the code does are red, choices you may object to yellow;
points merely worth knowing go in the journal. Existing reviewer comments that
remain unaddressed are mentioned where they apply.

The agent reads the forge with the tools it has for it, such as the forge's
command-line tool or an MCP server, and stops if it has none.

The skill is B<read-only toward the forge>. It never comments, approves,
requests changes, merges, or pushes. Posting a review there is up to you.

=head1 REVIEWING A WHOLE PROJECT

The B<review-project> skill prepares a codebase for a final review, or for
you to learn it. Ask your agent to use it, and say what to cover.

The agent reads the commit history (reverts, fixes, files that change most,
the reasons given in messages), the docs, the tests, TODO comments, and open
issues where it can. It records what you should look at as flags: suspected
problems and code that departs from its docs are red, choices you may object
to yellow, points merely worth knowing in the journal. Then it builds one
combined review of the code as it stands, splits its files into a handful of
topics (for example the skills, the Perl backend, the frontend), explains each
topic and file, and writes a guided tour: entry points, core data structures,
the main flows, then each flag. The page shows the topics where a review of
history shows commits, "1. Perl backend", "2. Frontend", each with its files;
a small review may have just one.

    review-helper build --squash --path lib --path t --title "Perl side"

C<--squash> reviews the code at the head as one change; with no C<--base>
it covers the whole codebase. C<--path> limits a review to matching files.
A large codebase is better split into several reviews, for example one for
the Perl code and one for the JavaScript; the agent suggests a split and
asks you.

=head1 COMMANDS

All commands run inside a git repository. Output goes to standard output;
errors go to standard error with a non-zero exit code.

C<review-helper> runs an implementation of the review-helper standard found
on your C<PATH>; this distribution's is C<review-helper-perl>, and the two
take the same commands. When several are installed, the first found on
your C<PATH> runs, unless C<REVIEW_HELPER_IMPL> names one (C<perl> and so
on). C<review-helper --which> lists the implementations it finds with their
paths, marks the one it runs with C<*>, and prints the versions that one
reports.

=over 4

=item review-helper FILE [--port N | --port-command CMD] [--listen ADDR] [--allow-host NAME]... [--open] [--reviewer NAME]

=item review-helper serve FILE [--port N | --port-command CMD] [--listen ADDR] [--allow-host NAME]... [--open] [--reviewer NAME]

Serve the review page on 127.0.0.1 and print its URL. C<--port> fixes the
port (the default is any free port). C<--port-command> instead runs C<CMD>
and listens on the port number it prints, for example a port-lease tool
that gives each worktree its own port; set C<REVIEW_HELPER_PORT_COMMAND> to
use one every time. C<CMD> is split on spaces and run without a shell.
C<--listen> listens on another address, such as C<0.0.0.0> for every
interface, and C<--allow-host> accepts another name for this machine (see
L</Reviewing from another machine>; C<REVIEW_HELPER_LISTEN> and
C<REVIEW_HELPER_ALLOW_HOSTS> set them every time). C<--open> also opens your
browser on Linux and macOS, on the loopback URL when there is one.
C<--reviewer> names who is reviewing (see L</Who is reviewing>).

=item review-helper build [--base REV] [--head REV] [--squash] [--path SPEC]... [--title TEXT] [--source URL] [--file PATH]

Create a review whose first iteration covers the commits after C<--base> up
to C<--head>, pin it, and print the review file's path. C<--head> defaults
to C<HEAD>. C<--squash> reviews the range as one combined change; C<--base>
is required without it and defaults to the whole codebase with it. Each
C<--path> (a path spec of the VCS: for git, a pathspec) limits the review to
matching files. C<--source> links the review to a pull request. C<--file>
chooses the file's path. The worktree's journal entries go into the first
iteration.

=item review-helper iterate FILE [--base REV] [--head REV]

Add the next iteration and print its number. The base defaults to the
previous iteration's, the head to C<HEAD>. C<--squash> and C<--path> carry
over from the review's build. A squashed review carries flags and
explanations into the new iteration only with the same base; a new C<--base>
carries none. A carried flag whose code changed waits for the agent to keep,
recolor or retire it through the sheet. The worktree's journal entries go
into the new iteration.

=item review-helper note [--flag COLOR] [--kind KIND] --path PATH [--unit NAME] [--snippet TEXT] --sentence TEXT [--detail TEXT]

Record a note in the current worktree and print its id. Without C<--flag> the
note is a journal entry, which the next C<build> or C<iterate> takes into its
iteration's journal (see L</The journal>); with it, a flag of C<COLOR>,
C<yellow> or C<red> (see L</Flags>), which the agent places. C<KIND> is one of
C<deviation>, C<assumption>, C<self-review>, C<test-revealed>, C<note> or
C<other>, the default. Needs no review file.

=item review-helper sheet [--all] FILE

Print the fill sheet: JSON listing everything in the latest iteration that
still needs the agent's text. With C<--all>, items already filled are listed
too, with their current text, so an agent can rewrite them through C<fill>.

=item review-helper fill FILE SHEET

Check a filled sheet (C<-> reads standard input) and import it. Nothing is
written unless the whole sheet is valid. Prints what was filled and what
remains.

=item review-helper feedback FILE [--open | --publish [ID...]]

Print the review's feedback and requests as JSON. C<--open> limits it to
those still open. C<--publish> prints what to post to the pull or merge
request instead: for each open item not yet posted, or each item ID, the
exact text of its comment and where a line comment goes, if one fits. The
B<review-publish> skill posts from it.

=item review-helper export FILE [--out PATH]

Print the review as JSON for sharing, without its feedback and requests.
C<--out> writes it to C<PATH>, creating missing directories.

=item review-helper import JSON [--file PATH]

Create a review file from an export (C<-> reads standard input) and print
its path. The review arrives open. It is named after the JSON file unless
C<--file> chooses the path. When this repository already has the review,
the export is merged into that file, keeping your feedback and requests; a
file holding another review is never overwritten. Commits the export covers
that this repository lacks are named on standard error.

=item review-helper close FILE

Mark the review closed.

=item review-helper published FILE ID

Record that feedback item ID was posted to the pull or merge request, so it
is not posted twice. The B<review-publish> skill runs this after each post.

=item review-helper list

List this repository's reviews: id, state, and path, one per line.

=item review-helper prune [--dry-run]

Delete the pinned refs of closed reviews and of reviews whose file is gone,
printing each one. C<--dry-run> only prints them.

=item review-helper skills path

Print the directory the shipped skills are in.

=item review-helper version

Print the version of the standard this tool implements (the review file
format, these commands and the page's HTTP API) on a line starting
C<standard>, then the tool's own version on a line starting
C<implementation>.

=back

=head1 THE REVIEW FILE FORMAT

The review file is an open, documented format, not a private detail of this
tool. One goal of the project is a standard base for AI-assisted code review:
a sharable review file that other tools, agent skills and review processes
can build on and extend. It covers the review file itself (an SQLite
database), the notes journal, the JSON fill sheet agents write explanations
through, the feedback and review JSON exports, the repository conventions
(the registry of reviews and the pinned refs), and the set of commands the
skills rely on. Another tool, in any language, that implements all of these
can read and write the same files and drive the same skills.

The full specification is the Markdown file F<standards/FORMAT.md> in the
distribution's share directory, next to the F<skills> directory that
C<review-helper skills path> prints:

    less "$(review-helper skills path)/../standards/FORMAT.md"

Beside it, F<CLI.md> specifies the commands the skills rely on and how the
C<review-helper> command finds an implementation, and F<API.md> the HTTP API
the review page uses. The three make up one standard with one version, which
C<review-helper version> prints. In the source repository they are in the
top-level F<standards> directory.

=head1 SOURCE

The source code repository for Review-Helper can be found at
L<https://github.com/exodist/Review-Helper>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
