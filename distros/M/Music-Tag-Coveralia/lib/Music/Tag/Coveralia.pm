package Music::Tag::Coveralia;

use 5.014000;
use strict;
use warnings;
use parent qw/Music::Tag::Generic/;

our $VERSION = '0.001';

use HTTP::Tiny;
use WWW::Search;

sub required_values { qw/album/ }
sub set_values { qw/picture/ }

my $ht = HTTP::Tiny->new(agent => "Music-Tag-Coveralia/$VERSION");

sub get_tag {
	my ($self) = @_;

	my $album = $self->info->album;
	my $ws = WWW::Search->new('Coveralia::Albums');
	$self->status(1, "Searching coveralia for the album $album");
	$ws->native_query(WWW::Search::escape_query($album));
	while (my $res = $ws->next_result) {
		$self->status(1, 'Found album ' . $res->title . ' by ' . $res->artist);
		next if $self->info->has_data('artist') && $self->info->artist ne $res->artist;
		$self->status(0, 'Selected album ' . $res->title . ' by ' . $res->artist);
		if ($res->cover('frontal')) {
			my $resp = $ht->get($res->cover('frontal'));
			last unless $resp->{success};
			$self->info->picture({_Data => $resp->{content}});
			$self->tagchange('picture');
		}
		last
	}

	return $self->info
}

1;
__END__

=encoding utf-8

=head1 NAME

Music::Tag::Coveralia - Get cover art from coveralia.com

=head1 SYNOPSIS

  use Music::Tag;
  my $mt = Music::Tag->new($filename);
  $mt->add_plugin('Coveralia');
  $mt->get_tag;

=head1 DESCRIPTION

This plugin gets cover art from L<http://coveralia.com>, based on album and (optionally) artist.

=head1 REQUIRED DATA VALUES

=over

=item album

Used as the search term.

=back

=head1 USED DATA VALUES

=over

=item artist

If present, the first album found from this artist is chosen. Otherwise the first album found is chosen.

=back

=head1 SET DATA VALUES

=over

=item picture

=back

=head1 SEE ALSO

L<Music::Tag>, L<WWW::Search::Coveralia>, L<http://coveralia.com>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2015 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
