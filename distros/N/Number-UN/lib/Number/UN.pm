package Number::UN;
{
  $Number::UN::VERSION = '0.003';
}
# ABSTRACT: details about UN numbers

use strict;
use warnings;

use JSON 'decode_json';
use Path::Class 'file';

use Exporter 'import';
our @EXPORT_OK = qw(get_un);


sub get_un {
  my $fn = sprintf "%s/%04d.json", data_dir(), shift;
  return unless -e $fn;
  open my $fh, '<', $fn;
  my $text = <$fh>;
  my $hashref = decode_json $text or return;
  return %$hashref;
}

sub data_dir {
  file(__FILE__)->parent()->subdir('UN-data');  
}

1;

__END__

=pod

=head1 NAME

Number::UN - details about UN numbers

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use Number::UN 'get_un';

  my %un = get_un(1993);
  print $un{description}; # Combustible liquids, n.o.s.

=head1 NAME

Number::UN - UN Numbers

=head1 LICENSE

The source code is distributed under the L<Perl5/Artistic License|http://dev.perl.org/licenses/artistic.html>, copyright John Tantalo (2012).

The data material, including UN number descriptions, is distributed under the L<Creative Commons Attribution-ShareAlike License|http://en.wikipedia.org/wiki/Wikipedia:Text_of_Creative_Commons_Attribution-ShareAlike_3.0_Unported_License>. This material was collected from L<List of UN numbers|http://en.wikipedia.org/wiki/List_of_UN_numbers>, 16 Feb 2012.

=head1 AUTHOR

John Tantalo <john.tantalo@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by John Tantalo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
