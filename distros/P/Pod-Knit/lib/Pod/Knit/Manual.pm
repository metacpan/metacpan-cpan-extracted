package Pod::Knit::Manual;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: manual for the Pod::Knit system 
$Pod::Knit::Manual::VERSION = '0.0.1';

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Knit::Manual - manual for the Pod::Knit system

=head1 VERSION

version 0.0.1

=head1 DESCRIPTION

I love L<Dist::Zilla> and I adore the doc-munging that L<Pod::Weaver> does.
I'm, however, scared of its L<Pod::Elemental> guts. Hence C<Pod::Knit>,
which is also a system to transform POD, but does it using an XML
representation of the document.

=head2 Using Pod::Knit

To use C<Pod::Knit>, you need a F<knit.yml> configuration file. That file
has two main sections: the C<plugins> section listing all the plugins that
you want to use, and the optional C<stash> section holding any variable you
may want to pass to the knitter.

E.g.,

    ---
    stash:
        author: Yanick Champoux <yanick@cpan.org>
    plugins:
        - Abstract
        - Attributes
        - Methods
        - NamedSections:
            sections:
                - synopsis
                - description
        - Version
        - Authors
        - Legal
        - Sort:
            order:
            - NAME
            - VERSION
            - SYNOPSIS
            - DESCRIPTION
            - ATTRIBUTES
            - METHODS
            - '*'
            - AUTHORS
            - AUTHOR
            - COPYRIGHT AND LICENSE

Note that the plugins will be applied to the POD in the order in which they
appear in the configuration file.

Then in that directory, use the script F<podknit> to munge a POD or Perl
file.

    $ podknit lib/My/Module.pm 

Magic!

=head2 Using Pod::Knit with Dist::Zilla

See L<Dist::Zilla::Plugin::PodKnit>.

=head2 Writing a Pod::Knit plugin

The documentation of L<Pod::Knit::Plugin> should give you a good idea how
to do that. Looking at already-existing plugins for inspiration is also
recommended.

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full text of the license can be found in the F<LICENSE> file included in
this distribution.

=cut

