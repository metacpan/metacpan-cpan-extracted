#!/usr/local/bin/perl
use News::Collabra(make_new_newsgroup);
print make_new_newsgroup('junk.deletethree', 'Delete me three', 'Another test group');
