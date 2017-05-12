package SVN::Hooks::DenyChanges;
# ABSTRACT: Deny some changes in a repository.
$SVN::Hooks::DenyChanges::VERSION = '1.34';
use strict;
use warnings;

use Carp;
use Data::Util qw(:check);
use SVN::Hooks;

use Exporter qw/import/;
my $HOOK = 'DENY_CHANGES';
our @EXPORT = ('DENY_ADDITION', 'DENY_DELETION', 'DENY_UPDATE', 'DENY_EXCEPT_USERS');


my %Deny;			# List of deny regexen
my %Except;			# Users exempt from the checks

sub _deny_change {
    my ($change, @regexes) = @_;

    foreach (@regexes) {
	is_rx($_) or croak "$HOOK: all arguments must be qr/Regexp/\n";
    }

    push @{$Deny{$change}}, @regexes;

    PRE_COMMIT(\&pre_commit);

    return 1;
}

sub DENY_ADDITION {
    my @args = @_;
    return _deny_change(add    => @args);
}

sub DENY_DELETION {
    my @args = @_;
    return _deny_change(delete => @args);
}

sub DENY_UPDATE {
    my @args = @_;
    return _deny_change(update => @args);
}

sub DENY_EXCEPT_USERS {
    my @users = @_;

    foreach my $user (@users) {
	is_string($user) or croak "DENY_EXCEPT_USERS: all arguments must be strings\n";
	$Except{$user} = undef;
    }

    return 1;
}

sub pre_commit {
    my ($svnlook) = @_;

    # Except users
    return if exists $Except{$svnlook->author()};

    my @errors;

    foreach my $regex (@{$Deny{add}}) {
      ADDED:
	foreach my $file ($svnlook->added()) {
	    if ($file =~ $regex) {
		push @errors, " Cannot add: $file";
		next ADDED;
	    }
	}
    }

    foreach my $regex (@{$Deny{delete}}) {
      DELETED:
	foreach my $file ($svnlook->deleted()) {
	    if ($file =~ $regex) {
		push @errors, " Cannot delete: $file";
		next DELETED;
	    }
	}
    }

    foreach my $regex (@{$Deny{update}}) {
      UPDATED:
	foreach my $file ($svnlook->updated()) {
	    if ($file =~ $regex) {
		push @errors, " Cannot update: $file";
		next UPDATED;
	    }
	}
    }

    croak "$HOOK:\n", join("\n", @errors), "\n"
	if @errors;

    return;
}

1; # End of SVN::Hooks::CheckMimeTypes

__END__

=pod

=encoding UTF-8

=head1 NAME

SVN::Hooks::DenyChanges - Deny some changes in a repository.

=head1 VERSION

version 1.34

=head1 SYNOPSIS

This SVN::Hooks plugin is used to disallow the addition, deletion, or
modification of parts of the repository structure.

It's active in the C<pre-commit> hook.

It's configured by the following directives.

=head2 DENY_ADDITION(REGEXP, ...)

This directive denies the addition of new files matching the Regexps
passed as arguments.

	DENY_ADDITION(qr/\.(doc|xls|ppt)$/); # ODF only, please

=head2 DENY_DELETION(REGEXP, ...)

This directive denies the deletion of files matching the Regexps
passed as arguments.

	DENY_DELETION(qr/contract/); # Can't delete contracts

=head2 DENY_UPDATE(REGEXP, ...)

This directive denies the modification of files matching the Regexps
passed as arguments.

	DENY_UPDATE(qr/^tags/); # Can't modify tags

=head2 DENY_EXCEPT_USERS(LIST)

This directive receives a list of user names which are to be exempt
from the rules specified by the other directives.

	DENY_EXCEPT_USERS(qw/john mary/);

This rule exempts users C<john> and C<mary> from the other deny rules.

=for Pod::Coverage pre_commit

=head1 AUTHOR

Gustavo L. de M. Chaves <gnustavo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by CPqD <www.cpqd.com.br>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
