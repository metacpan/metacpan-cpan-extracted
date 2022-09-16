package SVN::Hooks::Generic;
# ABSTRACT: Implement generic checks for all Subversion hooks.
$SVN::Hooks::Generic::VERSION = '1.36';
use strict;
use warnings;

use Carp;
use Data::Util qw(:check);
use SVN::Hooks;

use Exporter qw/import/;
my $HOOK = 'GENERIC';
our @EXPORT = ($HOOK);


sub GENERIC {
    my (@args) = @_;

    (@args % 2) == 0
	or croak "$HOOK: odd number of arguments.\n";

    my %args = @args;

    while (my ($hook, $functions) = each %args) {
	$hook =~ /(?:(?:pre|post)-(?:commit|lock|revprop-change|unlock)|start-commit)/
	    or die "$HOOK: invalid hook name ($hook)";
	if (is_code_ref($functions)) {
	    $functions = [$functions];
	} elsif (! is_array_ref($functions)) {
	    die "$HOOK: hook '$hook' should be mapped to a CODE-ref or to an ARRAY-ref.\n";
	}
	foreach my $foo (@$functions) {
	    is_code_ref($foo) or die "$HOOK: hook '$hook' should be mapped to CODE-refs.\n";
            unless (exists $SVN::Hooks::Hooks{$hook}{set}{$foo}) {
                push @{$SVN::Hooks::Hooks{$hook}{list}},
                    ($SVN::Hooks::Hooks{$hook}{set}{$foo} = sub { $foo->(@_); });
            }
	}
    }

    return 1;
}

1; # End of SVN::Hooks::Generic

__END__

=pod

=encoding UTF-8

=head1 NAME

SVN::Hooks::Generic - Implement generic checks for all Subversion hooks.

=head1 VERSION

version 1.36

=head1 SYNOPSIS

This SVN::Hooks plugin allows you to easily write generic checks for
all Subversion standard hooks. It's deprecated. You should use the
SVN::Hooks hook defining exported directives instead.

This module is configured by the following directive.

=head2 GENERIC(HOOK => FUNCTION, HOOK => [FUNCTIONS], ...)

This directive associates FUNCTION with a specific HOOK. You can make
more than one association with a single directive call, or you can use
multiple calls to make multiple associations. Moreover, you can
associate a hook with a single function or with a list of functions
(passing them as elements of an array). All functions associated with
a hook will be called in an unspecified order with the same arguments.

Each hook must be associated with functions with a specific signature,
i.e., the arguments that are passed to the function depends on the
hook to which it is associated.

The hooks are specified by their standard names.

The function signatures are the following:

=over

=item post-commit(SVN::Look)

=item post-lock(repos-path, username)

=item post-revprop-change(SVN::Look, username, property-name, action)

=item post-unlock(repos-path, username)

=item pre-commit(SVN::Look)

=item pre-lock(repos-path, path, username, comment, steal-lock-flag)

=item pre-revprop-change(SVN::Look, username, property-name, action)

=item pre-unlock(repos-path, path, username, lock-token, break-unlock-flag)

=item start-commit(repos-path, username, capabilities, txt-name)

=back

The functions may perform whatever checks they want. If the checks
succeed the function must simply return. Otherwise, they must die with
a suitable error message, which will be sent back to the user
performing the Subversion action which triggered the hook.

The sketch below shows how this directive could be used.

	sub my_start_commit {
	    my ($repo_path, $username, $capabilities, $txt_name) = @_;
	    # ...
	}

	sub my_pre_commit {
	    my ($svnlook) = @_;
	    # ...
	}

	GENERIC(
	    'start-commit' => \&my_start_commit,
	    'pre-commit'   => \&my_pre_commit,
	);

=head1 AUTHOR

Gustavo L. de M. Chaves <gnustavo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by CPqD <www.cpqd.com.br>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
