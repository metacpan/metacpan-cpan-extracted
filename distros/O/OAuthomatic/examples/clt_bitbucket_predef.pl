#!/usr/bin/perl -w
use strict;
use warnings;
use utf8;
use Const::Fast;
use Try::Tiny;
use OAuthomatic;

# Will create, modify then delete repo with this slug.

#   Name with - to stick with what 1.0 may do from name
#   (testing exact bitbucket quorks on PUT is not main job here...)
const my $TEST_REPO_SLUG => "oauthomatic-test-repo";
const my $TEST_REPO_NAME => "OAuthomatic Test Repo";


=head1 auth_to_bitbucket_predef

This is similar to auth_to_bitbucket_explicit.pl, but uses predefined
server settings from L<OAuthomatic::ServerDef::BitBucket> and performs
a few active operations.

The script behaves differently depending on situation (creates testing
repo if it was missing, updates it if it exists in initial form,
deletes if it exists in edited form). Run 3 times (and check out
effects on the web interface in the meantime).

=cut

print "*** Setting up OAuthomatic\n";

my $oauthomatic = OAuthomatic->new(
    app_name => "OAuthomatic demo",
    password_group => "OAuthomatic ad-hoc keys (private)",

    server => 'BitBucket',   # Look up def from OAuthomatic::ServerDef::BitBucket

    # browser => "firefox",
    # debug => 1,
   );

# Initiates OAuth-authorized communication. Not necessary
# (will be executed by first call if skipped), but let's be explicit.
$oauthomatic->ensure_authorized();

print "    Object ready to execute calls\n";

###########################################################################

print "\n*** GET current user info\n";

my $reply = $oauthomatic->get_json(
    'https://bitbucket.org/api/2.0/user');

print "    username:     ", $reply->{username}, "\n";
print "    display_name: ", $reply->{display_name}, "\n";
print "    type:         ", $reply->{type}, "\n";
print "    uuid:         ", $reply->{uuid}, "\n";
print "    website:      ", $reply->{website}, "\n";
my $links = $reply->{links};
if($links) {
    foreach my $link_name (sort keys %$links) {
        print "    links/$link_name: ", $links->{$link_name}->{href}, "\n";
    }
}

my $user_name = $reply->{username};
my $user_uuid = $reply->{uuid};  

# Theoretically using uuid should bring consistency. In practice, it fails
# on some calls and brings unexpected behaviours on other...

my $repo;

###########################################################################

print "\n*** GET test repository info (with error handling)\n";

try {
    $repo = $oauthomatic->get_json(
        "https://api.bitbucket.org/2.0/repositories/$user_name/$TEST_REPO_SLUG");

    print "Exists:\n";
    print "    name:        ", $repo->{name}, "\n";
    print "    scm:         ", $repo->{scm}, "\n";
    print "    language:    ", $repo->{language}, "\n";
    print "    is_private:  ", $repo->{is_private}, "\n";
    print "    description:  ", $repo->{description}, "\n";
} catch {
    my $error = $_;
    if($error->isa("OAuthomatic::Error::HTTPFailure")) {
        if($error->code == 404) {
            print "Repo does not exist (likely normal thing)\n\n";
            print "For the sake of interest, error details:\n",
              $error, "\n";
        } else {
            $error->throw;
        }
    } else {
        die "Unexpected error: $error\n"
    }
};
  
###########################################################################

unless($repo) {

    print "\n*** POST to create test repository\n";

    # https://confluence.atlassian.com/display/BITBUCKET/repository+Resource
    # For some reason post-ing by user_id crashes.
    my $repo = $oauthomatic->post_json(
        "https://api.bitbucket.org/2.0/repositories/$user_name/$TEST_REPO_SLUG",
        # "https://api.bitbucket.org/2.0/repositories/$user_uuid/$TEST_REPO_SLUG",
        {
            "scm" => "hg", 
            "name" => $TEST_REPO_NAME,
            "is_private" => "true",
            "description" => "This is created to test BitBucket client I am writing.\nZażółć gęślą jaźń",
            "fork_policy" => "no_public_forks",
            "language" => "perl",
            # "has_issues" => "false",
            # "has_wiki" => "false",
        });

    print "Created:\n";
    print "    name:        ", $repo->{name}, "\n";
    print "    scm:         ", $repo->{scm}, "\n";
    print "    language:    ", $repo->{language}, "\n";
    print "    is_private:  ", $repo->{is_private}, "\n";
    print "    description:  ", $repo->{description}, "\n";

}
elsif($repo->{description} !~ /THIS WAS EDITED/) {

    # Not yet in 2.0. In 1.0 we post update:
    # https://confluence.atlassian.com/display/BITBUCKET/repository+Resource+1.0#repositoryResource1.0-PUTarepositoryupdate

    print "\n*** PUT update on test repository\n";
    
    my $description = $repo->{description} . ' THIS WAS EDITED';

    $repo = $oauthomatic->put_json(
        "https://bitbucket.org/api/1.0/repositories/$user_name/$TEST_REPO_SLUG",
        {
            # accountname => $user_name,
            # repo_slug => $TEST_REPO_SLUG,
            # name => $repo->{name},
            language => $repo->{language},
            description => $description,
        });

    print "Modified:\n";
    print "    name:        ", $repo->{name}, "\n";
    print "    scm:         ", $repo->{scm}, "\n";
    print "    language:    ", $repo->{language}, "\n";
    print "    is_private:  ", $repo->{is_private}, "\n";
    print "    description:  ", $repo->{description}, "\n";
}
else {

    print "\n*** DELETE test repository\n";

    my $reply = $oauthomatic->delete_(
        "https://api.bitbucket.org/2.0/repositories/$user_name/$TEST_REPO_SLUG");

    print "Deleted:\n";
    print $reply;
}

###########################################################################

print "\n*** get_repository\n";

$repo = $oauthomatic->get_json(
   "https://api.bitbucket.org/2.0/repositories/$user_name/$TEST_REPO_SLUG");

print "Exists:\n";
print "    name:        ", $repo->{name}, "\n";
print "    scm:         ", $repo->{scm}, "\n";
print "    language:    ", $repo->{language}, "\n";
print "    is_private:  ", $repo->{is_private}, "\n";
print "    description:  ", $repo->{description}, "\n";

###########################################################################


