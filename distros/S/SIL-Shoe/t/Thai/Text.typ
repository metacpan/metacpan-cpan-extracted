\+DatabaseType Text
\ver 5.0
\desc Database type for general-purpose text. Uses \name as record marker (compatible with output of TextPrep.cct).
\+mkrset 
\lngDefault English
\mkrRecord name

\+mkr dt
\nam Date Stamp
\lng Date
\mkrOverThis name
\-mkr

\+mkr fe
\nam English free translation
\lng English
\mkrOverThis ref
\-mkr

\+mkr ge
\nam English Gloss
\lng English
\mkrOverThis tx
\CharStyle
\-mkr

\+mkr mb
\nam Morpheme Break
\lng UNICODE Thai
\mkrOverThis name
\CharStyle
\-mkr

\+mkr name
\nam Name of Text
\lng Default
\-mkr

\+mkr pr
\nam Phonemic representation
\lng IPA93
\mkrOverThis tx
\CharStyle
\-mkr

\+mkr ps
\nam Part of Speech
\lng Default
\mkrOverThis name
\CharStyle
\-mkr

\+mkr ref
\nam Reference Number
\lng Default
\mkrOverThis name
\-mkr

\+mkr tx
\nam Text
\lng UNICODE Thai
\mkrOverThis ref
\CharStyle
\-mkr

\-mkrset

\iInterlinCharWd 11

\+intprclst 
\fglst '
\fglend "
\mbnd =
\mbrks -

\+intprc Lookup
\bParseProc
\mkrFrom tx
\mkrTo mb

\+triLook 
\+drflst 
\-drflst
\-triLook

\+triPref 
\dbtyp dict
\+drflst 
\+drf 
\File d:\src\projects\shoebox\testing\Thai\dict.db
\-drf
\-drflst
\+mrflst 
\mkr lx
\-mrflst
\mkrOut mb
\-triPref

\+triRoot 
\dbtyp dict
\+drflst 
\+drf 
\File d:\src\projects\shoebox\testing\Thai\dict.db
\-drf
\-drflst
\+mrflst 
\mkr lx
\-mrflst
\mkrOut mb
\-triRoot
\GlossSeparator ;
\FailMark *
\bShowWord
\bPreferSuffix
\-intprc

\+intprc Lookup
\mkrFrom mb
\mkrTo pr

\+triLook 
\dbtyp dict
\+drflst 
\+drf 
\File d:\src\projects\shoebox\testing\Thai\dict.db
\-drf
\-drflst
\+mrflst 
\mkr lx
\-mrflst
\mkrOut pr
\-triLook
\GlossSeparator ;
\FailMark ***
\bShowFailMark
\-intprc

\+intprc Lookup
\mkrFrom mb
\mkrTo ge

\+triLook 
\dbtyp dict
\+drflst 
\+drf 
\File d:\src\projects\shoebox\testing\Thai\dict.db
\-drf
\-drflst
\+mrflst 
\mkr lx
\-mrflst
\mkrOut ge
\-triLook
\GlossSeparator ;
\FailMark ***
\bShowFailMark
\-intprc

\+intprc Lookup
\mkrFrom mb
\mkrTo ps

\+triLook 
\dbtyp dict
\+drflst 
\+drf 
\File d:\src\projects\shoebox\testing\Thai\dict.db
\-drf
\-drflst
\+mrflst 
\mkr lx
\-mrflst
\mkrOut ps
\-triLook
\GlossSeparator ;
\FailMark ***
\bShowFailMark
\-intprc

\-intprclst
\+filset 

\-filset

\+jmpset 
\+jmp Default
\+drflst 
\+drf 
\File D:\Work\MSEA\Langs\Khmer\Bee\Krung Data\Dictionary\Compound.db
\mkr lx
\-drf
\+drf 
\File D:\Work\MSEA\Langs\Khmer\Bee\Krung Data\Dictionary\Borrowed.db
\mkr lx
\-drf
\+drf 
\File D:\Work\MSEA\Langs\Khmer\Bee\Krung Data\Dictionary\Names.db
\mkr lx
\-drf
\+drf 
\File D:\Work\MSEA\Langs\Khmer\Bee\Krung Data\Dictionary\Monosyllables.db
\mkr lx
\-drf
\-drflst
\MatchWhole
\match_char c
\-jmp
\-jmpset

\+template 
\fld \id
\fld \tx
\fld \dt
\-template
\mkrRecord name
\mkrDateStamp dt
\+PrintProperties 
\header File: &f, Date: &d
\footer Page &p
\topmargin 1.00 in
\leftmargin 0.25 in
\bottommargin 1.00 in
\rightmargin 0.25 in
\recordsspace 10
\-PrintProperties
\+expset 

\+expRTF Rich Text Format
\exportedFile A:\Bee.rtf
\InterlinearSpacing 120
\+rtfPageSetup 
\paperSize letter
\topMargin 1
\bottomMargin 1
\leftMargin 1.25
\rightMargin 1.25
\gutter 0
\headerToEdge 0.5
\footerToEdge 0.5
\columns 1
\columnSpacing 0.5
\-rtfPageSetup
\-expRTF

\+expSF Standard Format
\-expSF

\expDefault Rich Text Format
\CurrentRecord
\AutoOpen
\SkipProperties
\-expset
\+numbering 
\mkrRef ref
\mkrTxt tx
\+subsetTextBreakMarkers 
\+mkrsubsetIncluded 
\mkr tx
\-mkrsubsetIncluded
\-subsetTextBreakMarkers
\-numbering
\-DatabaseType
