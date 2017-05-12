% lily was here -- automatically converted by etf2ly from entertainer.etf

\header {
title = "The Entertainer"
subtitle = "A Rag Tmie Two Step by Scott Joplin" 
composer = "Scott Joplin"
year = "1902"
tagline = "Public domain---converted from freenote ETF  source."
}

staffAlayerA =  \notes { {
\voiceOne
d'''16 e'''16 c'''16 a''16 ~  a''16 b''16 g''8   |
\oneVoice
d''16 e''16 c''16 a'16 ~  a'16 b'16 g'8   | 
d'16 e'16 c'16 a16 ~  a16 b16 a16 aes16   | 
r4 <f'8 b'8 d''8\> g''8> d'16 \! dis'16   |
\repeat  "volta" 2 {
	e'16-\p c''8 e'16 c''8 e'16 c''16 ~    | 
	c''4 \< ~  c''16 <c''16 e''16 c'''16> <d''16 f''16 d'''16> 
	<dis''16 fis''16 dis'''16>   |
	<e''16 e'''16> <c''16 c'''16> <d''16 d'''16> <c''16 c'''16>   | 
	<e''16 g''16 e'''16> <c''16 e''16 c'''16> <d''16 f''16 d'''16> 
	<e''16 g''16 e'''16> ~  <e''16 g''16 e'''16> <c''16 e''16 c'''16> 
	<d''8 f''8 d'''8>   |
}\alternative {

	{ <c''4 e''4 c'''4> ~  <c''8 e''8 \> c'''8> d'16 \! dis'16  } 
	{ <c''4 e''4 c'''4> ~  <c''16 e''16 c'''16> <e'16 c''16 e''16> 
	<f'16 d''16 f''16> <fis'16 dis''16 fis''16>    \bar "||:" \break
	}
}

 |
 \repeat "volta" 2 { 
	<g'8^"Repeat 8va"-\f
	   e''8 g''8> <a'16 e''16 a''16> <g'16 e''16 g''16> ~  
	<g'16 e''16 g''16> <e'16 c''16 e''16> <f'16 d''16 f''16> 
	<fis'16 dis''16 fis''16>   | 
	g'16 c''16 e''16 g''16 ~  g''16 e''16 c''16 g'16   | 
	<fis'8 a'8> <fis'8 d''8> <f'16 e''16> <f'8 d''8> <e'16 c''16> ~    | 
	<e'4 c''4> <e'16 c''16> <e'16 c''16 e''16> <f'16 d''16 f''16> }
\alternative {
  {<fis'16 dis''16 fis''16>   |}
  { <e'4 c''4> ~  <e'8 c''8 \> > d'16(  \! )dis'16
  \bar "||:" \break
  }
}

e'16 -\p c''8 e'16 c''8 e'16 c''16 ~    | 
c''4 ~  c''16 \<  <c''16 e''16 c'''16> <d''16 f''16 d'''16> 
<\! dis''16 fis''16 dis'''16>   | 
<e''16 g''16 e'''16> ~  <e''16 g''16 e'''16> <c''16 e''16 c'''16> 
<d''8 f''8 d'''8>   | 
<c''4 e''4 c'''4> <c''8 e''8 c'''8> r8   |

\repeat volta 2 {
	<f''16 a''16> gis''16 <f''8 a''8> ~  <f''8 a''8> <f''8 a''8 c'''8>   |
	\voiceOne
	<f''2 bes''2 d'''2>   |
	\oneVoice
	<d''16 f''16> e''16 <d''8 f''8> ~  <d''8 f''8> <d''8 f''8 a''8>   |
		\voiceOne
	<d''4 g''4 bes''4> ~  <d''8. g''8. bes''8.> g''16   |
	\voiceOne
	 g''16 c''16 d''16 
	e''16
	\oneVoice
	|
} \alternative {
	 { <a'8 f''8> b'16( c''16 d''16 e''16 f''16 )g''16   |  }
	 { <a'8 f''8> r8 <f''8 a''8 c'''8 f'''8> r8   |
\bar "||:"
	 }
}
\repeat volta 2 {
c''8 a'16 c''16 ~  c''16 a'16 c''16 a'16   | 
g'16 c''16 e''16 g''16 ~  g''16 e''16 c''16 g'16   | 
\alternative {
{ <e'8 g'8 c''8> <e'16 g'16> <e'16 g'16> <e'8 g'8> <e'8 g'8>   |  }
{ <e'4 g'4 c''4> <c''8 e''8 g''8 c'''8> r8   | }
}

 } }

staffAlayerB =  \notes { {
\voiceTwo
d''16 e''16 c''16 a'16 ~  a'16 b'16 g'8   | 
} s1*27 {

r8 bes'16 a'16 bes'16 c''16 d''8   | 
} s2 {
r8 g'16 fis'16 g'16 a'16 bes'8   | 
} s2*5 {
r8 bes'16 a'16 bes'16 c''16 d''8   | 
} s2 {
r8 g'16 fis'16 g'16 a'16 bes'8   | 
} s1 {
s4 bes'8 bes'8   | 
 } }

staffAglobal = \notes  { \key c \major \time 2/4 \clef "treble" s1*2
  s2*17
  s2*33
  \bar "||"
\key f \major s2*17
\key c \major }

staffA = \context Staff = staffA <
 \staffAglobal
 \context Voice = VA \staffAlayerA
 \context Voice = VB \staffAlayerB
>


staffBlayerA =  \notes { { } s2 {
 % FR(6)
d'16 e'16 c'16 a16 ~  a16 b16 g8   | 
d16 e16 c16 a,16 ~  a,16 b,16 a,16 aes,16   | 
<g,8 g8> r8 <g,,8 g,8> <g8 b8>   | 
c8 <e8 g8 c'8> <g,8 g8> <g8 bes8 c'8>   | 
d,8 <a8 d'8 f'8> a,8 <a8 d'8 f'8>   | 
f,8 <f8 a8> a,8 <f8 a8>   | 
c8 <e8 g8 c'8> g,8 <e8 g8 c'8>   | 
c8 <e8 g8 c'8> g,8 <e8 g8 c'8>   | 
<f,8 f8> <d,8 d8> <e,8 e8> <f,8 f8>   | 
<g,8 g8> <g8 c'8 e'8> <fis8 c'8 dis'8> <g8 c'8 e'8>   | 
<a,8 a8> <d,8 d8> <g,8 g8> <b,8 b8>   | 
<c8 c'8> r8 r4   | 
<c8 c'8> <g,8 g8> <c,8 c8> r8   | 
 } }

staffBlayerB =  \notes { { } s2*61 {

r4 g8 c8   | 
 } }

staffBglobal = \notes  { \key c \major \time 2/4
 \clef bass }

staffB = \context Staff = staffB <
 \staffBglobal
 \context Voice = VA \staffBlayerA
 \context Voice = VB \staffBlayerB
>

\score { < \staffA \staffB >
  \paper{
  \translator { \ScoreContext
  \consists "Regular_spacing_engraver"
  regularSpacingDelta = #(make-moment 1 8 )
  }
} 
}
