package Perl::Critic::Policy::Bangs::ProhibitUselessRegexModifiers;

use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities :classification :ppi };
use base 'Perl::Critic::Policy';

our $VERSION = '1.10';

Readonly::Scalar my $DESC => q{Prohibits adding "m" modifier to compiled regular expressions where it does nothing};
Readonly::Scalar my $EXPL => <<'EOF';
There is a bug in 5.8.x in that /$re/sm would incorrectly apply the
/sm modifiers to a regular expression. This makes the code work, but
for the wrong reason. In 5.10.0, this bug is "fixed" so that the
modifier no longer works, but no warning is emitted to tell you that
the modifiers are ignored.
http://perlbuzz.com/mechanix/2007/12/code-broken-by-regex-fixes-in.html
EOF


sub supported_parameters { return ()                   }
sub default_severity     { return $SEVERITY_HIGH       }
sub default_themes       { return qw( bangs bugs )     }
sub applies_to           { return 'PPI::Token::Regexp' }


sub violates {
    my ( $self, $elem, undef ) = @_;


    # we throw a violation if all these conditions are true:
    # 1) there's an 'm' modifier
    # 2) the *only* thing in the regex is a compiled regex from a previous qr().
    # 3) the modifiers are not the same in both places
    my %mods = $elem->get_modifiers();
    if ( $mods{'m'} || $mods{'s'} ) {
        my $match = $elem->get_match_string();
        if ( $match =~ /^\$\w+$/smx ) {  # It looks like a single variable in there
            if ( my $qr = _previously_assigned_quote_like_operator( $elem, $match ) ) {
                # don't violate if both regexes are modified in the same way
                if ( _sorted_modifiers( $elem ) ne _sorted_modifiers( $qr ) ) {
                    return $self->violation( $DESC, $EXPL, $elem );
                }
            }
        }
    }
    return; #ok!;
}

sub _previously_assigned_quote_like_operator {
    my ( $elem, $match ) = @_;

    my $qlop = _find_previous_quote_like_regexp( $elem ) or return;

    # find if this previous quote-like-regexp assigned to the variable in $match
    my $parent = $qlop->parent();
    if ( $parent->find_any( sub { $_[1]->isa( 'PPI::Token::Symbol' ) and
                $_[1]->content eq $match } ) ) {
        return $qlop;
    }
    return;
}


sub _find_previous_quote_like_regexp {
    my $elem = shift;

    my $qlop = $elem;
    while ( ! $qlop->isa( 'PPI::Token::QuoteLike::Regexp' ) ) {
        # we use previous_token instead of sprevious_sibling to get into previous statements.
        $qlop = $qlop->previous_token() or return;
    }
    return $qlop;
}

sub _sorted_modifiers {
    my $elem = shift;

    my %mods = $elem->get_modifiers();
    return join( '', sort keys %mods );
}

1;

=pod

=head1 NAME

Perl::Critic::Policy::Bangs::ProhibitUselessRegexModifiers - Adding modifiers to a regular expression made up entirely of a variable created with qr() is usually not doing what you expect.

=head1 AFFILIATION

This Policy is part of the L<Perl::Critic::Bangs> distribution.

=head1 DESCRIPTION

In older versions of perl, the modifiers on regular expressions where
incorrectly applied. This was fixed in 5.10, but no warnings were
emitted to warn the user that they were probably not getting the
effects they are looking for.

Correct:

  my $regex = qr(abc)m;
  if ( $string =~ /$regex/ ) {};

Not what you want:

  my $regex = qr(abc);
  if ( $string =~ /$regex/m ) {}; ## this triggers a violation of this policy.

See the thread that starts at:
L<http://www.nntp.perl.org/group/perl.perl5.porters/2007/12/msg131709.html>
for a description of how this problem can bite the users.

And see:
L<http://rt.perl.org/rt3//Public/Bug/Display.html?id=22354>
for a description of the bug and subsequent fix.

=head1 CONFIGURATION

This Policy is not configurable except for the standard options.

=head1 AUTHOR

Andrew Moore <amoore@mooresystems.com>

=head1 ACKNOWLEDGMENTS

Adapted from policies by Jeffrey Ryan Thalhammer <thaljef at cpan.org>,
Thanks to Andy Lester, "<andy at petdance.com>" for pointing out this common problem.

=head1 COPYRIGHT

Copyright (c) 2007-2011 Andy Lester <andy@petdance.com> and Andrew
Moore <amoore@mooresystems.com>

This library is free software; you can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

=cut
