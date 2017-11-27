#!/usr/bin/perl

#
# Copyright (C) 2017 Joelle Maslak
# All Rights Reserved - See License
#

package Perl::Critic::Policy::BadStrings;
$Perl::Critic::Policy::BadStrings::VERSION = '1.000';
use strict;

# ABSTRACT: Search for bad strings in source files


use File::FindStrings::Boilerplate 'script';

use Perl::Critic::Utils qw( :severities :classification :ppi :booleans );
use base 'Perl::Critic::Policy';

use File::FindStrings qw(find_words_in_string);

use Readonly;

Readonly::Scalar my $DESC => 'Bad string in source file';
Readonly::Scalar my $EXPL => 'A "bad string" was found in the source file';

sub default_severity     { return $SEVERITY_MEDIUM; }
sub supported_parameters { return qw(words); }
sub default_themes       { return qw(badstrings); }
sub applies_to           { return 'PPI::Document'; }

sub initialize_if_enabled ( $self, $config ) {
    $self->{_words} = [];

    my $w = $config->get('words');
    if ( defined($w) ) {
        # Regex shamelessly stolen from Perl::Critic::logicLAB::REquireSheBang
        push $self->{_words}->@*, split( m{ \s* [||]+ \s* }xsm, $w );
    }

    return $TRUE;
}

sub violates ( $self, $elem, $doc ) {
    my $content = $elem->content();

    my (@matches) = find_words_in_string( $content, $self->{_words}->@* );

    if (@matches) {
        return $self->violation( $DESC . ': "' . $matches[0]->{word} . '"', $EXPL, $elem );
    } else {
        return;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::BadStrings - Search for bad strings in source files

=head1 VERSION

version 1.000

=head1 DESCRIPTION

This policy will search for "bad words" in a file.  It does this by looking
at the raw Perl file, so the "bad words" can include different types of elements.

The obvious use for this module would be to search for obscene words, but it
can also be used to look for obsolete product names, former company names,
and, useful for the author, previous author names.

Another possible use is to search for strings such as "TODO:".

The search is performed without regard for the case of the match (if you
search for "FOO!" and the string "foo!" appears in the file, it will match).

=head1 AFFILIATION

This policy is a policy (the only one!) in the L<Perl::Critic::Policy::BadStrings>
distribution.  The policy is also themed: C<badstring>.

=head1 CONFIGURATION AND ENVIRONMENT

This policy allows you to configure the "words" that it will alert upon.

=head2 words

  [BadStrings]
  words = poo || Acme Industries

By default, no words are searched (so you must configure this policy for
it to be useful).  However, with the above example, files are examined for
the presence of either of the string "poo" or the string "Acme Industries".

=head2 severity

  [BadStrings]
  severity = 4

By default, the severity used by this module is 3, or "medium".  This can
be configured in the standard way used by other Critic modules.

=head1 BUGS AND TODO

This policy only reports the first "bad word" found in the file, even if
there are many matches of many different words.  It also does not properly
report the line/location of the problem, but instead says that the problem
is always in line 1, column 1.  Patches are welcome!

=head1 AUTHOR

Joelle Maslak <jmaslak@antelope.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Joelle Maslak.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
