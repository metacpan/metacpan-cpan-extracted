# Contributing to the development of PDF::Builder

**Working on your first Pull Request?** You can learn how from this *free* series [How to Contribute to an Open Source Project on GitHub](https://kcd.im/pull-request) 

We would appreciate the community around us chipping in with code, tests, 
documentation, and even just bug reports and feature requests. It's better 
knowing what users of PDF::Builder want and need, than for us to guess. It's 
not good to spend a lot of time working on something that no one is interested 
in! Of course, there's always that apocryphal quote from Henry Ford: "If I had
asked people what they wanted, the would have said **faster horses**."

You can contribute to the discussion by posting bug reports, feature requests, 
observations, etc. to the [GitHub issues area](https://github.com/PhilterPaper/Perl-PDF-Builder/issues?q=is%3Aissue+sort%3Aupdated-desc "issues")
(please tag new threads accordingly, using ["Labels"], if possible).

Please also read INFO/RoadMap to get an idea of where we would like for 
PDF::Builder to be heading, and may give you an idea of where you could
usefully contribute. Don't be afraid to discuss or propose taking PDF::Builder
off in a direction not in the RoadMap -- the worst that could happen is that
we say, "thanks, but no thanks."

First of all, please read the section "Sofware Development Kit" under 
PDF::Builder::Docs. This will be of interest if you want to do anything beyond 
simply installing PDF::Builder as a prerequisite for some other package. You 
can also get to this via "SOME SPECIAL NOTES" section of the root documentation 
(PDF::Builder). You should create all the HTML documentation by running 
"docs/buildDoc.pl --all" and read it before starting any serious work.

For code changes, a GitHub pull request, a formal patch file (e.g., "diff"), or 
even a replacement file or manual patch will do, so long as it's clear where it 
goes and what it does. If the volume of such work becomes excessive (i.e., a 
burden to us), we reserve the right to limit the ways that code changes can be 
submitted. At this point, the volume is low enough that almost anything can be 
handled. Please DO NOT send us code changes "out of the blue" (without prior
discussion), unless they are very small, so that you're not out a lot of
effort if we decline the offer.

## Do NOT...

Do NOT under ANY circumstances open a PR (Pull Request) to **report a _bug_.** 
It is a waste of both _your_ and _our_ time and effort. Instead, simply open a 
regular ticket (_issue_) in GitHub, and _attach_ a Perl (.pl) program that 
illustrates the problem, if possible.
If you believe that you have a program patch (i.e., a permanent change to the
code), and offer to share it as a PR, we may give the go-ahead. Unsolicited PRs
may be closed without further action, especially if it goes in a direction we
do not wish to go in.

Please do not start on a massive project (especially, new function), without 
discussing it with us first (via email or one of the discussion areas). This 
will save you the disappointment of seeing your hard work rejected because it 
doesn't fit in with what's going on with the rest of the PDF::Builder project. 
You are free to try contributing anything you want, or even to fork the project 
if you don't like the direction it's taking (that's how PDF::Builder split off 
from PDF::API2). Keeping in touch and coordinating with us ensures that your 
work won't be wasted. If you have something dependent on PDF::Builder 
functionality, but it doesn't fit our roadmap for core functionality, we may 
suggest that you release it as a separate package on CPAN (dependent on 
PDF::Builder), or as a new sub-package under PDF::Builder (e.g., like 
PDF::API2::Ladder), under either our ownership or yours.

## Contributing money instead of code

You may wish to see new features in PDF::Builder, but are not up to coding 
such. We have, from time to time, accepted payment to sponsor new features.
See INFO/SPONSORS for more information.

Good luck, and best wishes using and helping with PDF::Builder!

January, 2025
