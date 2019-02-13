

# Contributing to perl-net-sharepoint-basic

The perl-net-sharepoint-basic project team welcomes contributions from the community. If you wish to contribute code and you have not
signed our contributor license agreement (CLA), our bot will update the issue when you open a Pull Request. For any
questions about the CLA process, please refer to our [FAQ](https://cla.vmware.com/faq).

## Community

## Getting Started

You'll need a Perl installation with required modules and a SharePoint site credentials set to work against.

## Contribution Flow

This is a rough outline of what a contributor's workflow looks like:

- Create a topic branch from where you want to base your work
- Make commits of logical units
- Make sure your commit messages are in the proper format (see below)
- Push your changes to a topic branch in your fork of the repository
- Submit a pull request

Example:

``` shell
git remote add upstream https://github.com/vmware/perl-net-sharepoint-basic.git
git checkout -b my-new-feature master
git commit -a
git push origin my-new-feature
```

### Staying In Sync With Upstream

When your branch gets out of sync with the vmware/master branch, use the following to update:

``` shell
git checkout my-new-feature
git fetch -a
git pull --rebase upstream master
git push --force-with-lease origin my-new-feature
```

### Updating pull requests

If your PR fails to pass CI or needs changes based on code review, you'll most likely want to squash these changes into
existing commits.

If your pull request contains a single commit or your changes are related to the most recent commit, you can simply
amend the commit.

``` shell
git add .
git commit --amend
git push --force-with-lease origin my-new-feature
```

If you need to squash changes into an earlier commit, you can use:

``` shell
git add .
git commit --fixup <commit>
git rebase -i --autosquash master
git push --force-with-lease origin my-new-feature
```

Be sure to add a comment to the PR indicating your new changes are ready to review, as GitHub does not generate a
notification when you git push.

### Code Style

This code uses hard tabs.
This code uses snake_case for variable and function names, and ALL CAPS for constants, similar to other Perl modules.
A subroutine shall not exceed sixty lines including the inline documentation.

Each test file name must be prefixed with two digits followed by a dash:
* 0?- utility function tests
* 1?- basic object tests
* 2?- basic SharePoint interaction tests
* 3?- SharePoint operations tests

### Formatting Commit Messages

We follow the conventions on [How to Write a Git Commit Message](http://chris.beams.io/posts/git-commit/).

Be sure to include any related GitHub issue references in the commit message.  See
[GFM syntax](https://guides.github.com/features/mastering-markdown/#GitHub-flavored-markdown) for referencing issues
and commits.

## Reporting Bugs and Creating Issues

When opening a new issue, try to roughly follow the commit message format conventions above. The bugs should be filled via the request tracker of CPAN:
    http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-SharePoint-Basic

## Repository Structure

The perl library code is under lib/ following the Perl Module convention setup.
The tests (and the configurations fot the tests) are under t/ . 
The executables are in the scripts/ library. For each new executable, an entry needs to be added to Build.PL .

