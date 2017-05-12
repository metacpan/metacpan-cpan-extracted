<comment>#!perl</comment><comment>
</comment><normal>
</normal><keyword>use</keyword><normal> </normal><keyword>strict</keyword><normal>;</normal><normal>
</normal><keyword>use</keyword><normal> </normal><keyword>warnings</keyword><normal>;</normal><normal>
</normal><keyword>use</keyword><normal> </normal><keyword>diagnostics</keyword><normal>;</normal><normal>
</normal><keyword>use</keyword><normal> </normal><function>List::Util</function><normal> </normal><operator>'</operator><string>shuffle</string><operator>'</operator><normal>;</normal><normal>
</normal><normal>
</normal><comment># The size of the maze. Take the arguments from the command line or from the</comment><comment>
</comment><comment># default.</comment><comment>
</comment><keyword>my</keyword><normal> ( </normal><datatype>$HEIGHT</datatype><normal>, </normal><datatype>$WIDTH</datatype><normal> ) = </normal><variable>@ARGV</variable><normal> ? </normal><variable>@ARGV</variable><normal> : ( </normal><float>20</float><normal>, </normal><float>20</float><normal> );</normal><normal>
</normal><normal>
</normal><comment># Time::HiRes was officially released with Perl 5.8.0, though Module::Corelist</comment><comment>
</comment><comment># reports that it was actually released as early as v5.7.3. If you don't have</comment><comment>
</comment><comment># this module, your version of Perl is probably over a decade old</comment><comment>
</comment><keyword>use</keyword><normal> </normal><function>Time</function><normal>::HiRes </normal><operator>'</operator><string>usleep</string><operator>'</operator><normal>;</normal><normal>
</normal><normal>
</normal><comment># In Perl, $^O is the name of your operating system. On Windows (as of this</comment><comment>
</comment><comment># writing), it always 'MSWin32'.</comment><comment>
</comment><keyword>use</keyword><normal> </normal><keyword>constant</keyword><normal> IS_WIN32 => </normal><operator>'</operator><string>MSWin32</string><operator>'</operator><normal> </normal><operator>eq</operator><normal> </normal><variable>$^O</variable><normal>;</normal><normal>
</normal><normal>
</normal><comment># On Windows, we assume that the command to clear the screen is 'cls'. On all</comment><comment>
</comment><comment># other systems, we assume it's 'clear'. You may need to adjust this.</comment><comment>
</comment><keyword>use</keyword><normal> </normal><keyword>constant</keyword><normal> CLEAR => IS_WIN32 ? </normal><operator>'</operator><string>cls</string><operator>'</operator><normal> : </normal><operator>'</operator><string>clear</string><operator>'</operator><normal>;</normal><normal>
</normal><normal>
</normal><comment># We will only redraw the screen (and thus show the recursive maze generation)</comment><comment>
</comment><comment># if and only if the system is capable of clearing the screen. The system()</comment><comment>
</comment><comment># command returns 0 upon success. See perldoc -f system.</comment><comment>
</comment><comment># The following line works because $x == $y returns a boolean value.</comment><comment>
</comment><comment>#use constant CAN_REDRAW => 0 == system(CLEAR);</comment><comment>
</comment><keyword>use</keyword><normal> </normal><keyword>constant</keyword><normal> CAN_REDRAW => 0;</normal><normal>
</normal><normal>
</normal><comment># Time in microseconds between screen redraws. See Time::HiRes and the usleep</comment><comment>
</comment><comment># function</comment><comment>
</comment><keyword>use</keyword><normal> </normal><keyword>constant</keyword><normal> DELAY => </normal><float>10</float><normal>_000;</normal><normal>
</normal><normal>
</normal><keyword>use</keyword><normal> </normal><keyword>constant</keyword><normal> OPPOSITE_OF => {</normal><normal>
</normal><normal>    north => </normal><operator>'</operator><string>south</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>    south => </normal><operator>'</operator><string>north</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>    west  => </normal><operator>'</operator><string>east</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>    east  => </normal><operator>'</operator><string>west</string><operator>'</operator><normal>,</normal><normal>
</normal><normal>};</normal><normal>
</normal><normal>
</normal><keyword>my</keyword><normal> </normal><datatype>@maze</datatype><normal>;</normal><normal>
</normal><normal>tunnel( 0, 0, \</normal><datatype>@maze</datatype><normal> );</normal><normal>
</normal><keyword>my</keyword><normal> </normal><datatype>$num</datatype><normal> = </normal><float>10</float><normal>_000;</normal><normal>
</normal><normal>
</normal><function>system</function><normal>(CLEAR) </normal><keyword>if</keyword><normal> CAN_REDRAW;</normal><normal>
</normal><function>print</function><normal> render_maze( \</normal><datatype>@maze</datatype><normal> );</normal><normal>
</normal><normal>
</normal><function>exit</function><normal>;</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>tunnel</function><normal> {</normal><normal>
</normal><normal>    </normal><keyword>my</keyword><normal> ( </normal><datatype>$x</datatype><normal>, </normal><datatype>$y</datatype><normal>, </normal><datatype>$maze</datatype><normal> ) = </normal><datatype>@_</datatype><normal>;</normal><normal>
</normal><normal>
</normal><normal>    </normal><keyword>if</keyword><normal> (CAN_REDRAW) {</normal><normal>
</normal><normal>        </normal><keyword>my</keyword><normal> </normal><datatype>$render</datatype><normal> = render_maze(</normal><datatype>$maze</datatype><normal>);</normal><normal>
</normal><normal>        </normal><function>system</function><normal>(CLEAR);</normal><normal>
</normal><normal>        </normal><function>print</function><normal> </normal><datatype>$render</datatype><normal>;</normal><normal>
</normal><normal>        usleep DELAY;</normal><normal>
</normal><normal>    }</normal><normal>
</normal><normal>
</normal><normal>    </normal><comment># Here we need to use a unary plus in front of OPPOSITE_OF so that</comment><comment>
</comment><normal>    </normal><comment># Perl understands that this is a constant and that we're not trying</comment><comment>
</comment><normal>    </normal><comment># to access the %OPPOSITE_OF variable.</comment><comment>
</comment><normal>    </normal><keyword>my</keyword><normal> </normal><datatype>@directions</datatype><normal> = shuffle </normal><function>keys</function><normal> </normal><datatype>%</datatype><normal>{ +OPPOSITE_OF };</normal><normal>
</normal><normal>
</normal><normal>    </normal><keyword>foreach</keyword><normal> </normal><keyword>my</keyword><normal> </normal><datatype>$direction</datatype><normal> (</normal><datatype>@directions</datatype><normal>) {</normal><normal>
</normal><normal>        </normal><keyword>my</keyword><normal> ( </normal><datatype>$new_x</datatype><normal>, </normal><datatype>$new_y</datatype><normal> ) = ( </normal><datatype>$x</datatype><normal>, </normal><datatype>$y</datatype><normal> );</normal><normal>
</normal><normal>
</normal><normal>        </normal><keyword>if</keyword><normal>    ( </normal><operator>'</operator><string>east</string><operator>'</operator><normal>  </normal><operator>eq</operator><normal> </normal><datatype>$direction</datatype><normal> ) { </normal><datatype>$new_x</datatype><normal> += </normal><float>1</float><normal>; }</normal><normal>
</normal><normal>        </normal><keyword>elsif</keyword><normal> ( </normal><operator>'</operator><string>west</string><operator>'</operator><normal>  </normal><operator>eq</operator><normal> </normal><datatype>$direction</datatype><normal> ) { </normal><datatype>$new_x</datatype><normal> </normal><operator>-</operator><normal>= </normal><float>1</float><normal>; }</normal><normal>
</normal><normal>        </normal><keyword>elsif</keyword><normal> ( </normal><operator>'</operator><string>south</string><operator>'</operator><normal> </normal><operator>eq</operator><normal> </normal><datatype>$direction</datatype><normal> ) { </normal><datatype>$new_y</datatype><normal> += </normal><float>1</float><normal>; }</normal><normal>
</normal><normal>        </normal><keyword>else</keyword><normal>                            { </normal><datatype>$new_y</datatype><normal> </normal><operator>-</operator><normal>= </normal><float>1</float><normal>; }</normal><normal>
</normal><normal>
</normal><normal>        </normal><keyword>if</keyword><normal> ( have_not_visited( </normal><datatype>$new_x</datatype><normal>, </normal><datatype>$new_y</datatype><normal>, </normal><datatype>$maze</datatype><normal> ) ) {</normal><normal>
</normal><normal>            </normal><datatype>$maze</datatype><normal>->[</normal><datatype>$y</datatype><normal>][</normal><datatype>$x</datatype><normal>]{</normal><datatype>$direction</datatype><normal>} = </normal><float>1</float><normal>;</normal><normal>
</normal><normal>            </normal><datatype>$maze</datatype><normal>->[</normal><datatype>$new_y</datatype><normal>][</normal><datatype>$new_x</datatype><normal>]{ OPPOSITE_OF->{</normal><datatype>$direction</datatype><normal>} } = </normal><float>1</float><normal>;</normal><normal>
</normal><normal>
</normal><normal>            </normal><comment># This program will often recurse more than one hundred levels</comment><comment>
</comment><normal>            </normal><comment># deep and this is Perl's default recursion depth level prior to</comment><comment>
</comment><normal>            </normal><comment># issuing warnings. In this case, we're telling Perl that we know</comment><comment>
</comment><normal>            </normal><comment># that we'll exceed the recursion depth and to now warn us about</comment><comment>
</comment><normal>            </normal><comment># it</comment><comment>
</comment><normal>            </normal><keyword>no</keyword><normal> </normal><keyword>warnings</keyword><normal> </normal><operator>'</operator><string>recursion</string><operator>'</operator><normal>;</normal><normal>
</normal><normal>            tunnel( </normal><datatype>$new_x</datatype><normal>, </normal><datatype>$new_y</datatype><normal>, </normal><datatype>$maze</datatype><normal> );</normal><normal>
</normal><normal>        }</normal><normal>
</normal><normal>    }</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>have_not_visited</function><normal> {</normal><normal>
</normal><normal>    </normal><keyword>my</keyword><normal> ( </normal><datatype>$x</datatype><normal>, </normal><datatype>$y</datatype><normal>, </normal><datatype>$maze</datatype><normal> ) = </normal><datatype>@_</datatype><normal>;</normal><normal>
</normal><normal>
</normal><normal>    </normal><comment># the first two lines return false  if we're out of bounds</comment><comment>
</comment><normal>    </normal><keyword>return</keyword><normal> </normal><keyword>if</keyword><normal> </normal><datatype>$x</datatype><normal> < 0 </normal><operator>or</operator><normal> </normal><datatype>$y</datatype><normal> < 0;</normal><normal>
</normal><normal>    </normal><keyword>return</keyword><normal> </normal><keyword>if</keyword><normal> </normal><datatype>$x</datatype><normal> > </normal><datatype>$WIDTH</datatype><normal> </normal><operator>-</operator><normal> </normal><float>1</float><normal> </normal><operator>or</operator><normal> </normal><datatype>$y</datatype><normal> > </normal><datatype>$HEIGHT</datatype><normal> </normal><operator>-</operator><normal> </normal><float>1</float><normal>;</normal><normal>
</normal><normal>
</normal><normal>    </normal><comment># this returns false if we've already visited this cell</comment><comment>
</comment><normal>    </normal><keyword>return</keyword><normal> </normal><keyword>if</keyword><normal> </normal><datatype>$maze</datatype><normal>->[</normal><datatype>$y</datatype><normal>][</normal><datatype>$x</datatype><normal>];</normal><normal>
</normal><normal>
</normal><normal>    </normal><comment># return true</comment><comment>
</comment><normal>    </normal><keyword>return</keyword><normal> </normal><float>1</float><normal>;</normal><normal>
</normal><normal>}</normal><normal>
</normal><normal>
</normal><keyword>sub </keyword><function>render_maze</function><normal> {</normal><normal>
</normal><normal>    </normal><keyword>my</keyword><normal> </normal><datatype>$maze</datatype><normal> = </normal><function>shift</function><normal>;</normal><normal>
</normal><normal>
</normal><normal>    </normal><keyword>my</keyword><normal> </normal><datatype>$as_string</datatype><normal> = </normal><operator>"</operator><string>_</string><operator>"</operator><normal> x ( </normal><float>1</float><normal> + </normal><datatype>$WIDTH</datatype><normal> </normal><operator>*</operator><normal> </normal><float>2</float><normal> );</normal><normal>
</normal><normal>    </normal><datatype>$as_string</datatype><normal> .= </normal><operator>"</operator><char>\n</char><operator>"</operator><normal>;</normal><normal>
</normal><normal>
</normal><normal>    </normal><keyword>for</keyword><normal> </normal><keyword>my</keyword><normal> </normal><datatype>$y</datatype><normal> ( 0 .. </normal><datatype>$HEIGHT</datatype><normal> </normal><operator>-</operator><normal> </normal><float>1</float><normal> ) {</normal><normal>
</normal><normal>        </normal><datatype>$as_string</datatype><normal> .= </normal><operator>"</operator><string>|</string><operator>"</operator><normal>;</normal><normal>
</normal><normal>        </normal><keyword>for</keyword><normal> </normal><keyword>my</keyword><normal> </normal><datatype>$x</datatype><normal> ( 0 .. </normal><datatype>$WIDTH</datatype><normal> </normal><operator>-</operator><normal> </normal><float>1</float><normal> ) {</normal><normal>
</normal><normal>            </normal><keyword>my</keyword><normal> </normal><datatype>$cell</datatype><normal> = </normal><datatype>$maze</datatype><normal>->[</normal><datatype>$y</datatype><normal>][</normal><datatype>$x</datatype><normal>];</normal><normal>
</normal><normal>            </normal><datatype>$as_string</datatype><normal> .= </normal><datatype>$cell</datatype><normal>->{south} ? </normal><operator>"</operator><string> </string><operator>"</operator><normal> : </normal><operator>"</operator><string>_</string><operator>"</operator><normal>;</normal><normal>
</normal><normal>            </normal><datatype>$as_string</datatype><normal> .= </normal><datatype>$cell</datatype><normal>->{east}  ? </normal><operator>"</operator><string> </string><operator>"</operator><normal> : </normal><operator>"</operator><string>|</string><operator>"</operator><normal>;</normal><normal>
</normal><normal>        }</normal><normal>
</normal><normal>        </normal><datatype>$as_string</datatype><normal> .= </normal><operator>"</operator><char>\n</char><operator>"</operator><normal>;</normal><normal>
</normal><normal>    }</normal><normal>
</normal><normal>    </normal><keyword>return</keyword><normal> </normal><datatype>$as_string</datatype><normal>;</normal><normal>
</normal><normal>}</normal><normal>
</normal>