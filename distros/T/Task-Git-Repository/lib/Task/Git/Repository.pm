package Task::Git::Repository;
$Task::Git::Repository::VERSION = '1.003';
use strict;
use warnings;

1;

__END__

=head1 NAME

Task::Git::Repository - Install all Git::Repository plugins at once

=head1 VERSION

version 1.003

=head1 SYNOPSIS

    cpan Task::Git::Repository

    cpanp -i Task::Git::Repository

    cpanm Task::Git::Repository

=head1 DESCRIPTION

L<Git::Repository> is a Git wrapper for Perl with a deliberately very
simple interface of only two main methods. The details of the Git commands
to be run are defined in the parameters to these methods.

Being so simple, L<Git::Repository> lacks a lot of methods that of its
users might find desirable. This is where L<Git::Repository::Plugin>
comes into play. It allows one to consume plugins (some would say I<Roles>)
to extend its capabilities.

=head1 CONTENTS

L<Git::Repository> - Perl interface to Git repositories

L<Git::Repository::Plugin::AUTOLOAD> - Git subcommands as L<Git::Repository> methods

L<Git::Repository::Plugin::Blame> - Add a blame() method to L<Git::Repository>

L<Git::Repository::Plugin::Dirty> - methods to inspect the dirtiness of a git repository

L<Git::Repository::Plugin::FileHistory> - Class representing file on git repository

L<Git::Repository::Plugin::Gerrit> - Add some integration with Gerrit

L<Git::Repository::Plugin::GitHooks> - A Git::Repository plugin with some goodies for hook developers

L<Git::Repository::Plugin::Hooks> - Work with hooks in a L<Git::Repository>

L<Git::Repository::Plugin::Info> - Information about a L<Git::Repository>

L<Git::Repository::Plugin::Log> - Add a log() method to Git::Repository

L<Git::Repository::Plugin::Status> - Show the working tree status

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Task-Git-Repository or by email to
bug-task-git-repository@rt.cpan.org.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Philippe Bruhat (BooK) <book@cpan.org>

=head1 COPYRIGHT

Copyright 2014-2018 Philippe Bruhat (BooK), All Rights Reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
