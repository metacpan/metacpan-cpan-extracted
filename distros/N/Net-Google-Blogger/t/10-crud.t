use strict;
use warnings;

use Test::More;
use Test::Deep;

use Net::Google::Blogger;


sub entry_props_set_ok {
    ## Verifies that entry properties match values in given hash.
    my ($entry, $props, $msg) = @_;

    foreach (keys %$props) {
        my @vals = ( scalar $entry->$_(), $props->{$_} );
        my $func = $_ eq 'categories' ? 'cmp_bag' : 'is';

        no strict 'refs';
        &$func(@vals, "\"$_\" property saved correctly $msg");
    }
}

# Only run network tests if Blogger access credentials are specified in the environment.
plan(
    $ENV{TEST_BLOGGER_LOGIN_ID} ?
        ( tests => 16 ) :
        ( skip_all => 'To run live tests, set TEST_BLOGGER_LOGIN_ID, TEST_BLOGGER_PASSWORD and TEST_BLOGGER_BLOG_ID environment variables to identify test Blogger account and blog.')
);

# Authenticate.
my $blogger = Net::Google::Blogger->new(
    login_id   => $ENV{TEST_BLOGGER_LOGIN_ID},
    password   => $ENV{TEST_BLOGGER_PASSWORD},
);
ok($blogger, 'Authenticated');

# Retrieve all blogs.
my @blogs = $blogger->blogs;
ok(@blogs > 0, 'Blogs retrieved');

# Retrieved entries from test blog.
my ($blog) = grep $_->numeric_id == $ENV{TEST_BLOGGER_BLOG_ID}, @blogs;
my ($entry) = $blog->entries;
ok($entry, 'Entry retrieved');

# Create new entry.
my %new_entry_props = (
    title      => 'New entry',
    content    => 'New entry content',
    categories => [ 'Cats', 'aren\'t always', 'black' ],
);
my $new_entry = Net::Google::Blogger::Blog::Entry->new(%new_entry_props, blog => $blog);
is(ref $new_entry, 'Net::Google::Blogger::Blog::Entry', 'Instantiated new entry');

# Save new entry.
my $save_response = $new_entry->save;
ok($new_entry->id, 'Saved new entry');
entry_props_set_ok($new_entry, \%new_entry_props, 'on creation');

# Update the entry.
my %updated_entry_props = (
    title      => 'Updated entry',
    content    => 'Updated entry content',
    categories => [ "$new_entry", 'Some', 'black' ],
);
$new_entry->$_($updated_entry_props{$_}) foreach keys %updated_entry_props;
$new_entry->save;
entry_props_set_ok($new_entry, \%updated_entry_props, 'on update');

# Search by category (match.)
my ($found_entry) = $blog->search_entries(categories => [ @{ $updated_entry_props{categories} }[0,2] ]);
is(ref $found_entry, 'Net::Google::Blogger::Blog::Entry', 'Entry found');
is($found_entry->id, $new_entry->id, 'Entry found correctly');

# Search by category (no match.)
my ($not_found_entry) = $blog->search_entries(categories => [ '##__ABSOLUTELY_IMPOSSIBLE_CATEGORY__##' ]);
ok(!$not_found_entry, 'Entry not found');

# Delete entry.
my $new_entry_url = $new_entry->public_url;
$new_entry->delete;
is($blogger->http_get($new_entry_url)->code, 404, 'Entry deleted from server');
my ($deleted_entry) = grep $_->id eq $new_entry->id, $blog->entries;
ok(!$deleted_entry, 'Entry deleted from blog list');
