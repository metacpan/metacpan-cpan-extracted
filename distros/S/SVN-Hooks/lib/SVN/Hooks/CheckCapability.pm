package SVN::Hooks::CheckCapability;
# ABSTRACT: Check the svn client capabilities.
$SVN::Hooks::CheckCapability::VERSION = '1.35';
use strict;
use warnings;

use Carp;
use SVN::Hooks;

use Exporter qw/import/;
my $HOOK = 'CHECK_CAPABILITY';
our @EXPORT = ($HOOK);


my @Capabilities;

sub CHECK_CAPABILITY {
    push @Capabilities, @_;

    START_COMMIT(\&start_commit);

    return 1;
}

sub start_commit {
    my ($repo_path, $user, $capabilities, $txt_name) = @_;

    $capabilities ||= ''; # pre 1.5 svn clients don't pass the capabilities

    # Create a hash to facilitate the checks
    my %supported;
    @supported{split /:/, $capabilities} = undef;

    # Grok which required capabilities are missing
    my @missing = grep {! exists $supported{$_}} @Capabilities;

    if (@missing) {
	croak "$HOOK: Your subversion client does not support the following capabilities:\n\n\t",
	    join(', ', @missing),
	    "\n\nPlease, consider upgrading to a newer version of your client.\n";
    }
}

1; # End of SVN::Hooks::CheckCapability

__END__

=pod

=encoding UTF-8

=head1 NAME

SVN::Hooks::CheckCapability - Check the svn client capabilities.

=head1 VERSION

version 1.35

=head1 SYNOPSIS

This SVN::Hooks plugin checks if the Subversion client implements the
required capabilities.

It's active in the C<start-commit> hook.

It's configured by the following directive.

=head2 CHECK_CAPABILITY(CAPABILITY...)

This directive enables the checking, causing the commit to abort if it
doesn't comply.

The arguments are a list of capability names. Every capability
specified must be supported by the client in order to the hook to
succeed.

Example:

	CHECK_CAPABILITY('mergeinfo');

=for Pod::Coverage start_commit

=head1 AUTHOR

Gustavo L. de M. Chaves <gnustavo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by CPqD <www.cpqd.com.br>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
