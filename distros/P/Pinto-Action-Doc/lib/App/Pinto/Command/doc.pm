package App::Pinto::Command::doc;
{
  $App::Pinto::Command::doc::VERSION = '0.004';
}

# ABSTRACT: generate html docs from the dists in a stack

use strict;
use warnings;

use Pinto::Util qw(interpolate);

#-----------------------------------------------------------------------------

use base 'App::Pinto::Command';

#------------------------------------------------------------------------------

sub command_names { return qw( doc ) }

#------------------------------------------------------------------------------

sub opt_spec {
    my ( $self, $app ) = @_;

    return (
        [ "out|o=s",           "Destination for generated HTML" ],
        [ "title=s",           "Your project's title" ],
        [ "desc=s",            "Your project's description" ],
        [ "charset=s",         "This is used in meta tag in html. default 'UTF-8'" ],
        [ "noindex!",          "Don't create index on each pod pages." ],
        [ "forcegen!",         "Generate documents each time" ],
        [ "lang=s",            "Set this language as xml:lang. default 'en'" ],
        [],
        [ "root|r=s",          "Path to pinto root" ],
        [ "author|A=s",        "Limit to distributions by author" ],
        [ "distributions|D=s", "Limit to matching distribution names" ],
        [ "packages|P=s",      "Limit to matching package names" ],
        [ "pinned!",           "Limit to pinned packages (negatable)" ],
        [ "stack|s=s",         "List contents of this stack" ],
        [ "local",             "Limit to local distributions" ],
        [ 'help|h',            "print usage message and exit" ],
    );
}

#------------------------------------------------------------------------------

sub validate_args {
    my ( $self, $opts, $args ) = @_;

    $self->usage_error('Multiple arguments are not allowed')
        if @{$args} > 1;

    $opts->{stack} = $args->[0]
        if $args->[0];

    $self->usage_error('missing required options: output')
        unless $opts->{out};
    
    return 1;
}

#------------------------------------------------------------------------------

1;

__END__

=pod

=head1 NAME

App::Pinto::Command::doc - generate html docs from the dists in a stack

=head1 VERSION

version 0.004

=head1 SYNOPSIS

  pinto --root=REPOSITORY_ROOT doc --out=HTML_ROOT [OPTIONS]

=head1 DESCRIPTION

This command creates html documents from the distributions on a stack. It uses
L<Pod::ProjectDocs> to do the HTML generation. The command's options are a
combination of the pinto list and pod2projectdocs commands.

=head1 WARNING

The Pinto API is not yet stable so it's entirely possible that changes to Pinto
will break this module.

This module doesn't work with remote Pinto repositories.

=head1 COMMAND OPTIONS (Pod::ProjectDocs)

=over 4

=item --out=HTML_ROOT

=item -o HTML_ROOT

C<HTML_ROOT> is the directory where the HTML docs will be generated. The
directory will be created for you if it doesn't exist.

=item --title=TITLE

The C<TITLE> that will be used as a header to the generated HTML docs.

=item --desc=DESCRIPTION

The C<DESCRIPTION> that will be used in the generated HTML docs.

=item --charset=CHARSET

The C<CHARSET> that will be used in the HTML meta tag. Defaults to UTF-8.

=item --noindex

Don't create an index on each of the pod pages.

=item --forcegen

Generate documents each time ignoring the last modified timestamp.

=item --lang=LANG

The C<LANG> that will be set as xml:lang. Default to 'en'.

=back

=head1 COMMAND OPTIONS (Pinto)

=over 4

=item --author AUTHOR

=item -A AUTHOR

Limit the listing to records where the distribution author is AUTHOR.
Note this is an exact match, not a pattern match.  However, it is
not case sensitive.

=item --distributions PATTERN

=item -D PATTERN

Limit the listing to records where the distribution archive name
matches C<PATTERN>.  Note that C<PATTERN> is just a plain string, not
a regular expression.  The C<PATTERN> will match if it appears
anywhere in the distribution archive name.

=item --packages PATTERN

=item -P PATTERN

Limit the listing to records where the package name matches
C<PATTERN>.  Note that C<PATTERN> is just a plain string, not a
regular expression.  The C<PATTERN> will match if it appears anywhere
in the package name.

=item --pinned

Limit the listing to records for packages that are pinned.

=item --stack NAME

=item -s NAME

List the contents of the stack with the given NAME.  Defaults to the
name of whichever stack is currently marked as the default stack.  Use
the L<stacks|App::Pinto::Command::stacks> command to see the
stacks in the repository.

=item --local

Limit the listing to only local distributions.

=back

=head1 AUTHOR

Andy Gorman <agorman@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Andy Gorman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
