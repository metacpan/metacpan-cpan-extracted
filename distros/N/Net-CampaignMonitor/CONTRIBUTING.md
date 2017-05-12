# Guidelines for contributing

1. [Fork the repository](https://help.github.com/articles/fork-a-repo).
2. [Create a topic branch](http://learn.github.com/p/branching.html).
3. Make your changes, including tests for your changes.
4. Ensure that all tests pass, by running:

    ```
    export CAMPAIGN_MONITOR_API_KEY={Your API key to use for running the tests}
    export CAMPAIGN_MONITOR_ACCESS_TOKEN={Your OAuth access token for running the tests}
    export CAMPAIGN_MONITOR_REFRESH_TOKEN={Your OAuth refresh token for running the tests}
    cpanm --quiet --installdeps --notest .
    perl Makefile.PL && make test
    ```

    The [Travis CI build](https://travis-ci.org/campaignmonitor/createsend-perl) runs on Perl `5.10`, `5.12`, `5.14`, and `5.16`.

5. It should go without saying, but do not increment the version number in your commits.
6. [Submit a pull request](https://help.github.com/articles/using-pull-requests).
