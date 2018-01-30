=head1 NAME

PPIx::Regexp::Token::GroupType - Represent a grouping parenthesis type.

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{(?i:foo)}smx' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Token::GroupType> is a
L<PPIx::Regexp::Token|PPIx::Regexp::Token>.

C<PPIx::Regexp::Token::GroupType> is the parent of
L<PPIx::Regexp::Token::GroupType::Assertion|PPIx::Regexp::Token::GroupType::Assertion>,
L<PPIx::Regexp::Token::GroupType::BranchReset|PPIx::Regexp::Token::GroupType::BranchReset>,
L<PPIx::Regexp::Token::GroupType::Code|PPIx::Regexp::Token::GroupType::Code>,
L<PPIx::Regexp::Token::GroupType::Modifier|PPIx::Regexp::Token::GroupType::Modifier>,
L<PPIx::Regexp::Token::GroupType::NamedCapture|PPIx::Regexp::Token::GroupType::NamedCapture>,
L<PPIx::Regexp::Token::GroupType::Subexpression|PPIx::Regexp::Token::GroupType::Subexpression>
and
L<PPIx::Regexp::Token::GroupType::Switch|PPIx::Regexp::Token::GroupType::Switch>.

=head1 DESCRIPTION

This class represents any of the magic sequences of characters that can
follow an open parenthesis. This particular class is intended to be
abstract.

=head1 METHODS

This class provides no public methods beyond those provided by its
superclass.

=cut

package PPIx::Regexp::Token::GroupType;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token };

our $VERSION = '0.054';

# Return true if the token can be quantified, and false otherwise
sub can_be_quantified { return };

=head2 __defining_string

 my $string = $class->__defining_string();

This method is private to the C<PPIx-Regexp> package, and is documented
for the author's benefit only. It may be changed or revoked without
notice.

This method returns an array of strings that define the specific group
type.  These strings will normally start with C<'?'>.

Optionally, the first returned item may be a hash reference. The only
supported key is C<{suffix}>, which is a string to be suffixed to each
of the regular expressions made by C<__make_group_type_matcher()> out of
the defining strings, inside a C<(?= ... )>, so that it is not included
in the match.

This method B<must> be overridden, unless C<__make_group_type_matcher()>
is. The override B<must> return the same thing each time, since the
results of C<__make_group_type_matcher()> are cached.

=cut

sub __defining_string {
    require Carp;
    Carp::confess(
	'Programming error - __defining_string() must be overridden' );
}

=head2 __make_group_type_matcher

 my $hash_ref = $class->__make_group_type_matcher();

This method is private to the C<PPIx-Regexp> package, and is documented
for the author's benefit only. It may be changed or revoked without
notice.

This method returns a reference to a hash. The keys are regexp delimiter
characters which appear in the defining strings for the group type. For
each key, the value is a reference to an array of C<Regexp> objects,
properly escaped for the key character. Key C<''> provides the regular
expressions to be used if the regexp delimiter does not appear in any of
the defining strings.

If this method is overridden by the subclass, method
C<__defining_string()> need not be, unless the overridden
C<__make_group_type_matcher()> calls C<__defining_string()>.

=cut

sub __make_group_type_matcher {
    my ( $class ) = @_;

    my @defs = $class->__defining_string();

    my $opt = ref $defs[0] ? shift @defs : {};

    my $suffix = defined $opt->{suffix} ?
	qr/ (?= \Q$opt->{suffix}\E ) /smx :
	'';

    my %seen;
    my @chars = grep { ! $seen{$_}++ } split qr{}smx, join '', @defs;

    my %rslt;
    foreach my $str ( @defs ) {
	push @{ $rslt{''} ||= [] }, qr{ \A \Q$str\E $suffix }smx;
	foreach my $chr ( @chars ) {
	    ( my $expr = $str ) =~ s/ (?= \Q$chr\E ) /\\/smxg;
	    push @{ $rslt{$chr} ||= [] }, qr{ \A \Q$expr\E $suffix }smx;
	}
    }
    return \%rslt;
}


=head2 __match_setup

 $class->__match_setup( $tokenizer );

This method is private to the C<PPIx-Regexp> package, and is documented
for the author's benefit only. It may be changed or revoked without
notice.

This method performs whatever setup is needed once it is determined that
the given group type has been detected.  This method is called only if
the class matched at the current position in the string being parsed. It
must perform whatever extra setup is needed for the match. It returns
nothing.

This method need not be overridden. The default does nothing.

=cut

sub __match_setup {
    return;
}

my %matcher;

sub __PPIX_TOKENIZER__regexp {
    my ( $class, $tokenizer ) = @_;	# $character unused

    my $mtch = $matcher{$class} ||= $class->__make_group_type_matcher();

    my $re_list = $mtch->{ $tokenizer->get_start_delimiter() } ||
	$mtch->{''};

    foreach my $re ( @{ $re_list } ) {
	my $accept = $tokenizer->find_regexp( $re )
	    or next;
	$class->__match_setup( $tokenizer );
	return $accept;
    }

    return;
}

1;

__END__

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2018 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
