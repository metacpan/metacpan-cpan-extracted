package Template::Plugin::Lingua::Conjunction;

use 5.006;
use strict;
use warnings;
use base 'Template::Plugin';

use Lingua::Conjunction ();

our $VERSION = '0.02';

# This plugin is a singleton with no state at all, so...
sub load {
    my($pkg, $context) = @_;
    bless \$pkg, $pkg;
}

sub new { shift }

sub conjunction {
    my $me = shift;
    
    # Flatten any arrays in the parameters
    @_ = map { ref $_ ? @$_ : $_ } @_;
    
    # And call
    goto &Lingua::Conjunction::conjunction;
}

# Shorter alias
sub list { goto &conjunction }

for(qw(lang separator separator_phrase connector_type penultimate)) {
    eval qq{
        sub $_ {
            shift;
            unshift \@_, 'Lingua::Conjunction';
            goto &Lingua::Conjunction::$_;
        }
    }
}

1;


=head1 NAME

Template::Plugin::Lingua::Conjunction - Template Toolkit plugin for human-readable lists

=head1 SYNOPSIS

  [% USE Lingua.Conjunction %]
  [% Lingua.Conjunction.conjunction("Alice", "Bob", "Charlie") %] have secrets 
  from [% Lingua.Conjunction.list("Eve", "Mallory") %]
  
  Alice, Bob, and Charlie have secrets from Eve and Mallory.

=head1 DESCRIPTION

Lingua::Conjunction is a module to create sentence-style, human-readable lists 
of items from a Perl list.  For example, given the list ("foo", "bar", "baz") 
it would return the string "foo, bar, and baz".  If any of the strings in the 
list had a comma in them, it would switch to using a semicolon.  It supports 
multiple languages and use of arbitrary separator characters.  It handles any 
number of items gracefully, even two or one.

Template::Plugin::Lingua::Conjunction is a wrapper around this module so that 
it can be used from the Template Toolkit.

The main method of this plugin is C<conjunction> (or C<list> for short).  It 
takes a list of items or arrays of items which should be converted and returns 
a human-readable string representation.

Template::Plugin::Lingua::Conjunction also supports Lingua::Conjunction's 
settings methods, namely C<lang>, C<separator>, C<separator_phrase>, 
C<connector_type>, and C<penultimate>.  For documentation on them, see 
L<Lingua::Conjunction>.

=head1 SEE ALSO

L<Lingua::Conjunction>, L<Template::Manual>

=head1 AUTHOR

Brent Royal-Gordon E<lt>brentdax@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Brent Royal-Gordon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut
