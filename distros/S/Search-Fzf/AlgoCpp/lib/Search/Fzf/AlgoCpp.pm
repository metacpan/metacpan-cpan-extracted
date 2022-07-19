package Search::Fzf::AlgoCpp;
use strict;
use warnings;

our $VERSION = '0.01';
# our %EXPORT_TAGS = ( 'all' => [qw(test)] );
# our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} } );

require XSLoader;
XSLoader::load('Search::Fzf::AlgoCpp', $VERSION);

1;
__END__

=head1 NAME

Search::Fzf::AlgoCpp - A C++ backend for Fzf.

=head1 SYNOPSIS

  use Search::Fzf::AlgoCpp;
  my @perlArr = qw(Hello fzf world);
  my $tac = 0;
  my $caseInsensitive = 1;
  my $headerLines = 0;
  my $algo = Search::Fzf::AlgoCpp->new($tac, $caseInsensitive, $headerLines);
  $algo->read(\@perlArr);

=head1 DESCRIPTION

A C++ backend for Fzf, it contains input and match functions.

=head1 AUTHOR

Liyao, E<lt>liyao0117@qq.com<gt>

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2009 by Liyao.

  This code is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
