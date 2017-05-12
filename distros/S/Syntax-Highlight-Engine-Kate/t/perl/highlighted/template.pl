<comment># Copyright (c) 2006 Hans Jeuken. All rights reserved.</comment><comment>
</comment><comment># This program is free software; you can redistribute it and/or</comment><comment>
</comment><comment># modify it under the same terms as Perl itself.</comment><comment>
</comment><normal>
</normal><keyword>package</keyword><normal> </normal><function>Syntax::Highlight</function><normal>::</normal><function>Engine</function><normal>::</normal><function>Kate</function><normal>::</normal><function>Template</function><normal>;</normal><normal>
</normal><normal>
</normal><keyword>our</keyword><normal> </normal><datatype>$VERSION</datatype><normal> = </normal><operator>'</operator><string>0.06</string><operator>'</operator><normal>;</normal><normal>
</normal><normal>
</normal><keyword>use</keyword><normal> </normal><keyword>strict</keyword><normal>;</normal><normal>
</normal><keyword>use</keyword><normal> Carp </normal><operator>qw(</operator><normal>cluck</normal><operator>)</operator><normal>;</normal><normal>
</normal><keyword>use</keyword><normal> </normal><function>Data::Dumper</function><normal>;</normal><normal>
</normal><normal>
</normal><comment>#my $regchars = '\\^.$|()[]*+?';</comment><comment>
</comment><normal>
</normal><keyword>sub </keyword><function>new</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$proto</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$class</datatype><normal> = </normal><function>ref</function><normal>(</normal><datatype>$proto</datatype><normal>) || </normal><datatype>$proto</datatype><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>%args</datatype><normal> = (</normal><datatype>@_</datatype><normal>);</normal><normal>
</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$debug</datatype><normal> = </normal><function>delete</function><normal> </normal><datatype>$args</datatype><normal>{</normal><operator>'</operator><string>debug</string><operator>'</operator><normal>};</normal><normal>
</normal><normal>	</normal><keyword>unless</keyword><normal> (</normal><function>defined</function><normal>(</normal><datatype>$debug</datatype><normal>)) { </normal><datatype>$debug</datatype><normal> = 0 };</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$substitutions</datatype><normal> = </normal><function>delete</function><normal> </normal><datatype>$args</datatype><normal>{</normal><operator>'</operator><string>substitutions</string><operator>'</operator><normal>};</normal><normal>
</normal><normal>	</normal><keyword>unless</keyword><normal> (</normal><function>defined</function><normal>(</normal><datatype>$substitutions</datatype><normal>)) { </normal><datatype>$substitutions</datatype><normal> = {} };</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$formattable</datatype><normal> = </normal><function>delete</function><normal> </normal><datatype>$args</datatype><normal>{</normal><operator>'</operator><string>format_table</string><operator>'</operator><normal>};</normal><normal>
</normal><normal>	</normal><keyword>unless</keyword><normal> (</normal><function>defined</function><normal>(</normal><datatype>$formattable</datatype><normal>)) { </normal><datatype>$formattable</datatype><normal> = {} };</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$engine</datatype><normal> = </normal><function>delete</function><normal> </normal><datatype>$args</datatype><normal>{</normal><operator>'</operator><string>engine</string><operator>'</operator><normal>};</normal><normal>
</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = {};</normal><normal>
</normal><normal>	</normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>attributes</string><operator>'</operator><normal>} = {},</normal><normal>
</normal><normal>	</normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>captured</string><operator>'</operator><normal>} = [];</normal><normal>
</normal><normal>	</normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>contextdata</string><operator>'</operator><normal>} = {};</normal><normal>
</normal><normal>	</normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>basecontext</string><operator>'</operator><normal>} = </normal><operator>''</operator><normal>;</normal><normal>
</normal><normal>	</normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>debug</string><operator>'</operator><normal>} = </normal><datatype>$debug</datatype><normal>;</normal><normal>
</normal><normal>	</normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>deliminators</string><operator>'</operator><normal>} = </normal><operator>''</operator><normal>;</normal><normal>
</normal><normal>	</normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>engine</string><operator>'</operator><normal>} = </normal><operator>''</operator><normal>;</normal><normal>
</normal><normal>	</normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>format_table</string><operator>'</operator><normal>} = </normal><datatype>$formattable</datatype><normal>;</normal><normal>
</normal><normal>	</normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>keywordcase</string><operator>'</operator><normal>} = </normal><float>1</float><normal>;</normal><normal>
</normal><normal>	</normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>lastchar</string><operator>'</operator><normal>} = </normal><operator>''</operator><normal>;</normal><normal>
</normal><normal>	</normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>linesegment</string><operator>'</operator><normal>} = </normal><operator>''</operator><normal>;</normal><normal>
</normal><normal>	</normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>lists</string><operator>'</operator><normal>} = {};</normal><normal>
</normal><normal>	</normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>linestart</string><operator>'</operator><normal>} = </normal><float>1</float><normal>;</normal><normal>
</normal><normal>	</normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>out</string><operator>'</operator><normal>} = [];</normal><normal>
</normal><normal>	</normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>plugins</string><operator>'</operator><normal>} = {};</normal><normal>
</normal><normal>	</normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>snippet</string><operator>'</operator><normal>} = </normal><operator>''</operator><normal>;</normal><normal>
</normal><normal>	</normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>snippetattribute</string><operator>'</operator><normal>} = </normal><operator>''</operator><normal>;</normal><normal>
</normal><normal>	</normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>stack</string><operator>'</operator><normal>} = [];</normal><normal>
</normal><normal>	</normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>substitutions</string><operator>'</operator><normal>} = </normal><datatype>$substitutions</datatype><normal>;</normal><normal>
</normal><normal>	</normal><function>bless</function><normal> (</normal><datatype>$self</datatype><normal>, </normal><datatype>$class</datatype><normal>);</normal><normal>
</normal><normal>	</normal><keyword>unless</keyword><normal> (</normal><function>defined</function><normal> </normal><datatype>$engine</datatype><normal>) { </normal><datatype>$engine</datatype><normal> = </normal><datatype>$self</datatype><normal> };</normal><normal>
</normal><normal>	</normal><datatype>$self</datatype><normal>-></normal><datatype>engine</datatype><normal>(</normal><datatype>$engine</datatype><normal>);</normal><normal>
</normal><normal>	</normal><datatype>$self</datatype><normal>-></normal><datatype>initialize</datatype><normal>;</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><datatype>$self</datatype><normal>;</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>attributes</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>@_</datatype><normal>) { </normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>attributes</string><operator>'</operator><normal>} = </normal><function>shift</function><normal>; };</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>attributes</string><operator>'</operator><normal>};</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>basecontext</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>@_</datatype><normal>) { </normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>basecontext</string><operator>'</operator><normal>} = </normal><function>shift</function><normal>; };</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>basecontext</string><operator>'</operator><normal>};</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>captured</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> (</normal><datatype>$self</datatype><normal>, </normal><datatype>$c</datatype><normal>) = </normal><datatype>@_</datatype><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><function>defined</function><normal>(</normal><datatype>$c</datatype><normal>)) {</normal><normal>
</normal><normal>		</normal><keyword>my</keyword><normal> </normal><datatype>$t</datatype><normal> = </normal><datatype>$self</datatype><normal>-></normal><datatype>engine</datatype><normal>-></normal><datatype>stackTop</datatype><normal>;</normal><normal>
</normal><normal>		</normal><keyword>my</keyword><normal> </normal><datatype>$n</datatype><normal> = 0;</normal><normal>
</normal><normal>		</normal><keyword>my</keyword><normal> </normal><datatype>@o</datatype><normal> = ();</normal><normal>
</normal><normal>		</normal><keyword>while</keyword><normal> (</normal><function>defined</function><normal>(</normal><datatype>$c</datatype><normal>->[</normal><datatype>$n</datatype><normal>])) {</normal><normal>
</normal><normal>			</normal><function>push</function><normal> </normal><datatype>@o</datatype><normal>, </normal><datatype>$c</datatype><normal>->[</normal><datatype>$n</datatype><normal>];</normal><normal>
</normal><normal>			</normal><datatype>$n</datatype><normal> ++;</normal><normal>
</normal><normal>		}</normal><normal>
</normal><normal>		</normal><keyword>if</keyword><normal> (</normal><datatype>@o</datatype><normal>) {</normal><normal>
</normal><normal>			</normal><datatype>$t</datatype><normal>->[</normal><float>2</float><normal>] = \</normal><datatype>@o</datatype><normal>;</normal><normal>
</normal><normal>		}</normal><normal>
</normal><normal>	};</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>capturedGet</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> (</normal><datatype>$self</datatype><normal>, </normal><datatype>$num</datatype><normal>) = </normal><datatype>@_</datatype><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$s</datatype><normal> = </normal><datatype>$self</datatype><normal>-></normal><datatype>engine</datatype><normal>-></normal><datatype>stack</datatype><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><function>defined</function><normal>(</normal><datatype>$s</datatype><normal>->[</normal><float>1</float><normal>])) {</normal><normal>
</normal><normal>		</normal><keyword>my</keyword><normal> </normal><datatype>$c</datatype><normal> = </normal><datatype>$s</datatype><normal>->[</normal><float>1</float><normal>]</normal><operator>-</operator><normal>>[</normal><float>2</float><normal>];</normal><normal>
</normal><normal>		</normal><datatype>$num</datatype><normal> -</normal><operator>-</operator><normal>;</normal><normal>
</normal><normal>		</normal><keyword>if</keyword><normal> (</normal><function>defined</function><normal>(</normal><datatype>$c</datatype><normal>)) {</normal><normal>
</normal><normal>			</normal><keyword>if</keyword><normal> (</normal><function>defined</function><normal>(</normal><datatype>$c</datatype><normal>->[</normal><datatype>$num</datatype><normal>])) {</normal><normal>
</normal><normal>				</normal><keyword>my</keyword><normal> </normal><datatype>$r</datatype><normal> = </normal><datatype>$c</datatype><normal>->[</normal><datatype>$num</datatype><normal>];</normal><normal>
</normal><normal>				</normal><keyword>return</keyword><normal> </normal><datatype>$r</datatype><normal>;</normal><normal>
</normal><normal>			} </normal><keyword>else</keyword><normal> {</normal><normal>
</normal><normal>				</normal><function>warn</function><normal> </normal><operator>"</operator><string>capture number </string><datatype>$num</datatype><string> not defined</string><operator>"</operator><normal>;</normal><normal>
</normal><normal>			}</normal><normal>
</normal><normal>		} </normal><keyword>else</keyword><normal> {</normal><normal>
</normal><normal>			</normal><function>warn</function><normal> </normal><operator>"</operator><string>dynamic substitution is called for but nothing to substitute</string><char>\n</char><operator>"</operator><normal>;</normal><normal>
</normal><normal>			</normal><keyword>return</keyword><normal> </normal><function>undef</function><normal>;</normal><normal>
</normal><normal>		}</normal><normal>
</normal><normal>	} </normal><keyword>else</keyword><normal> {</normal><normal>
</normal><normal>		</normal><function>warn</function><normal> </normal><operator>"</operator><string>no parent context to take captures from</string><operator>"</operator><normal>;</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><comment>#sub captured {</comment><comment>
</comment><comment>#	my $self = shift;</comment><comment>
</comment><comment>#	if (@_) { </comment><comment>
</comment><comment>#		$self->{'captured'} = shift;</comment><comment>
</comment><comment>##		print Dumper($self->{'captured'});</comment><comment>
</comment><comment>#	};</comment><comment>
</comment><comment>#	return $self->{'captured'}</comment><comment>
</comment><comment>##	my ($self, $c) = @_;</comment><comment>
</comment><comment>##	if (defined($c)) {</comment><comment>
</comment><comment>##		my $t = $self->engine->stackTop;</comment><comment>
</comment><comment>##		my $n = 0;</comment><comment>
</comment><comment>##		my @o = ();</comment><comment>
</comment><comment>##		while (defined($c->[$n])) {</comment><comment>
</comment><comment>##			push @o, $c->[$n];</comment><comment>
</comment><comment>##			$n ++;</comment><comment>
</comment><comment>##		}</comment><comment>
</comment><comment>##		if (@o) {</comment><comment>
</comment><comment>##			$t->[2] = \@o;</comment><comment>
</comment><comment>##		}</comment><comment>
</comment><comment>##	};</comment><comment>
</comment><comment>#}</comment><comment>
</comment><comment>#</comment><comment>
</comment><comment>#sub capturedGet {</comment><comment>
</comment><comment>#	my ($self, $num) = @_;</comment><comment>
</comment><comment>#	my $s = $self->captured;</comment><comment>
</comment><comment>#	if (defined $s) {</comment><comment>
</comment><comment>#		$num --;</comment><comment>
</comment><comment>#		if (defined($s->[$num])) {</comment><comment>
</comment><comment>#			return $s->[$num];</comment><comment>
</comment><comment>#		} else {</comment><comment>
</comment><comment>#			$self->logwarning("capture number $num not defined");</comment><comment>
</comment><comment>#		}</comment><comment>
</comment><comment>#	} else {</comment><comment>
</comment><comment>#		$self->logwarning("dynamic substitution is called for but nothing to substitute");</comment><comment>
</comment><comment>#		return undef;</comment><comment>
</comment><comment>#	}</comment><comment>
</comment><comment>#}</comment><comment>
</comment><normal>
</normal><keyword>sub </keyword><function>capturedParse</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> (</normal><datatype>$self</datatype><normal>, </normal><datatype>$string</datatype><normal>, </normal><datatype>$mode</datatype><normal>) = </normal><datatype>@_</datatype><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$s</datatype><normal> = </normal><operator>''</operator><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><function>defined</function><normal>(</normal><datatype>$mode</datatype><normal>)) {</normal><normal>
</normal><normal>		</normal><keyword>if</keyword><normal> (</normal><datatype>$string</datatype><normal> =~ </normal><operator>s/</operator><char>^(</char><basen>\d</basen><char>)</char><operator>//</operator><normal>) {</normal><normal>
</normal><normal>			</normal><datatype>$s</datatype><normal> = </normal><datatype>$self</datatype><normal>-></normal><datatype>capturedGet</datatype><normal>(</normal><variable>$1</variable><normal>);</normal><normal>
</normal><normal>			</normal><keyword>if</keyword><normal> (</normal><datatype>$string</datatype><normal> </normal><operator>ne</operator><normal> </normal><operator>''</operator><normal>) {</normal><normal>
</normal><normal>				</normal><datatype>$self</datatype><normal>-></normal><datatype>logwarning</datatype><normal>(</normal><operator>"</operator><string>character class is longer then 1 character, ignoring the rest</string><operator>"</operator><normal>);</normal><normal>
</normal><normal>			}</normal><normal>
</normal><normal>		}</normal><normal>
</normal><normal>	} </normal><keyword>else</keyword><normal> {</normal><normal>
</normal><normal>		</normal><keyword>while</keyword><normal> (</normal><datatype>$string</datatype><normal> </normal><operator>ne</operator><normal> </normal><operator>''</operator><normal>) {</normal><normal>
</normal><normal>			</normal><keyword>if</keyword><normal> (</normal><datatype>$string</datatype><normal> =~ </normal><operator>s/</operator><char>^([^</char><basen>\%</basen><char>]*)</char><others>\%</others><char>(</char><basen>\d</basen><char>)</char><operator>//</operator><normal>) {</normal><normal>
</normal><normal>				</normal><keyword>my</keyword><normal> </normal><datatype>$r</datatype><normal> = </normal><datatype>$self</datatype><normal>-></normal><datatype>capturedGet</datatype><normal>(</normal><variable>$2</variable><normal>);</normal><normal>
</normal><normal>				</normal><keyword>if</keyword><normal> (</normal><datatype>$r</datatype><normal> </normal><operator>ne</operator><normal> </normal><operator>''</operator><normal>) {</normal><normal>
</normal><normal>					</normal><datatype>$s</datatype><normal> = </normal><datatype>$s</datatype><normal> . </normal><variable>$1</variable><normal> . </normal><datatype>$r</datatype><datatype>
</datatype><normal>				} </normal><keyword>else</keyword><normal> {</normal><normal>
</normal><normal>					</normal><datatype>$s</datatype><normal> = </normal><datatype>$s</datatype><normal> . </normal><variable>$1</variable><normal> . </normal><operator>'</operator><string>%</string><operator>'</operator><normal> . </normal><variable>$2</variable><normal>;</normal><normal>
</normal><normal>					</normal><datatype>$self</datatype><normal>-></normal><datatype>logwarning</datatype><normal>(</normal><operator>"</operator><string>target is an empty string</string><operator>"</operator><normal>);</normal><normal>
</normal><normal>				}</normal><normal>
</normal><normal>			} </normal><keyword>else</keyword><normal> {</normal><normal>
</normal><normal>				</normal><datatype>$string</datatype><normal> =~ </normal><operator>s/</operator><char>^(</char><others>.</others><char>)</char><operator>//</operator><normal>;</normal><normal>
</normal><normal>				</normal><datatype>$s</datatype><normal> = </normal><operator>"</operator><datatype>$s</datatype><variable>$1</variable><operator>"</operator><normal>;</normal><normal>
</normal><normal>			}</normal><normal>
</normal><normal>		}</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><datatype>$s</datatype><normal>;</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>column</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><function>length</function><normal>(</normal><datatype>$self</datatype><normal>-></normal><datatype>linesegment</datatype><normal>);</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>contextdata</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>@_</datatype><normal>) { </normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>contextdata</string><operator>'</operator><normal>} = </normal><function>shift</function><normal>; };</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>contextdata</string><operator>'</operator><normal>};</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>contextInfo</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> (</normal><datatype>$self</datatype><normal>, </normal><datatype>$context</datatype><normal>, </normal><datatype>$item</datatype><normal>) = </normal><datatype>@_</datatype><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal>  (</normal><function>exists</function><normal> </normal><datatype>$self</datatype><normal>-></normal><datatype>contextdata</datatype><normal>->{</normal><datatype>$context</datatype><normal>}) {</normal><normal>
</normal><normal>		</normal><keyword>my</keyword><normal> </normal><datatype>$c</datatype><normal> = </normal><datatype>$self</datatype><normal>-></normal><datatype>contextdata</datatype><normal>->{</normal><datatype>$context</datatype><normal>};</normal><normal>
</normal><normal>		</normal><keyword>if</keyword><normal> (</normal><function>exists</function><normal> </normal><datatype>$c</datatype><normal>->{</normal><datatype>$item</datatype><normal>}) {</normal><normal>
</normal><normal>			</normal><keyword>return</keyword><normal> </normal><datatype>$c</datatype><normal>->{</normal><datatype>$item</datatype><normal>}</normal><normal>
</normal><normal>		} </normal><keyword>else</keyword><normal> {</normal><normal>
</normal><normal>			</normal><keyword>return</keyword><normal> </normal><function>undef</function><normal>;</normal><normal>
</normal><normal>		}</normal><normal>
</normal><normal>	} </normal><keyword>else</keyword><normal> {</normal><normal>
</normal><normal>		</normal><datatype>$self</datatype><normal>-></normal><datatype>logwarning</datatype><normal>(</normal><operator>"</operator><string>undefined context '</string><datatype>$context</datatype><operator>'"</operator><normal>);</normal><normal>
</normal><normal>		</normal><keyword>return</keyword><normal> </normal><function>undef</function><normal>;</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>contextParse</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> (</normal><datatype>$self</datatype><normal>, </normal><datatype>$plug</datatype><normal>, </normal><datatype>$context</datatype><normal>) = </normal><datatype>@_</datatype><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>$context</datatype><normal> =~ </normal><operator>/</operator><char>^</char><others>#pop</others><operator>/i</operator><normal>) {</normal><normal>
</normal><normal>		</normal><keyword>while</keyword><normal> (</normal><datatype>$context</datatype><normal> =~ </normal><operator>s/</operator><others>#pop</others><operator>//i</operator><normal>) {</normal><normal>
</normal><normal>			</normal><datatype>$self</datatype><normal>-></normal><datatype>stackPull</datatype><normal>;</normal><normal>
</normal><normal>		}</normal><normal>
</normal><normal>	} </normal><keyword>elsif</keyword><normal> (</normal><datatype>$context</datatype><normal> =~ </normal><operator>/</operator><char>^</char><others>#stay</others><operator>/i</operator><normal>) {</normal><normal>
</normal><normal>		</normal><comment>#don't do anything </comment><comment>
</comment><normal>	} </normal><keyword>elsif</keyword><normal> (</normal><datatype>$context</datatype><normal> =~ </normal><operator>/</operator><char>^</char><others>##</others><char>(</char><others>.</others><char>+)</char><operator>/</operator><normal>) {</normal><normal>
</normal><normal>		</normal><keyword>my</keyword><normal> </normal><datatype>$new</datatype><normal> = </normal><datatype>$self</datatype><normal>-></normal><datatype>pluginGet</datatype><normal>(</normal><variable>$1</variable><normal>);</normal><normal>
</normal><normal>		</normal><datatype>$self</datatype><normal>-></normal><datatype>stackPush</datatype><normal>([</normal><datatype>$new</datatype><normal>, </normal><datatype>$new</datatype><normal>-></normal><datatype>basecontext</datatype><normal>]);</normal><normal>
</normal><normal>	} </normal><keyword>else</keyword><normal> {</normal><normal>
</normal><normal>		</normal><datatype>$self</datatype><normal>-></normal><datatype>stackPush</datatype><normal>([</normal><datatype>$plug</datatype><normal>, </normal><datatype>$context</datatype><normal>]);</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>debug</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>@_</datatype><normal>) { </normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>debug</string><operator>'</operator><normal>} = </normal><function>shift</function><normal>; };</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>debug</string><operator>'</operator><normal>};</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>debugTest</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>@_</datatype><normal>) { </normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>debugtest</string><operator>'</operator><normal>} = </normal><function>shift</function><normal>; };</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>debugtest</string><operator>'</operator><normal>};</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>deliminators</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>@_</datatype><normal>) { </normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>deliminators</string><operator>'</operator><normal>} = </normal><function>shift</function><normal>; };</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>deliminators</string><operator>'</operator><normal>};</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>engine</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>@_</datatype><normal>) { </normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>engine</string><operator>'</operator><normal>} = </normal><function>shift</function><normal>; };</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>engine</string><operator>'</operator><normal>};</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>firstnonspace</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> (</normal><datatype>$self</datatype><normal>, </normal><datatype>$string</datatype><normal>) = </normal><datatype>@_</datatype><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$line</datatype><normal> = </normal><datatype>$self</datatype><normal>-></normal><datatype>linesegment</datatype><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> ((</normal><datatype>$line</datatype><normal> =~ </normal><operator>/</operator><char>^</char><basen>\s</basen><char>*$</char><operator>/</operator><normal>) </normal><operator>and</operator><normal> (</normal><datatype>$string</datatype><normal> =~ </normal><operator>/</operator><char>^[^</char><basen>\s</basen><char>]</char><operator>/</operator><normal>)) {</normal><normal>
</normal><normal>		</normal><keyword>return</keyword><normal> </normal><float>1</float><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><operator>''</operator><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>formatTable</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>@_</datatype><normal>) { </normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>format_table</string><operator>'</operator><normal>} = </normal><function>shift</function><normal>; };</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>format_table</string><operator>'</operator><normal>};</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>highlight</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> (</normal><datatype>$self</datatype><normal>, </normal><datatype>$text</datatype><normal>) = </normal><datatype>@_</datatype><normal>;</normal><normal>
</normal><normal>	</normal><datatype>$self</datatype><normal>-></normal><datatype>snippet</datatype><normal>(</normal><operator>''</operator><normal>);</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$out</datatype><normal> = </normal><datatype>$self</datatype><normal>-></normal><datatype>out</datatype><normal>;</normal><normal>
</normal><normal>	</normal><datatype>@$out</datatype><normal> = ();</normal><normal>
</normal><normal>	</normal><keyword>while</keyword><normal> (</normal><datatype>$text</datatype><normal> </normal><operator>ne</operator><normal> </normal><operator>''</operator><normal>) {</normal><normal>
</normal><normal>		</normal><keyword>my</keyword><normal> </normal><datatype>$top</datatype><normal> = </normal><datatype>$self</datatype><normal>-></normal><datatype>stackTop</datatype><normal>;</normal><normal>
</normal><normal>		</normal><keyword>if</keyword><normal> (</normal><function>defined</function><normal>(</normal><datatype>$top</datatype><normal>)) {</normal><normal>
</normal><normal>			</normal><keyword>my</keyword><normal> (</normal><datatype>$plug</datatype><normal>, </normal><datatype>$context</datatype><normal>) = </normal><datatype>@$top</datatype><normal>;</normal><normal>
</normal><normal>			</normal><keyword>if</keyword><normal> (</normal><datatype>$text</datatype><normal> =~ </normal><operator>s/</operator><char>^(</char><basen>\n</basen><char>)</char><operator>//</operator><normal>) {</normal><normal>
</normal><normal>				</normal><datatype>$self</datatype><normal>-></normal><datatype>snippetForce</datatype><normal>;</normal><normal>
</normal><normal>				</normal><keyword>my</keyword><normal> </normal><datatype>$e</datatype><normal> = </normal><datatype>$plug</datatype><normal>-></normal><datatype>contextInfo</datatype><normal>(</normal><datatype>$context</datatype><normal>, </normal><operator>'</operator><string>lineending</string><operator>'</operator><normal>);</normal><normal>
</normal><normal>				</normal><keyword>if</keyword><normal> (</normal><function>defined</function><normal>(</normal><datatype>$e</datatype><normal>)) {</normal><normal>
</normal><normal>					</normal><datatype>$self</datatype><normal>-></normal><datatype>contextParse</datatype><normal>(</normal><datatype>$plug</datatype><normal>, </normal><datatype>$e</datatype><normal>)</normal><normal>
</normal><normal>				}</normal><normal>
</normal><normal>				</normal><keyword>my</keyword><normal> </normal><datatype>$attr</datatype><normal> = </normal><datatype>$plug</datatype><normal>-></normal><datatype>attributes</datatype><normal>->{</normal><datatype>$plug</datatype><normal>-></normal><datatype>contextInfo</datatype><normal>(</normal><datatype>$context</datatype><normal>, </normal><operator>'</operator><string>attribute</string><operator>'</operator><normal>)};</normal><normal>
</normal><normal>				</normal><datatype>$self</datatype><normal>-></normal><datatype>snippetParse</datatype><normal>(</normal><variable>$1</variable><normal>, </normal><datatype>$attr</datatype><normal>);</normal><normal>
</normal><normal>				</normal><datatype>$self</datatype><normal>-></normal><datatype>snippetForce</datatype><normal>;</normal><normal>
</normal><normal>				</normal><datatype>$self</datatype><normal>-></normal><datatype>linesegment</datatype><normal>(</normal><operator>''</operator><normal>);</normal><normal>
</normal><normal>				</normal><keyword>my</keyword><normal> </normal><datatype>$b</datatype><normal> = </normal><datatype>$plug</datatype><normal>-></normal><datatype>contextInfo</datatype><normal>(</normal><datatype>$context</datatype><normal>, </normal><operator>'</operator><string>linebeginning</string><operator>'</operator><normal>);</normal><normal>
</normal><normal>				</normal><keyword>if</keyword><normal> (</normal><function>defined</function><normal>(</normal><datatype>$b</datatype><normal>)) {</normal><normal>
</normal><normal>					</normal><datatype>$self</datatype><normal>-></normal><datatype>contextParse</datatype><normal>(</normal><datatype>$plug</datatype><normal>, </normal><datatype>$b</datatype><normal>)</normal><normal>
</normal><normal>				}</normal><normal>
</normal><normal>			} </normal><keyword>else</keyword><normal> {</normal><normal>
</normal><normal>				</normal><keyword>my</keyword><normal> </normal><datatype>$sub</datatype><normal> = </normal><datatype>$plug</datatype><normal>-></normal><datatype>contextInfo</datatype><normal>(</normal><datatype>$context</datatype><normal>, </normal><operator>'</operator><string>callback</string><operator>'</operator><normal>);</normal><normal>
</normal><normal>				</normal><keyword>my</keyword><normal> </normal><datatype>$result</datatype><normal> = &</normal><datatype>$sub</datatype><normal>(</normal><datatype>$plug</datatype><normal>, \</normal><datatype>$text</datatype><normal>);</normal><normal>
</normal><normal>				</normal><keyword>unless</keyword><normal>(</normal><datatype>$result</datatype><normal>) {</normal><normal>
</normal><normal>					</normal><keyword>my</keyword><normal> </normal><datatype>$f</datatype><normal> = </normal><datatype>$plug</datatype><normal>-></normal><datatype>contextInfo</datatype><normal>(</normal><datatype>$context</datatype><normal>, </normal><operator>'</operator><string>fallthrough</string><operator>'</operator><normal>);</normal><normal>
</normal><normal>					</normal><keyword>if</keyword><normal> (</normal><function>defined</function><normal>(</normal><datatype>$f</datatype><normal>)) {</normal><normal>
</normal><normal>						</normal><datatype>$self</datatype><normal>-></normal><datatype>contextParse</datatype><normal>(</normal><datatype>$plug</datatype><normal>, </normal><datatype>$f</datatype><normal>);</normal><normal>
</normal><normal>					} </normal><keyword>else</keyword><normal> {</normal><normal>
</normal><normal>						</normal><datatype>$text</datatype><normal> =~ </normal><operator>s/</operator><char>^(</char><others>.</others><char>)</char><operator>//</operator><normal>;</normal><normal>
</normal><normal>						</normal><keyword>my</keyword><normal> </normal><datatype>$attr</datatype><normal> = </normal><datatype>$plug</datatype><normal>-></normal><datatype>attributes</datatype><normal>->{</normal><datatype>$plug</datatype><normal>-></normal><datatype>contextInfo</datatype><normal>(</normal><datatype>$context</datatype><normal>, </normal><operator>'</operator><string>attribute</string><operator>'</operator><normal>)};</normal><normal>
</normal><normal>						</normal><datatype>$self</datatype><normal>-></normal><datatype>snippetParse</datatype><normal>(</normal><variable>$1</variable><normal>, </normal><datatype>$attr</datatype><normal>);</normal><normal>
</normal><normal>					}</normal><normal>
</normal><normal>				}</normal><normal>
</normal><normal>			}</normal><normal>
</normal><normal>		} </normal><keyword>else</keyword><normal> {</normal><normal>
</normal><normal>			</normal><function>push</function><normal> </normal><datatype>@$out</datatype><normal>, </normal><function>length</function><normal>(</normal><datatype>$text</datatype><normal>), </normal><operator>'</operator><string>Normal</string><operator>'</operator><normal>;</normal><normal>
</normal><normal>			</normal><datatype>$text</datatype><normal> = </normal><operator>''</operator><normal>;</normal><normal>
</normal><normal>		}</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><datatype>$self</datatype><normal>-></normal><datatype>snippetForce</datatype><normal>;</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><datatype>@$out</datatype><normal>;</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>highlightText</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> (</normal><datatype>$self</datatype><normal>, </normal><datatype>$text</datatype><normal>) = </normal><datatype>@_</datatype><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$res</datatype><normal> = </normal><operator>''</operator><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>@hl</datatype><normal> = </normal><datatype>$self</datatype><normal>-></normal><datatype>highlight</datatype><normal>(</normal><datatype>$text</datatype><normal>);</normal><normal>
</normal><normal>	</normal><keyword>while</keyword><normal> (</normal><datatype>@hl</datatype><normal>) {</normal><normal>
</normal><normal>		</normal><keyword>my</keyword><normal> </normal><datatype>$f</datatype><normal> = </normal><function>shift</function><normal> </normal><datatype>@hl</datatype><normal>;</normal><normal>
</normal><normal>		</normal><keyword>my</keyword><normal> </normal><datatype>$t</datatype><normal> = </normal><function>shift</function><normal> </normal><datatype>@hl</datatype><normal>;</normal><normal>
</normal><normal>		</normal><keyword>unless</keyword><normal> (</normal><function>defined</function><normal>(</normal><datatype>$t</datatype><normal>)) { </normal><datatype>$t</datatype><normal> = </normal><operator>'</operator><string>Normal</string><operator>'</operator><normal> }</normal><normal>
</normal><normal>		</normal><keyword>my</keyword><normal> </normal><datatype>$s</datatype><normal> = </normal><datatype>$self</datatype><normal>-></normal><datatype>substitutions</datatype><normal>;</normal><normal>
</normal><normal>		</normal><keyword>my</keyword><normal> </normal><datatype>$rr</datatype><normal> = </normal><operator>''</operator><normal>;</normal><normal>
</normal><normal>		</normal><keyword>while</keyword><normal> (</normal><datatype>$f</datatype><normal> </normal><operator>ne</operator><normal> </normal><operator>''</operator><normal>) {</normal><normal>
</normal><normal>			</normal><keyword>my</keyword><normal> </normal><datatype>$k</datatype><normal> = </normal><function>substr</function><normal>(</normal><datatype>$f</datatype><normal> , 0, </normal><float>1</float><normal>);</normal><normal>
</normal><normal>			</normal><datatype>$f</datatype><normal> = </normal><function>substr</function><normal>(</normal><datatype>$f</datatype><normal>, </normal><float>1</float><normal>, </normal><function>length</function><normal>(</normal><datatype>$f</datatype><normal>) </normal><decval>-1</decval><normal>);</normal><normal>
</normal><normal>			</normal><keyword>if</keyword><normal> (</normal><function>exists</function><normal> </normal><datatype>$s</datatype><normal>->{</normal><datatype>$k</datatype><normal>}) {</normal><normal>
</normal><normal>				 </normal><datatype>$rr</datatype><normal> = </normal><datatype>$rr</datatype><normal> . </normal><datatype>$s</datatype><normal>->{</normal><datatype>$k</datatype><normal>}</normal><normal>
</normal><normal>			} </normal><keyword>else</keyword><normal> {</normal><normal>
</normal><normal>				</normal><datatype>$rr</datatype><normal> = </normal><datatype>$rr</datatype><normal> . </normal><datatype>$k</datatype><normal>;</normal><normal>
</normal><normal>			}</normal><normal>
</normal><normal>		}</normal><normal>
</normal><normal>		</normal><keyword>my</keyword><normal> </normal><datatype>$rt</datatype><normal> = </normal><datatype>$self</datatype><normal>-></normal><datatype>formatTable</datatype><normal>;</normal><normal>
</normal><normal>		</normal><keyword>if</keyword><normal> (</normal><function>exists</function><normal> </normal><datatype>$rt</datatype><normal>->{</normal><datatype>$t</datatype><normal>}) {</normal><normal>
</normal><normal>			</normal><keyword>my</keyword><normal> </normal><datatype>$o</datatype><normal> = </normal><datatype>$rt</datatype><normal>->{</normal><datatype>$t</datatype><normal>};</normal><normal>
</normal><normal>			</normal><datatype>$res</datatype><normal> = </normal><datatype>$res</datatype><normal> . </normal><datatype>$o</datatype><normal>->[0] . </normal><datatype>$rr</datatype><normal> . </normal><datatype>$o</datatype><normal>->[</normal><float>1</float><normal>];</normal><normal>
</normal><normal>		} </normal><keyword>else</keyword><normal> {</normal><normal>
</normal><normal>			</normal><datatype>$res</datatype><normal> = </normal><datatype>$res</datatype><normal> . </normal><datatype>$rr</datatype><normal>;</normal><normal>
</normal><normal>			</normal><datatype>$self</datatype><normal>-></normal><datatype>logwarning</datatype><normal>(</normal><operator>"</operator><string>undefined format tag '</string><datatype>$t</datatype><operator>'"</operator><normal>);</normal><normal>
</normal><normal>		}</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><datatype>$res</datatype><normal>;</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>includePlugin</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> (</normal><datatype>$self</datatype><normal>, </normal><datatype>$language</datatype><normal>, </normal><datatype>$text</datatype><normal>) = </normal><datatype>@_</datatype><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$eng</datatype><normal> = </normal><datatype>$self</datatype><normal>-></normal><datatype>engine</datatype><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$plug</datatype><normal> = </normal><datatype>$eng</datatype><normal>-></normal><datatype>pluginGet</datatype><normal>(</normal><datatype>$language</datatype><normal>);</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><function>defined</function><normal>(</normal><datatype>$plug</datatype><normal>)) {</normal><normal>
</normal><normal>		</normal><keyword>my</keyword><normal> </normal><datatype>$context</datatype><normal> = </normal><datatype>$plug</datatype><normal>-></normal><datatype>basecontext</datatype><normal>;</normal><normal>
</normal><normal>		</normal><keyword>my</keyword><normal> </normal><datatype>$call</datatype><normal> = </normal><datatype>$plug</datatype><normal>-></normal><datatype>contextInfo</datatype><normal>(</normal><datatype>$context</datatype><normal>, </normal><operator>'</operator><string>callback</string><operator>'</operator><normal>);</normal><normal>
</normal><normal>		</normal><keyword>if</keyword><normal> (</normal><function>defined</function><normal>(</normal><datatype>$call</datatype><normal>)) {</normal><normal>
</normal><normal>			</normal><keyword>return</keyword><normal> &</normal><datatype>$call</datatype><normal>(</normal><datatype>$plug</datatype><normal>, </normal><datatype>$text</datatype><normal>);</normal><normal>
</normal><normal>		} </normal><keyword>else</keyword><normal> {</normal><normal>
</normal><normal>			</normal><datatype>$self</datatype><normal>-></normal><datatype>logwarning</datatype><normal>(</normal><operator>"</operator><string>cannot find callback for context '</string><datatype>$context</datatype><operator>'"</operator><normal>);</normal><normal>
</normal><normal>		}</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> 0;</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>includeRules</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> (</normal><datatype>$self</datatype><normal>, </normal><datatype>$context</datatype><normal>, </normal><datatype>$text</datatype><normal>) = </normal><datatype>@_</datatype><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$call</datatype><normal> = </normal><datatype>$self</datatype><normal>-></normal><datatype>contextInfo</datatype><normal>(</normal><datatype>$context</datatype><normal>, </normal><operator>'</operator><string>callback</string><operator>'</operator><normal>);</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><function>defined</function><normal>(</normal><datatype>$call</datatype><normal>)) {</normal><normal>
</normal><normal>		</normal><keyword>return</keyword><normal> &</normal><datatype>$call</datatype><normal>(</normal><datatype>$self</datatype><normal>, </normal><datatype>$text</datatype><normal>);</normal><normal>
</normal><normal>	} </normal><keyword>else</keyword><normal> {</normal><normal>
</normal><normal>		</normal><datatype>$self</datatype><normal>-></normal><datatype>logwarning</datatype><normal>(</normal><operator>"</operator><string>cannot find callback for context '</string><datatype>$context</datatype><operator>'"</operator><normal>);</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> 0;</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>initialize</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>$self</datatype><normal>-></normal><datatype>engine</datatype><normal> </normal><operator>eq</operator><normal> </normal><datatype>$self</datatype><normal>) {</normal><normal>
</normal><normal>		</normal><datatype>$self</datatype><normal>-></normal><datatype>stack</datatype><normal>([[</normal><datatype>$self</datatype><normal>, </normal><datatype>$self</datatype><normal>-></normal><datatype>basecontext</datatype><normal>]]);</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>keywordscase</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>@_</datatype><normal>) { </normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>keywordcase</string><operator>'</operator><normal>} = </normal><function>shift</function><normal>; }</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>keywordscase</string><operator>'</operator><normal>}</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>languagePlug</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> (</normal><datatype>$cw</datatype><normal>, </normal><datatype>$name</datatype><normal>) = </normal><datatype>@_</datatype><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>%numb</datatype><normal> = (</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>1</string><operator>'</operator><normal> => </normal><operator>'</operator><string>One</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>2</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Two</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>3</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Three</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>4</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Four</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>5</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Five</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>6</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Six</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>7</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Seven</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>8</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Eight</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>9</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Nine</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>		</normal><operator>'</operator><string>0</string><operator>'</operator><normal> => </normal><operator>'</operator><string>Zero</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>	);</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>$name</datatype><normal> =~ </normal><operator>s/</operator><char>^(</char><basen>\d</basen><char>)</char><operator>//</operator><normal>) {</normal><normal>
</normal><normal>		</normal><datatype>$name</datatype><normal> = </normal><datatype>$numb</datatype><normal>{</normal><variable>$1</variable><normal>} . </normal><datatype>$name</datatype><normal>;</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><datatype>$name</datatype><normal> =~ </normal><operator>s/</operator><others>\.</others><operator>//</operator><normal>;</normal><normal>
</normal><normal>	</normal><datatype>$name</datatype><normal> =~ </normal><operator>s/</operator><others>\+</others><operator>/</operator><string>plus</string><operator>/g</operator><normal>;</normal><normal>
</normal><normal>	</normal><datatype>$name</datatype><normal> =~ </normal><operator>s/</operator><others>\-</others><operator>/</operator><string>minus</string><operator>/g</operator><normal>;</normal><normal>
</normal><normal>	</normal><datatype>$name</datatype><normal> =~ </normal><operator>s/</operator><others>#</others><operator>/</operator><string>dash</string><operator>/g</operator><normal>;</normal><normal>
</normal><normal>	</normal><datatype>$name</datatype><normal> =~ </normal><operator>s/</operator><char>[^</char><basen>0-9a-zA-Z</basen><char>]</char><operator>/</operator><string>_</string><operator>/g</operator><normal>;</normal><normal>
</normal><normal>	</normal><datatype>$name</datatype><normal> =~ </normal><operator>s/</operator><others>__</others><operator>/</operator><string>_</string><operator>/g</operator><normal>;</normal><normal>
</normal><normal>	</normal><datatype>$name</datatype><normal> =~ </normal><operator>s/</operator><others>_</others><char>$</char><operator>//</operator><normal>;</normal><normal>
</normal><normal>	</normal><datatype>$name</datatype><normal> = </normal><function>ucfirst</function><normal>(</normal><datatype>$name</datatype><normal>);</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><datatype>$name</datatype><normal>;</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>lastchar</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$l</datatype><normal> = </normal><datatype>$self</datatype><normal>-></normal><datatype>linesegment</datatype><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>$l</datatype><normal> </normal><operator>eq</operator><normal> </normal><operator>''</operator><normal>) { </normal><keyword>return</keyword><normal> </normal><operator>"</operator><char>\n</char><operator>"</operator><normal> } </normal><comment>#last character was a newline</comment><comment>
</comment><normal>	</normal><keyword>return</keyword><normal> </normal><function>substr</function><normal>(</normal><datatype>$l</datatype><normal>, </normal><function>length</function><normal>(</normal><datatype>$l</datatype><normal>) </normal><operator>-</operator><normal> </normal><float>1</float><normal>, </normal><float>1</float><normal>);</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>lastcharDeliminator</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$deliminators</datatype><normal> = </normal><operator>'</operator><string>\s|\~|\!|\%|\^|\&|\*|\+|\(|\)|-|=|\{|\}|\[|\]|:|;|<|>|,|</string><char>\\</char><string>|\||\.|\?|\/</string><operator>'</operator><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>$self</datatype><normal>-></normal><datatype>linestart</datatype><normal> </normal><operator>or</operator><normal> (</normal><datatype>$self</datatype><normal>-></normal><datatype>lastchar</datatype><normal> =~ </normal><operator>/</operator><datatype>$deliminators</datatype><operator>/</operator><normal>))  {</normal><normal>
</normal><normal>		</normal><keyword>return</keyword><normal> </normal><float>1</float><normal>;</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><operator>''</operator><normal>;</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>linesegment</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>@_</datatype><normal>) { </normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>linesegment</string><operator>'</operator><normal>} = </normal><function>shift</function><normal>; };</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>linesegment</string><operator>'</operator><normal>};</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>linestart</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>$self</datatype><normal>-></normal><datatype>linesegment</datatype><normal> </normal><operator>eq</operator><normal> </normal><operator>''</operator><normal>) {</normal><normal>
</normal><normal>		</normal><keyword>return</keyword><normal> </normal><float>1</float><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><operator>''</operator><normal>;</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>lists</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>@_</datatype><normal>) { </normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>lists</string><operator>'</operator><normal>} = </normal><function>shift</function><normal>; }</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>lists</string><operator>'</operator><normal>}</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>out</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>@_</datatype><normal>) { </normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>out</string><operator>'</operator><normal>} = </normal><function>shift</function><normal>; }</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>out</string><operator>'</operator><normal>};</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>listAdd</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$listname</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$lst</datatype><normal> = </normal><datatype>$self</datatype><normal>-></normal><datatype>lists</datatype><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>@_</datatype><normal>) {</normal><normal>
</normal><normal>		</normal><keyword>my</keyword><normal> </normal><datatype>@l</datatype><normal> = </normal><function>reverse</function><normal> </normal><function>sort</function><normal> </normal><datatype>@_</datatype><normal>;</normal><normal>
</normal><normal>		</normal><datatype>$lst</datatype><normal>->{</normal><datatype>$listname</datatype><normal>} = \</normal><datatype>@l</datatype><normal>;</normal><normal>
</normal><normal>	} </normal><keyword>else</keyword><normal> {</normal><normal>
</normal><normal>		</normal><datatype>$lst</datatype><normal>->{</normal><datatype>$listname</datatype><normal>} = [];</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>logwarning</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> (</normal><datatype>$self</datatype><normal>, </normal><datatype>$warning</datatype><normal>) = </normal><datatype>@_</datatype><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$top</datatype><normal> = </normal><datatype>$self</datatype><normal>-></normal><datatype>engine</datatype><normal>-></normal><datatype>stackTop</datatype><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><function>defined</function><normal> </normal><datatype>$top</datatype><normal>) {</normal><normal>
</normal><normal>		</normal><keyword>my</keyword><normal> </normal><datatype>$lang</datatype><normal> = </normal><datatype>$top</datatype><normal>->[0]</normal><operator>-</operator><normal>>language;</normal><normal>
</normal><normal>		</normal><keyword>my</keyword><normal> </normal><datatype>$context</datatype><normal> = </normal><datatype>$top</datatype><normal>->[</normal><float>1</float><normal>];</normal><normal>
</normal><normal>		</normal><datatype>$warning</datatype><normal> = </normal><operator>"</operator><datatype>$warning</datatype><char>\n</char><string>  Language => </string><datatype>$lang</datatype><string>, Context => </string><datatype>$context</datatype><char>\n</char><operator>"</operator><normal>;</normal><normal>
</normal><normal>	} </normal><keyword>else</keyword><normal> {</normal><normal>
</normal><normal>		</normal><datatype>$warning</datatype><normal> = </normal><operator>"</operator><datatype>$warning</datatype><char>\n</char><string>  STACK IS EMPTY: PANIC</string><char>\n</char><operator>"</operator><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	cluck(</normal><datatype>$warning</datatype><normal>);</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>parseResult</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> (</normal><datatype>$self</datatype><normal>, </normal><datatype>$text</datatype><normal>, </normal><datatype>$string</datatype><normal>, </normal><datatype>$lahead</datatype><normal>, </normal><datatype>$column</datatype><normal>, </normal><datatype>$fnspace</datatype><normal>, </normal><datatype>$context</datatype><normal>, </normal><datatype>$attr</datatype><normal>) = </normal><datatype>@_</datatype><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$eng</datatype><normal> = </normal><datatype>$self</datatype><normal>-></normal><datatype>engine</datatype><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>$fnspace</datatype><normal>) {</normal><normal>
</normal><normal>		</normal><keyword>unless</keyword><normal> (</normal><datatype>$eng</datatype><normal>-></normal><datatype>firstnonspace</datatype><normal>(</normal><datatype>$$text</datatype><normal>)) {</normal><normal>
</normal><normal>			</normal><keyword>return</keyword><normal> </normal><operator>''</operator><normal>
</normal><normal>		}</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><function>defined</function><normal>(</normal><datatype>$column</datatype><normal>)) {</normal><normal>
</normal><normal>		</normal><keyword>if</keyword><normal> (</normal><datatype>$column</datatype><normal> </normal><operator>ne</operator><normal> </normal><datatype>$eng</datatype><normal>-></normal><datatype>column</datatype><normal>) {</normal><normal>
</normal><normal>			</normal><keyword>return</keyword><normal> </normal><operator>''</operator><normal>;</normal><normal>
</normal><normal>		}</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><keyword>unless</keyword><normal> (</normal><datatype>$lahead</datatype><normal>) {</normal><normal>
</normal><normal>		</normal><datatype>$$text</datatype><normal> = </normal><function>substr</function><normal>(</normal><datatype>$$text</datatype><normal>, </normal><function>length</function><normal>(</normal><datatype>$string</datatype><normal>));</normal><normal>
</normal><normal>		</normal><keyword>my</keyword><normal> </normal><datatype>$r</datatype><normal>;</normal><normal>
</normal><normal>		</normal><keyword>unless</keyword><normal> (</normal><function>defined</function><normal>(</normal><datatype>$attr</datatype><normal>)) {</normal><normal>
</normal><normal>			</normal><keyword>my</keyword><normal> </normal><datatype>$t</datatype><normal> = </normal><datatype>$eng</datatype><normal>-></normal><datatype>stackTop</datatype><normal>;</normal><normal>
</normal><normal>			</normal><keyword>my</keyword><normal> (</normal><datatype>$plug</datatype><normal>, </normal><datatype>$ctext</datatype><normal>) = </normal><datatype>@$t</datatype><normal>;</normal><normal>
</normal><normal>			</normal><datatype>$r</datatype><normal> = </normal><datatype>$plug</datatype><normal>-></normal><datatype>attributes</datatype><normal>->{</normal><datatype>$plug</datatype><normal>-></normal><datatype>contextInfo</datatype><normal>(</normal><datatype>$ctext</datatype><normal>, </normal><operator>'</operator><string>attribute</string><operator>'</operator><normal>)};</normal><normal>
</normal><normal>		} </normal><keyword>else</keyword><normal> {</normal><normal>
</normal><normal>			</normal><datatype>$r</datatype><normal> = </normal><datatype>$self</datatype><normal>-></normal><datatype>attributes</datatype><normal>->{</normal><datatype>$attr</datatype><normal>};</normal><normal>
</normal><normal>		}</normal><normal>
</normal><normal>		</normal><datatype>$eng</datatype><normal>-></normal><datatype>snippetParse</datatype><normal>(</normal><datatype>$string</datatype><normal>, </normal><datatype>$r</datatype><normal>);</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><datatype>$eng</datatype><normal>-></normal><datatype>contextParse</datatype><normal>(</normal><datatype>$self</datatype><normal>, </normal><datatype>$context</datatype><normal>);</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><float>1</float><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>pluginGet</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> (</normal><datatype>$self</datatype><normal>, </normal><datatype>$language</datatype><normal>) = </normal><datatype>@_</datatype><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$plugs</datatype><normal> = </normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>plugins</string><operator>'</operator><normal>};</normal><normal>
</normal><normal>	</normal><keyword>unless</keyword><normal> (</normal><function>exists</function><normal>(</normal><datatype>$plugs</datatype><normal>->{</normal><datatype>$language</datatype><normal>})) {</normal><normal>
</normal><normal>		</normal><keyword>my</keyword><normal> </normal><datatype>$modname</datatype><normal> = </normal><operator>'</operator><string>Syntax::Highlight::Engine::Kate::</string><operator>'</operator><normal> . </normal><datatype>$self</datatype><normal>-></normal><datatype>languagePlug</datatype><normal>(</normal><datatype>$language</datatype><normal>);</normal><normal>
</normal><normal>		</normal><keyword>unless</keyword><normal> (</normal><function>defined</function><normal>(</normal><datatype>$modname</datatype><normal>)) {</normal><normal>
</normal><normal>			</normal><datatype>$self</datatype><normal>-></normal><datatype>logwarning</datatype><normal>(</normal><operator>"</operator><string>no valid module found for language '</string><datatype>$language</datatype><operator>'"</operator><normal>);</normal><normal>
</normal><normal>			</normal><keyword>return</keyword><normal> </normal><function>undef</function><normal>;</normal><normal>
</normal><normal>		}</normal><normal>
</normal><normal>		</normal><keyword>my</keyword><normal> </normal><datatype>$plug</datatype><normal>;</normal><normal>
</normal><normal>		</normal><function>eval</function><normal> </normal><operator>"</operator><string>use </string><datatype>$modname</datatype><string>; \$plug = new </string><datatype>$modname</datatype><string>(engine => \$self);</string><operator>"</operator><normal>;</normal><normal>
</normal><normal>		</normal><keyword>if</keyword><normal> (</normal><function>defined</function><normal>(</normal><datatype>$plug</datatype><normal>)) {</normal><normal>
</normal><normal>			</normal><datatype>$plugs</datatype><normal>->{</normal><datatype>$language</datatype><normal>} = </normal><datatype>$plug</datatype><normal>;</normal><normal>
</normal><normal>		} </normal><keyword>else</keyword><normal> {</normal><normal>
</normal><normal>			</normal><datatype>$self</datatype><normal>-></normal><datatype>logwarning</datatype><normal>(</normal><operator>"</operator><string>cannot create plugin for language '</string><datatype>$language</datatype><operator>'</operator><char>\n</char><variable>$@</variable><operator>"</operator><normal>);</normal><normal>
</normal><normal>		}</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><function>exists</function><normal>(</normal><datatype>$plugs</datatype><normal>->{</normal><datatype>$language</datatype><normal>})) {</normal><normal>
</normal><normal>		</normal><keyword>return</keyword><normal> </normal><datatype>$plugs</datatype><normal>->{</normal><datatype>$language</datatype><normal>};</normal><normal>
</normal><normal>	} </normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><function>undef</function><normal>;</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>reset</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><datatype>$self</datatype><normal>-></normal><datatype>stack</datatype><normal>([[</normal><datatype>$self</datatype><normal>, </normal><datatype>$self</datatype><normal>-></normal><datatype>basecontext</datatype><normal>]]);</normal><normal>
</normal><normal>	</normal><datatype>$self</datatype><normal>-></normal><datatype>out</datatype><normal>([]);</normal><normal>
</normal><normal>	</normal><datatype>$self</datatype><normal>-></normal><datatype>snippet</datatype><normal>(</normal><operator>''</operator><normal>);</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>snippet</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>@_</datatype><normal>) { </normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>snippet</string><operator>'</operator><normal>} = </normal><function>shift</function><normal>; }</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>snippet</string><operator>'</operator><normal>};</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>snippetAppend</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> (</normal><datatype>$self</datatype><normal>, </normal><datatype>$ch</datatype><normal>) = </normal><datatype>@_</datatype><normal>;</normal><normal>
</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><keyword>if</keyword><normal> </normal><operator>not</operator><normal> </normal><function>defined</function><normal> </normal><datatype>$ch</datatype><normal>;</normal><normal>
</normal><normal>	</normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>snippet</string><operator>'</operator><normal>} = </normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>snippet</string><operator>'</operator><normal>} . </normal><datatype>$ch</datatype><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>$ch</datatype><normal> </normal><operator>ne</operator><normal> </normal><operator>''</operator><normal>) {</normal><normal>
</normal><normal>		</normal><datatype>$self</datatype><normal>-></normal><datatype>linesegment</datatype><normal>(</normal><datatype>$self</datatype><normal>-></normal><datatype>linesegment</datatype><normal> . </normal><datatype>$ch</datatype><normal>);</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal>;</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>snippetAttribute</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>@_</datatype><normal>) { </normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>snippetattribute</string><operator>'</operator><normal>} = </normal><function>shift</function><normal>; }</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>snippetattribute</string><operator>'</operator><normal>};</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>snippetForce</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$parse</datatype><normal> = </normal><datatype>$self</datatype><normal>-></normal><datatype>snippet</datatype><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>$parse</datatype><normal> </normal><operator>ne</operator><normal> </normal><operator>''</operator><normal>) {</normal><normal>
</normal><normal>		</normal><keyword>my</keyword><normal> </normal><datatype>$out</datatype><normal> = </normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>out</string><operator>'</operator><normal>};</normal><normal>
</normal><normal>		</normal><function>push</function><normal>(</normal><datatype>@$out</datatype><normal>, </normal><datatype>$parse</datatype><normal>, </normal><datatype>$self</datatype><normal>-></normal><datatype>snippetAttribute</datatype><normal>);</normal><normal>
</normal><normal>		</normal><datatype>$self</datatype><normal>-></normal><datatype>snippet</datatype><normal>(</normal><operator>''</operator><normal>);</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>snippetParse</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$snip</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$attr</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> ((</normal><function>defined</function><normal> </normal><datatype>$attr</datatype><normal>) </normal><operator>and</operator><normal> (</normal><datatype>$attr</datatype><normal> </normal><operator>ne</operator><normal> </normal><datatype>$self</datatype><normal>-></normal><datatype>snippetAttribute</datatype><normal>)) { </normal><normal>
</normal><normal>		</normal><datatype>$self</datatype><normal>-></normal><datatype>snippetForce</datatype><normal>;</normal><normal>
</normal><normal>		</normal><datatype>$self</datatype><normal>-></normal><datatype>snippetAttribute</datatype><normal>(</normal><datatype>$attr</datatype><normal>);</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><datatype>$self</datatype><normal>-></normal><datatype>snippetAppend</datatype><normal>(</normal><datatype>$snip</datatype><normal>);</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>stack</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>@_</datatype><normal>) { </normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>stack</string><operator>'</operator><normal>} = </normal><function>shift</function><normal>; }</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>stack</string><operator>'</operator><normal>};</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>stackPush</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> (</normal><datatype>$self</datatype><normal>, </normal><datatype>$val</datatype><normal>) = </normal><datatype>@_</datatype><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$stack</datatype><normal> = </normal><datatype>$self</datatype><normal>-></normal><datatype>stack</datatype><normal>;</normal><normal>
</normal><normal>	</normal><function>unshift</function><normal>(</normal><datatype>@$stack</datatype><normal>, </normal><datatype>$val</datatype><normal>);</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>stackPull</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> (</normal><datatype>$self</datatype><normal>, </normal><datatype>$val</datatype><normal>) = </normal><datatype>@_</datatype><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$stack</datatype><normal> = </normal><datatype>$self</datatype><normal>-></normal><datatype>stack</datatype><normal>;</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><function>shift</function><normal>(</normal><datatype>@$stack</datatype><normal>);</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>stackTop</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><datatype>$self</datatype><normal>-></normal><datatype>stack</datatype><normal>->[0];</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>stateCompare</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> (</normal><datatype>$self</datatype><normal>, </normal><datatype>$state</datatype><normal>) = </normal><datatype>@_</datatype><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$h</datatype><normal> = [ </normal><datatype>$self</datatype><normal>-></normal><datatype>stateGet</datatype><normal> ];</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$equal</datatype><normal> = 0;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (Dumper(</normal><datatype>$h</datatype><normal>) </normal><operator>eq</operator><normal> Dumper(</normal><datatype>$state</datatype><normal>)) { </normal><datatype>$equal</datatype><normal> = </normal><float>1</float><normal> };</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><datatype>$equal</datatype><normal>;</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>stateGet</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$s</datatype><normal> = </normal><datatype>$self</datatype><normal>-></normal><datatype>stack</datatype><normal>;</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><datatype>@$s</datatype><normal>;</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>stateSet</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$s</datatype><normal> = </normal><datatype>$self</datatype><normal>-></normal><datatype>stack</datatype><normal>;</normal><normal>
</normal><normal>	</normal><datatype>@$s</datatype><normal> = (</normal><datatype>@_</datatype><normal>);</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>substitutions</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>@_</datatype><normal>) { </normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>substitutions</string><operator>'</operator><normal>} = </normal><function>shift</function><normal>; }</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><datatype>$self</datatype><normal>->{</normal><operator>'</operator><string>substitutions</string><operator>'</operator><normal>};</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>testAnyChar</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$text</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$string</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$insensitive</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$test</datatype><normal> = </normal><function>substr</function><normal>(</normal><datatype>$$text</datatype><normal>, 0, </normal><float>1</float><normal>);</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$bck</datatype><normal> = </normal><datatype>$test</datatype><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>$insensitive</datatype><normal>) {</normal><normal>
</normal><normal>		</normal><datatype>$string</datatype><normal> = </normal><function>lc</function><normal>(</normal><datatype>$string</datatype><normal>);</normal><normal>
</normal><normal>		</normal><datatype>$test</datatype><normal> = </normal><function>lc</function><normal>(</normal><datatype>$test</datatype><normal>);</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><function>index</function><normal>(</normal><datatype>$string</datatype><normal>, </normal><datatype>$test</datatype><normal>) > </normal><decval>-1</decval><normal>) {</normal><normal>
</normal><normal>		</normal><keyword>return</keyword><normal> </normal><datatype>$self</datatype><normal>-></normal><datatype>parseResult</datatype><normal>(</normal><datatype>$text</datatype><normal>, </normal><datatype>$bck</datatype><normal>, </normal><datatype>@_</datatype><normal>);</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><operator>''</operator><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>testDetectChar</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$text</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$char</datatype><normal> = </normal><function>shift</function><normal>; </normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$insensitive</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$dyn</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>$dyn</datatype><normal>) {</normal><normal>
</normal><normal>		</normal><datatype>$char</datatype><normal> = </normal><datatype>$self</datatype><normal>-></normal><datatype>capturedParse</datatype><normal>(</normal><datatype>$char</datatype><normal>, </normal><float>1</float><normal>);</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$test</datatype><normal> = </normal><function>substr</function><normal>(</normal><datatype>$$text</datatype><normal>, 0, </normal><float>1</float><normal>);</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$bck</datatype><normal> = </normal><datatype>$test</datatype><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>$insensitive</datatype><normal>) {</normal><normal>
</normal><normal>		</normal><datatype>$char</datatype><normal> = </normal><function>lc</function><normal>(</normal><datatype>$char</datatype><normal>);</normal><normal>
</normal><normal>		</normal><datatype>$test</datatype><normal> = </normal><function>lc</function><normal>(</normal><datatype>$test</datatype><normal>);</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>$char</datatype><normal> </normal><operator>eq</operator><normal> </normal><datatype>$test</datatype><normal>) {</normal><normal>
</normal><normal>		</normal><keyword>return</keyword><normal> </normal><datatype>$self</datatype><normal>-></normal><datatype>parseResult</datatype><normal>(</normal><datatype>$text</datatype><normal>, </normal><datatype>$bck</datatype><normal>, </normal><datatype>@_</datatype><normal>);</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><operator>''</operator><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>testDetect2Chars</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$text</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$char</datatype><normal> = </normal><function>shift</function><normal>; </normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$char1</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$insensitive</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$dyn</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>$dyn</datatype><normal>) {</normal><normal>
</normal><normal>		</normal><datatype>$char</datatype><normal> = </normal><datatype>$self</datatype><normal>-></normal><datatype>capturedParse</datatype><normal>(</normal><datatype>$char</datatype><normal>, </normal><float>1</float><normal>);</normal><normal>
</normal><normal>		</normal><datatype>$char1</datatype><normal> = </normal><datatype>$self</datatype><normal>-></normal><datatype>capturedParse</datatype><normal>(</normal><datatype>$char1</datatype><normal>, </normal><float>1</float><normal>);</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$string</datatype><normal> = </normal><datatype>$char</datatype><normal> . </normal><datatype>$char1</datatype><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$test</datatype><normal> = </normal><function>substr</function><normal>(</normal><datatype>$$text</datatype><normal>, 0, </normal><float>2</float><normal>);</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$bck</datatype><normal> = </normal><datatype>$test</datatype><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>$insensitive</datatype><normal>) {</normal><normal>
</normal><normal>		</normal><datatype>$string</datatype><normal> = </normal><function>lc</function><normal>(</normal><datatype>$string</datatype><normal>);</normal><normal>
</normal><normal>		</normal><datatype>$test</datatype><normal> = </normal><function>lc</function><normal>(</normal><datatype>$test</datatype><normal>);</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>$string</datatype><normal> </normal><operator>eq</operator><normal> </normal><datatype>$test</datatype><normal>) {</normal><normal>
</normal><normal>		</normal><keyword>return</keyword><normal> </normal><datatype>$self</datatype><normal>-></normal><datatype>parseResult</datatype><normal>(</normal><datatype>$text</datatype><normal>, </normal><datatype>$bck</datatype><normal>, </normal><datatype>@_</datatype><normal>);</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><operator>''</operator><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>testDetectIdentifier</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$text</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>$$text</datatype><normal> =~ </normal><operator>/</operator><char>^([</char><basen>a-zA-Z_</basen><char>][</char><basen>a-zA-Z0-9_</basen><char>]+)</char><operator>/</operator><normal>) {</normal><normal>
</normal><normal>		</normal><keyword>return</keyword><normal> </normal><datatype>$self</datatype><normal>-></normal><datatype>parseResult</datatype><normal>(</normal><datatype>$text</datatype><normal>, </normal><variable>$1</variable><normal>, </normal><datatype>@_</datatype><normal>);</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><operator>''</operator><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>testDetectSpaces</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$text</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>$$text</datatype><normal> =~ </normal><operator>/</operator><char>^([</char><basen>\\040|\\t</basen><char>]+)</char><operator>/</operator><normal>) {</normal><normal>
</normal><normal>		</normal><keyword>return</keyword><normal> </normal><datatype>$self</datatype><normal>-></normal><datatype>parseResult</datatype><normal>(</normal><datatype>$text</datatype><normal>, </normal><variable>$1</variable><normal>, </normal><datatype>@_</datatype><normal>);</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><operator>''</operator><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>testFloat</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$text</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>$self</datatype><normal>-></normal><datatype>engine</datatype><normal>-></normal><datatype>lastcharDeliminator</datatype><normal>) {</normal><normal>
</normal><normal>		</normal><keyword>if</keyword><normal> (</normal><datatype>$$text</datatype><normal> =~ </normal><operator>/</operator><char>^((?=</char><others>\.</others><char>?</char><basen>\d</basen><char>)</char><basen>\d</basen><char>*(?:</char><others>\.</others><basen>\d</basen><char>*)?(?:[</char><basen>Ee</basen><char>][</char><basen>+-</basen><char>]?</char><basen>\d</basen><char>+)?)</char><operator>/</operator><normal>) {</normal><normal>
</normal><normal>			</normal><keyword>return</keyword><normal> </normal><datatype>$self</datatype><normal>-></normal><datatype>parseResult</datatype><normal>(</normal><datatype>$text</datatype><normal>, </normal><variable>$1</variable><normal>, </normal><datatype>@_</datatype><normal>);</normal><normal>
</normal><normal>		}</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><operator>''</operator><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>testHlCChar</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$text</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>$$text</datatype><normal> =~ </normal><operator>/</operator><char>^(</char><others>'.'</others><char>)</char><operator>/</operator><normal>) {</normal><normal>
</normal><normal>		</normal><keyword>return</keyword><normal> </normal><datatype>$self</datatype><normal>-></normal><datatype>parseResult</datatype><normal>(</normal><datatype>$text</datatype><normal>, </normal><variable>$1</variable><normal>, </normal><datatype>@_</datatype><normal>);</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><operator>''</operator><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>testHlCHex</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$text</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>$self</datatype><normal>-></normal><datatype>engine</datatype><normal>-></normal><datatype>lastcharDeliminator</datatype><normal>) {</normal><normal>
</normal><normal>		</normal><keyword>if</keyword><normal> (</normal><datatype>$$text</datatype><normal> =~ </normal><operator>/</operator><char>^(</char><others>0x</others><char>[</char><basen>0-9a-fA-F</basen><char>]+)</char><operator>/</operator><normal>) {</normal><normal>
</normal><normal>			</normal><keyword>return</keyword><normal> </normal><datatype>$self</datatype><normal>-></normal><datatype>parseResult</datatype><normal>(</normal><datatype>$text</datatype><normal>, </normal><variable>$1</variable><normal>, </normal><datatype>@_</datatype><normal>);</normal><normal>
</normal><normal>		}</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><operator>''</operator><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>testHlCOct</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$text</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>$self</datatype><normal>-></normal><datatype>engine</datatype><normal>-></normal><datatype>lastcharDeliminator</datatype><normal>) {</normal><normal>
</normal><normal>		</normal><keyword>if</keyword><normal> (</normal><datatype>$$text</datatype><normal> =~ </normal><operator>/</operator><char>^(</char><others>0</others><char>[</char><basen>0-7</basen><char>]+)</char><operator>/</operator><normal>) {</normal><normal>
</normal><normal>			</normal><keyword>return</keyword><normal> </normal><datatype>$self</datatype><normal>-></normal><datatype>parseResult</datatype><normal>(</normal><datatype>$text</datatype><normal>, </normal><variable>$1</variable><normal>, </normal><datatype>@_</datatype><normal>);</normal><normal>
</normal><normal>		}</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><operator>''</operator><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>testHlCStringChar</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$text</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>$$text</datatype><normal> =~ </normal><operator>/</operator><char>^(</char><others>\\</others><char>[</char><basen>a|b|e|f|n|r|t|v|'|"|\?</basen><char>])</char><operator>/</operator><normal>) {</normal><normal>
</normal><normal>		</normal><keyword>return</keyword><normal> </normal><datatype>$self</datatype><normal>-></normal><datatype>parseResult</datatype><normal>(</normal><datatype>$text</datatype><normal>, </normal><variable>$1</variable><normal>, </normal><datatype>@_</datatype><normal>);</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>$$text</datatype><normal> =~ </normal><operator>/</operator><char>^(</char><others>\\x</others><char>[</char><basen>0-9a-fA-F</basen><char>][</char><basen>0-9a-fA-F</basen><char>]?)</char><operator>/</operator><normal>) {</normal><normal>
</normal><normal>		</normal><keyword>return</keyword><normal> </normal><datatype>$self</datatype><normal>-></normal><datatype>parseResult</datatype><normal>(</normal><datatype>$text</datatype><normal>, </normal><variable>$1</variable><normal>, </normal><datatype>@_</datatype><normal>);</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>$$text</datatype><normal> =~ </normal><operator>/</operator><char>^(</char><others>\\</others><char>[</char><basen>0-7</basen><char>][</char><basen>0-7</basen><char>]?[</char><basen>0-7</basen><char>]?)</char><operator>/</operator><normal>) {</normal><normal>
</normal><normal>		</normal><keyword>return</keyword><normal> </normal><datatype>$self</datatype><normal>-></normal><datatype>parseResult</datatype><normal>(</normal><datatype>$text</datatype><normal>, </normal><variable>$1</variable><normal>, </normal><datatype>@_</datatype><normal>);</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><operator>''</operator><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>testInt</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$text</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>$self</datatype><normal>-></normal><datatype>engine</datatype><normal>-></normal><datatype>lastcharDeliminator</datatype><normal>) {</normal><normal>
</normal><normal>		</normal><keyword>if</keyword><normal> (</normal><datatype>$$text</datatype><normal> =~ </normal><operator>/</operator><char>^([</char><basen>+-</basen><char>]?</char><basen>\d</basen><char>+)</char><operator>/</operator><normal>) {</normal><normal>
</normal><normal>			</normal><keyword>return</keyword><normal> </normal><datatype>$self</datatype><normal>-></normal><datatype>parseResult</datatype><normal>(</normal><datatype>$text</datatype><normal>, </normal><variable>$1</variable><normal>, </normal><datatype>@_</datatype><normal>);</normal><normal>
</normal><normal>		}</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><operator>''</operator><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>testKeyword</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$text</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$list</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$eng</datatype><normal> = </normal><datatype>$self</datatype><normal>-></normal><datatype>engine</datatype><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$deliminators</datatype><normal> = </normal><datatype>$self</datatype><normal>-></normal><datatype>deliminators</datatype><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> ((</normal><datatype>$eng</datatype><normal>-></normal><datatype>lastcharDeliminator</datatype><normal>)  </normal><operator>and</operator><normal> (</normal><datatype>$$text</datatype><normal> =~ </normal><operator>/</operator><char>^([^</char><basen>$deliminators</basen><char>]+)</char><operator>/</operator><normal>)) {</normal><normal>
</normal><normal>		</normal><keyword>my</keyword><normal> </normal><datatype>$match</datatype><normal> = </normal><variable>$1</variable><normal>;</normal><normal>
</normal><normal>		</normal><keyword>my</keyword><normal> </normal><datatype>$l</datatype><normal> = </normal><datatype>$self</datatype><normal>-></normal><datatype>lists</datatype><normal>->{</normal><datatype>$list</datatype><normal>};</normal><normal>
</normal><normal>		</normal><keyword>if</keyword><normal> (</normal><function>defined</function><normal>(</normal><datatype>$l</datatype><normal>)) {</normal><normal>
</normal><normal>			</normal><keyword>my</keyword><normal> </normal><datatype>@list</datatype><normal> = </normal><datatype>@$l</datatype><normal>;</normal><normal>
</normal><normal>			</normal><keyword>my</keyword><normal> </normal><datatype>@rl</datatype><normal> = ();</normal><normal>
</normal><normal>			</normal><keyword>unless</keyword><normal> (</normal><datatype>$self</datatype><normal>-></normal><datatype>keywordscase</datatype><normal>) {</normal><normal>
</normal><normal>				</normal><datatype>@rl</datatype><normal> = </normal><function>grep</function><normal> { (</normal><function>lc</function><normal>(</normal><datatype>$match</datatype><normal>) </normal><operator>eq</operator><normal> </normal><function>lc</function><normal>(</normal><variable>$_</variable><normal>)) } </normal><datatype>@list</datatype><normal>;</normal><normal>
</normal><normal>			} </normal><keyword>else</keyword><normal> {</normal><normal>
</normal><normal>				</normal><datatype>@rl</datatype><normal> = </normal><function>grep</function><normal> { (</normal><datatype>$match</datatype><normal> </normal><operator>eq</operator><normal> </normal><variable>$_</variable><normal>) } </normal><datatype>@list</datatype><normal>;</normal><normal>
</normal><normal>			}</normal><normal>
</normal><normal>			</normal><keyword>if</keyword><normal> (</normal><datatype>@rl</datatype><normal>) {</normal><normal>
</normal><normal>				</normal><keyword>return</keyword><normal> </normal><datatype>$self</datatype><normal>-></normal><datatype>parseResult</datatype><normal>(</normal><datatype>$text</datatype><normal>, </normal><datatype>$match</datatype><normal>, </normal><datatype>@_</datatype><normal>);</normal><normal>
</normal><normal>			}</normal><normal>
</normal><normal>		} </normal><keyword>else</keyword><normal> {</normal><normal>
</normal><normal>			</normal><datatype>$self</datatype><normal>-></normal><datatype>logwarning</datatype><normal>(</normal><operator>"</operator><string>list '</string><datatype>$list</datatype><operator>'</operator><string> is not defined, failing test</string><operator>"</operator><normal>);</normal><normal>
</normal><normal>		}</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><operator>''</operator><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>testLineContinue</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$text</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$lahead</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>$lahead</datatype><normal>) {</normal><normal>
</normal><normal>		</normal><keyword>if</keyword><normal> (</normal><datatype>$$text</datatype><normal> =~ </normal><operator>/</operator><char>^</char><others>\\</others><basen>\n</basen><operator>/</operator><normal>) {</normal><normal>
</normal><normal>			</normal><datatype>$self</datatype><normal>-></normal><datatype>parseResult</datatype><normal>(</normal><datatype>$text</datatype><normal>, </normal><operator>"</operator><string>\\</string><operator>"</operator><normal>, </normal><datatype>$lahead</datatype><normal>, </normal><datatype>@_</datatype><normal>);</normal><normal>
</normal><normal>			</normal><keyword>return</keyword><normal> </normal><float>1</float><normal>;</normal><normal>
</normal><normal>		}</normal><normal>
</normal><normal>	} </normal><keyword>else</keyword><normal> {</normal><normal>
</normal><normal>		</normal><keyword>if</keyword><normal> (</normal><datatype>$$text</datatype><normal> =~ </normal><operator>s/</operator><char>^(</char><others>\\</others><char>)(</char><basen>\n</basen><char>)</char><operator>/</operator><variable>$2</variable><operator>/</operator><normal>) {</normal><normal>
</normal><normal>			</normal><keyword>return</keyword><normal> </normal><datatype>$self</datatype><normal>-></normal><datatype>parseResult</datatype><normal>(</normal><datatype>$text</datatype><normal>, </normal><operator>"</operator><string>\\</string><operator>"</operator><normal>, </normal><datatype>$lahead</datatype><normal>, </normal><datatype>@_</datatype><normal>);</normal><normal>
</normal><normal>		}</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><operator>''</operator><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>testRangeDetect</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$text</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$char</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$char1</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$insensitive</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$string</datatype><normal> = </normal><operator>"</operator><datatype>$char</datatype><string>\[^</string><datatype>$char1</datatype><string>\]+</string><datatype>$char1</datatype><operator>"</operator><normal>;</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><datatype>$self</datatype><normal>-></normal><datatype>testRegExpr</datatype><normal>(</normal><datatype>$text</datatype><normal>, </normal><datatype>$string</datatype><normal>, </normal><datatype>$insensitive</datatype><normal>, 0, </normal><datatype>@_</datatype><normal>);</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>testRegExpr</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$text</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$reg</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$insensitive</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$dynamic</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>$dynamic</datatype><normal>) {</normal><normal>
</normal><normal>		</normal><datatype>$reg</datatype><normal> = </normal><datatype>$self</datatype><normal>-></normal><datatype>capturedParse</datatype><normal>(</normal><datatype>$reg</datatype><normal>);</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$eng</datatype><normal> = </normal><datatype>$self</datatype><normal>-></normal><datatype>engine</datatype><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>$reg</datatype><normal> =~ </normal><operator>s/</operator><char>^</char><others>\^</others><operator>//</operator><normal>) {</normal><normal>
</normal><normal>		</normal><keyword>unless</keyword><normal> (</normal><datatype>$eng</datatype><normal>-></normal><datatype>linestart</datatype><normal>) {</normal><normal>
</normal><normal>			</normal><keyword>return</keyword><normal> </normal><operator>''</operator><normal>;</normal><normal>
</normal><normal>		}</normal><normal>
</normal><normal>	} </normal><keyword>elsif</keyword><normal> (</normal><datatype>$reg</datatype><normal> =~ </normal><operator>s/</operator><char>^</char><others>\\</others><char>(</char><others>b</others><char>)</char><operator>//i</operator><normal>) {</normal><normal>
</normal><normal>		</normal><keyword>my</keyword><normal> </normal><datatype>$lastchar</datatype><normal> = </normal><datatype>$self</datatype><normal>-></normal><datatype>engine</datatype><normal>-></normal><datatype>lastchar</datatype><normal>;</normal><normal>
</normal><normal>		</normal><keyword>if</keyword><normal> (</normal><variable>$1</variable><normal> </normal><operator>eq</operator><normal> </normal><operator>'</operator><string>b</string><operator>'</operator><normal>) {</normal><normal>
</normal><normal>			</normal><keyword>if</keyword><normal> (</normal><datatype>$lastchar</datatype><normal> =~ </normal><operator>/</operator><basen>\w</basen><operator>/</operator><normal>) { </normal><keyword>return</keyword><normal> </normal><operator>''</operator><normal> }</normal><normal>
</normal><normal>		} </normal><keyword>else</keyword><normal> {</normal><normal>
</normal><normal>			</normal><keyword>if</keyword><normal> (</normal><datatype>$lastchar</datatype><normal> =~ </normal><operator>/</operator><basen>\W</basen><operator>/</operator><normal>) { </normal><keyword>return</keyword><normal> </normal><operator>''</operator><normal> }</normal><normal>
</normal><normal>		}</normal><normal>
</normal><normal>	}</normal><normal>
</normal><comment>#	$reg = "^($reg)";</comment><comment>
</comment><normal>	</normal><datatype>$reg</datatype><normal> = </normal><operator>"</operator><string>^</string><datatype>$reg</datatype><operator>"</operator><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$pos</datatype><normal>;</normal><normal>
</normal><comment>#	my @cap = ();</comment><comment>
</comment><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$sample</datatype><normal> = </normal><datatype>$$text</datatype><normal>;</normal><normal>
</normal><normal>
</normal><normal>	</normal><comment># emergency measurements to avoid exception (szabgab)</comment><comment>
</comment><normal>	</normal><datatype>$reg</datatype><normal> = </normal><function>eval</function><normal> { </normal><operator>qr/</operator><datatype>$reg</datatype><operator>/</operator><normal> };</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><variable>$@</variable><normal>) {</normal><normal>
</normal><normal>		</normal><function>warn</function><normal> </normal><variable>$@</variable><normal>;</normal><normal>
</normal><normal>		</normal><keyword>return</keyword><normal> </normal><operator>''</operator><normal>;</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>$insensitive</datatype><normal>) {</normal><normal>
</normal><normal>		</normal><keyword>if</keyword><normal> (</normal><datatype>$sample</datatype><normal> =~ </normal><operator>/</operator><datatype>$reg</datatype><operator>/ig</operator><normal>) {</normal><normal>
</normal><normal>			</normal><datatype>$pos</datatype><normal> = </normal><function>pos</function><normal>(</normal><datatype>$sample</datatype><normal>);</normal><normal>
</normal><comment>#			@cap = ($1, $2, $3, $4, $5, $6, $7, $8, $9);</comment><comment>
</comment><comment>#			my @cap = ();</comment><comment>
</comment><normal>			</normal><keyword>if</keyword><normal> (</normal><variable>$#</variable><normal>-) {</normal><normal>
</normal><normal>				</normal><keyword>no</keyword><normal> </normal><keyword>strict</keyword><normal> </normal><operator>'</operator><string>refs</string><operator>'</operator><normal>;</normal><normal>
</normal><normal>				</normal><keyword>my</keyword><normal> </normal><datatype>@cap</datatype><normal> = </normal><function>map</function><normal> {</normal><datatype>$$_</datatype><normal>} </normal><float>1</float><normal> .. </normal><variable>$#</variable><normal>-;</normal><normal>
</normal><normal>				</normal><datatype>$self</datatype><normal>-></normal><datatype>captured</datatype><normal>(\</normal><datatype>@cap</datatype><normal>)</normal><normal>
</normal><normal>			}</normal><normal>
</normal><comment>#			my $r  = 1;</comment><comment>
</comment><comment>#			my $c  = 1;</comment><comment>
</comment><comment>#			my @cap = ();</comment><comment>
</comment><comment>#			while ($r) {</comment><comment>
</comment><comment>#				eval "if (defined\$$c) { push \@cap, \$$c } else { \$r = 0 }";</comment><comment>
</comment><comment>#				$c ++;</comment><comment>
</comment><comment>#			}</comment><comment>
</comment><comment>#			if (@cap) { $self->captured(\@cap) };</comment><comment>
</comment><normal>		}</normal><normal>
</normal><normal>	} </normal><keyword>else</keyword><normal> {</normal><normal>
</normal><normal>		</normal><keyword>if</keyword><normal> (</normal><datatype>$sample</datatype><normal> =~ </normal><operator>/</operator><datatype>$reg</datatype><operator>/g</operator><normal>) {</normal><normal>
</normal><normal>			</normal><datatype>$pos</datatype><normal> = </normal><function>pos</function><normal>(</normal><datatype>$sample</datatype><normal>);</normal><normal>
</normal><comment>#			@cap = ($1, $2, $3, $4, $5, $6, $7, $8, $9);</comment><comment>
</comment><comment>#			my @cap = ();</comment><comment>
</comment><normal>			</normal><keyword>if</keyword><normal> (</normal><variable>$#</variable><normal>-) {</normal><normal>
</normal><normal>				</normal><keyword>no</keyword><normal> </normal><keyword>strict</keyword><normal> </normal><operator>'</operator><string>refs</string><operator>'</operator><normal>;</normal><normal>
</normal><normal>				</normal><keyword>my</keyword><normal> </normal><datatype>@cap</datatype><normal> = </normal><function>map</function><normal> {</normal><datatype>$$_</datatype><normal>} </normal><float>1</float><normal> .. </normal><variable>$#</variable><normal>-;</normal><normal>
</normal><normal>				</normal><datatype>$self</datatype><normal>-></normal><datatype>captured</datatype><normal>(\</normal><datatype>@cap</datatype><normal>);</normal><normal>
</normal><normal>			}</normal><normal>
</normal><comment>#			my $r  = 1;</comment><comment>
</comment><comment>#			my $c  = 1;</comment><comment>
</comment><comment>#			my @cap = ();</comment><comment>
</comment><comment>#			while ($r) {</comment><comment>
</comment><comment>#				eval "if (defined\$$c) { push \@cap, \$$c } else { \$r = 0 }";</comment><comment>
</comment><comment>#				$c ++;</comment><comment>
</comment><comment>#			}</comment><comment>
</comment><comment>#			if (@cap) { $self->captured(\@cap) };</comment><comment>
</comment><normal>		}</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><function>defined</function><normal>(</normal><datatype>$pos</datatype><normal>) </normal><operator>and</operator><normal> (</normal><datatype>$pos</datatype><normal> > 0)) {</normal><normal>
</normal><normal>		</normal><keyword>my</keyword><normal> </normal><datatype>$string</datatype><normal> = </normal><function>substr</function><normal>(</normal><datatype>$$text</datatype><normal>, 0, </normal><datatype>$pos</datatype><normal>);</normal><normal>
</normal><normal>		</normal><keyword>return</keyword><normal> </normal><datatype>$self</datatype><normal>-></normal><datatype>parseResult</datatype><normal>(</normal><datatype>$text</datatype><normal>, </normal><datatype>$string</datatype><normal>, </normal><datatype>@_</datatype><normal>);</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><operator>''</operator><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>testStringDetect</function><normal> {</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$self</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$text</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$string</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$insensitive</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$dynamic</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>$dynamic</datatype><normal>) {</normal><normal>
</normal><normal>		</normal><datatype>$string</datatype><normal> = </normal><datatype>$self</datatype><normal>-></normal><datatype>capturedParse</datatype><normal>(</normal><datatype>$string</datatype><normal>);</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$test</datatype><normal> = </normal><function>substr</function><normal>(</normal><datatype>$$text</datatype><normal>, 0, </normal><function>length</function><normal>(</normal><datatype>$string</datatype><normal>));</normal><normal>
</normal><normal>	</normal><keyword>my</keyword><normal> </normal><datatype>$bck</datatype><normal> = </normal><datatype>$test</datatype><normal>;</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>$insensitive</datatype><normal>) {</normal><normal>
</normal><normal>		</normal><datatype>$string</datatype><normal> = </normal><function>lc</function><normal>(</normal><datatype>$string</datatype><normal>);</normal><normal>
</normal><normal>		</normal><datatype>$test</datatype><normal> = </normal><function>lc</function><normal>(</normal><datatype>$test</datatype><normal>);</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><keyword>if</keyword><normal> (</normal><datatype>$string</datatype><normal> </normal><operator>eq</operator><normal> </normal><datatype>$test</datatype><normal>) {</normal><normal>
</normal><normal>		</normal><keyword>return</keyword><normal> </normal><datatype>$self</datatype><normal>-></normal><datatype>parseResult</datatype><normal>(</normal><datatype>$text</datatype><normal>, </normal><datatype>$bck</datatype><normal>, </normal><datatype>@_</datatype><normal>);</normal><normal>
</normal><normal>	}</normal><normal>
</normal><normal>	</normal><keyword>return</keyword><normal> </normal><operator>''</operator><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><normal>
</normal><float>1</float><normal>;</normal><normal>
</normal><normal>
</normal><keyword>__END__</keyword><normal>
</normal><normal>
</normal><comment>=head1 NAME</comment><comment>
</comment><comment>
</comment><comment>Syntax::Highlight::Engine::Kate::Template - a template for syntax highlighting plugins</comment><comment>
</comment><comment>
</comment><comment>=head1 DESCRIPTION</comment><comment>
</comment><comment>
</comment><comment>Syntax::Highlight::Engine::Kate::Template is a framework to assist authors of plugin modules.</comment><comment>
</comment><comment>All methods to provide highlighting to the Syntax::Highlight::Engine::Kate module are there, Just</comment><comment>
</comment><comment>no syntax definitions and callbacks. An instance of Syntax::Highlight::Engine::Kate::Template </comment><comment>
</comment><comment>should never be created, it's meant to be sub classed only. </comment><comment>
</comment><comment>
</comment><comment>=head1 METHODS</comment><comment>
</comment><comment>
</comment><comment>=over 4</comment><comment>
</comment><comment>
</comment><comment>=item B<attributes>(I<?$attributesref?>);</comment><comment>
</comment><comment>
</comment><comment>Sets and returns a reference to the attributes hash.</comment><comment>
</comment><comment>
</comment><comment>=item B<basecontext>(I<?$context?>);</comment><comment>
</comment><comment>
</comment><comment>Sets and returns the basecontext instance variable. This is the context that is used when highlighting starts.</comment><comment>
</comment><comment>
</comment><comment>=item B<captured>(I<$cap>);</comment><comment>
</comment><comment>
</comment><comment>Puts $cap in the first element of the stack, the current context. Used when the context is dynamic.</comment><comment>
</comment><comment>
</comment><comment>=item B<capturedGet>(I<$num>);</comment><comment>
</comment><comment>
</comment><comment>Returns the $num'th element that was captured in the current context.</comment><comment>
</comment><comment>
</comment><comment>=item B<capturedParse>(I<$string>, I<$mode>);</comment><comment>
</comment><comment>
</comment><comment>If B<$mode> is specified, B<$string> should only be one character long and numeric.</comment><comment>
</comment><comment>B<capturedParse> will return the Nth captured element of the current context.</comment><comment>
</comment><comment>
</comment><comment>If B<$mode> is not specified, all occurences of %[1-9] will be replaced by the captured</comment><comment>
</comment><comment>element of the current context.</comment><comment>
</comment><comment>
</comment><comment>=item B<column></comment><comment>
</comment><comment>
</comment><comment>returns the column position in the line that is currently highlighted.</comment><comment>
</comment><comment>
</comment><comment>=item B<contextdata>(I<\%data>);</comment><comment>
</comment><comment>
</comment><comment>Sets and returns a reference to the contextdata hash.</comment><comment>
</comment><comment>
</comment><comment>=item B<contextInfo>(I<$context>, I<$item>);</comment><comment>
</comment><comment>
</comment><comment>returns the value of several context options. B<$item> can be B<callback>, B<attribute>, B<lineending>,</comment><comment>
</comment><comment>B<linebeginning>, B<fallthrough>.</comment><comment>
</comment><comment>
</comment><comment>=item B<contextParse>(I<$plugin>, I<$context>);</comment><comment>
</comment><comment>
</comment><comment>Called by the plugins after a test succeeds. if B<$context> has following values:</comment><comment>
</comment><comment>
</comment><comment> #pop       returns to the previous context, removes to top item in the stack. Can</comment><comment>
</comment><comment>            also be specified as #pop#pop etc.</comment><comment>
</comment><comment> #stay      does nothing.</comment><comment>
</comment><comment> ##....     Switches to the plugin specified in .... and assumes it's basecontext.</comment><comment>
</comment><comment> ....       Swtiches to the context specified in ....</comment><comment>
</comment><comment>
</comment><comment>=item B<deliminators>(I<?$delim?>);</comment><comment>
</comment><comment>
</comment><comment>Sets and returns a string that is a regular expression for detecting deliminators.</comment><comment>
</comment><comment>
</comment><comment>=item B<engine></comment><comment>
</comment><comment>
</comment><comment>Returns a reference to the Syntax::Highlight::Engine::Kate module that created this plugin.</comment><comment>
</comment><comment>
</comment><comment>=item B<firstnonspace>(I<$string>);</comment><comment>
</comment><comment>
</comment><comment>returns true if the current line did not contain a non-spatial character so far and the first </comment><comment>
</comment><comment>character in B<$string> is also a spatial character.</comment><comment>
</comment><comment>
</comment><comment>=item B<formatTable></comment><comment>
</comment><comment>
</comment><comment>sets and returns the instance variable B<format_table>. See also the option B<format_table></comment><comment>
</comment><comment>
</comment><comment>=item B<highlight>(I<$text>);</comment><comment>
</comment><comment>
</comment><comment>highlights I<$text>. It does so by selecting the proper callback</comment><comment>
</comment><comment>from the B<commands> hash and invoke it. It will do so untill</comment><comment>
</comment><comment>$text has been reduced to an empty string. returns a paired list</comment><comment>
</comment><comment>of snippets of text and the attribute with which they should be </comment><comment>
</comment><comment>highlighted.</comment><comment>
</comment><comment>
</comment><comment>=item B<highlightText>(I<$text>);</comment><comment>
</comment><comment>
</comment><comment>highlights I<$text> and reformats it using the B<format_table> and B<substitutions></comment><comment>
</comment><comment>
</comment><comment>=item B<includePlugin>(I<$language>, I<\$text>);</comment><comment>
</comment><comment>
</comment><comment>Includes the plugin for B<$language> in the highlighting.</comment><comment>
</comment><comment>
</comment><comment>=item B<includeRules>(I<$language>, I<\$text>);</comment><comment>
</comment><comment>
</comment><comment>Includes the plugin for B<$language> in the highlighting.</comment><comment>
</comment><comment>
</comment><comment>=item B<keywordscase></comment><comment>
</comment><comment>
</comment><comment>Sets and returns the keywordscase instance variable.</comment><comment>
</comment><comment>
</comment><comment>=item B<lastchar></comment><comment>
</comment><comment>
</comment><comment>return the last character that was processed.</comment><comment>
</comment><comment>
</comment><comment>=item B<lastcharDeliminator></comment><comment>
</comment><comment>
</comment><comment>returns true if the last character processed was a deliminator.</comment><comment>
</comment><comment>
</comment><comment>=item B<linesegment></comment><comment>
</comment><comment>
</comment><comment>returns the string of text in the current line that has been processed so far,</comment><comment>
</comment><comment>
</comment><comment>=item B<linestart></comment><comment>
</comment><comment>
</comment><comment>returns true if processing is currently at the beginning of a line.</comment><comment>
</comment><comment>
</comment><comment>=item B<listAdd>(I<'listname'>, I<$item1>, I<$item2> ...);</comment><comment>
</comment><comment>
</comment><comment>Adds a list to the 'lists' hash.</comment><comment>
</comment><comment>
</comment><comment>=item B<lists>(I<?\%lists?>);</comment><comment>
</comment><comment>
</comment><comment>sets and returns the instance variable 'lists'.</comment><comment>
</comment><comment>
</comment><comment>=item B<out>(I<?\@highlightedlist?>);</comment><comment>
</comment><comment>
</comment><comment>sets and returns the instance variable 'out'.</comment><comment>
</comment><comment>
</comment><comment>=item B<parseResult>(I<\$text>, I<$match>, I<$lookahaed>, I<$column>, I<$firstnonspace>, I<$context>, I<$attribute>);</comment><comment>
</comment><comment>
</comment><comment>Called by every one of the test methods below. If the test matches, it will do a couple of subtests.</comment><comment>
</comment><comment>If B<$column> is a defined numerical value it will test if the process is at the requested column.</comment><comment>
</comment><comment>If B<$firnonspace> is true, it will test this also.</comment><comment>
</comment><comment>Ig it is not a look ahead and all tests are passed, B<$match> is then parsed and removed from B<$$text>.</comment><comment>
</comment><comment>
</comment><comment>=item B<pluginGet>(I<$language>);</comment><comment>
</comment><comment>
</comment><comment>Returns a reference to a plugin object for the specified language. Creating an </comment><comment>
</comment><comment>instance if needed.</comment><comment>
</comment><comment>
</comment><comment>=item B<reset></comment><comment>
</comment><comment>
</comment><comment>Resets the highlight engine to a fresh state, does not change the syntx.</comment><comment>
</comment><comment>
</comment><comment>=item B<snippet></comment><comment>
</comment><comment>
</comment><comment>Contains the current snippet of text that will have one attribute. The moment the attribute </comment><comment>
</comment><comment>changes it will be parsed.</comment><comment>
</comment><comment>
</comment><comment>=item B<snippetAppend>(I<$string>)</comment><comment>
</comment><comment>
</comment><comment>appends I<$string> to the current snippet.</comment><comment>
</comment><comment>
</comment><comment>=item B<snippetAttribute>(I<$attribute>)</comment><comment>
</comment><comment>
</comment><comment>Sets and returns the used attribute.</comment><comment>
</comment><comment>
</comment><comment>=item B<snippetForce></comment><comment>
</comment><comment>
</comment><comment>Forces the current snippet to be parsed.</comment><comment>
</comment><comment>
</comment><comment>=item B<snippetParse>(I<$text>, I<?$attribute?>)</comment><comment>
</comment><comment>
</comment><comment>If attribute is defined and differs from the current attribute it does a snippetForce and</comment><comment>
</comment><comment>sets the current attribute to B<$attribute>. Then it does a snippetAppend of B<$text></comment><comment>
</comment><comment>
</comment><comment>=item B<stack></comment><comment>
</comment><comment>
</comment><comment>sets and returns the instance variable 'stack', a reference to an array</comment><comment>
</comment><comment>
</comment><comment>=item B<stackPull></comment><comment>
</comment><comment>
</comment><comment>retrieves the element that is on top of the stack, decrements stacksize by 1.</comment><comment>
</comment><comment>
</comment><comment>=item B<stackPush>(I<$tagname>);</comment><comment>
</comment><comment>
</comment><comment>puts I<$tagname> on top of the stack, increments stacksize by 1</comment><comment>
</comment><comment>
</comment><comment>=item B<stackTop></comment><comment>
</comment><comment>
</comment><comment>Retrieves the element that is on top of the stack.</comment><comment>
</comment><comment>
</comment><comment>=item B<stateCompare>(I<\@state>)</comment><comment>
</comment><comment>
</comment><comment>Compares two lists, \@state and the stack. returns true if they</comment><comment>
</comment><comment>match.</comment><comment>
</comment><comment>
</comment><comment>=item B<stateGet></comment><comment>
</comment><comment>
</comment><comment>Returns a list containing the entire stack.</comment><comment>
</comment><comment>
</comment><comment>=item B<stateSet>(I<@list>)</comment><comment>
</comment><comment>
</comment><comment>Accepts I<@list> as the current stack.</comment><comment>
</comment><comment>
</comment><comment>=item B<substitutions></comment><comment>
</comment><comment>
</comment><comment>sets and returns a reference to the substitutions hash.</comment><comment>
</comment><comment>
</comment><comment>=back

The methods below all return a boolean value.</comment><comment>
</comment><comment>
</comment><comment>=over 4</comment><comment>
</comment><comment>
</comment><comment>=item B<testAnyChar>(I<\$text>, I<$string>, I<$insensitive>, I<$lookahaed>, I<$column>, I<$firstnonspace>, I<$context>, I<$attribute>);</comment><comment>
</comment><comment>
</comment><comment>=item B<testDetectChar>(I<\$text>, I<$char>, I<$insensitive>, I<$dynamic>, I<$lookahaed>, I<$column>, I<$firstnonspace>, I<$context>, I<$attribute>);</comment><comment>
</comment><comment>
</comment><comment>=item B<testDetect2Chars>(I<\$text>, I<$char1>, I<$char2>, I<$insensitive>, I<$dynamic>, I<$lookahaed>, I<$column>, I<$firstnonspace>, I<$context>, I<$attribute>);</comment><comment>
</comment><comment>
</comment><comment>=item B<testDetectIdentifier>(I<\$text>, I<$lookahaed>, I<$column>, I<$firstnonspace>, I<$context>, I<$attribute>);</comment><comment>
</comment><comment>
</comment><comment>=item B<testDetectSpaces>(I<\$text>, I<$lookahaed>, I<$column>, I<$firstnonspace>, I<$context>, I<$attribute>);</comment><comment>
</comment><comment>
</comment><comment>=item B<testFloat>(I<\$text>, I<$lookahaed>, I<$column>, I<$firstnonspace>, I<$context>, I<$attribute>);</comment><comment>
</comment><comment>
</comment><comment>=item B<testHlCChar>(I<\$text>, I<$lookahaed>, I<$column>, I<$firstnonspace>, I<$context>, I<$attribute>);</comment><comment>
</comment><comment>
</comment><comment>=item B<testHlCHex>(I<\$text>, I<$lookahaed>, I<$column>, I<$firstnonspace>, I<$context>, I<$attribute>);</comment><comment>
</comment><comment>
</comment><comment>=item B<testHlCOct>(I<\$text>, I<$lookahaed>, I<$column>, I<$firstnonspace>, I<$context>, I<$attribute>);</comment><comment>
</comment><comment>
</comment><comment>=item B<testHlCStringChar>(I<\$text>, I<$lookahaed>, I<$column>, I<$firstnonspace>, I<$context>, I<$attribute>);</comment><comment>
</comment><comment>
</comment><comment>=item B<testInt>(I<\$text>, I<$lookahaed>, I<$column>, I<$firstnonspace>, I<$context>, I<$attribute>);</comment><comment>
</comment><comment>
</comment><comment>=item B<testKeyword>(I<\$text>, I<$list>, I<$insensitive>, I<$lookahaed>, I<$column>, I<$firstnonspace>, I<$context>, I<$attribute>);</comment><comment>
</comment><comment>
</comment><comment>=item B<testLineContinue>(I<\$text>, I<$lookahaed>, I<$column>, I<$firstnonspace>, I<$context>, I<$attribute>);</comment><comment>
</comment><comment>
</comment><comment>=item B<testRangeDetect>(I<\$text>,  I<$char1>, I<$char2>, I<$insensitive>, I<$lookahaed>, I<$column>, I<$firstnonspace>, I<$context>, I<$attribute>);</comment><comment>
</comment><comment>
</comment><comment>=item B<testRegExpr>(I<\$text>, I<$reg>, I<$insensitive>, I<$dynamic>, I<$lookahaed>, I<$column>, I<$firstnonspace>, I<$context>, I<$attribute>);</comment><comment>
</comment><comment>
</comment><comment>=item B<testStringDetect>(I<\$text>, I<$string>, I<$insensitive>, I<$dynamic>, II<$lookahaed>, I<$column>, I<$firstnonspace>, I<$context>, I<$attribute>);</comment><comment>
</comment><comment>
</comment><comment>=back

=head1 ACKNOWLEDGEMENTS</comment><comment>
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
</comment><comment>You may freely distribute and/or modify this module under same terms as</comment><comment>
</comment><comment>Perl itself </comment><comment>
</comment><comment>
</comment><comment>=head1 SEE ALSO</comment><comment>
</comment><comment>
</comment><comment>Synax::Highlight::Engine::Kate http:://www.kate-editor.org</comment>