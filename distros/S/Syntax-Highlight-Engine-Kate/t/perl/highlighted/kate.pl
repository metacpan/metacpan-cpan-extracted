<normal>
</normal><comment># Copyright (c) 2006 Hans Jeuken. All rights reserved.</comment><comment>
</comment><comment># This program is free software; you can redistribute it and/or</comment><comment>
</comment><comment># modify it under the same terms as Perl itself.</comment><comment>
</comment><normal>
</normal><keyword>package</keyword><normal> </normal><function>Syntax::Highlight</function><normal>::</normal><function>Engine</function><normal>::</normal><function>Kate</function><normal>;</normal><normal>
</normal><normal>
</normal><keyword>use</keyword><normal> </normal><float>5.006</float><normal>;</normal><normal>
</normal><keyword>our</keyword><normal> </normal><datatype>$VERSION</datatype><normal> = </normal><operator>'</operator><string>0.06</string><operator>'</operator><normal>;</normal><normal>
</normal><keyword>use</keyword><normal> </normal><keyword>strict</keyword><normal>;</normal><normal>
</normal><keyword>use</keyword><normal> </normal><keyword>warnings</keyword><normal>;</normal><normal>
</normal><keyword>use</keyword><normal> Carp;</normal><normal>
</normal><keyword>use</keyword><normal> </normal><function>Data::Dumper</function><normal>;</normal><normal>
</normal><keyword>use</keyword><normal> </normal><function>File::Basename</function><normal>;</normal><normal>
</normal><normal>
</normal><keyword>use</keyword><normal> base(</normal><operator>'</operator><string>Syntax::Highlight::Engine::Kate::Template</string><operator>'</operator><normal>);</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>new</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$proto</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$class</datatype><normal> = </normal><function>ref</function><normal>(</normal><datatype>$proto</datatype><normal>) || </normal><datatype>$proto</datatype><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>%args</datatype><normal> = (</normal><datatype>@_</datatype><normal>);</normal><normal>
</normal><normal>	</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$add</datatype><normal> = </normal><function>delete</function><normal> </normal><datatype>$args</datatype><normal>{</normal><operator>'</operator><string>plugins</string><operator>'</operator><normal>};</normal><normal>
</normal><normal>	</normal><keyword>unless</keyword><normal> (</normal><function>defined</function><normal>(</normal><datatype>$add</datatype><normal>)) { </normal><datatype>$add</datatype><normal> = [] };</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$language</datatype><normal> = </normal><function>delete</function><normal> </normal><datatype>$args</datatype><normal>{</normal><operator>'</operator><string>language</string><operator>'</operator><normal>};</normal><normal>
</normal><normal>	</normal><keyword>unless</keyword><normal> (</normal><function>defined</function><normal>(</normal><datatype>$language</datatype><normal>)) { </normal><datatype>$language</datatype><normal> = </normal><operator>'</operator><string>Off</string><operator>'</operator><normal> };</normal><normal>
</normal><normal>	</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><datatype>$class</datatype><normal>-></normal><datatype>SUPER</datatype><normal>::</normal><datatype>new</datatype><normal>(</normal><datatype>%args</datatype><normal>);</normal><normal>
</normal><normal>
</normal><normal>	</normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>plugins</string><operator>'</operator><normal>} = {};</normal><normal>
</normal><normal>	</normal><comment>#begin autoinsert</comment><comment>
</comment><normal>	</normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>extensions</string><operator>'</operator><normal>} = {</normal><normal>
</normal><normal>		</normal><operator>'</operator><string> *.cls</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>LaTeX</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string> *.dtx</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>LaTeX</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string> *.ltx</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>LaTeX</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string> *.sty</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>LaTeX</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.4GL</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>4GL</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.4gl</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>4GL</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.ABC</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>ABC</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.ASM</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>AVR Assembler</string><operator>'</operator><normal>, </normal><operator>'</operator><string>PicAsm</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.BAS</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>FreeBASIC</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.BI</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>FreeBASIC</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.C</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>C++</string><operator>'</operator><normal>, </normal><operator>'</operator><string>C</string><operator>'</operator><normal>, </normal><operator>'</operator><string>ANSI C89</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.D</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>D</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.F</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Fortran</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.F90</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Fortran</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.F95</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Fortran</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.FOR</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Fortran</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.FPP</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Fortran</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.GDL</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>GDL</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.H</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>C++</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.JSP</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>JSP</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.LOGO</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>de_DE</string><operator>'</operator><normal>, </normal><operator>'</operator><string>en_US</string><operator>'</operator><normal>, </normal><operator>'</operator><string>nl</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.LY</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>LilyPond</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.Logo</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>de_DE</string><operator>'</operator><normal>, </normal><operator>'</operator><string>en_US</string><operator>'</operator><normal>, </normal><operator>'</operator><string>nl</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.M</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Matlab</string><operator>'</operator><normal>, </normal><operator>'</operator><string>Octave</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.MAB</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>MAB-DB</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.Mab</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>MAB-DB</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.PER</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>4GL-PER</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.PIC</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>PicAsm</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.PRG</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>xHarbour</string><operator>'</operator><normal>, </normal><operator>'</operator><string>Clipper</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.R</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>R Script</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.S</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>GNU Assembler</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.SQL</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>SQL</string><operator>'</operator><normal>, </normal><operator>'</operator><string>SQL (MySQL)</string><operator>'</operator><normal>, </normal><operator>'</operator><string>SQL (PostgreSQL)</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.SRC</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>PicAsm</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.V</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Verilog</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.VCG</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>GDL</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.a</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Ada</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.abc</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>ABC</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.ada</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Ada</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.adb</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Ada</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.ado</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Stata</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.ads</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Ada</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.ahdl</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>AHDL</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.ai</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>PostScript</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.ans</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Ansys</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.asm</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>AVR Assembler</string><operator>'</operator><normal>, </normal><operator>'</operator><string>Asm6502</string><operator>'</operator><normal>, </normal><operator>'</operator><string>Intel x86 (NASM)</string><operator>'</operator><normal>, </normal><operator>'</operator><string>PicAsm</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.asm-avr</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>AVR Assembler</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.asp</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>ASP</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.awk</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>AWK</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.bas</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>FreeBASIC</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.basetest</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>BaseTest</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.bash</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Bash</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.bi</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>FreeBASIC</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.bib</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>BibTeX</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.bro</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Component-Pascal</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.c</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>C</string><operator>'</operator><normal>, </normal><operator>'</operator><string>ANSI C89</string><operator>'</operator><normal>, </normal><operator>'</operator><string>LPC</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.c++</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>C++</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.cc</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>C++</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.cfc</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>ColdFusion</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.cfg</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Quake Script</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.cfm</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>ColdFusion</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.cfml</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>ColdFusion</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.cg</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Cg</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.cgis</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>CGiS</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.ch</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>xHarbour</string><operator>'</operator><normal>, </normal><operator>'</operator><string>Clipper</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.cis</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Cisco</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.cl</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Common Lisp</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.cmake</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>CMake</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.config</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Logtalk</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.cp</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Component-Pascal</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.cpp</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>C++</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.cs</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>C#</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.css</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>CSS</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.cue</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>CUE Sheet</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.cxx</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>C++</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.d</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>D</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.daml</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>XML</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.dbm</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>ColdFusion</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.def</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Modula-2</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.desktop</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>.desktop</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.diff</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Diff</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.do</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Stata</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.docbook</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>XML</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.dox</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Doxygen</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.doxygen</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Doxygen</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.e</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>E Language</string><operator>'</operator><normal>, </normal><operator>'</operator><string>Eiffel</string><operator>'</operator><normal>, </normal><operator>'</operator><string>Euphoria</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.ebuild</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Bash</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.eclass</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Bash</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.eml</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Email</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.eps</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>PostScript</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.err</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>4GL</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.ex</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Euphoria</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.exu</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Euphoria</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.exw</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Euphoria</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.f</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Fortran</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.f90</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Fortran</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.f95</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Fortran</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.fe</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>ferite</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.feh</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>ferite</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.flex</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Lex/Flex</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.for</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Fortran</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.fpp</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Fortran</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.frag</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>GLSL</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.gdl</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>GDL</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.glsl</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>GLSL</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.guile</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Scheme</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.h</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>C++</string><operator>'</operator><normal>, </normal><operator>'</operator><string>C</string><operator>'</operator><normal>, </normal><operator>'</operator><string>ANSI C89</string><operator>'</operator><normal>, </normal><operator>'</operator><string>Inform</string><operator>'</operator><normal>, </normal><operator>'</operator><string>LPC</string><operator>'</operator><normal>, </normal><operator>'</operator><string>Objective-C</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.h++</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>C++</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.hcc</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>C++</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.hpp</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>C++</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.hs</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Haskell</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.hsp</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Spice</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.ht</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Apache Configuration</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.htm</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>HTML</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.html</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>HTML</string><operator>'</operator><normal>, </normal><operator>'</operator><string>Mason</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.hxx</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>C++</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.i</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>progress</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.idl</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>IDL</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.inc</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>POV-Ray</string><operator>'</operator><normal>, </normal><operator>'</operator><string>PHP (HTML)</string><operator>'</operator><normal>, </normal><operator>'</operator><string>LPC</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.inf</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Inform</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.ini</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>INI Files</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.java</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Java</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.js</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>JavaScript</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.jsp</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>JSP</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.katetemplate</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Kate File Template</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.kbasic</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>KBasic</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.kdelnk</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>.desktop</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.l</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Lex/Flex</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.ldif</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>LDIF</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.lex</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Lex/Flex</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.lgo</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>de_DE</string><operator>'</operator><normal>, </normal><operator>'</operator><string>en_US</string><operator>'</operator><normal>, </normal><operator>'</operator><string>nl</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.lgt</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Logtalk</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.lhs</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Literate Haskell</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.lisp</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Common Lisp</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.logo</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>de_DE</string><operator>'</operator><normal>, </normal><operator>'</operator><string>en_US</string><operator>'</operator><normal>, </normal><operator>'</operator><string>nl</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.lsp</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Common Lisp</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.lua</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Lua</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.ly</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>LilyPond</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.m</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Matlab</string><operator>'</operator><normal>, </normal><operator>'</operator><string>Objective-C</string><operator>'</operator><normal>, </normal><operator>'</operator><string>Octave</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.m3u</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>M3U</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.mab</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>MAB-DB</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.md</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Modula-2</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.mi</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Modula-2</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.ml</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Objective Caml</string><operator>'</operator><normal>, </normal><operator>'</operator><string>SML</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.mli</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Objective Caml</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.moc</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>C++</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.mod</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Modula-2</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.mup</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Music Publisher</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.not</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Music Publisher</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.o</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>LPC</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.octave</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Octave</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.p</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Pascal</string><operator>'</operator><normal>, </normal><operator>'</operator><string>progress</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.pas</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Pascal</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.pb</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>PureBasic</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.per</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>4GL-PER</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.per.err</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>4GL-PER</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.php</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>PHP (HTML)</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.php3</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>PHP (HTML)</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.phtm</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>PHP (HTML)</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.phtml</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>PHP (HTML)</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.pic</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>PicAsm</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.pike</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Pike</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.pl</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Perl</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.pls</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>INI Files</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.pm</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Perl</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.po</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>GNU Gettext</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.pot</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>GNU Gettext</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.pov</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>POV-Ray</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.pp</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Pascal</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.prg</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>xHarbour</string><operator>'</operator><normal>, </normal><operator>'</operator><string>Clipper</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.pro</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>RSI IDL</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.prolog</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Prolog</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.ps</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>PostScript</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.py</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Python</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.pyw</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Python</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.rb</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Ruby</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.rc</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>XML</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.rdf</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>XML</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.reg</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>WINE Config</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.rex</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>REXX</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.rib</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>RenderMan RIB</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.s</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>GNU Assembler</string><operator>'</operator><normal>, </normal><operator>'</operator><string>MIPS Assembler</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.sa</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Sather</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.sce</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>scilab</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.scheme</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Scheme</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.sci</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>scilab</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.scm</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Scheme</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.sgml</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>SGML</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.sh</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Bash</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.shtm</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>HTML</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.shtml</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>HTML</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.siv</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Sieve</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.sml</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>SML</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.sp</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Spice</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.spec</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>RPM Spec</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.sql</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>SQL</string><operator>'</operator><normal>, </normal><operator>'</operator><string>SQL (MySQL)</string><operator>'</operator><normal>, </normal><operator>'</operator><string>SQL (PostgreSQL)</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.src</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>PicAsm</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.ss</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Scheme</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.t2t</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>txt2tags</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.tcl</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Tcl/Tk</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.tdf</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>AHDL</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.tex</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>LaTeX</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.tji</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>TaskJuggler</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.tjp</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>TaskJuggler</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.tk</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Tcl/Tk</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.tst</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>BaseTestchild</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.uc</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>UnrealScript</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.v</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Verilog</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.vcg</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>GDL</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.vert</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>GLSL</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.vhd</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>VHDL</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.vhdl</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>VHDL</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.vl</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Verilog</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.vm</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Velocity</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.w</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>progress</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.wml</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>PHP (HTML)</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.wrl</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>VRML</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.xml</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>XML</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.xsl</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>xslt</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.xslt</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>xslt</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.y</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Yacc/Bison</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*.ys</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>yacas</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*Makefile*</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Makefile</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*makefile*</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Makefile</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>*patch</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Diff</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>CMakeLists.txt</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>CMake</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>ChangeLog</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>ChangeLog</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>QRPGLESRC.*</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>ILERPG</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>apache.conf</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Apache Configuration</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>apache2.conf</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Apache Configuration</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>httpd.conf</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Apache Configuration</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>httpd2.conf</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>Apache Configuration</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>xorg.conf</string><operator>'</operator><normal> => [</normal><operator>'</operator><string>x.org Configuration</string><operator>'</operator><normal>, ],</normal><normal>
</normal><normal>	};</normal><normal>
</normal><normal>	</normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>sections</string><operator>'</operator><normal>} = {</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Assembler</string><operator>'</operator><normal> => [</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>AVR Assembler</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Asm6502</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>GNU Assembler</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Intel x86 (NASM)</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>MIPS Assembler</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>PicAsm</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Configuration</string><operator>'</operator><normal> => [</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>.desktop</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Apache Configuration</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Cisco</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>INI Files</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>WINE Config</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>x.org Configuration</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Database</string><operator>'</operator><normal> => [</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>4GL</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>4GL-PER</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>LDIF</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>SQL</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>SQL (MySQL)</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>SQL (PostgreSQL)</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>progress</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Hardware</string><operator>'</operator><normal> => [</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>AHDL</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Spice</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>VHDL</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Verilog</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Logo</string><operator>'</operator><normal> => [</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>de_DE</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>en_US</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>nl</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Markup</string><operator>'</operator><normal> => [</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>ASP</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>BibTeX</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>CSS</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>ColdFusion</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Doxygen</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>GNU Gettext</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>HTML</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>JSP</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Javadoc</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Kate File Template</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>LaTeX</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>MAB-DB</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>PostScript</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>SGML</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>VRML</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Wikimedia</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>XML</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>txt2tags</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>xslt</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Other</string><operator>'</operator><normal> => [</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>ABC</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Alerts</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>CMake</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>CSS/PHP</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>CUE Sheet</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>ChangeLog</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Debian Changelog</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Debian Control</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Diff</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Email</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>JavaScript/PHP</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>LilyPond</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>M3U</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Makefile</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Music Publisher</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>POV-Ray</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>RPM Spec</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>RenderMan RIB</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Scientific</string><operator>'</operator><normal> => [</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>GDL</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Matlab</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Octave</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>TI Basic</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>scilab</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Script</string><operator>'</operator><normal> => [</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Ansys</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Scripts</string><operator>'</operator><normal> => [</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>AWK</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Bash</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Common Lisp</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Euphoria</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>JavaScript</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Lua</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Mason</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>PHP (HTML)</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>PHP/PHP</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Perl</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Pike</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Python</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Quake Script</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>R Script</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>REXX</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Ruby</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Scheme</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Sieve</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>TaskJuggler</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Tcl/Tk</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>UnrealScript</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Velocity</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>ferite</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Sources</string><operator>'</operator><normal> => [</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>ANSI C89</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Ada</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>C</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>C#</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>C++</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>CGiS</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Cg</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Clipper</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Component-Pascal</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>D</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>E Language</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Eiffel</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Fortran</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>FreeBASIC</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>GLSL</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Haskell</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>IDL</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>ILERPG</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Inform</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Java</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>KBasic</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>LPC</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Lex/Flex</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Literate Haskell</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Logtalk</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Modula-2</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Objective Caml</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Objective-C</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Pascal</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Prolog</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>PureBasic</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>RSI IDL</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>SML</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Sather</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Stata</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>Yacc/Bison</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>xHarbour</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>yacas</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		],</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Test</string><operator>'</operator><normal> => [</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>BaseTest</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>			</normal><operator>'</operator><string>BaseTestchild</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		],</normal><normal>
</normal><normal>	};</normal><normal>
</normal><normal>	</normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>syntaxes</string><operator>'</operator><normal>} = {</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>.desktop</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Desktop</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>4GL</string><operator>'</operator><normal> => </normal><operator>'</operator><string>FourGL</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>4GL-PER</string><operator>'</operator><normal> => </normal><operator>'</operator><string>FourGLminusPER</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>ABC</string><operator>'</operator><normal> => </normal><operator>'</operator><string>ABC</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>AHDL</string><operator>'</operator><normal> => </normal><operator>'</operator><string>AHDL</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>ANSI C89</string><operator>'</operator><normal> => </normal><operator>'</operator><string>ANSI_C89</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>ASP</string><operator>'</operator><normal> => </normal><operator>'</operator><string>ASP</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>AVR Assembler</string><operator>'</operator><normal> => </normal><operator>'</operator><string>AVR_Assembler</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>AWK</string><operator>'</operator><normal> => </normal><operator>'</operator><string>AWK</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Ada</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Ada</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Alerts</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Alerts</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Ansys</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Ansys</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Apache Configuration</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Apache_Configuration</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Asm6502</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Asm6502</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>BaseTest</string><operator>'</operator><normal> => </normal><operator>'</operator><string>BaseTest</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>BaseTestchild</string><operator>'</operator><normal> => </normal><operator>'</operator><string>BaseTestchild</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Bash</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Bash</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>BibTeX</string><operator>'</operator><normal> => </normal><operator>'</operator><string>BibTeX</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>C</string><operator>'</operator><normal> => </normal><operator>'</operator><string>C</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>C#</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Cdash</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>C++</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Cplusplus</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>CGiS</string><operator>'</operator><normal> => </normal><operator>'</operator><string>CGiS</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>CMake</string><operator>'</operator><normal> => </normal><operator>'</operator><string>CMake</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>CSS</string><operator>'</operator><normal> => </normal><operator>'</operator><string>CSS</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>CSS/PHP</string><operator>'</operator><normal> => </normal><operator>'</operator><string>CSS_PHP</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>CUE Sheet</string><operator>'</operator><normal> => </normal><operator>'</operator><string>CUE_Sheet</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Cg</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Cg</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>ChangeLog</string><operator>'</operator><normal> => </normal><operator>'</operator><string>ChangeLog</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Cisco</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Cisco</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Clipper</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Clipper</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>ColdFusion</string><operator>'</operator><normal> => </normal><operator>'</operator><string>ColdFusion</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Common Lisp</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Common_Lisp</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Component-Pascal</string><operator>'</operator><normal> => </normal><operator>'</operator><string>ComponentminusPascal</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>D</string><operator>'</operator><normal> => </normal><operator>'</operator><string>D</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Debian Changelog</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Debian_Changelog</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Debian Control</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Debian_Control</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Diff</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Diff</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Doxygen</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Doxygen</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>E Language</string><operator>'</operator><normal> => </normal><operator>'</operator><string>E_Language</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Eiffel</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Eiffel</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Email</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Email</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Euphoria</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Euphoria</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Fortran</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Fortran</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>FreeBASIC</string><operator>'</operator><normal> => </normal><operator>'</operator><string>FreeBASIC</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>GDL</string><operator>'</operator><normal> => </normal><operator>'</operator><string>GDL</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>GLSL</string><operator>'</operator><normal> => </normal><operator>'</operator><string>GLSL</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>GNU Assembler</string><operator>'</operator><normal> => </normal><operator>'</operator><string>GNU_Assembler</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>GNU Gettext</string><operator>'</operator><normal> => </normal><operator>'</operator><string>GNU_Gettext</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>HTML</string><operator>'</operator><normal> => </normal><operator>'</operator><string>HTML</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Haskell</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Haskell</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>IDL</string><operator>'</operator><normal> => </normal><operator>'</operator><string>IDL</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>ILERPG</string><operator>'</operator><normal> => </normal><operator>'</operator><string>ILERPG</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>INI Files</string><operator>'</operator><normal> => </normal><operator>'</operator><string>INI_Files</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Inform</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Inform</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Intel x86 (NASM)</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Intel_x86_NASM</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>JSP</string><operator>'</operator><normal> => </normal><operator>'</operator><string>JSP</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Java</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Java</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>JavaScript</string><operator>'</operator><normal> => </normal><operator>'</operator><string>JavaScript</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>JavaScript/PHP</string><operator>'</operator><normal> => </normal><operator>'</operator><string>JavaScript_PHP</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Javadoc</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Javadoc</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>KBasic</string><operator>'</operator><normal> => </normal><operator>'</operator><string>KBasic</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Kate File Template</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Kate_File_Template</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>LDIF</string><operator>'</operator><normal> => </normal><operator>'</operator><string>LDIF</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>LPC</string><operator>'</operator><normal> => </normal><operator>'</operator><string>LPC</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>LaTeX</string><operator>'</operator><normal> => </normal><operator>'</operator><string>LaTeX</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Lex/Flex</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Lex_Flex</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>LilyPond</string><operator>'</operator><normal> => </normal><operator>'</operator><string>LilyPond</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Literate Haskell</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Literate_Haskell</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Logtalk</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Logtalk</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Lua</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Lua</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>M3U</string><operator>'</operator><normal> => </normal><operator>'</operator><string>M3U</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>MAB-DB</string><operator>'</operator><normal> => </normal><operator>'</operator><string>MABminusDB</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>MIPS Assembler</string><operator>'</operator><normal> => </normal><operator>'</operator><string>MIPS_Assembler</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Makefile</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Makefile</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Mason</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Mason</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Matlab</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Matlab</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Modula-2</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Modulaminus2</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Music Publisher</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Music_Publisher</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Objective Caml</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Objective_Caml</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Objective-C</string><operator>'</operator><normal> => </normal><operator>'</operator><string>ObjectiveminusC</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Octave</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Octave</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>PHP (HTML)</string><operator>'</operator><normal> => </normal><operator>'</operator><string>PHP_HTML</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>PHP/PHP</string><operator>'</operator><normal> => </normal><operator>'</operator><string>PHP_PHP</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>POV-Ray</string><operator>'</operator><normal> => </normal><operator>'</operator><string>POVminusRay</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Pascal</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Pascal</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Perl</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Perl</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>PicAsm</string><operator>'</operator><normal> => </normal><operator>'</operator><string>PicAsm</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Pike</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Pike</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>PostScript</string><operator>'</operator><normal> => </normal><operator>'</operator><string>PostScript</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Prolog</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Prolog</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>PureBasic</string><operator>'</operator><normal> => </normal><operator>'</operator><string>PureBasic</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Python</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Python</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Quake Script</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Quake_Script</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>R Script</string><operator>'</operator><normal> => </normal><operator>'</operator><string>R_Script</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>REXX</string><operator>'</operator><normal> => </normal><operator>'</operator><string>REXX</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>RPM Spec</string><operator>'</operator><normal> => </normal><operator>'</operator><string>RPM_Spec</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>RSI IDL</string><operator>'</operator><normal> => </normal><operator>'</operator><string>RSI_IDL</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>RenderMan RIB</string><operator>'</operator><normal> => </normal><operator>'</operator><string>RenderMan_RIB</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Ruby</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Ruby</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>SGML</string><operator>'</operator><normal> => </normal><operator>'</operator><string>SGML</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>SML</string><operator>'</operator><normal> => </normal><operator>'</operator><string>SML</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>SQL</string><operator>'</operator><normal> => </normal><operator>'</operator><string>SQL</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>SQL (MySQL)</string><operator>'</operator><normal> => </normal><operator>'</operator><string>SQL_MySQL</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>SQL (PostgreSQL)</string><operator>'</operator><normal> => </normal><operator>'</operator><string>SQL_PostgreSQL</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Sather</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Sather</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Scheme</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Scheme</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Sieve</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Sieve</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Spice</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Spice</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Stata</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Stata</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>TI Basic</string><operator>'</operator><normal> => </normal><operator>'</operator><string>TI_Basic</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>TaskJuggler</string><operator>'</operator><normal> => </normal><operator>'</operator><string>TaskJuggler</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Tcl/Tk</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Tcl_Tk</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>UnrealScript</string><operator>'</operator><normal> => </normal><operator>'</operator><string>UnrealScript</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>VHDL</string><operator>'</operator><normal> => </normal><operator>'</operator><string>VHDL</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>VRML</string><operator>'</operator><normal> => </normal><operator>'</operator><string>VRML</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Velocity</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Velocity</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Verilog</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Verilog</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>WINE Config</string><operator>'</operator><normal> => </normal><operator>'</operator><string>WINE_Config</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Wikimedia</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Wikimedia</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>XML</string><operator>'</operator><normal> => </normal><operator>'</operator><string>XML</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>Yacc/Bison</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Yacc_Bison</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>de_DE</string><operator>'</operator><normal> => </normal><operator>'</operator><string>De_DE</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>en_US</string><operator>'</operator><normal> => </normal><operator>'</operator><string>En_US</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>ferite</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Ferite</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>nl</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Nl</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>progress</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Progress</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>scilab</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Scilab</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>txt2tags</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Txt2tags</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>x.org Configuration</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Xorg_Configuration</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>xHarbour</string><operator>'</operator><normal> => </normal><operator>'</operator><string>XHarbour</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>xslt</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Xslt</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>yacas</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Yacas</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>	};</normal><normal>
</normal><normal>	</normal><comment>#end autoinsert</comment><comment>
</comment><normal>	</normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>language </string><operator>'</operator><normal>} = </normal><operator>''</operator><normal>;</normal><normal>
</normal><normal>	</normal><function>bless</function><normal> (</normal><datatype>$self</datatype><normal>, </normal><datatype>$class</datatype><normal>);</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>$language</datatype><normal> </normal><operator>ne</operator><normal> </normal><operator>''</operator><normal>) {</normal><normal>
</normal><normal>		</normal><datatype>$self</datatype><normal>-></normal><datatype>language</datatype><normal>(</normal><datatype>$language</datatype><normal>);</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><datatype>$self</datatype><normal>;</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>extensions</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>extensions</string><operator>'</operator><normal>};</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><comment>#overriding Template's initialize method. now it should not do anything.</comment><comment>
</comment><keyword>sub </keyword><function>initialize</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$cw</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>language</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>@_</datatype><normal>) {</normal><normal>
</normal><normal>		</normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>language</string><operator>'</operator><normal>} = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>		</normal><datatype>$self</datatype><normal>-></normal><datatype>reset</datatype><normal>;</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>language</string><operator>'</operator><normal>};</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>languageAutoSet</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> (</normal><datatype>$self</datatype><normal>, </normal><datatype>$file</datatype><normal>) = </normal><datatype>@_</datatype><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$lang</datatype><normal> = </normal><datatype>$self</datatype><normal>-></normal><datatype>languagePropose</datatype><normal>(</normal><datatype>$file</datatype><normal>);</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><function>defined</function><normal> </normal><datatype>$lang</datatype><normal>) {</normal><normal>
</normal><normal>		</normal><datatype>$self</datatype><normal>-></normal><datatype>language</datatype><normal>(</normal><datatype>$lang</datatype><normal>)</normal><normal>
</normal><normal>	} </normal><keyword>else</keyword><normal> {</normal><normal>
</normal><normal>		</normal><datatype>$self</datatype><normal>-></normal><datatype>language</datatype><normal>(</normal><operator>'</operator><string>Off</string><operator>'</operator><normal>)</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>languageList</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$l</datatype><normal> = </normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>syntaxes</string><operator>'</operator><normal>};</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><function>sort</function><normal> {</normal><function>uc</function><normal>(</normal><datatype>$a</datatype><normal>) cmp </normal><function>uc</function><normal>(</normal><datatype>$b</datatype><normal>)} </normal><function>keys</function><normal> %</normal><datatype>$l</datatype><normal>;</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>languagePropose</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> (</normal><datatype>$self</datatype><normal>, </normal><datatype>$file</datatype><normal>) = </normal><datatype>@_</datatype><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$hsh</datatype><normal> = </normal><datatype>$self</datatype><normal>-></normal><datatype>extensions</datatype><normal>;</normal><normal>
</normal><normal>	</normal><keyword>foreach</keyword><normal> </normal><keyword>my</keyword><normal> </normal><datatype>$key</datatype><normal> (</normal><function>keys</function><normal> %</normal><datatype>$hsh</datatype><normal>) {</normal><normal>
</normal><normal>		</normal><keyword>my</keyword><normal> </normal><datatype>$reg</datatype><normal> = </normal><datatype>$key</datatype><normal>;</normal><normal>
</normal><normal>		</normal><datatype>$reg</datatype><normal> =~ </normal><operator>s/</operator><others>\.</others><operator>/</operator><string>\\.</string><operator>/g</operator><normal>;</normal><normal>
</normal><normal>		</normal><datatype>$reg</datatype><normal> =~ </normal><operator>s/</operator><others>\+</others><operator>/</operator><string>\\+</string><operator>/g</operator><normal>;</normal><normal>
</normal><normal>		</normal><datatype>$reg</datatype><normal> =~ </normal><operator>s/</operator><others>\*</others><operator>/</operator><string>.*</string><operator>/g</operator><normal>;</normal><normal>
</normal><normal>		</normal><datatype>$reg</datatype><normal> = </normal><operator>"</operator><datatype>$reg</datatype><string>\$</string><operator>"</operator><normal>;</normal><normal>
</normal><normal>		</normal><keyword>if</keyword><normal> (</normal><datatype>$file</datatype><normal> =~ </normal><operator>/</operator><datatype>$reg</datatype><operator>/</operator><normal>) {</normal><normal>
</normal><normal>			</normal><keyword>return</keyword><normal> </normal><datatype>$hsh</datatype><normal>->{</normal><datatype>$key</datatype><normal>}</normal><operator>-</operator><normal>>[0]</normal><normal>
</normal><normal>		}</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><function>undef</function><normal>;</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>languagePlug</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> (</normal><datatype>$self</datatype><normal>, </normal><datatype>$req</datatype><normal>) = </normal><datatype>@_</datatype><normal>;</normal><normal>
</normal><normal>	</normal><keyword>unless</keyword><normal> (</normal><function>exists</function><normal>(</normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>syntaxes</string><operator>'</operator><normal>}</normal><operator>-</operator><normal>>{</normal><datatype>$req</datatype><normal>})) {</normal><normal>
</normal><normal>		</normal><function>warn</function><normal> </normal><operator>"</operator><string>undefined language: </string><datatype>$req</datatype><operator>"</operator><normal>;</normal><normal>
</normal><normal>		</normal><keyword>return</keyword><normal> </normal><function>undef</function><normal>;</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>syntaxes</string><operator>'</operator><normal>}</normal><operator>-</operator><normal>>{</normal><datatype>$req</datatype><normal>};</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>reset</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$lang</datatype><normal> = </normal><datatype>$self</datatype><normal>-></normal><datatype>language</datatype><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>$lang</datatype><normal> </normal><operator>eq</operator><normal> </normal><operator>'</operator><string>Off</string><operator>'</operator><normal>) {</normal><normal>
</normal><normal>		</normal><datatype>$self</datatype><normal>-></normal><datatype>stack</datatype><normal>([]);</normal><normal>
</normal><normal>	} </normal><keyword>else</keyword><normal> {</normal><normal>
</normal><normal>		</normal><keyword>my</keyword><normal> </normal><datatype>$plug</datatype><normal>	= </normal><datatype>$self</datatype><normal>-></normal><datatype>pluginGet</datatype><normal>(</normal><datatype>$lang</datatype><normal>);</normal><normal>
</normal><normal>		</normal><keyword>my</keyword><normal> </normal><datatype>$basecontext</datatype><normal> = </normal><datatype>$plug</datatype><normal>-></normal><datatype>basecontext</datatype><normal>;</normal><normal>
</normal><normal>		</normal><datatype>$self</datatype><normal>-></normal><datatype>stack</datatype><normal>([</normal><normal>
</normal><normal>			[</normal><datatype>$plug</datatype><normal>, </normal><datatype>$basecontext</datatype><normal>]</normal><normal>
</normal><normal>		]);</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><datatype>$self</datatype><normal>-></normal><datatype>out</datatype><normal>([]);</normal><normal>
</normal><normal>	</normal><datatype>$self</datatype><normal>-></normal><datatype>snippet</datatype><normal>(</normal><operator>''</operator><normal>);</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>sections</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>sections</string><operator>'</operator><normal>};</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>syntaxes</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>syntaxes</string><operator>'</operator><normal>}</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><normal>
</normal><float>1</float><normal>;</normal><normal>
</normal><normal>
</normal><keyword>__END__</keyword><normal>
</normal><normal>
</normal><comment>=head1 NAME</comment><comment>
</comment><comment>
</comment><comment>Syntax::Highlight::Engine::Kate - a port to Perl of the syntax highlight engine of the Kate texteditor.</comment><comment>
</comment><comment>
</comment><comment>=head1 SYNOPSIS</comment><comment>
</comment><comment>
</comment><comment> #if you want to create a compiled executable, you may want to do this:</comment><comment>
</comment><comment> use Syntax::Highlight::Engine::Kate::All;</comment><comment>
</comment><comment> </comment><comment>
</comment><comment> use Syntax::Highlight::Engine::Kate;</comment><comment>
</comment><comment> my $hl = new Syntax::Highlight::Engine::Kate(</comment><comment>
</comment><comment>    language => 'Perl',</comment><comment>
</comment><comment>    substitutions => {</comment><comment>
</comment><comment>       "<" => "&lt;",</comment><comment>
</comment><comment>       ">" => "&gt;",</comment><comment>
</comment><comment>       "&" => "&amp;",</comment><comment>
</comment><comment>       " " => "&nbsp;",</comment><comment>
</comment><comment>       "\t" => "&nbsp;&nbsp;&nbsp;",</comment><comment>
</comment><comment>       "\n" => "<BR>\n",</comment><comment>
</comment><comment>    },</comment><comment>
</comment><comment>    format_table => {</comment><comment>
</comment><comment>       Alert => ["<font color=\"#0000ff\">", "</font>"],</comment><comment>
</comment><comment>       BaseN => ["<font color=\"#007f00\">", "</font>"],</comment><comment>
</comment><comment>       BString => ["<font color=\"#c9a7ff\">", "</font>"],</comment><comment>
</comment><comment>       Char => ["<font color=\"#ff00ff\">", "</font>"],</comment><comment>
</comment><comment>       Comment => ["<font color=\"#7f7f7f\"><i>", "</i></font>"],</comment><comment>
</comment><comment>       DataType => ["<font color=\"#0000ff\">", "</font>"],</comment><comment>
</comment><comment>       DecVal => ["<font color=\"#00007f\">", "</font>"],</comment><comment>
</comment><comment>       Error => ["<font color=\"#ff0000\"><b><i>", "</i></b></font>"],</comment><comment>
</comment><comment>       Float => ["<font color=\"#00007f\">", "</font>"],</comment><comment>
</comment><comment>       Function => ["<font color=\"#007f00\">", "</font>"],</comment><comment>
</comment><comment>       IString => ["<font color=\"#ff0000\">", ""],</comment><comment>
</comment><comment>       Keyword => ["<b>", "</b>"],</comment><comment>
</comment><comment>       Normal => ["", ""],</comment><comment>
</comment><comment>       Operator => ["<font color=\"#ffa500\">", "</font>"],</comment><comment>
</comment><comment>       Others => ["<font color=\"#b03060\">", "</font>"],</comment><comment>
</comment><comment>       RegionMarker => ["<font color=\"#96b9ff\"><i>", "</i></font>"],</comment><comment>
</comment><comment>       Reserved => ["<font color=\"#9b30ff\"><b>", "</b></font>"],</comment><comment>
</comment><comment>       String => ["<font color=\"#ff0000\">", "</font>"],</comment><comment>
</comment><comment>       Variable => ["<font color=\"#0000ff\"><b>", "</b></font>"],</comment><comment>
</comment><comment>       Warning => ["<font color=\"#0000ff\"><b><i>", "</b></i></font>"],</comment><comment>
</comment><comment>    },</comment><comment>
</comment><comment> );</comment><comment>
</comment><comment> </comment><comment>
</comment><comment> #or</comment><comment>
</comment><comment> </comment><comment>
</comment><comment> my $hl = new Syntax::Highlight::Engine::Kate::Perl(</comment><comment>
</comment><comment>    substitutions => {</comment><comment>
</comment><comment>       "<" => "&lt;",</comment><comment>
</comment><comment>       ">" => "&gt;",</comment><comment>
</comment><comment>       "&" => "&amp;",</comment><comment>
</comment><comment>       " " => "&nbsp;",</comment><comment>
</comment><comment>       "\t" => "&nbsp;&nbsp;&nbsp;",</comment><comment>
</comment><comment>       "\n" => "<BR>\n",</comment><comment>
</comment><comment>    },</comment><comment>
</comment><comment>    format_table => {</comment><comment>
</comment><comment>       Alert => ["<font color=\"#0000ff\">", "</font>"],</comment><comment>
</comment><comment>       BaseN => ["<font color=\"#007f00\">", "</font>"],</comment><comment>
</comment><comment>       BString => ["<font color=\"#c9a7ff\">", "</font>"],</comment><comment>
</comment><comment>       Char => ["<font color=\"#ff00ff\">", "</font>"],</comment><comment>
</comment><comment>       Comment => ["<font color=\"#7f7f7f\"><i>", "</i></font>"],</comment><comment>
</comment><comment>       DataType => ["<font color=\"#0000ff\">", "</font>"],</comment><comment>
</comment><comment>       DecVal => ["<font color=\"#00007f\">", "</font>"],</comment><comment>
</comment><comment>       Error => ["<font color=\"#ff0000\"><b><i>", "</i></b></font>"],</comment><comment>
</comment><comment>       Float => ["<font color=\"#00007f\">", "</font>"],</comment><comment>
</comment><comment>       Function => ["<font color=\"#007f00\">", "</font>"],</comment><comment>
</comment><comment>       IString => ["<font color=\"#ff0000\">", ""],</comment><comment>
</comment><comment>       Keyword => ["<b>", "</b>"],</comment><comment>
</comment><comment>       Normal => ["", ""],</comment><comment>
</comment><comment>       Operator => ["<font color=\"#ffa500\">", "</font>"],</comment><comment>
</comment><comment>       Others => ["<font color=\"#b03060\">", "</font>"],</comment><comment>
</comment><comment>       RegionMarker => ["<font color=\"#96b9ff\"><i>", "</i></font>"],</comment><comment>
</comment><comment>       Reserved => ["<font color=\"#9b30ff\"><b>", "</b></font>"],</comment><comment>
</comment><comment>       String => ["<font color=\"#ff0000\">", "</font>"],</comment><comment>
</comment><comment>       Variable => ["<font color=\"#0000ff\"><b>", "</b></font>"],</comment><comment>
</comment><comment>       Warning => ["<font color=\"#0000ff\"><b><i>", "</b></i></font>"],</comment><comment>
</comment><comment>    },</comment><comment>
</comment><comment> );</comment><comment>
</comment><comment> </comment><comment>
</comment><comment> </comment><comment>
</comment><comment> print "<html>\n<head>\n</head>\n<body>\n";</comment><comment>
</comment><comment> while (my $in = <>) {</comment><comment>
</comment><comment>    print $hl->highlightText($in);</comment><comment>
</comment><comment> }</comment><comment>
</comment><comment> print "</body>\n</html>\n";</comment><comment>
</comment><comment>
</comment><comment>=head1 DESCRIPTION</comment><comment>
</comment><comment>
</comment><comment>Syntax::Highlight::Engine::Kate is a port to perl of the syntax highlight engine of the </comment><comment>
</comment><comment>Kate text editor.</comment><comment>
</comment><comment>
</comment><comment>The language xml files of kate have been rewritten to perl modules using a script. These modules </comment><comment>
</comment><comment>function as plugins to this module.</comment><comment>
</comment><comment>
</comment><comment>Syntax::Highlight::Engine::Kate inherits Syntax::Highlight::Engine::Kate::Template.</comment><comment>
</comment><comment>
</comment><comment>=head1 OPTIONS</comment><comment>
</comment><comment>
</comment><comment>=over 4</comment><comment>
</comment><comment>
</comment><comment>=item B<language></comment><comment>
</comment><comment>
</comment><comment>Specify the language you want highlighted.</comment><comment>
</comment><comment>look in the B<PLUGINS> section for supported languages.</comment><comment>
</comment><comment>
</comment><comment>
</comment><comment>
</comment><comment>=item B<plugins></comment><comment>
</comment><comment>
</comment><comment>If you created your own language plugins you may specify a list of them with this option.</comment><comment>
</comment><comment>
</comment><comment> plugins => [</comment><comment>
</comment><comment>   ["MyModuleName", "MyLanguageName", "*,ext1;*.ext2", "Section"],</comment><comment>
</comment><comment>   ....</comment><comment>
</comment><comment> ]</comment><comment>
</comment><comment>
</comment><comment>=item B<format_table></comment><comment>
</comment><comment>
</comment><comment>This option must be specified if the B<highlightText> method needs to do anything useful for you.</comment><comment>
</comment><comment>All mentioned keys in the synopsis must be specified.</comment><comment>
</comment><comment>
</comment><comment>
</comment><comment>=item B<substitutions></comment><comment>
</comment><comment>
</comment><comment>With this option you can specify additional formatting options.</comment><comment>
</comment><comment>
</comment><comment>
</comment><comment>=back

=head1 METHODS</comment><comment>
</comment><comment>
</comment><comment>=over 4</comment><comment>
</comment><comment>
</comment><comment>=item B<extensions></comment><comment>
</comment><comment>
</comment><comment>returns a reference to the extensions hash,</comment><comment>
</comment><comment>
</comment><comment>=item B<language>(I<?$language?>)</comment><comment>
</comment><comment>
</comment><comment>Sets and returns the current language that is highlighted. when setting the language a reset is also done.</comment><comment>
</comment><comment>
</comment><comment>=item B<languageAutoSet>(I<$filename>);</comment><comment>
</comment><comment>
</comment><comment>Suggests language name for the fiven file B<$filename></comment><comment>
</comment><comment>
</comment><comment>=item B<languageList></comment><comment>
</comment><comment>
</comment><comment>returns a list of languages for which plugins have been defined.</comment><comment>
</comment><comment>
</comment><comment>=item B<languagePlug>(I<$language>);</comment><comment>
</comment><comment>
</comment><comment>returns the module name of the plugin for B<$language></comment><comment>
</comment><comment>
</comment><comment>=item B<languagePropose>(I<$filename>);</comment><comment>
</comment><comment>
</comment><comment>Suggests language name for the fiven file B<$filename></comment><comment>
</comment><comment>
</comment><comment>=item B<sections></comment><comment>
</comment><comment>
</comment><comment>Returns a reference to the sections hash.</comment><comment>
</comment><comment>
</comment><comment>=back

=head1 ATTRIBUTES</comment><comment>
</comment><comment>
</comment><comment>In the kate XML syntax files you find under the section B<<itemDatas>> entries like </comment><comment>
</comment><comment><itemData name="Unknown Property"  defStyleNum="dsError" italic="1"/>. Kate is an editor</comment><comment>
</comment><comment>so it is ok to have definitions for forground and background colors and so on. However, </comment><comment>
</comment><comment>since this Module is supposed to be a more universal highlight engine, the attributes need</comment><comment>
</comment><comment>to be fully abstract. In which case, Kate does not have enough default attributes defined</comment><comment>
</comment><comment>to fullfill all needs. Kate defines the following standard attributes: B<dsNormal>, B<dsKeyword>, </comment><comment>
</comment><comment>B<dsDataType>, B<dsDecVal>, B<dsBaseN>, B<dsFloat>, B<dsChar>, B<dsString>, B<dsComment>, B<dsOthers>, </comment><comment>
</comment><comment>B<dsAlert>, B<dsFunction>, B<dsRegionMarker>, B<dsError>. This module leaves out the "ds" part and uses </comment><comment>
</comment><comment>following additional attributes: B<BString>, B<IString>, B<Operator>, B<Reserved>, B<Variable>. I have </comment><comment>
</comment><comment>modified the XML files so that each highlight mode would get it's own attribute. In quite a few cases</comment><comment>
</comment><comment>still not enough attributes were defined. So in some languages different modes have the same attribute.</comment><comment>
</comment><comment>
</comment><comment>=head1 PLUGINS</comment><comment>
</comment><comment>
</comment><comment>Below an overview of existing plugins. All have been tested on use and can be created. The ones for which no samplefile</comment><comment>
</comment><comment>is available are marked. Those marked OK have highlighted the testfile without appearant mistakes. This does</comment><comment>
</comment><comment>not mean that all bugs are shaken out. </comment><comment>
</comment><comment>
</comment><comment> LANGUAGE             MODULE                   COMMENT</comment><comment>
</comment><comment> ********             ******                   ******</comment><comment>
</comment><comment> .desktop             Desktop                  OK</comment><comment>
</comment><comment> 4GL                  FourGL                   No sample file</comment><comment>
</comment><comment> 4GL-PER              FourGLminusPER           No sample file</comment><comment>
</comment><comment> ABC                  ABC                      OK</comment><comment>
</comment><comment> AHDL                 AHDL                     OK</comment><comment>
</comment><comment> ANSI C89             ANSI_C89                 No sample file</comment><comment>
</comment><comment> ASP                  ASP                      OK</comment><comment>
</comment><comment> AVR Assembler        AVR_Assembler            OK</comment><comment>
</comment><comment> AWK                  AWK                      OK</comment><comment>
</comment><comment> Ada                  Ada                      No sample file</comment><comment>
</comment><comment>                      Alerts                   OK hidden module</comment><comment>
</comment><comment> Ansys                Ansys                    No sample file</comment><comment>
</comment><comment> Apache Configuration Apache_Configuration     No sample file</comment><comment>
</comment><comment> Asm6502              Asm6502                  No sample file</comment><comment>
</comment><comment> Bash                 Bash                     OK</comment><comment>
</comment><comment> BibTeX               BibTeX                   OK</comment><comment>
</comment><comment> C                    C                        No sample file</comment><comment>
</comment><comment> C#                   Cdash                    No sample file</comment><comment>
</comment><comment> C++                  Cplusplus                OK</comment><comment>
</comment><comment> CGiS                 CGiS                     No sample file</comment><comment>
</comment><comment> CMake                CMake                    OK</comment><comment>
</comment><comment> CSS                  CSS                      OK</comment><comment>
</comment><comment> CUE Sheet            CUE_Sheet                No sample file</comment><comment>
</comment><comment> Cg                   Cg                       No sample file</comment><comment>
</comment><comment> ChangeLog            ChangeLog                No sample file</comment><comment>
</comment><comment> Cisco                Cisco                    No sample file</comment><comment>
</comment><comment> Clipper              Clipper                  OK</comment><comment>
</comment><comment> ColdFusion           ColdFusion               No sample file</comment><comment>
</comment><comment> Common Lisp          Common_Lisp              OK</comment><comment>
</comment><comment> Component-Pascal     ComponentminusPascal     No sample file</comment><comment>
</comment><comment> D                    D                        No sample file</comment><comment>
</comment><comment> Debian Changelog     Debian_Changelog         No sample file</comment><comment>
</comment><comment> Debian Control       Debian_Control           No sample file</comment><comment>
</comment><comment> Diff                 Diff                     No sample file</comment><comment>
</comment><comment> Doxygen              Doxygen                  OK</comment><comment>
</comment><comment> E Language           E_Language               OK</comment><comment>
</comment><comment> Eiffel               Eiffel                   No sample file</comment><comment>
</comment><comment> Email                Email                    OK</comment><comment>
</comment><comment> Euphoria             Euphoria                 OK</comment><comment>
</comment><comment> Fortran              Fortran                  OK</comment><comment>
</comment><comment> FreeBASIC            FreeBASIC                No sample file</comment><comment>
</comment><comment> GDL                  GDL                      No sample file</comment><comment>
</comment><comment> GLSL                 GLSL                     OK</comment><comment>
</comment><comment> GNU Assembler        GNU_Assembler            No sample file</comment><comment>
</comment><comment> GNU Gettext          GNU_Gettext              No sample file</comment><comment>
</comment><comment> HTML                 HTML                     OK</comment><comment>
</comment><comment> Haskell              Haskell                  OK</comment><comment>
</comment><comment> IDL                  IDL                      No sample file</comment><comment>
</comment><comment> ILERPG               ILERPG                   No sample file</comment><comment>
</comment><comment> INI Files            INI_Files                No sample file</comment><comment>
</comment><comment> Inform               Inform                   No sample file</comment><comment>
</comment><comment> Intel x86 (NASM)     Intel_X86_NASM           seems to have issues</comment><comment>
</comment><comment> JSP                  JSP                      OK</comment><comment>
</comment><comment> Java                 Java                     OK</comment><comment>
</comment><comment> JavaScript           JavaScript               OK</comment><comment>
</comment><comment> Javadoc              Javadoc                  No sample file</comment><comment>
</comment><comment> KBasic               KBasic                   No sample file</comment><comment>
</comment><comment> Kate File Template   Kate_File_Template       No sample file</comment><comment>
</comment><comment> LDIF                 LDIF                     No sample file</comment><comment>
</comment><comment> LPC                  LPC                      No sample file</comment><comment>
</comment><comment> LaTeX                LaTex                    OK</comment><comment>
</comment><comment> Lex/Flex             Lex_Flex                 OK</comment><comment>
</comment><comment> LilyPond             LilyPond                 OK</comment><comment>
</comment><comment> Literate Haskell     Literate_Haskell         OK</comment><comment>
</comment><comment> Lua                  Lua                      No sample file</comment><comment>
</comment><comment> M3U                  M3U                      OK</comment><comment>
</comment><comment> MAB-DB               MABminusDB               No sample file</comment><comment>
</comment><comment> MIPS Assembler       MIPS_Assembler           No sample file</comment><comment>
</comment><comment> Makefile             Makefile                 No sample file</comment><comment>
</comment><comment> Mason                Mason                    No sample file</comment><comment>
</comment><comment> Matlab               Matlab                   has issues</comment><comment>
</comment><comment> Modula-2             Modulaminus2             No sample file</comment><comment>
</comment><comment> Music Publisher      Music_Publisher          No sample file</comment><comment>
</comment><comment> Octave               Octave                   OK</comment><comment>
</comment><comment> PHP (HTML)           PHP_HTML                 OK</comment><comment>
</comment><comment>                      PHP_PHP                  OK hidden module</comment><comment>
</comment><comment> POV-Ray              POV_Ray                  OK</comment><comment>
</comment><comment> Pascal               Pascal                   No sample file</comment><comment>
</comment><comment> Perl                 Perl                     OK</comment><comment>
</comment><comment> PicAsm               PicAsm                   OK</comment><comment>
</comment><comment> Pike                 Pike                     OK</comment><comment>
</comment><comment> PostScript           PostScript               OK</comment><comment>
</comment><comment> Prolog               Prolog                   No sample file</comment><comment>
</comment><comment> PureBasic            PureBasic                OK</comment><comment>
</comment><comment> Python               Python                   OK</comment><comment>
</comment><comment> Quake Script         Quake_Script             No sample file</comment><comment>
</comment><comment> R Script             R_Script                 No sample file</comment><comment>
</comment><comment> REXX                 REXX                     No sample file</comment><comment>
</comment><comment> RPM Spec             RPM_Spec                 No sample file</comment><comment>
</comment><comment> RSI IDL              RSI_IDL                  No sample file</comment><comment>
</comment><comment> RenderMan RIB        RenderMan_RIB            OK</comment><comment>
</comment><comment> Ruby                 Ruby                     OK</comment><comment>
</comment><comment> SGML                 SGML                     No sample file</comment><comment>
</comment><comment> SML                  SML                      No sample file</comment><comment>
</comment><comment> SQL                  SQL                      No sample file</comment><comment>
</comment><comment> SQL (MySQL)          SQL_MySQL                No sample file</comment><comment>
</comment><comment> SQL (PostgreSQL)     SQL_PostgreSQL           No sample file</comment><comment>
</comment><comment> Sather               Sather                   No sample file</comment><comment>
</comment><comment> Scheme               Scheme                   OK</comment><comment>
</comment><comment> Sieve                Sieve                    No sample file</comment><comment>
</comment><comment> Spice                Spice                    OK</comment><comment>
</comment><comment> Stata                Stata                    OK</comment><comment>
</comment><comment> TI Basic             TI_Basic                 No sample file</comment><comment>
</comment><comment> TaskJuggler          TaskJuggler              No sample file</comment><comment>
</comment><comment> Tcl/Tk               TCL_Tk                   OK</comment><comment>
</comment><comment> UnrealScript         UnrealScript             OK</comment><comment>
</comment><comment> VHDL                 VHDL                     No sample file</comment><comment>
</comment><comment> VRML                 VRML                     OK</comment><comment>
</comment><comment> Velocity             Velocity                 No sample file</comment><comment>
</comment><comment> Verilog              Verilog                  No sample file</comment><comment>
</comment><comment> WINE Config          WINE_Config              No sample file</comment><comment>
</comment><comment> Wikimedia            Wikimedia                No sample file</comment><comment>
</comment><comment> XML                  XML                      OK</comment><comment>
</comment><comment> XML (Debug)          XML_Debug                No sample file</comment><comment>
</comment><comment> Yacc/Bison           Yacc_Bison               OK</comment><comment>
</comment><comment> de_DE                De_DE                    No sample file</comment><comment>
</comment><comment> en_EN                En_EN                    No sample file</comment><comment>
</comment><comment> ferite               Ferite                   No sample file</comment><comment>
</comment><comment> nl                   Nl                       No sample file</comment><comment>
</comment><comment> progress             Progress                 No sample file</comment><comment>
</comment><comment> scilab               Scilab                   No sample file</comment><comment>
</comment><comment> txt2tags             Txt2tags                 No sample file</comment><comment>
</comment><comment> x.org Configuration  X_org_Configuration      OK</comment><comment>
</comment><comment> xHarbour             XHarbour                 OK</comment><comment>
</comment><comment> xslt                 Xslt                     No sample file</comment><comment>
</comment><comment> yacas                Yacas                    No sample file</comment><comment>
</comment><comment>
</comment><comment>
</comment><comment>=head1 BUGS</comment><comment>
</comment><comment>
</comment><comment>Float is detected differently than in the Kate editor.</comment><comment>
</comment><comment>
</comment><comment>The regular expression engine of the Kate editor, qregexp, appears to be more tolerant to mistakes</comment><comment>
</comment><comment>in regular expressions than perl. This might lead to error messages and differences in behaviour. </comment><comment>
</comment><comment>Most of the problems were sorted out while developing, because error messages appeared. For as far</comment><comment>
</comment><comment>as differences in behaviour is concerned, testing is the only way to find out, so i hope the users</comment><comment>
</comment><comment>out there will be able to tell me more.</comment><comment>
</comment><comment>
</comment><comment>This module is mimicking the behaviour of the syntax highlight engine of the Kate editor. If you find</comment><comment>
</comment><comment>a bug/mistake in the highlighting, please check if Kate behaves in the same way. If yes, the cause is</comment><comment>
</comment><comment>likely to be found there.</comment><comment>
</comment><comment>
</comment><comment>=head1 TO DO</comment><comment>
</comment><comment>
</comment><comment>Rebuild the scripts i am using to generate the modules from xml files so they are more pro-actively tracking</comment><comment>
</comment><comment>flaws in the build of the xml files like missing lists. Also regular expressions in the xml can be tested better </comment><comment>
</comment><comment>before used in plugins.</comment><comment>
</comment><comment>
</comment><comment>Refine the testmethods in Syntax::Highlight::Engine::Kate::Template, so that choices for casesensitivity, </comment><comment>
</comment><comment>dynamic behaviour and lookahead can be determined at generate time of the plugin, might increase throughput.</comment><comment>
</comment><comment>
</comment><comment>Implement codefolding.</comment><comment>
</comment><comment>
</comment><comment>=head1 ACKNOWLEDGEMENTS</comment><comment>
</comment><comment>
</comment><comment>All the people who wrote Kate and the syntax highlight xml files.</comment><comment>
</comment><comment>
</comment><comment>=head1 AUTHOR AND COPYRIGHT</comment><comment>
</comment><comment>
</comment><comment>This module is written and maintained by:</comment><comment>
</comment><comment>
</comment><comment>Hans Jeuken < haje at toneel dot demon dot nl ></comment><comment>
</comment><comment>
</comment><comment>Copyright (c) 2006 by Hans Jeuken, all rights reserved.</comment><comment>
</comment><comment>
</comment><comment>You may freely distribute and/or modify this module under the same terms </comment><comment>
</comment><comment>as Perl itself. </comment><comment>
</comment><comment>
</comment><comment>=head1 SEE ALSO</comment><comment>
</comment><comment>
</comment><comment>Syntax::Highlight::Engine::Kate::Template http:://www.kate-editor.org</comment><comment>
</comment><comment>
</comment><comment>=cut</comment><comment>
</comment><comment>
</comment>
