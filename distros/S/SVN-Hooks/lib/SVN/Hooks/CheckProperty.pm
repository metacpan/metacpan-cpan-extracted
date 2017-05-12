package SVN::Hooks::CheckProperty;
# ABSTRACT: Check properties in added files.
$SVN::Hooks::CheckProperty::VERSION = '1.34';
use strict;
use warnings;

use Carp;
use Data::Util qw(:check);
use SVN::Hooks;

use Exporter qw/import/;
my $HOOK = 'CHECK_PROPERTY';
our @EXPORT = ($HOOK);


my @Checks;

sub CHECK_PROPERTY {
    my ($where, $prop, $what) = @_;

    is_string($where) || is_rx($where)
	or croak "$HOOK: first argument must be a STRING or a qr/Regexp/\n";
    is_string($prop)
	or croak "$HOOK: second argument must be a STRING\n";
    ! defined $what || is_string($what) || is_rx($what)
	or croak "$HOOK: third argument must be undefined, or a NUMBER, or a STRING, or a qr/Regexp/\n";

    push @Checks, [$where, $prop => $what];

    PRE_COMMIT(\&pre_commit);

    return 1;
}

sub pre_commit {
    my ($svnlook) = @_;

    my @errors;

    foreach my $added ($svnlook->added()) {
	foreach my $check (@Checks) {
	    my ($where, $prop, $what) = @$check;
	    if (is_rx($where) && $added =~ $where
		    || is_string($where) && $where eq substr($added, 0, length $where)) {
		my $props = $svnlook->proplist($added);
		my $is_set = exists $props->{$prop};
		if (! defined $what) {
		    $is_set or push @errors, "property $prop must be set for: $added";
		} elsif (is_value($what)) {
		    if (is_integer($what)) {
			if ($what) {
			    $is_set or  push @errors, "property $prop must be set for: $added";
			} else {
			    $is_set and push @errors, "property $prop must not be set for: $added";
			}
		    } elsif (! $is_set) {
			push @errors, "property $prop must be set to \"$what\" for: $added";
		    } elsif ($props->{$prop} ne $what) {
			push @errors, "property $prop must be set to \"$what\" and not to \"$props->{$prop}\" for: $added";
		    }
		} elsif (! $is_set) {
		    push @errors, "property $prop must be set and match \"$what\" for: $added";
		} elsif ($props->{$prop} !~ $what) {
		    push @errors, "property $prop must match \"$what\" but is \"$props->{$prop}\" for: $added";
		}
	    }
	}
    }

    croak join("\n", "$HOOK:", @errors), "\n"
	if @errors;

    return;
}

1; # End of SVN::Hooks::CheckProperty

__END__

=pod

=encoding UTF-8

=head1 NAME

SVN::Hooks::CheckProperty - Check properties in added files.

=head1 VERSION

version 1.34

=head1 SYNOPSIS

This SVN::Hooks plugin checks if some files added to the repository
have some properties set.

It's active in the C<pre-commit> hook.

It's configured by the following directive.

=head2 CHECK_PROPERTY(WHERE, PROPERTY[, VALUE])

This directive enables the checking, causing the commit to abort if it
doesn't comply.

The WHERE argument must be a qr/Regexp/ matching all files that must
comply to this rule.

The PROPERTY argument is the name of the property that must be set for
the files matching WHERE.

The optional VALUE argument specifies the value for PROPERTY depending
on its type:

=over

=item UNDEF or not present

The PROPERTY must be set.

=item NUMBER

If non-zero, the PROPERTY must be set. If zero, the PROPERTY must NOT be set.

=item STRING

The PROPERTY must be set with a value equal to the string.

=item qr/Regexp/

The PROPERTY must be set with a value that matches the Regexp.

=back

Example:

	CHECK_PROPERTY(qr/\.(?:do[ct]|od[bcfgimpst]|ot[ghpst]|pp[st]|xl[bst])$/i
	       => 'svn:needs-lock');

=for Pod::Coverage pre_commit

=head1 AUTHOR

Gustavo L. de M. Chaves <gnustavo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by CPqD <www.cpqd.com.br>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
