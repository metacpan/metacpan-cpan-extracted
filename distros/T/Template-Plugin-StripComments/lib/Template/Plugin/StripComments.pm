package Template::Plugin::StripComments;

###############################################################################
# Required inclusions.
###############################################################################
use strict;
use warnings;
use base qw(Template::Plugin::Filter);

###############################################################################
# Version number.
###############################################################################
our $VERSION = '1.03';

###############################################################################
# Subroutine:   init()
###############################################################################
# Initializes the template plugin.
###############################################################################
sub init {
    my $self = shift;
    $self->{'_DYNAMIC'} = 1;
    $self->install_filter( $self->{'_ARGS'}->[0] || 'stripcomments' );
    return $self;
}

###############################################################################
# Subroutine:   filter($text)
###############################################################################
# Filters the given text, removing comment blocks as necessary.
###############################################################################
sub filter {
    my ($self, $text) = @_;

    # C-style comments
    $text =~ s{/\*.*?\*/}{}sg;

    # HTML style comments
    $text =~ s{<!--.*?-->}{}sg;

    # Return the filtered text back to the caller
    return $text;
}

1;

=head1 NAME

Template::Plugin::StripComments - Template Toolkit filter to strip comment blocks

=head1 SYNOPSIS

  [% USE StripComments %]
  ...
  [% FILTER stripcomments %]
    /* C-style block comments get removed */

    <!-- as do HTML comments -->
  [% END %]
  ...
  [% text | stripcomments %]

=head1 DESCRIPTION

C<Template::Plugin::StripComments> is a filter plugin for L<Template::Toolkit>,
which strips comment blocks from the filtered text.

The following types of comment blocks are stripped:

=over

=item /* c-style comments */

=item <!-- HTML comments -->

=back

=head1 METHODS

=over

=item init()

Initializes the template plugin.

=item filter($text)

Filters the given text, removing comment blocks as necessary.

=back

=head1 AUTHOR

Graham TerMarsch <cpan@howlingfrog.com>

=head1 COPYRIGHT

Copyright (C) 2007, Graham TerMarsch.  All Rights Reserved.

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=head1 SEE ALSO

L<Template::Plugin::Filter>.

=cut
