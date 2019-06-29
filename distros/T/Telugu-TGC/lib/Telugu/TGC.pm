package Telugu::TGC;

use Mouse;
use Regexp::Grammars;
use Kavorka -all;
use utf8;

our $VERSION = '0.08';

# V[m] | CH | {CH}C[v][m] | D | F | Hpv | W | Sid | N | Other | NT

# []  - 0 or 1 times
# {}  - zero or more times
# |   - a rule separator
# V   - independent vowel
# m   - modifier(Anusvara/Visarga/Chandrabindu)
# C   - consonant
# v   - dependent vowel
# H   - virama
# D   - digit
# F   - fraction
# W   - weights
# Sid - siddham
# N   - never occurs, if script is written properly it never matches
# CH  - matches only when virama is at the end of the word

# [m]  is written as  m_
# [v]  is written as  v_
# {CH} is written as  CH__

my @result = ();

method TE::String::X() {
    for my $element ( @{ $self->{Tgc} } ) {
        $element->X();
    }
}

method TE::Tgc::X() {
    (        $self->{S}
          || $self->{Vm}
          || $self->{CH}
          || $self->{CHCvm}
          || $self->{D}
          || $self->{F}
          || $self->{W}
          || $self->{Sid}
          || $self->{N}
          || $self->{Other}
          || $self->{NT} )->X();
}

method TE::S::X() {
    push @result, $self->{''};
}

method TE::Vm::X() {
    push @result, $self->{V}{''} . $self->{m_}{''};
}

method TE::CH::X() {
    push @result, $self->{''};
}

method TE::CHCvm::X() {
    push @result,
      $self->{CH__}{''} . $self->{C}{''} . $self->{v_}{''} . $self->{m_}{''};
}

method TE::D::X() {
    push @result, $self->{''};
}

method TE::F::X() {
    push @result, $self->{''};
}

method TE::W::X() {
    push @result, $self->{''};
}

method TE::Sid::X() {
    push @result, $self->{''};
}

method TE::N::X() {
    push @result, $self->{''};
}

method TE::Other::X() {
    push @result, $self->{''};
}

method TE::NT::X() {
    push @result, $self->{''};
}

my $parser = qr {
    <nocontext:>
    <String>
    <objrule:  TE::String>        <[Tgc]>+
    <objrule:  TE::Tgc>           <ws: (\s++)*> <S> | <Vm> | <CH> | <CHCvm> | <D> | <F> | <W> | <Sid> | <N> | <Other> | <NT>
    <objrule:  TE::Vm>            <V><m_>
    <objrule:  TE::CHCvm>         <CH__><C><v_><m_>
    <objtoken: TE::CH>            ([క-హౘ-ౚ])(్\b)
    <objtoken: TE::V>             [అ-ఔౠ-ౡ]
    <objtoken: TE::m_>            [ఀ-ఄఽౕౖ]?
    <objtoken: TE::CH__>          (([క-హౘ-ౚ])(్))*
    <objtoken: TE::C>             [క-హౘ-ౚ]
    <objtoken: TE::v_>            [ా-ౌౢౣ]?
    <objtoken: TE::D>             [౦-౯]
    <objtoken: TE::F>             [౸-౾]
    <objtoken: TE::W>             [౿]
    <objtoken: TE::Sid>           [౷]
    <objtoken: TE::N>             [ా-ౌౢౣఀ-ఄఽౕౖ]
    <objtoken: TE::S>             [ ]
    <objtoken: TE::Other>         [ఀ-౿]
    <objtoken: TE::NT>            [^ఀ-౿]
}xms;

method TGC( Str $string ) {
    if ( $string =~ $parser ) {
        $/{String}->X();
    }
    return @result;
}

1;
__END__
=encoding utf-8

=head1 NAME

Telugu::TGC - Tailored grapheme clusters for Telugu languauge.

=head1 SYNOPSIS

	 use Telugu::TGC;
	 use utf8;
	 binmode STDOUT, ":encoding(UTF-8)";

	 my $tgc = Telugu::TGC->new();
	 my @result = $tgc->TGC("రాజ్కుమార్రెడ్డి");
	 print $result[1], "\n";


=head1 DESCRIPTION

This module provides one function, TGC.
This function takes a string and returns an array.


=head1 BUGS

Please send me email, if you find any bugs


=head1 AUTHOR

Rajkumar Reddy, mesg.raj@outlook.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Rajkumar Reddy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
