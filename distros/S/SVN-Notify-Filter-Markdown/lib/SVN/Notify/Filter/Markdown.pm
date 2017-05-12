package SVN::Notify::Filter::Markdown;

use strict;
use Text::Markdown ();
use SVN::Notify ();
$SVN::Notify::Filter::Markdown::VERSION = '0.05';

sub log_message {
    my ($notify, $lines) = @_;
    return $lines unless $notify->content_type eq 'text/html';
    my $m = Text::Markdown->new;
    return [ $m->markdown( join $/, @{ $lines } ) ];
}

1;

=head1 Name

SVN::Notify::Filter::Markdown - Convert SVN::Notify log messages from Markdown to HTML

=head1 Synopsis

Use F<svnnotify> in F<post-commit>:

  svnnotify --p "$1" --r "$2" --to you@example.com --handler HTML \
  --filter Markdown

Use the class in a custom script:

  use SVN::Notify;

  my $notifier = SVN::Notify->new(
      repos_path => $path,
      revision   => $rev,
      to         => 'you@example.com',
      handler    => 'HTML::ColorDiff',
      filters    => [ 'Markdown' ],
  );
  $notifier->prepare;
  $notifier->execute;

=head1 Description

This module filters SVN::Notify log message output to convert it from Markdown
format to HTML. Essentially, this means that if you write your commit log
messages in Markdown format and like to use
L<SVN::Notify::HTML|SVN::Notify::HTML> or
L<SVN::Notify::HTML::ColorDiff|SVN::Notify::HTML::ColorDiff> to format your
commit notifications, you can use this filter to convert the Markdown
formatting in the log message to HTML. Just pass C<--filter Markdown> to your
call to C<svnnotify> in F<post-commit> and you're good to go.

If you don't know what any of this means, read the L<SVN::Notify|SVN::Notify>
documentation. It talks about using SVN::Notify to send nicely formatted
emails for every Subversion commit. This module just makes them even more
nicely formatted.

=head1 See Also

=over

=item L<SVN::Notify|SVN::Notify>

=item L<Text::Markdown|Text::Markdown>

=item L<http://daringfireball.net/projects/markdown/>

=back

=head1 Support

This module is stored in an open L<GitHub
repository|http://github.com/theory/svn-notify-filter-markdown/>. Feel free to
fork and contribute!

Please file bug reports via L<GitHub
Issues|http://github.com/theory/svn-notify-filter-markdown/issues/> or by
sending mail to
L<bug-SVN-Notify-Filter-Markdown@rt.cpan.org|mailto:bug-SVN-Notify-Filter-Markdown@rt.cpan.org>.

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Copyright and License

Copyright (c) 2008-2011 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
