package Syntax::Feature::Qqn;
use strict;
use warnings;

our $VERSION = '0.06';

sub install {
    shift;
    require Syntax::Feature::Qn;
    Devel::Declare->setup_for( {@_}->{into}, {
        qqn => { const => \&Syntax::Feature::Qn::_parse },
    });
}

1;

__END__

=head1 NAME

Syntax::Feature::Qqn - Perl syntax extension for line-based quoting

=head1 SYNOPSIS

  use syntax 'qqn';

  $bar = 'BAR';
  @foo = qqn {
    foo
    $bar
    bam
  };
  # ("foo", "BAR", "bam")

=head1 DESCRIPTION

This module is an extension of Syntax::Feature::Qn. See those docs for
details.

=head1 SEE ALSO

Syntax::Feature::Qn, q and qq in perlfunc.

=head1 AUTHOR

Rick Myers, <jrm@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Rick Myers.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.20.1 or, at
your option, any later version of Perl 5 you may have available.

