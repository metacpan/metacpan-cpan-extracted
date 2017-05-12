package Template::Plugin::String::Truncate;
BEGIN {
  $Template::Plugin::String::Truncate::VERSION = '0.02';
}
use strict;

# ABSTRACT: String::Truncate functions for Template Toolkit

require Template::Plugin;
use base qw(Template::Plugin);

use String::Truncate qw();


sub elide { shift; return String::Truncate::elide(@_) }


sub trunc { shift; return String::Truncate::trunc(@_) }

1;
__END__
=pod

=head1 NAME

Template::Plugin::String::Truncate - String::Truncate functions for Template Toolkit

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    [% USE st = String.Truncate %]

    This string is elided: [% st.elide('LONG ASS STRING, SON!', 18); %]
    This one is truncated: [% st.trunc('DAMN YOU GOT LONG STRINGS!', 10); %]
    And other stuff can happen too: [% st.elide('SHORT STRING', 5, { truncate => 'left' }) %]

=head1 DESCRIPTION

This plugin allows you to use functions from L<String::Truncate> in your templates.
It is very simple and hopefully requires little explanation.  

=head1 FUNCTIONS

=head2 elide

Truncates a string and marks the elision.  See C<elide> in L<String::Truncate>.

=head2 trunc

Truncates a string.  See C<trunc> in L<String::Truncate>.

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Cold Hard Code, LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

