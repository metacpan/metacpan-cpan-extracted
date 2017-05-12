package Perl::Critic::Policy::CodeLayout::ProhibitHashBarewords;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = '0.07';


sub default_severity { return $SEVERITY_MEDIUM }
sub default_themes   { return qw(itch) }
sub applies_to       { return 'PPI::Token::Word' }

sub violates {
    my ( $self, $elem ) = @_;

    #we only want the check hash keys
    return if !is_hash_key($elem);

    return if is_method_call($elem);
    return if is_function_call($elem);

    my $desc = q{Hash key with bareword};
    my $expl = q{Place quotes on all hash key barewords};
    return $self->violation( $desc, $expl, $elem );
}

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::CodeLayout::ProhibitHashBarewords

=head1 AFFILIATION

This policy is part of L<Perl::Critic::Itch>.

=head1 VERSION

0.07

=head1 DESCRIPTION

This Policy forces (single) quotes on all hash keys barewords.

When specifying constant string hash keys, you should use (single) quotes. E.g., $my_hash{'some_key'} 

This is the appropriate choice because it results in consistent formatting and if you forget to use quotes sometimes, you have to remember to add them when your key contains internal hyphens, spaces, or other special characters. 

Quoted keys are also more likely to be syntax-highlighted by your editor.



=head1 INTERFACE

Standard for a L<Perl::Critic::Policy>.

=head1 ACKNOWLEDGMENTS

Thanks to

=over 4

=item * Jose Carlos Pereira for pointing me in the right direction!

=item * All Perl::Critic::Policy contributors. Their code examples were quite useful.

=back

