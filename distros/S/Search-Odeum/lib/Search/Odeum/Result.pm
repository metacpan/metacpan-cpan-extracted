package Search::Odeum::Result;
use strict;

1;

__END__

=head1 NAME

Search::Odeum::Result - Perl interface to the Odeum inverted index API.

=head1 SYNOPSIS

  use Search::Odeum;
  my $od = Search::Odeum->new('index');
  my $res = $od->search('Perl');
  while(my $doc = $res->next) {
      printf "%s\n", $doc->uri;
  }
  $od->close;

=head1 DESCRIPTION

Search::Odeum::Result is a search result of Odeum database.

=head1 METHODS

=over 4

=item next

get the next Search::Odeum::Document object.

=item init

initialize the iterator of documents.

=item num

get the number of the documents.
but this number contains the deleted document.

=item and_op(I<$result2>);

get the new result which have common elements of two results;

 my $res = $res1->and_op($res2);

=item or_op(I<$result2>);

get the new result which have sum of elements of two results;

=item notand_op(I<$result2>);

get the new result which have difference of elements of two results;

=back

=head1 SEE ALSO

http://qdbm.sourceforge.net/

=head1 AUTHOR

Tomohiro IKEBE, E<lt>ikebe@shebang.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Tomohiro IKEBE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
