package SVN::Hooks::CheckStructure;
# ABSTRACT: Check the structure of a repository.
$SVN::Hooks::CheckStructure::VERSION = '1.34';
use strict;
use warnings;

use Carp;
use Data::Util qw(:check);
use SVN::Hooks;

use Exporter qw/import/;
my $HOOK = 'CHECK_STRUCTURE';
our @EXPORT = ($HOOK, 'check_structure');


my $Structure;

sub CHECK_STRUCTURE {
    ($Structure) = @_;

    PRE_COMMIT(\&pre_commit);

    return 1;
}

sub _check_structure {
    my ($structure, $path) = @_;

    @$path > 0 or croak "Can't happen!";

    if (is_string($structure)) {
	if ($structure eq 'DIR') {
	    return (1) if @$path > 1;
	    return (0, "the component ($path->[0]) should be a DIR in");
	} elsif ($structure eq 'FILE') {
	    return (0, "the component ($path->[0]) should be a FILE in") if @$path > 1;
	    return (1);
	} elsif (is_integer($structure)) {
	    return (1) if $structure;
	    return (0, "invalid path");
	} else {
	    return (0, "syntax error: unknown string spec ($structure), while checking");
	}
    } elsif (is_array_ref($structure)) {
	return (0, "syntax error: odd number of elements in the structure spec, while checking")
	    unless scalar(@$structure) % 2 == 0;
	return (0, "the component ($path->[0]) should be a DIR in")
	    unless @$path > 1;
	shift @$path;
	# Return ok if the directory doesn't have subcomponents.
	return (1) if @$path == 1 && length($path->[0]) == 0;

	for (my $s=0; $s<$#$structure; $s+=2) {
	    my ($lhs, $rhs) = @{$structure}[$s, $s+1];
	    if (is_string($lhs)) {
		if ($lhs eq $path->[0]) {
		    return _check_structure($rhs, $path);
		} elsif (is_integer($lhs)) {
		    if ($lhs) {
			return _check_structure($rhs, $path);
		    } elsif (is_string($rhs)) {
			return (0, "$rhs, while checking");
		    } else {
			return (0, "syntax error: the right hand side of a number must be string, while checking");
		    }
		}
	    } elsif (is_rx($lhs)) {
		if ($path->[0] =~ $lhs) {
		    return _check_structure($rhs, $path);
		}
	    } else {
		my $what = ref $lhs;
		return (0, "syntax error: the left hand side of arrays in the structure spec must be scalars or qr/Regexes/, not $what, while checking");
	    }
	}
	return (0, "the component ($path->[0]) is not allowed in");
    } else {
	my $what = ref $structure;
	return (0, "syntax error: invalid reference to a $what in the structure spec, while checking");
    }
}


sub check_structure {
    my ($structure, $path) = @_;
    $path = "/$path" unless $path =~ m@^/@; # make sure it's an absolute path
    my @path = split '/', $path, -1; # preserve trailing empty components
    my ($code, $error) = _check_structure($structure, \@path);
    croak "$error: $path\n" if $code == 0;
    return 1;
}

sub pre_commit {
    my ($svnlook) = @_;

    my @errors;

    foreach my $added ($svnlook->added()) {
	# Split the $added path in its components. We prefix $added
	# with a slash to make it look like an absolute path for
	# _check_structure. The '-1' is to preserve trailing empty
	# components so that we can differentiate directory paths from
	# file paths.
	my @added = split '/', "/$added", -1;
	my ($code, $error) = _check_structure($Structure, \@added);
	push @errors, "$error: $added" if $code == 0;
    }

    croak join("\n", "$HOOK:", @errors), "\n"
	if @errors;

    return;
}

1; # End of SVN::Hooks::CheckStructure

__END__

=pod

=encoding UTF-8

=head1 NAME

SVN::Hooks::CheckStructure - Check the structure of a repository.

=head1 VERSION

version 1.34

=head1 SYNOPSIS

This SVN::Hooks plugin checks if the files and directories added to
the repository are allowed by its structure definition. If they don't,
the commit is aborted.

It's active in the C<pre-commit> hook.

It's configured by the following directive.

=head2 CHECK_STRUCTURE(STRUCT_DEF)

This directive enables the checking, causing the commit to abort if it
doesn't comply.

The STRUCT_DEF argument specify the repository strucure with a
recursive data structure consisting of one of:

=over

=item ARRAY REF

An array ref specifies the contents of a directory. The referenced
array must contain a pair number of elements. Each pair consists of a
NAME_DEF and a STRUCT_DEF. The NAME_DEF specifies the name of the
component contained in the directory and the STRUCT_DEF specifies
recursively what it must be.

The NAME_DEF specifies a name in one of these ways:

=over

=item STRING

A string specifies a name directly.

=item REGEXP

A regexp specifies the class of names that match it.

=item NUMBER

A number may be used as an else-clause. A non-zero number means that
any name not yet matched by the previous pair must conform to the
associated STRUCT_DEF.

A zero means that no name will do and signals an error. In this case,
if the STRUCT_DEF is a string it is used as a help message shown to
the user.

=back

If no NAME_DEF matches the component being looked for, then it is a
structure violation and the commit fails.

=item STRING

A string must be one of 'FILE' and 'DIR', specifying what the current
component must be.

=item NUMBER

A non-zero number simply tells that whatever the current component is
is ok and finishes the check successfully.

A zero tells that whatever the current component is is a structure
violation and aborts the commit.

=back

Now that we have this semi-formal definition off the way, let's try to
understand it with some examples.

	my $tag_rx    = qr/^[a-z]+-\d+\.\d+$/; # e.g. project-1.0
	my $branch_rx = qr/^[a-z]+-/;	# must start with letters and hifen
	my $project_struct = [
	    'META.yml'    => 'FILE',
	    'Makefile.PL' => 'FILE',
	    ChangeLog     => 'FILE',
	    LICENSE       => 'FILE',
	    MANIFEST      => 'FILE',
	    README        => 'FILE',
	    t => [
		qr/\.t$/  => 'FILE',
	    ],
	    lib => 'DIR',
	];

	CHECK_STRUCTURE(
	    [
		trunk => $project_struct,
		branches => [
		    $branch_rx => $project_rx,
		],
		tags => [
		    $tag_rx => $project_rx,
		],
	    ],
	);

The structure's first level consists of the three usual directories:
C<trunk>, C<tags>, and C<branches>. Anything else in this level is
denied.

Below the C<trunk> we allow some usual files and two directories only:
C<lib> and C<t>. Below C<trunk/t> we may allow only test files with
the C<.t> extension and below C<lib> we allow anything.

We require that each branch and tag have the same structure as the
C<trunk>, which is made easier by the use of the C<$project_struct>
variable. Moreover, we impose some restrictions on the names of the
tags and the branches.

=for Pod::Coverage pre_commit

=head1 EXPORT

=head2 check_structure(STRUCT_DEF, PATH)

SVN::Hooks::CheckStructure exports a function to allow for the
verification of path structures outside the context of a Subversion
hook. (It would probably be better to take this function to its own
module and use that module here. We'll take care of that eventually.)

The function check_structure takes two arguments. The first is a
STRUCT_DEF exactly the same as specified for the CHECK_STRUCTURE
directive above. The second is a PATH to a file which will be checked
against the STRUCT_DEF.

The function returns true if the check succeeds and dies with a proper
message otherwise.

The function is intended to check paths as they're shown by the 'svn
ls' command, i.e., with no leading slashes and with a trailing slash
to indicate directories. The leading slash is assumed if it's missing,
but the trailing slash is needed to indicate directories.

=head1 AUTHOR

Gustavo L. de M. Chaves <gnustavo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by CPqD <www.cpqd.com.br>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
