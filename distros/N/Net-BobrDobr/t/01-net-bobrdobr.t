#! perl

use strict;
use Test::More;

BEGIN {
	our $file = -f "bobr-key" ? "bobr-key" : "../bobr-key";
	plan skip_all => "No bobrdobr api and/or secret keys available"
		unless (-f "bobr-key");
	use_ok('Net::BobrDobr')
};

my @act = qw(net-bobrdobr net-bobrdobr);

my $bd = new Net::BobrDobr ('api' => $file,'debug' => 0);
isa_ok ($bd,"Net::BobrDobr");

# ECHO
my $r0 = $bd->call ("test.echo",'test1' => "one",'test2' => "two");
ok ($r0->{'stat'} eq "ok","test.echo status");
ok ($r0->{'test1'} eq "one" && $r0->{'test2'} eq "two","test.echo answer");

my $con = $bd->connect ($act[0],$act[1]);
ok (defined $con,"connect");

# GETBOOKMARKS
my $r1 = $bd->call ("userpages.getBookmarks");
ok ($r1->{'stat'} eq "ok","userpages.getBookmarks status");
ok (scalar (keys %{$r1->{'bookmarklist'}->{'bookmark'}}) >= 2,"bookmarks");

# TAGS
my $r2 = $bd->call ("userpages.getTags");
ok ($r2->{'stat'} eq "ok","userpages.getBookmarks status");
ok (scalar (@{$r2->{'taglist'}->{'tag'}}) == 2,"tags");

# GROUPS
my $r3 = $bd->call ("userpages.getGroups");
ok ($r3->{'stat'} eq "ok","userpages.getGroups status");

# ADDBOOKMARK
my $r4 = $bd->call ("userpages.addBookmark",
		    'url' => "http://arto.homeunix.org",
		    'title' => "ARTO home",
		    'description' => "Test bookmark",
		    'tags' => "perl",
		    'private' => "true");
ok ($r4->{'stat'} eq "ok","userpages.addBookmark status");
ok ($r4->{'bookmarklist'}->{'bookmark'}->{'url'} eq "http://arto.homeunix.org",
   "userpages.addBookmark added");
my $id = $r4->{'bookmarklist'}->{'bookmark'}->{'id'};

# EDITBOOKMARK
my $r5 = $bd->call ("userpages.editBookmark",
		    'bookmark_id' => $id,
		    'title' => "ARTO home changed",
		    'tags' => "perl");
ok ($r5->{'stat'} eq "ok","userpages.addBookmark status");

my $r6 = $bd->call ("userpages.editBookmark",
		    'bookmark_id' => "2128506",
		    'title' => "ARTO home changed",
		    'tags' => "perl");
ok ($r6->{'stat'} eq "fail","userpages.addBookmark status fail");

# REMOVEBOOKMARK
my $r7 = $bd->call ("userpages.removeBookmark",
		    'bookmark_id' => $id);
ok ($r7->{'stat'} eq "ok","userpages.removeBookmark status");

my $r8 = $bd->call ("userpages.removeBookmark",
		    'bookmark_id' => "2128506");
ok ($r8->{'stat'} eq "fail","userpages.removeBookmark status fail");

exit;

### That's all, folks!
