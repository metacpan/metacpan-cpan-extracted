package SVN::Hooks::Notify;
# ABSTRACT: Subversion activity notification.
$SVN::Hooks::Notify::VERSION = '1.36';
use strict;
use warnings;

use SVN::Hooks;

use Exporter qw/import/;
my $HOOK = 'NOTIFY';
our @EXPORT = qw/NOTIFY_DEFAULTS NOTIFY/;


my %Defaults;

sub NOTIFY_DEFAULTS {
    %Defaults = @_;

    return 1;
}


my %Options;

sub NOTIFY {
    %Options = @_;

    POST_COMMIT(\&post_commit);

    return 1;
};

sub post_commit {
    my ($svnlook) = @_;

    require SVN::Notify;

    my $notifier = SVN::Notify->new(
	%Defaults,
	%Options,
	repos_path => $svnlook->repo(),
	revision   => $svnlook->rev(),
    );
    $notifier->prepare;
    $notifier->execute;
    return;
}

1; # End of SVN::Hooks::Notify

__END__

=pod

=encoding UTF-8

=head1 NAME

SVN::Hooks::Notify - Subversion activity notification.

=head1 VERSION

version 1.36

=head1 SYNOPSIS

This SVN::Hooks plugin sends notification emails for Subversion
repository activity. It is actually a simple wrapper around the
SVN::Notify module.

It's active in the C<post-commit> hook.

It's configured by the following directives.

=head2 NOTIFY_DEFAULTS(%HASH)

This directive allows you to specify default arguments for the
SVN::Notify constructor.

	NOTIFY_DEFAULTS(
	    user_domain => 'cpqd.com.br',
	    sendmail    => '/usr/sbin/sendmail',
	    language    => 'pt_BR',
	);
	NOTIFY_DEFAULTS(smtp => 'smtp.cpqd.com.br');

Please, see the SVN::Notify documentation to know about all the
available options.

=head2 NOTIFY(%HASH)

This directive merges the options received with the defaults obtained
from NOTIFY_DEFAULTS and passes the result to the SVN::Notify
constructor.

Note that neither the C<repos_path> nor the C<revision> options need
to be specified. They are grokked automatically.

	NOTIFY(
	    to        => 'commit-list@example.com',
            with_diff => 1,
	);

	NOTIFY(
	    to_email_map => {
                '^trunk/produtos|^branches' => 'commit-list@example.com',
                '^conf' => 'admin@example.com',
	    },
            subject_prefix => '[REPO] ',
            attach_diff  => 1,
	);

=for Pod::Coverage post_commit

=head1 AUTHOR

Gustavo L. de M. Chaves <gnustavo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by CPqD <www.cpqd.com.br>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
