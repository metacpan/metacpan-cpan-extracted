package SVN::Hooks::AllowLogChange;
# ABSTRACT: Allow changes in revision log messages.
$SVN::Hooks::AllowLogChange::VERSION = '1.34';
use strict;
use warnings;

use Carp;
use Data::Util qw(:check);
use SVN::Hooks;

use Exporter qw/import/;
my $HOOK = 'ALLOW_LOG_CHANGE';
our @EXPORT = ($HOOK);


my @Valid_Users;

sub ALLOW_LOG_CHANGE {
    my @args = @_;

    foreach my $who (@args) {
	if (is_string($who) || is_rx($who)) {
	    push @Valid_Users, $who;
	} else {
	    croak "$HOOK: invalid argument '$who'\n";
	}
    }

    PRE_REVPROP_CHANGE(\&pre_revprop_change);

    return 1;
}

sub pre_revprop_change {
    my ($svnlook, $rev, $author, $propname, $action) = @_;

    $propname eq 'svn:log'
	or croak "$HOOK: the revision property $propname cannot be changed.\n";

    $action eq 'M'
	or croak "$HOOK: a revision log can only be modified, not added or deleted.\n";

    # If no users are specified, anyone can do it.
    return unless @Valid_Users;

    for my $user (@Valid_Users) {
	return if is_string($user) && $author eq $user || $author =~ $user;
    }

    croak "$HOOK: you are not allowed to change a revision log.\n";
}

1; # End of SVN::Hooks::AllowLogChange

__END__

=pod

=encoding UTF-8

=head1 NAME

SVN::Hooks::AllowLogChange - Allow changes in revision log messages.

=head1 VERSION

version 1.34

=head1 SYNOPSIS

This SVN::Hooks plugin is used to allow revision log changes by some
users.

It's deprecated. You should use SVN::Hooks::AllowPropChange instead.

It's active in the C<pre-revprop-change> hook.

It's configured by the following directive.

=head2 ALLOW_LOG_CHANGE(WHO, ...)

This directive enables the change of revision log messages, which are
maintained in the C<svn:log> revision property.

The optional WHO argument specifies the users that are allowed to make
those changes. If absent, any user can change a log
message. Otherwise, it specifies the allowed users depending on its
type.

=over

=item STRING

Specify a single user by name.

=item REGEXP

Specify the class of users whose names are matched by the
Regexp.

=back

	ALLOW_LOG_CHANGE();
	ALLOW_LOG_CHANGE('jsilva');
	ALLOW_LOG_CHANGE(qr/silva$/);

=for Pod::Coverage pre_revprop_change

=head1 AUTHOR

Gustavo L. de M. Chaves <gnustavo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by CPqD <www.cpqd.com.br>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
