#!inc/bin/testml-cpan

*swim.parse('Byte') == *byte
  :"Swim to ByteCode - +"

*swim.parse('Markdown') == *markdown
  :"Swim to Markdown - +"

*swim.parse('Pod') == *pod
  :"Swim to Pod - +"

*swim.parse('Pod', 'wrap') == *pod-wrap
  :"Swim to Pod - +"



=== Fix a formatting bug from ingydotnet/git-subrepo
--- swim
The `clone` command accepts the `--branch=` `--edit`, `--force` and `--message=` options.

--- pod-wrap
The C<clone> command accepts the C<--branch=> C<--edit>, C<--force> and C<--message=> options.



=== https://github.com/ingydotnet/inline-pm/pull/74/files
--- swim
Best of all, it works the same on both Unix and Microsoft Windows. See
[Inline-Support] for support information.

--- pod-wrap
Best of all, it works the same on both Unix and Microsoft Windows. See L<Inline-Support> for support information.



=== List with code
--- swim
* Foo `bar`

--- byte
+list
+item
 Foo 
+code
 bar
-code
-item
-list

# --- markdown
# * Foo `bar`

--- pod
=over

=item * Foo C<bar>

=back

=== '::' in data paragraph

--- swim
- Dump
  Data::Dumper is OK
--- byte
+data
 Dump
+para
 Data::Dumper is OK
-para
-data

--- pod
=over

=item Dump

Data::Dumper is OK

=back
