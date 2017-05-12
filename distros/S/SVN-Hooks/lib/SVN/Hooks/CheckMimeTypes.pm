package SVN::Hooks::CheckMimeTypes;
# ABSTRACT: Require the svn:mime-type property.
$SVN::Hooks::CheckMimeTypes::VERSION = '1.34';
use strict;
use warnings;

use Carp;
use SVN::Hooks;

use Exporter qw/import/;
my $HOOK = 'CHECK_MIMETYPES';
our @EXPORT = ($HOOK);


my $Help = <<"EOS";
You may want to consider uncommenting the auto-props section
in your ~/.subversion/config file. Read the Subversion book
(http://svnbook.red-bean.com/), Chapter 7, Properties section,
Automatic Property Setting subsection for more help.
EOS

sub CHECK_MIMETYPES {
    my ($help) = @_;
    $Help = $help if defined $help;

    PRE_COMMIT(\&pre_commit);

    return 1;
}

sub pre_commit {
    my ($svnlook) = @_;

    my @errors;

    foreach my $added ($svnlook->added()) {
	next if $added =~ m:/$:; # disregard directories
	my $props = $svnlook->proplist($added);

        next if exists $props->{'svn:special'}; # disregard symbolic links too

	unless (my $mimetype = $props->{'svn:mime-type'}) {
	    push @errors, "property svn:mime-type is not set for: $added";
	} elsif ($mimetype =~ m:^text/:) {
	    for my $prop ('svn:eol-style', 'svn:keywords') {
		push @errors, "property $prop is not set for text file: $added"
		    unless exists $props->{$prop};
	    }
	}
    }

    if (@errors) {
	croak "$HOOK:\n", join("\n", @errors), <<'EOS', $Help;

Every added file must have the svn:mime-type property set. In
addition, text files must have the svn:eol-style and svn:keywords
properties set.

For binary files try running
svn propset svn:mime-type application/octet-stream path/of/file

For text files try
svn propset svn:mime-type text/plain path/of/file
svn propset svn:eol-style native path/of/file
svn propset svn:keywords 'Author Date Id Revision' path/of/file

EOS
    }
}

1; # End of SVN::Hooks::CheckMimeTypes

__END__

=pod

=encoding UTF-8

=head1 NAME

SVN::Hooks::CheckMimeTypes - Require the svn:mime-type property.

=head1 VERSION

version 1.34

=head1 SYNOPSIS

This SVN::Hooks plugin checks if the files added to the repository
have the B<svn:mime-type> property set. Moreover, for text files, it
checks if the properties B<svn:eol-style> and B<svn:keywords> are also
set.

The plugin was based on the
L<check-mime-type.pl|http://svn.digium.com/view/repotools/check-mime-type.pl>
script.

It's active in the C<pre-commit> hook.

It's configured by the following directive.

=head2 CHECK_MIMETYPES([MESSAGE])

This directive enables the checking, causing the commit to abort if it
doesn't comply.

The MESSAGE argument is an optional help message shown to the user in
case the commit fails. Note that by default the plugin already inserts
a rather verbose help message in case of errors.

	CHECK_MIMETYPES("Use TortoiseSVN -> Properties menu option to set properties.");

=for Pod::Coverage pre_commit

=head1 AUTHOR

Gustavo L. de M. Chaves <gnustavo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by CPqD <www.cpqd.com.br>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
