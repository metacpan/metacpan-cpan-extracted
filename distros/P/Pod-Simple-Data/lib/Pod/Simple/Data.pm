package Pod::Simple::Data;

use strict;
use warnings;
use 5.008_005;

use Pod::Simple ();
use vars qw( @ISA $VERSION );
$VERSION = '0.02';
@ISA = ('Pod::Simple');

sub new {
  my $self = shift;
  my $new = $self->SUPER::new();
  $new->{'output_fh'} ||= *STDOUT{IO};
  $new->nix_X_codes(1);
  push @_, '*' unless scalar(@_);
  $new->accept_targets(@_);
  return $new;
}

sub _handle_text {
  my $para = $_[0]{'curr_open'}->[-1];
  if (defined $para && $para->[0] eq '=for') {
     print {$_[0]{'output_fh'}} $_[1];
     print {$_[0]{'output_fh'}} "\n" unless $_[1] =~ /\n$/;
  }
  return;
}

1;
__END__

=head1 NAME

Pod::Simple::Data -- retrieve the data inlined in Pod

=for html
<a href="https://travis-ci.org/fperrad/Pod-Simple-Data"><img alt="Build Status" src="https://travis-ci.org/fperrad/Pod-Simple-Data.png?branch=master" /></a>
<a href="https://coveralls.io/repos/fperrad/Pod-Simple-Data?branch=master"><img alt="Coverage Status" src="https://coveralls.io/repos/fperrad/Pod-Simple-Data.png?branch=master" /></a>
<a href="http://badge.fury.io/pl/Pod-Simple-Data"><img alt="CPAN version" src="http://badge.fury.io/pl/Pod-Simple-Data.svg" /></a>

=head1 SYNOPSIS

  perl -MPod::Simple::Data -e \
   "exit Pod::Simple::Data->new('stuff', 'xstuff')->parse_file(shift)->any_errata_seen" \
   thingy.pod

=head1 DESCRIPTION

This class is that for retrieving data from C<< =begin/=for/=end >> sections.
The constructor accepts a list of identifier, the default is C<'*'> which allows
to retrieve all data.

This is a subclass of L<Pod::Simple> and inherits all its methods.

=head1 CALLING FROM THE COMMAND LINE

  perl -MPod::Simple::Data -e \
   "exit Pod::Simple::Data->new()->parse_file(shift)->any_errata_seen" \
   thingy.pod

=head1 CALLING FROM PERL

=head2 Minimal code

  use Pod::Simple::Data;
  my $p = Pod::Simple::Data->new();
  $p->output_string(\my $data);
  $p->parse_file('path/to/Module/Name.pm');
  open my $out, '>', 'out.dat' or die "Cannot open 'out.dat': $!\n";
  print $out $data;

=head1 SEE ALSO

L<Pod::Simple>, L<< perlpodspec/About Data Paragraphs >>,
L<Travis CI|https://travis-ci.org/fperrad/Pod-Simple-Data>,
L<Coveralls|https://coveralls.io/r/fperrad/Pod-Simple-Data>

=head1 AUTHOR

Francois Perrad E<lt>francois.perrad@gadz.orgE<gt>

=head1 COPYRIGHT

Copyright 2014 Francois Perrad

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
