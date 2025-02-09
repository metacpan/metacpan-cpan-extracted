# String-Equivalence-Amharic
Normalization Utilities for Amharic

Special Note
------------
This package was previously named "String::Amharic::Downgrade" and packaged
in a String-Downgrade-0.03.tar.gz archive up until version 0.03 after which
time the module was renamed String::Equivalence::Amharic.

Overview
--------
Under the "three levels of Amharic spelling" theory, this package will
take a canonical word (level 1) and generate level two words (the level
of popular use).  Hence "pencanonical", though think spherically and the
"pen" part of it spans the breadth of level two.  Its a little easier to
think of a simple "downgrade" vs debating the width of "pen".

The package is useful for some problems, it will produce orthographically
"legal" simplification and avoids improbable naive simplifications.
Text::Metaphone::Amharic of course over simplifies as it addresses a
different problem.  So while not to promote level 2 orthographies, for some
instances it is useful to generate level 2 renderings given a canonical
form.  The package is intended to be a labor saving device and is by no
means perfect.

You *must* start with the canonical spelling of a word as only downgrades
can occur.  Starting with a near canonical form and downgrading will generate
a shorter word list than you would have starting from the top.

TODO:
----
* Better handle old amharic
