package Perl::Critic::TooMuchCode;
use strict;
our $VERSION='0.18';

# Well, we need a place for this monkey-patching business.
sub __get_terop_usage {
    my ($used, $doc) = @_;
    for my $question_mark (@{ $doc->find( sub { $_[1]->isa('PPI::Token::Operator') && $_[1]->content eq '?' }) ||[]}) {
        my $el = $question_mark->snext_sibling;
        next unless $el->isa('PPI::Token::Label');

        my $tok = $el->content;
        $tok =~ s/\s*:\z//;

        $used->{$tok}++;
    }
}

1;
__END__

=head1 NAME

Perl::Critic::TooMuchCode - perlcritic add-ons that generally check for dead code.

=head1 DESCRIPTION

This add-on for L<Perl::Critic> is aiming for identifying trivial dead
code. Either the ones that has no use, or the one that produce no
effect. Having dead code floating around causes maintenance burden. Some
might prefer not to generate them in the first place.

=head1 AUTHOR

Kang-min Liu <gugod@gugod.org>

=head1 LICENSE

MIT

=cut
