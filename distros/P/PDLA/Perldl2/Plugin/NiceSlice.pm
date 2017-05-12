package PDLA::Perldl2::Plugin::NiceSlice;

use Devel::REPL::Plugin;

use namespace::clean -except => [ 'meta' ];

use PDLA::Lite;
use PDLA::NiceSlice;

my $preproc = sub {
   my ($txt) = @_;
   my $new = PDLA::NiceSlice::perldlpp('main',$txt);
   return $new;
};

around 'compile' => sub {

  my ($orig, $self) = (shift, shift);
  my ($lines, @args) = @_;

  no PDLA::NiceSlice;
  $lines = $preproc->($lines);

  $self->$orig($lines, @args);
};

1;

__END__

=head1 NAME

PDLA::Perldl2::Plugin::NiceSlice - enable PDLA NiceSlice syntax

=head1 DESCRIPTION

This plugin enables one to use the PDLA::NiceSlice syntax in an
instance of C<Devel::REPL> such as the new Perldl2 shell, C<pdl2>.
Without the plugin, array slicing looks like this:
    
  pdl> use PDLA;
  
  pdl> $a = sequence(10);
  $PDLA1 = [0 1 2 3 4 5 6 7 8 9];
  
  pdl> $a->slice("2:9:2");
  $PDLA1 = [2 4 6 8];

After the NiceSlice plugin has been loaded, you can use this:

  pdl> $a(2:9:2)
  $PDLA1 = [2 4 6 8];

=head1 CAVEATS

C<PDLA::NiceSlice> uses Perl source preprocessing.
If you need 100% pure Perl compatibility, use the
slice method instead.

=head1 SEE ALSO

C<PDLA::NiceSlice>, C<Devel::REPL>, C<PDLA::Perldl>

=head1 AUTHOR

Chris Marshall, C<< <chm at cpan dot org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Christopher Marshall

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
