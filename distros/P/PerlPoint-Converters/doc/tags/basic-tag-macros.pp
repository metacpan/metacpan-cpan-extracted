
// This macro is used to display a final hint usually used in
// a basic tags PerlPoint documentation. It uses Active Content.

// The trick is to list all tag names except of the one documented
// in the current section, which is passed by option "current".

// If there is a documentation of a mentioned tag as well, a
// reference will be generated, otherwise the tagname is just
// formatted boldly.

+OTHER_BASIC_TAGS:\EMBED{lang=perl}
                  {
                   my @list=map
                             {"\\B<\\REF{occasion=1 name=$main::_ type=linked}<$main::_>>"}
                                grep(uc($main::_) ne '__current__', qw(
                                                                       B
                                                                       C
                                                                       EMBED
                                                                       FORMAT
                                                                       HIDE
                                                                       I
                                                                       IMAGE
                                                                       INCLUDE
                                                                       LOCALTOC
                                                                       READY
                                                                       REF
                                                                       SEQ
                                                                       STOP
                                                                       TABLE
                                                                      )
                                    );
                   join(' ', join(', ', @list[0..($#list-1)]), 'and', $list[-1]);
                  }
                  \END_EMBED

