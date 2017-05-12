package Rhetoric::Storage::CouchDB;
use common::sense;
use aliased 'Squatting::H';

use AnyEvent::CouchDB;
use Method::Signatures::Simple;

use Rhetoric::Helpers ':all';

our $storage = H->new({
  init => method {
  },
  meta => method($key, $value) {
  },
  new_post => method($post) {
  },
  post => method($post) {
  },
  posts => method($year, $month, $slug) {
  },
  categories => method {
  },
  category_posts => method {
  },
  archives => method {
  },
  archive_posts => method($year, $month) {
  },
  comments => method($post) {
  },
  new_comment => method($year, $month, $slug, $comment) {
  },
});

1;

__END__

=head1 NAME

Rhetoric::Storage::File - filesystem-based storage for Rhetoric blog data

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 API

=head2 Package Variables

=head3 $storage

=head2 Methods for $storage

=head3 init


=cut

# Local Variables: ***
# mode: cperl ***
# indent-tabs-mode: nil ***
# cperl-close-paren-offset: -2 ***
# cperl-continued-statement-offset: 2 ***
# cperl-indent-level: 2 ***
# cperl-indent-parens-as-block: t ***
# cperl-tab-always-indent: nil ***
# End: ***
# vim:tabstop=2 softtabstop=2 shiftwidth=2 shiftround expandtab

