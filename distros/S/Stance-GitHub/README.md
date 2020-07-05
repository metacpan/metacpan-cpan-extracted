Stance::GitHub - A Perl Interface to GitHub
===========================================

This code is part of **The Stance Project**, an attempt to build a
small toolkit of modern API clients for rapidly building
proof-of-concept application ideas, using Perl.

This library in particular provides access to the GitHub API,
either for github.com, or on-premise GitHub Enterprise.

Usage
-----

This is an object-oriented library; you create a GitHub object:

    use Stance::GitHub;

    my $github = Stance::GitHub->new();

Then, you'll need to authenticate.  Currently, only _personal
access tokens_ are supported, but I'll be adding support for
OAuth2 flows soon.

    $github->authenticate(token => $ENV{GITHUB_TOKEN});

After that, you can recurse through organizations into
repositories, and finally to issues (which include pull requests):

    for my $org ($github->orgs) {
      for my $repo ($org->repos) {

        print "$org->{login} / $repo->{name}:\n";
        for my $issue ($repo->issues) {
          printf "%- 5s  %-30.30s  %-10.10s  [%s]\n",
            $issue->{number},
            $issue->{title},
            $issue->{user}{login},
            $issue->{updated_at};
        }
        print "\n";
      }
    }

Remember, [GitHub limits requests][limits], even authenticated
ones!

Contributing
------------

This code is licensed MIT.  Enjoy.

If you find a bug, please raise a [GitHub Issue][issues] first,
before submitting a PR.

Happy Hacking!

[issues]: https://github.com/jhunt/perl-Stance-GitHub/issues
[limits]: https://developer.github.com/v3/#rate-limiting
